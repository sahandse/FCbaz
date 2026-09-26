import { readFile, writeFile } from 'node:fs/promises';

const catalogPath = 'data/live/catalog.json';
const catalog = JSON.parse(await readFile(catalogPath, 'utf8'));

function plain(text) {
  return String(text ?? '')
    .replace(/<script[\s\S]*?<\/script>/gi, ' ')
    .replace(/<style[\s\S]*?<\/style>/gi, ' ')
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
  if (!value || value === '-') return 0;
  const multiplier = value.endsWith('M') ? 1000000 : value.endsWith('K') ? 1000 : 1;
  const number = Number(value.replace(/[KM]$/, ''));
  const result = Math.round(number * multiplier);
  return Number.isFinite(result) && result > 0 ? result : 0;
}

async function fetchSource() {
  const urls = [
    'https://www.easysbc.io/',
    'https://r.jina.ai/https://www.easysbc.io/',
  ];
  let lastError;
  for (const url of urls) {
    try {
      const response = await fetch(url, {
        headers: {
          accept: 'text/html,text/plain,text/markdown,*/*;q=0.8',
          'user-agent': 'Mozilla/5.0 FCBaz/1.9 public-data-sync',
        },
        signal: AbortSignal.timeout(20000),
      });
      if (!response.ok) throw new Error(`${response.status} ${response.statusText}`);
      const text = await response.text();
      if (text.length < 1000) throw new Error('EasySBC response too small');
      return text;
    } catch (error) {
      lastError = error;
    }
  }
  throw lastError ?? new Error('EasySBC unavailable');
}

const source = await fetchSource();
const text = plain(source);
const normalizedText = normalize(text);

let priced = 0;
for (const player of catalog.players ?? []) {
  const name = String(player.name ?? '').trim();
  const rating = Number(player.rating ?? 0);
  const position = String(player.position ?? '').trim().toUpperCase();
  if (!name || !rating || !position) continue;

  const target = normalize(name);
  const index = normalizedText.indexOf(target);
  if (index < 0) continue;

  const rawWindow = text.slice(Math.max(0, index - 180), Math.min(text.length, index + name.length + 100));
  const patterns = [
    new RegExp(`(?:PLAYER\\s+(?:NEW\\s+)?)?([0-9][0-9,]*(?:\\.[0-9]+)?[KM]?)\\s+${rating}\\s*${position}[^A-Za-z0-9]{0,20}${name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}`, 'i'),
    new RegExp(`([0-9][0-9,]*(?:\\.[0-9]+)?[KM]?)\\s+${rating}\\s*${position}`, 'i'),
  ];

  let value = 0;
  for (const pattern of patterns) {
    const match = rawWindow.match(pattern);
    if (match) {
      value = coins(match[1]);
      if (value > 0) break;
    }
  }
  if (value <= 0) continue;

  player.price_ps = value;
  player.market_price = value;
  player.price_source = 'easysbc-public';
  player.price_source_url = 'https://www.easysbc.io/';
  player.price_updated_at = new Date().toISOString();
  priced++;
}

for (const sbc of catalog.sbcs ?? []) {
  const name = String(sbc.title_en ?? sbc.title ?? '').trim();
  if (!name) continue;
  const target = normalize(name);
  const index = normalizedText.indexOf(target);
  if (index < 0) continue;
  const rawWindow = text.slice(Math.max(0, index - 30), Math.min(text.length, index + name.length + 80));
  const match = rawWindow.match(/([0-9][0-9,]*(?:\.[0-9]+)?[KM]?)\s+(?:Non-Repeatable|Repeatable|Reward)/i)
    ?? rawWindow.match(new RegExp(`${name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\s+([0-9][0-9,]*(?:\\.[0-9]+)?[KM]?)`, 'i'));
  if (!match) continue;
  const value = coins(match[1]);
  if (value <= 0) continue;
  sbc.estimated_cost = value;
  sbc.cost = value;
  sbc.cost_source = 'easysbc-public';
  sbc.cost_source_url = 'https://www.easysbc.io/';
}

catalog.sources = [...new Set([...(catalog.sources ?? []), 'https://www.easysbc.io/'])];
catalog.market_enriched_at = new Date().toISOString();
catalog.priced_players = (catalog.players ?? []).filter((p) => Number(p.price_ps ?? p.market_price ?? 0) > 0).length;

await writeFile(catalogPath, `${JSON.stringify(catalog, null, 2)}\n`);
console.log({ pricedNow: priced, totalPriced: catalog.priced_players });
