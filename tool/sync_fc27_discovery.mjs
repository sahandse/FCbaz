import { readFile, writeFile } from 'node:fs/promises';

const catalogPath = 'data/live/catalog.json';
const sources = {
  popular_players: 'https://www.fut.gg/whats-hot/',
  new_players: 'https://www.fut.gg/whats-new/',
};

const catalog = JSON.parse(await readFile(catalogPath, 'utf8'));
const players = Array.isArray(catalog.players) ? catalog.players : [];

function normalize(value) {
  return String(value ?? '')
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/gi, ' ')
    .trim()
    .toLowerCase();
}

async function readPublic(url) {
  const targets = [`https://r.jina.ai/${url}`, url];
  let lastError;
  for (const target of targets) {
    try {
      const response = await fetch(target, {
        headers: {
          accept: 'text/plain,text/markdown,text/html;q=0.9,*/*;q=0.8',
          'user-agent': 'FCBaz-Discovery/1.4 (+https://github.com/sahandse/FCbaz)',
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
  throw lastError ?? new Error(`unable to fetch ${url}`);
}

function namesFromPage(text) {
  const names = [];
  const seen = new Set();
  const pattern = /([A-ZÀ-ÖØ-öø-ÿĀ-ž][A-Za-zÀ-ÖØ-öø-ÿĀ-ž'’.-]+(?:\s+[A-ZÀ-ÖØ-öø-ÿĀ-ž][A-Za-zÀ-ÖØ-öø-ÿĀ-ž'’.-]+){0,4})\s+(\d{2})\s+(?:OVR\s*)?(GK|CB|LB|RB|LWB|RWB|CDM|CM|CAM|LM|RM|LW|RW|CF|ST)\b/g;
  for (const match of text.matchAll(pattern)) {
    const name = match[1].replace(/\s+/g, ' ').trim();
    const key = normalize(name);
    if (!key || seen.has(key)) continue;
    seen.add(key);
    names.push(name);
  }
  return names;
}

function resolvePlayers(names, sourceUrl) {
  const resolved = [];
  const used = new Set();
  for (const name of names) {
    const key = normalize(name);
    const matches = players
      .filter((player) => normalize(player.name) === key)
      .sort((a, b) => Number(b.rating ?? 0) - Number(a.rating ?? 0));
    const player = matches[0];
    if (!player || used.has(player.id)) continue;
    used.add(player.id);
    resolved.push({
      ...player,
      discovery_source_url: sourceUrl,
    });
    if (resolved.length >= 30) break;
  }
  return resolved;
}

let changed = false;
for (const [key, url] of Object.entries(sources)) {
  try {
    const text = await readPublic(url);
    const names = namesFromPage(text);
    const resolved = resolvePlayers(names, url);
    if (!resolved.length) {
      console.warn(`[${key}] no catalog players resolved; keeping previous snapshot`);
      continue;
    }
    catalog[key] = resolved;
    changed = true;
    console.log(`[${key}] resolved ${resolved.length} players from ${names.length} names`);
  } catch (error) {
    console.warn(`[${key}] sync failed: ${error}`);
  }
}

catalog.sources = [...new Set([...(catalog.sources ?? []), ...Object.values(sources)])];
if (changed) {
  catalog.discovery_generated_at = new Date().toISOString();
  await writeFile(catalogPath, `${JSON.stringify(catalog, null, 2)}\n`);
  console.log(`Updated ${catalogPath} discovery feeds`);
} else {
  console.log('No discovery feed changes; catalog kept intact');
}
