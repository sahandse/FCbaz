import { readFile, writeFile } from 'node:fs/promises';

const catalogPath = 'data/live/catalog.json';
const eaRatingsBase = 'https://drop-api.ea.com/rating/ea-sports-fc';

const playerPages = [
  { url: 'https://www.fut.gg/fc-27/ratings/', version: 'Gold' },
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
  if (value && typeof value === 'object') {
    return clean(value.shortLabel ?? value.shortName ?? value.label ?? value.name ?? value.id ?? '');
  }
  return String(value ?? '')
    .replace(/<[^>]+>/g, ' ')
    .replace(/\s+/g, ' ')
    .replace(/^(new|image:?|view)\s+/i, '')
    .trim();
}

function numberAt(raw, keys) {
  for (const key of keys) {
    const direct = raw?.[key];
    if (direct !== undefined && direct !== null) {
      if (typeof direct === 'number' && Number.isFinite(direct)) return Math.round(direct);
      if (typeof direct === 'string' && direct.trim()) {
        const parsed = Number(direct);
        if (Number.isFinite(parsed)) return Math.round(parsed);
      }
      if (typeof direct === 'object') {
        const nested = numberAt(direct, ['value', 'rating', 'score']);
        if (nested !== 0) return nested;
      }
    }
    const match = Object.keys(raw ?? {}).find((candidate) => candidate.toLowerCase() === key.toLowerCase());
    if (match && match !== key) {
      const nested = numberAt({ [key]: raw[match] }, [key]);
      if (nested !== 0) return nested;
    }
  }
  return 0;
}

function stringAt(raw, keys) {
  for (const key of keys) {
    const direct = raw?.[key];
    if (direct !== undefined && direct !== null) {
      const value = clean(direct);
      if (value) return value;
    }
    const match = Object.keys(raw ?? {}).find((candidate) => candidate.toLowerCase() === key.toLowerCase());
    if (match) {
      const value = clean(raw[match]);
      if (value) return value;
    }
  }
  return '';
}

function candidateItems(payload) {
  if (Array.isArray(payload)) return payload;
  if (!payload || typeof payload !== 'object') return [];
  for (const key of ['items', 'players', 'ratings', 'results', 'data', 'records', 'content', 'response']) {
    const match = Object.keys(payload).find((candidate) => candidate.toLowerCase() === key);
    const value = match ? payload[match] : undefined;
    if (Array.isArray(value) && value.length) return value;
    if (value && typeof value === 'object') {
      const nested = candidateItems(value);
      if (nested.length) return nested;
    }
  }
  return [];
}

function metadataName(value) {
  return value && typeof value === 'object'
    ? stringAt(value, ['label', 'name', 'shortName'])
    : clean(value);
}

function classifyBaseRarity(rating) {
  if (rating >= 75) return 'Gold';
  if (rating >= 65) return 'Silver';
  return 'Bronze';
}

function normalizeEaPlayer(raw, sourceUrl) {
  if (!raw || typeof raw !== 'object') return null;
  const stats = raw.stats && typeof raw.stats === 'object' ? raw.stats : {};
  const eaId = numberAt(raw, ['eaId', 'eaID', 'playerId', 'playerID', 'id']);
  const firstName = stringAt(raw, ['firstName']);
  const lastName = stringAt(raw, ['lastName']);
  const name = stringAt(raw, ['name', 'fullName']) || [firstName, lastName].filter(Boolean).join(' ') || stringAt(raw, ['commonName']);
  const rating = numberAt(raw, ['overall', 'overallRating', 'rating']);
  const position = stringAt(raw, ['position', 'preferredPosition']) || 'UNK';
  if (!eaId || !name || rating < 40 || rating > 99 || !position || position === 'UNK') return null;

  const rarity = classifyBaseRarity(rating);
  const stat = (keys) => Math.max(0, Math.min(99, numberAt(raw, keys) || numberAt(stats, keys)));
  const team = metadataName(raw.team);
  const nationality = metadataName(raw.nationality);
  const league = metadataName(raw.league) || metadataName(raw.team?.league) || stringAt(raw, ['leagueName']);
  const avatar = stringAt(raw, ['avatarUrl', 'imageUrl', 'portraitUrl']);
  const externalId = stringAt(raw, ['externalId', 'externalID', 'external_id']) || String(eaId);

  return {
    id: `ea-${externalId}`,
    name,
    rating,
    position,
    positions: [position],
    club_name: team,
    league_name: league,
    nation_name: nationality,
    version: rarity,
    rarity,
    card_type: rarity,
    image_url: avatar,
    card_image_url: '',
    pace: stat(['pace', 'pac']),
    shooting: stat(['shooting', 'sho']),
    passing: stat(['passing', 'pas']),
    dribbling: stat(['dribbling', 'dri']),
    defending: stat(['defending', 'def']),
    physical: stat(['physical', 'phy']),
    price_ps: 0,
    price_pc: 0,
    source_url: sourceUrl,
  };
}

async function fetchEaBulk(maxPages = 5) {
  const players = [];
  const seen = new Set();
  for (let page = 0; page < maxPages; page++) {
    const url = new URL(eaRatingsBase);
    url.searchParams.set('locale', 'en');
    url.searchParams.set('limit', '100');
    url.searchParams.set('offset', String(page * 100));
    const response = await fetch(url, {
      headers: {
        accept: 'application/json',
        'user-agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/137 Safari/537.36',
      },
      signal: AbortSignal.timeout(15000),
    });
    if (!response.ok) throw new Error(`EA ratings HTTP ${response.status} offset ${page * 100}`);
    const payload = await response.json();
    const items = candidateItems(payload);
    if (!items.length) break;
    for (const raw of items) {
      const item = normalizeEaPlayer(raw, url.toString());
      if (!item) continue;
      const key = `${item.id}|${item.rating}|${item.position}`;
      if (seen.add(key)) players.push(item);
    }
    if (items.length < 100) break;
  }
  return players;
}

function asInt(value) {
  if (typeof value === 'number') return Math.round(value);
  const raw = String(value ?? '').trim().toUpperCase().replaceAll(',', '');
  if (!raw) return 0;
  let multiplier = 1;
  let number = raw;
  if (raw.endsWith('K')) {
    multiplier = 1000;
    number = raw.slice(0, -1);
  } else if (raw.endsWith('M')) {
    multiplier = 1000000;
    number = raw.slice(0, -1);
  }
  return Math.round((Number.parseFloat(number) || 0) * multiplier);
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

function normalizeFutbinPlayer(raw, sourceUrl) {
  const name = clean(raw.playername ?? raw.name ?? raw.common_name);
  const rating = asInt(raw.rating ?? raw.overall);
  const position = clean(raw.position);
  if (!name || rating < 40 || rating > 99 || !position) return null;
  const version = clean(raw.version ?? raw.rarity ?? raw.card_type ?? raw.raretype) || classifyBaseRarity(rating);
  const rawId = clean(raw.ID ?? raw.id ?? raw.player_id ?? raw.playerid ?? raw.resource_id);
  const id = rawId || slugId('futbin', `${name}-${rating}-${position}-${version}`);
  return {
    id,
    name,
    rating,
    position,
    positions: [position],
    club_name: clean(raw.club_name ?? raw.club),
    league_name: clean(raw.league_name ?? raw.league),
    nation_name: clean(raw.nation_name ?? raw.nation),
    version,
    rarity: clean(raw.rarity ?? raw.raretype ?? version),
    card_type: clean(raw.card_type ?? raw.type ?? version),
    image_url: clean(raw.image_url ?? raw.image),
    card_image_url: clean(raw.card_image_url ?? raw.card_image),
    pace: asInt(raw.pace ?? raw.pac),
    shooting: asInt(raw.shooting ?? raw.sho),
    passing: asInt(raw.passing ?? raw.pas),
    dribbling: asInt(raw.dribbling ?? raw.dri),
    defending: asInt(raw.defending ?? raw.def),
    physical: asInt(raw.physical ?? raw.phy),
    price_ps: asInt(raw.price_ps ?? raw.price_ps_coins ?? raw.ps_LCPrice),
    price_pc: asInt(raw.price_pc ?? raw.price_pc_coins ?? raw.pc_LCPrice),
    source_url: sourceUrl,
  };
}

async function fetchFutbinBulk(maxPages = 5) {
  const players = [];
  for (let page = 1; page <= maxPages; page++) {
    const url = new URL('https://www.futbin.org/futbin/api/getFilteredPlayers');
    url.searchParams.set('platform', 'PS');
    url.searchParams.set('page', String(page));
    const response = await fetch(url, {
      headers: {
        accept: 'application/json',
        'user-agent': 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 FCBaz/1.3',
        referer: 'https://www.futbin.com/',
        origin: 'https://www.futbin.com',
      },
      signal: AbortSignal.timeout(15000),
    });
    if (!response.ok) throw new Error(`FUTBIN HTTP ${response.status} page ${page}`);
    const json = await response.json();
    const data = Array.isArray(json?.data) ? json.data : [];
    if (!data.length) break;
    for (const raw of data) {
      const item = normalizeFutbinPlayer(raw, url.toString());
      if (item) players.push(item);
    }
  }
  return players;
}

function discover(markdown, section, baseUrl) {
  const pathPart = section === 'sbcs' ? 'sbc' : section;
  const absolute = new RegExp(`\\[([^\\]]{2,100})\\]\\((https?:\\/\\/www\\.fut\\.gg\\/${pathPart}\\/[^)#?\\s]+[^)]*)\\)`, 'gi');
  const relative = new RegExp(`\\[([^\\]]{2,100})\\]\\((\\/${pathPart}\\/[^)#?\\s]+[^)]*)\\)`, 'gi');
  const found = [];
  const seen = new Set();
  for (const regex of [absolute, relative]) {
    for (const match of markdown.matchAll(regex)) {
      const title = clean(match[1]);
      if (!title || /^(all|expired|players|evolutions|objectives|sbc|view all)$/i.test(title)) continue;
      const url = match[2].startsWith('http') ? match[2] : new URL(match[2], 'https://www.fut.gg').toString();
      if (seen.has(title.toLowerCase())) continue;
      seen.add(title.toLowerCase());
      const tail = markdown.slice(match.index + match[0].length, match.index + match[0].length + 360);
      const description = clean(tail.split('\n').find((line) => clean(line).length > 20) ?? '');
      found.push({ id: slugId('futgg', title), ...(section === 'sbcs' ? { title_en: title } : { title }), description: description.slice(0, 260), source_url: url || baseUrl });
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
    byKey.set(key, previous ? { ...previous, ...item, id: previous.id || item.id, source_url: item.source_url || previous.source_url } : item);
  }
  return [...byKey.values()];
}

const playerKey = (item) => `${item.name ?? ''}|${item.rating ?? ''}|${item.position ?? ''}|${item.version ?? ''}`.toLowerCase();
let successfulSections = 0;
let totalPlayerDiscoveries = 0;

try {
  const bulk = await fetchEaBulk();
  if (bulk.length) {
    current.players = mergeVerified(current.players, bulk, playerKey);
    successfulSections++;
    totalPlayerDiscoveries += bulk.length;
    console.log(`[players:EA official] discovered ${bulk.length}, total ${current.players.length}`);
  }
} catch (error) {
  console.warn(`[players:EA official] sync failed: ${error}`);
}

try {
  const bulk = await fetchFutbinBulk();
  if (bulk.length) {
    current.players = mergeVerified(current.players, bulk, playerKey);
    successfulSections++;
    totalPlayerDiscoveries += bulk.length;
    console.log(`[players:FUTBIN bulk] discovered ${bulk.length}, total ${current.players.length}`);
  }
} catch (error) {
  console.warn(`[players:FUTBIN bulk] sync failed: ${error}`);
}

for (const source of playerPages) {
  try {
    const text = await reader(source.url);
    const items = discoverPlayers(text, source.url, source.version);
    if (!items.length) {
      console.warn(`[players:${source.version}] no items discovered; keeping previous snapshot`);
      continue;
    }
    current.players = mergeVerified(current.players, items, playerKey);
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
    if (!items.length) {
      console.warn(`[${section}] no items discovered; keeping previous snapshot`);
      continue;
    }
    current[section] = mergeVerified(current[section], items, (item) => String(item.title_en ?? item.title ?? '').trim().toLowerCase());
    successfulSections++;
    console.log(`[${section}] discovered ${items.length}, total ${current[section].length}`);
  } catch (error) {
    console.warn(`[${section}] sync failed: ${error}`);
  }
}

if (successfulSections === 0) throw new Error('No live FC27 section could be refreshed; catalog left unchanged.');

current.game_year = 27;
current.generated_at = new Date().toISOString();
current.sources = [...new Set([...(current.sources ?? []), eaRatingsBase, 'https://www.futbin.org/futbin/api/getFilteredPlayers', ...playerPages.map((item) => item.url), ...Object.values(pages)])];
await writeFile(catalogPath, `${JSON.stringify(current, null, 2)}\n`);
console.log(`Updated ${catalogPath}; player discoveries this run: ${totalPlayerDiscoveries}; total players: ${current.players.length}`);
