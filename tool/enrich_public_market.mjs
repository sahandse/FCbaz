import { readFile, writeFile } from 'node:fs/promises';

const catalogPath = 'data/live/catalog.json';
const catalog = JSON.parse(await readFile(catalogPath, 'utf8'));

function cleanLine(value) {
  return String(value ?? '')
    .replace(/!\[[^\]]*\]\([^)]*\)/g, ' ')
    .replace(/\[([^\]]+)\]\([^)]*\)/g, '$1')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/gi, ' ')
    .replace(/&amp;/gi, '&')
    .replace(/\s+/g, ' ')
    .trim();
}

function normalize(value) {
  return String(value ?? '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/gi, ' ')
    .trim()
    .toLowerCase();
}

function coins(raw) {
  const value = String(raw ?? '').trim().toUpperCase().replaceAll(',', '');
  if (!value || value === '-' || value === '—') return 0;
  const multiplier = value.endsWith('M') ? 1000000 : value.endsWith('K') ? 1000 : 1;
  const number = Number(value.replace(/[KM]$/, ''));
  const result = Math.round(number * multiplier);
  return Number.isFinite(result) && result > 0 ? result : 0;
}

async function fetchText(url) {
  const targets = [`https://r.jina.ai/${url}`, url];
  let lastError;
  for (const target of targets) {
    try {
      const response = await fetch(target, {
        headers: {
          accept: 'text/plain,text/markdown,text/html;q=0.9,*/*;q=0.8',
          'user-agent': 'Mozilla/5.0 FCBaz/1.9 public-data-sync',
        },
        signal: AbortSignal.timeout(20000),
      });
      if (!response.ok) throw new Error(`${response.status} ${response.statusText}`);
      const body = await response.text();
      if (body.length < 800) throw new Error('response too small');
      return body;
    } catch (error) {
      lastError = error;
    }
  }
  throw lastError ?? new Error(`Unable to fetch ${url}`);
}

function playerLines(text) {
  return String(text)
    .split(/\r?\n/)
    .map(cleanLine)
    .filter((line) =>
      /^\d{2}\s/.test(line) &&
      (/(?:PAC|DIV)\d+/i.test(line)) &&
      /(?:\d+(?:\.\d+)?[KM]?|—)$/.test(line),
    );
}

function nameMatches(line, name) {
  const hay = normalize(line);
  const full = normalize(name);
  if (full && hay.includes(full)) return true;
  const parts = full.split(' ').filter(Boolean);
  if (parts.length < 2) return false;
  return hay.includes(parts[0]) && hay.includes(parts[parts.length - 1]);
}

function statMatchCount(line, player) {
  const pairs = [
    ['PAC', player.pace],
    ['SHO', player.shooting],
    ['PAS', player.passing],
    ['DRI', player.dribbling],
    ['DEF', player.defending],
    ['PHY', player.physical],
  ];
  return pairs.filter(([label, value]) => Number(value) > 0 && line.includes(`${label}${value}`)).length;
}

async function collectFcDataLines() {
  const urls = [];
  for (let page = 1; page <= 14; page++) {
    urls.push(`https://fcdata.io/players/?page=${page}`);
  }
  // Hall of FUT cards are useful in FCBaz but sit outside the top-rating pages.
  urls.push('https://fcdata.io/players/?rarity=9');

  const out = [];
  for (let start = 0; start < urls.length; start += 3) {
    const batch = urls.slice(start, start + 3);
    const pages = await Promise.all(batch.map(async (url) => {
      try {
        const body = await fetchText(url);
        return playerLines(body);
      } catch (error) {
        console.warn(`[FCData] failed ${url}: ${error}`);
        return [];
      }
    }));
    for (const page of pages) out.push(...page);
  }
  return [...new Set(out)];
}

const lines = await collectFcDataLines();
console.log(`[FCData] parsed ${lines.length} market rows`);

let priced = 0;
for (const player of catalog.players ?? []) {
  const name = String(player.name ?? '').trim();
  const rating = Number(player.rating ?? 0);
  const position = String(player.position ?? '').trim().toUpperCase();
  if (!name || !rating || !position) continue;

  const candidates = lines.filter((line) =>
    line.startsWith(`${rating} `) &&
    line.slice(0, 42).includes(position) &&
    nameMatches(line, name),
  );
  if (!candidates.length) continue;

  let selected = candidates[0];
  let bestStats = statMatchCount(selected, player);
  for (const candidate of candidates.slice(1)) {
    const score = statMatchCount(candidate, player);
    if (score > bestStats) {
      selected = candidate;
      bestStats = score;
    }
  }

  // For outfield cards with face stats, require a strong stat match when multiple versions exist.
  const knownStats = [player.pace, player.shooting, player.passing, player.dribbling, player.defending, player.physical]
    .filter((value) => Number(value) > 0).length;
  if (knownStats >= 5 && candidates.length > 1 && bestStats < 4) continue;

  const priceMatch = selected.match(/(\d+(?:\.\d+)?[KM]?|—)$/i);
  const value = coins(priceMatch?.[1]);
  if (value <= 0) continue;

  player.price_ps = value;
  player.market_price = value;
  player.price_source = 'fcdata-public';
  player.price_source_url = 'https://fcdata.io/players/';
  player.price_updated_at = new Date().toISOString();
  priced++;
}

// FCData publishes live SBC aggregate costs on its public FC27 content surface.
try {
  const home = cleanLine(await fetchText('https://fcdata.io/'));
  for (const sbc of catalog.sbcs ?? []) {
    const name = String(sbc.title_en ?? sbc.title ?? '').trim();
    if (!name) continue;
    const escaped = name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const match = home.match(new RegExp(`${escaped}.{0,180}?([0-9][0-9,]*(?:\\.[0-9]+)?[KM]?)`, 'i'));
    const value = coins(match?.[1]);
    if (value <= 0) continue;
    sbc.estimated_cost = value;
    sbc.cost = value;
    sbc.cost_source = 'fcdata-public';
    sbc.cost_source_url = 'https://fcdata.io/';
  }
} catch (error) {
  console.warn(`[FCData] SBC cost enrichment failed: ${error}`);
}

catalog.sources = [...new Set([...(catalog.sources ?? []), 'https://fcdata.io/players/', 'https://fcdata.io/'])];
catalog.market_enriched_at = new Date().toISOString();
catalog.priced_players = (catalog.players ?? []).filter((p) => Number(p.price_ps ?? p.market_price ?? 0) > 0).length;

await writeFile(catalogPath, `${JSON.stringify(catalog, null, 2)}\n`);
console.log({ pricedNow: priced, totalPriced: catalog.priced_players });
