import { readFile, writeFile } from 'node:fs/promises';

const catalogPath = 'data/live/catalog.json';
const pages = {
  players: 'https://www.fut.gg/fc-27/ratings/',
  evolutions: 'https://www.fut.gg/evolutions/',
  sbcs: 'https://www.fut.gg/sbc/',
  objectives: 'https://www.fut.gg/objectives/',
};

const current = JSON.parse(await readFile(catalogPath, 'utf8'));

async function reader(url) {
  const targets = [`https://r.jina.ai/${url}`, url];
  let lastError;
  for (const target of targets) {
    try {
      const response = await fetch(target, {
        headers: {
          'user-agent': 'FCBaz-LiveData/1.2.1 (+https://github.com/sahandse/FCbaz)',
          accept: 'text/plain,text/markdown,text/html;q=0.9,*/*;q=0.8',
        },
        signal: AbortSignal.timeout(20000),
      });
      if (!response.ok) throw new Error(`${response.status} ${response.statusText}`);
      const text = await response.text();
      if (text.length < 300) throw new Error('response too small');
      return text;
    } catch (error) {
      lastError = error;
    }
  }
  throw lastError ?? new Error(`Unable to fetch ${url}`);
}

function slugId(prefix, value) {
  return `${prefix}-${value}`
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 110);
}

function clean(value) {
  return value
    .replace(/<[^>]+>/g, ' ')
    .replace(/\s+/g, ' ')
    .replace(/^(new|image:?|view)\s+/i, '')
    .trim();
}

function discoverPlayers(text, baseUrl) {
  const found = [];
  const seen = new Set();
  const patterns = [
    /([A-ZÀ-ÖØ-öø-ÿĀ-ž][A-Za-zÀ-ÖØ-öø-ÿĀ-ž'’.-]+(?:\s+[A-ZÀ-ÖØ-öø-ÿĀ-ž][A-Za-zÀ-ÖØ-öø-ÿĀ-ž'’.-]+){1,4})\s+(\d{2})\s+OVR\s*[·•-]\s*([A-Z]{1,4})/g,
    /([A-ZÀ-ÖØ-öø-ÿĀ-ž][A-Za-zÀ-ÖØ-öø-ÿĀ-ž'’.-]+(?:\s+[A-ZÀ-ÖØ-öø-ÿĀ-ž][A-Za-zÀ-ÖØ-öø-ÿĀ-ž'’.-]+){1,4})\s+(\d{2})\s+(GK|CB|LB|RB|LWB|RWB|CDM|CM|CAM|LM|RM|LW|RW|CF|ST)\b/g,
  ];
  for (const pattern of patterns) {
    for (const match of text.matchAll(pattern)) {
      const name = clean(match[1]);
      const rating = Number(match[2]);
      const position = match[3];
      if (!name || rating < 40 || rating > 99 || seen.has(`${name}-${rating}-${position}`)) continue;
      seen.add(`${name}-${rating}-${position}`);
      found.push({
        id: slugId('futgg', `${name}-${rating}-${position}`),
        name,
        rating,
        position,
        positions: [position],
        version: 'FC27',
        source_url: baseUrl,
      });
    }
  }
  return found;
}

function discover(markdown, section, baseUrl) {
  const pathPart = section === 'sbcs' ? 'sbc' : section;
  const absolute = new RegExp(
    `\\[([^\\]]{2,100})\\]\\((https?:\\/\\/www\\.fut\\.gg\\/${pathPart}\\/[^)#?\\s]+[^)]*)\\)`,
    'gi',
  );
  const relative = new RegExp(
    `\\[([^\\]]{2,100})\\]\\((\\/${pathPart}\\/[^)#?\\s]+[^)]*)\\)`,
    'gi',
  );
  const found = [];
  const seen = new Set();
  for (const regex of [absolute, relative]) {
    for (const match of markdown.matchAll(regex)) {
      const title = clean(match[1]);
      if (!title || /^(all|expired|players|evolutions|objectives|sbc|view all)$/i.test(title)) continue;
      const url = match[2].startsWith('http') ? match[2] : new URL(match[2], 'https://www.fut.gg').toString();
      const key = title.toLowerCase();
      if (seen.has(key)) continue;
      seen.add(key);
      const tail = markdown.slice(match.index + match[0].length, match.index + match[0].length + 360);
      const description = clean(tail.split('\n').find((line) => clean(line).length > 20) ?? '');
      found.push({
        id: slugId('futgg', title),
        ...(section === 'sbcs' ? { title_en: title } : { title }),
        description: description.slice(0, 260),
        source_url: url || baseUrl,
      });
    }
  }
  return found;
}

function mergeVerified(existing = [], discovered = [], keyOf) {
  const byKey = new Map();
  for (const item of existing) {
    const key = keyOf(item);
    if (key) byKey.set(key, { ...item });
  }
  for (const item of discovered) {
    const key = keyOf(item);
    if (!key) continue;
    const previous = byKey.get(key);
    byKey.set(key, previous ? { ...previous, ...item, source_url: item.source_url || previous.source_url } : item);
  }
  return [...byKey.values()];
}

let successfulSections = 0;
for (const [section, url] of Object.entries(pages)) {
  try {
    const text = await reader(url);
    const items = section === 'players' ? discoverPlayers(text, url) : discover(text, section, url);
    if (items.length === 0) {
      console.warn(`[${section}] no items discovered; keeping previous snapshot`);
      continue;
    }
    if (section === 'players') {
      current.players = mergeVerified(current.players, items, (item) => `${item.name ?? ''}|${item.rating ?? ''}|${item.position ?? ''}`.toLowerCase());
    } else {
      current[section] = mergeVerified(current[section], items, (item) => String(item.title_en ?? item.title ?? '').trim().toLowerCase());
    }
    successfulSections++;
    console.log(`[${section}] discovered ${items.length}, total ${current[section].length}`);
  } catch (error) {
    console.warn(`[${section}] sync failed: ${error}`);
  }
}

if (successfulSections === 0) {
  throw new Error('No live FC27 section could be refreshed; catalog left unchanged.');
}

current.game_year = 27;
current.generated_at = new Date().toISOString();
current.sources = [...new Set([...(current.sources ?? []), ...Object.values(pages)])];

await writeFile(catalogPath, `${JSON.stringify(current, null, 2)}\n`);
console.log(`Updated ${catalogPath}`);
