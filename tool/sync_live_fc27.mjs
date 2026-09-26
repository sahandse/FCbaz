import { readFile, writeFile } from 'node:fs/promises';

const catalogPath = 'data/live/catalog.json';
const pages = {
  evolutions: 'https://www.fut.gg/evolutions/',
  sbcs: 'https://www.fut.gg/sbc/',
  objectives: 'https://www.fut.gg/objectives/',
};

const current = JSON.parse(await readFile(catalogPath, 'utf8'));

async function reader(url) {
  const targets = [
    `https://r.jina.ai/${url}`,
    url,
  ];
  let lastError;
  for (const target of targets) {
    try {
      const response = await fetch(target, {
        headers: {
          'user-agent': 'FCBaz-LiveData/1.2 (+https://github.com/sahandse/FCbaz)',
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
      if (!title || /^(all|expired|players|evolutions|objectives|sbc|view all)$/i.test(title)) {
        continue;
      }
      const url = match[2].startsWith('http')
        ? match[2]
        : new URL(match[2], 'https://www.fut.gg').toString();
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

function mergeVerified(existing = [], discovered = []) {
  const byTitle = new Map();
  for (const item of existing) {
    const title = String(item.title_en ?? item.title ?? '').trim().toLowerCase();
    if (title) byTitle.set(title, { ...item });
  }

  for (const item of discovered) {
    const title = String(item.title_en ?? item.title ?? '').trim().toLowerCase();
    if (!title) continue;
    const previous = byTitle.get(title);
    byTitle.set(title, previous
      ? {
          ...item,
          ...previous,
          source_url: item.source_url || previous.source_url,
          description: previous.description || item.description,
        }
      : item);
  }
  return [...byTitle.values()];
}

let successfulSections = 0;
for (const [section, url] of Object.entries(pages)) {
  try {
    const text = await reader(url);
    const items = discover(text, section, url);
    if (items.length === 0) {
      console.warn(`[${section}] no items discovered; keeping previous snapshot`);
      continue;
    }
    current[section] = mergeVerified(current[section], items);
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
current.sources = [...new Set([
  ...(current.sources ?? []),
  ...Object.values(pages),
])];

await writeFile(catalogPath, `${JSON.stringify(current, null, 2)}\n`);
console.log(`Updated ${catalogPath}`);
