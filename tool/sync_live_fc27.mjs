import { readFile, writeFile } from 'node:fs/promises';

const catalogPath = 'data/live/catalog.json';

const playerPages = [
  { url: 'https://www.fut.gg/fc-27/ratings/', version: 'Gold Rare' },
  { url: 'https://www.fut.gg/rarities/base-icon/', version: 'Base Icon' },
  { url: 'https://www.fut.gg/rarities/base-hero/', version: 'Base Hero' },
  { url: 'https://www.fut.gg/rarities/team-of-the-week/', version: 'Team of the week' },
  { url: 'https://www.fut.gg/rarities/destined-for-glory/', version: 'Destined for Glory' },
  { url: 'https://www.fut.gg/rarities/squad-foundations/', version: 'Squad Foundations' },
  { url: 'https://www.fut.gg/hall-of-fut/', version: 'Base Hall of FUT' },
  { url: 'https://www.fut.gg/rarities/debut-international-icon/', version: 'Debut International Icon' },
];

const pages = {
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
          'user-agent': 'FCBaz-LiveData/1.3 (+https://github.com/sahandse/FCbaz)',
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
  return String(value ?? '')
    .replace(/<[^>]+>/g, ' ')
    .replace(/\s+/g, ' ')
    .replace(/^(new|image:?|view)\s+/i, '')
    .trim();
}

function discoverPlayers(text, baseUrl, version) {
  const found = [];
  const seen = new Set();
  const patterns = [
    /([A-ZÀ-ÖØ-öø-ÿĀ-ž][A-Za-zÀ-ÖØ-öø-ÿĀ-ž'’.-]+(?:\s+[A-ZÀ-ÖØ-öø-ÿĀ-ž][A-Za-zÀ-ÖØ-öø-ÿĀ-ž'’.-]+){0,4})\s+(\d{2})\s+OVR\s*[·•-]\s*(GK|CB|LB|RB|LWB|RWB|CDM|CM|CAM|LM|RM|LW|RW|CF|ST)\b/g,
    /([A-ZÀ-ÖØ-öø-ÿĀ-ž][A-Za-zÀ-ÖØ-öø-ÿĀ-ž'’.-]+(?:\s+[A-ZÀ-ÖØ-öø-ÿĀ-ž][A-Za-zÀ-ÖØ-öø-ÿĀ-ž'’.-]+){0,4})\s+(\d{2})\s+(GK|CB|LB|RB|LWB|RWB|CDM|CM|CAM|LM|RM|LW|RW|CF|ST)\b/g,
  ];

  for (const pattern of patterns) {
    for (const match of text.matchAll(pattern)) {
      const name = clean(match[1]);
      const rating = Number(match[2]);
      const position = match[3];
      const key = `${name}|${rating}|${position}|${version}`.toLowerCase();
      if (!name || rating < 40 || rating > 99 || seen.has(key)) continue;
      seen.add(key);
      found.push({
        id: slugId('futgg', `${name}-${rating}-${position}-${version}`),
        name,
        rating,
        position,
        positions: [position],
        version,
        rarity: version,
        card_type: version,
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
    byKey.set(
      key,
      previous
        ? { ...previous, ...item, source_url: item.source_url || previous.source_url }
        : item,
    );
  }
  return [...byKey.values()];
}

let successfulSections = 0;
let totalPlayerDiscoveries = 0;
for (const source of playerPages) {
  try {
    const text = await reader(source.url);
    const items = discoverPlayers(text, source.url, source.version);
    if (items.length === 0) {
      console.warn(`[players:${source.version}] no items discovered; keeping previous snapshot`);
      continue;
    }
    current.players = mergeVerified(
      current.players,
      items,
      (item) => `${item.name ?? ''}|${item.rating ?? ''}|${item.position ?? ''}|${item.version ?? ''}`.toLowerCase(),
    );
    successfulSections++;
    totalPlayerDiscoveries += items.length;
    console.log(`[players:${source.version}] discovered ${items.length}, total ${current.players.length}`);
  } catch (error) {
    console.warn(`[players:${source.version}] sync failed: ${error}`);
  }
}

for (const [section, url] of Object.entries(pages)) {
  try {
    const text = await reader(url);
    const items = discover(text, section, url);
    if (items.length === 0) {
      console.warn(`[${section}] no items discovered; keeping previous snapshot`);
      continue;
    }
    current[section] = mergeVerified(
      current[section],
      items,
      (item) => String(item.title_en ?? item.title ?? '').trim().toLowerCase(),
    );
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
current.sources = [
  ...new Set([
    ...(current.sources ?? []),
    ...playerPages.map((item) => item.url),
    ...Object.values(pages),
  ]),
];

await writeFile(catalogPath, `${JSON.stringify(current, null, 2)}\n`);
console.log(`Updated ${catalogPath}; player discoveries this run: ${totalPlayerDiscoveries}`);
