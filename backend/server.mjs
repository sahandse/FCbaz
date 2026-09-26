import http from 'node:http';

const PORT = Number(process.env.PORT || 8787);
const API_KEY = process.env.PARSE_API_KEY || '';
const SCRAPER_ID = process.env.PARSE_SCRAPER_ID || '21963078-8a17-40ff-a896-9b0b0ec3e828';
const CACHE_TTL = Math.max(10, Number(process.env.CACHE_TTL_SECONDS || 60));
const PROVIDER_BASE = 'https://api.parse.bot/scraper/' + SCRAPER_ID + '/';
const FUTBIN_PUBLIC_BASE = 'https://www.futbin.org/futbin/api/';
const cache = new Map();

function send(res, status, body, extraHeaders = {}) {
  const payload = JSON.stringify(body);
  res.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'cache-control': 'no-store',
    'access-control-allow-origin': '*',
    ...extraHeaders,
  });
  res.end(payload);
}

function asInt(value) {
  if (typeof value === 'number' && Number.isFinite(value)) return Math.round(value);
  const raw = String(value ?? '').trim().toUpperCase().replaceAll(',', '');
  if (!raw || raw === 'NULL' || raw === 'N/A') return 0;
  let multiplier = 1;
  let numberPart = raw;
  if (raw.endsWith('K')) {
    multiplier = 1000;
    numberPart = raw.slice(0, -1);
  } else if (raw.endsWith('M')) {
    multiplier = 1000000;
    numberPart = raw.slice(0, -1);
  }
  const n = Number(numberPart);
  return Number.isFinite(n) ? Math.round(n * multiplier) : 0;
}

function unwrap(payload) {
  if (payload && typeof payload === 'object' && 'data' in payload) return payload.data;
  return payload;
}

function stringList(value) {
  if (!Array.isArray(value)) return [];
  return value
    .map((x) => {
      if (x && typeof x === 'object') return String(x.name ?? x.title ?? x.label ?? '');
      return String(x ?? '');
    })
    .filter(Boolean);
}

function flattenNumericStats(value) {
  const out = {};
  if (!value || typeof value !== 'object') return out;
  for (const [key, raw] of Object.entries(value)) {
    if (raw && typeof raw === 'object' && !Array.isArray(raw)) {
      for (const [childKey, childValue] of Object.entries(raw)) {
        const n = asInt(childValue);
        if (n > 0) out[childKey] = n;
      }
    } else {
      const n = asInt(raw);
      if (n > 0) out[key] = n;
    }
  }
  return out;
}

async function futbinPublicGet(endpoint, params = {}, { ttl = CACHE_TTL } = {}) {
  const url = new URL(FUTBIN_PUBLIC_BASE + endpoint);
  for (const [key, value] of Object.entries(params)) {
    if (value === undefined || value === null || value === '') continue;
    url.searchParams.set(key, String(value));
  }

  const cacheKey = 'public:' + url.toString();
  const cached = cache.get(cacheKey);
  const now = Date.now();
  if (cached && now - cached.at < ttl * 1000) return cached.value;

  const response = await fetch(url, {
    headers: {
      Accept: 'application/json, text/plain, */*',
      'Accept-Language': 'en-US,en;q=0.9',
      Referer: 'https://www.futbin.com/',
      Origin: 'https://www.futbin.com',
      'User-Agent': 'Mozilla/5.0 FCBaz/1.0',
    },
    signal: AbortSignal.timeout(20000),
  });

  const text = await response.text();
  let body;
  try {
    body = JSON.parse(text);
  } catch {
    throw Object.assign(new Error('futbin_public_invalid_json'), { status: 502 });
  }

  if (!response.ok) {
    const error = new Error(body?.message || body?.error || ('futbin_public_http_' + response.status));
    error.status = response.status === 429 ? 429 : 502;
    throw error;
  }

  cache.set(cacheKey, { at: now, value: body });
  return body;
}

function publicPlatform(value) {
  return String(value || '').toLowerCase() === 'pc' ? 'PC' : 'PS';
}

function publicFilterParams(params = {}) {
  const out = { platform: publicPlatform(params.platform), page: params.page || 1 };
  const direct = [
    'version', 'nation_id', 'league_id', 'club_id', 'min_rating', 'max_rating',
    'min_price', 'max_price', 'min_pace', 'max_pace', 'min_shooting',
    'max_shooting', 'min_passing', 'max_passing', 'min_dribbling',
    'max_dribbling', 'min_defending', 'max_defending', 'min_physical',
    'max_physical', 'min_skills', 'max_skills', 'min_weak_foot', 'max_weak_foot',
  ];
  for (const key of direct) {
    if (params[key] !== undefined && params[key] !== null && params[key] !== '') out[key] = params[key];
  }
  if (params.position) out.position = params.position;
  return out;
}

async function publicFindPlayerById(playerId) {
  const id = String(playerId);
  for (let page = 1; page <= 20; page++) {
    const raw = await futbinPublicGet('getFilteredPlayers', { platform: 'PS', page }, { ttl: 180 });
    const list = Array.isArray(raw?.data) ? raw.data : [];
    const found = list.find((item) =>
      String(item?.ID ?? '') === id ||
      String(item?.playerid ?? '') === id ||
      String(item?.resource_id ?? '') === id
    );
    if (found) return found;
    if (!list.length) break;
  }
  return null;
}

async function publicSearchPlayers(query, page = 1) {
  const q = String(query || '').trim().toLowerCase();
  const matches = [];
  const start = Math.max(1, Number(page) || 1);
  const maxPages = start === 1 ? 16 : 8;
  for (let offset = 0; offset < maxPages; offset++) {
    const current = start + offset;
    const raw = await futbinPublicGet('getFilteredPlayers', { platform: 'PS', page: current }, { ttl: 180 });
    const list = Array.isArray(raw?.data) ? raw.data : [];
    if (!list.length) break;
    for (const item of list) {
      const name = String(item?.playername ?? item?.name ?? item?.common_name ?? '').toLowerCase();
      if (name.includes(q)) matches.push(item);
    }
    if (matches.length >= 30) break;
  }
  return { data: matches.slice(0, 30), meta: { source: 'futbin-public', query: q } };
}

async function publicProvider(endpoint, params = {}, { ttl = CACHE_TTL } = {}) {
  if (endpoint === 'list_fc27_players') {
    return futbinPublicGet('getFilteredPlayers', publicFilterParams(params), { ttl });
  }
  if (endpoint === 'search_players_fc27') {
    return publicSearchPlayers(params.query, params.page || 1);
  }
  if (endpoint === 'get_player_details') {
    const found = await publicFindPlayerById(params.player_id);
    if (!found) throw Object.assign(new Error('player_not_found'), { status: 404 });
    return { data: found, meta: { source: 'futbin-public' } };
  }
  if (endpoint === 'get_fc27_player_price') {
    const id = String(params.player_id || '');
    const platform = publicPlatform(params.platform);
    const raw = await futbinPublicGet('getPlayersPrice', { player_ids: id, platform }, { ttl: Math.min(ttl, 60) });
    const p = raw?.[id]?.prices?.[platform] || {};
    return {
      data: {
        player_id: id,
        price: asInt(p?.LCPrice),
        current: asInt(p?.LCPrice),
        price_range: { min: asInt(p?.MinPrice), max: asInt(p?.MaxPrice) },
        updated: String(p?.updated ?? ''),
      },
      meta: { source: 'futbin-public', platform },
    };
  }
  if (endpoint === 'get_market_trends') {
    const raw = await futbinPublicGet('getPopularPlayers', {}, { ttl });
    return { data: { top_movers: Array.isArray(raw?.data) ? raw.data : [] }, meta: { source: 'futbin-public' } };
  }
  if (endpoint === 'get_fc27_market_snapshot') {
    const ids = String(params.player_ids || '').split(',').map((x) => x.trim()).filter(Boolean);
    const platform = publicPlatform(params.platform);
    if (!ids.length) return { data: { players: [] } };
    const raw = await futbinPublicGet('getPlayersPrice', { player_ids: ids.join(','), platform }, { ttl: Math.min(ttl, 60) });
    return {
      data: { players: ids.map((id) => ({ player_id: id, price: asInt(raw?.[id]?.prices?.[platform]?.LCPrice) })), timestamp: Date.now() },
      meta: { source: 'futbin-public', platform },
    };
  }
  if (endpoint === 'get_player_price_history') {
    return { data: { history: [] }, meta: { source: 'none', status: 'unavailable' } };
  }
  if (endpoint === 'get_sbcs') return { data: { sbcs: [] }, meta: { source: 'none', status: 'unavailable' } };
  if (endpoint === 'get_evos') return { data: { evolutions: [] }, meta: { source: 'none', status: 'unavailable' } };
  if (endpoint === 'get_objectives') return { data: { objectives: [] }, meta: { source: 'none', status: 'unavailable' } };
  if (endpoint === 'fc27_sbc_solver') {
    return {
      data: { players: [], total_cost: 0, message: 'SBC solver unavailable from current real-data source.', search_complete: false, proven_optimal: false },
      meta: { source: 'none', status: 'unavailable' },
    };
  }
  throw Object.assign(new Error('unsupported_public_provider_endpoint'), { status: 501 });
}

async function provider(endpoint, params = {}, { ttl = CACHE_TTL } = {}) {
  if (!API_KEY) return publicProvider(endpoint, params, { ttl });

  const url = new URL(PROVIDER_BASE + endpoint);
  for (const [key, value] of Object.entries(params)) {
    if (value === undefined || value === null || value === '') continue;
    url.searchParams.set(key, String(value));
  }

  const cacheKey = url.toString();
  const cached = cache.get(cacheKey);
  const now = Date.now();
  if (cached && now - cached.at < ttl * 1000) return cached.value;

  const response = await fetch(url, {
    headers: { 'X-API-Key': API_KEY, Accept: 'application/json', 'User-Agent': 'FCBaz/1.0' },
    signal: AbortSignal.timeout(55000),
  });
  const text = await response.text();
  let body;
  try {
    body = JSON.parse(text);
  } catch {
    throw Object.assign(new Error('provider_invalid_json'), { status: 502 });
  }
  if (!response.ok || body?.status === 'error') {
    const error = new Error(body?.message || body?.error || ('provider_http_' + response.status));
    error.status = response.status === 429 ? 429 : 502;
    throw error;
  }
  cache.set(cacheKey, { at: now, value: body });
  return body;
}

function normalizePlayer(raw) {
  const stats = raw?.stats || raw?.face_stats || {};
  const positions = raw?.alternative_positions || raw?.positions || [];
  return {
    id: String(raw?.id ?? raw?.ID ?? raw?.player_id ?? raw?.playerid ?? raw?.resource_id ?? ''),
    name: String(raw?.name ?? raw?.playername ?? raw?.common_name ?? ''),
    rating: asInt(raw?.rating ?? raw?.overall),
    position: String(raw?.position ?? '').replaceAll('+', ''),
    positions: Array.isArray(positions)
      ? positions.map(String)
      : String(raw?.pos_all ?? positions ?? '').split(',').map((x) => x.trim()).filter(Boolean),
    club_name: String(raw?.club_name ?? raw?.club ?? ''),
    league_name: String(raw?.league_name ?? raw?.league ?? ''),
    nation_name: String(raw?.nation_name ?? raw?.nation ?? ''),
    version: String(raw?.version ?? raw?.rarity ?? ''),
    rarity: String(raw?.rarity ?? raw?.rarity_name ?? ''),
    card_type: String(raw?.card_type ?? raw?.type ?? raw?.quality ?? ''),
    image_url: String(raw?.image_large ?? raw?.image ?? raw?.image_url ?? ''),
    card_image_url: String(raw?.card_image_large_url ?? raw?.card_image_url ?? raw?.card_image ?? ''),
    pace: asInt(stats.PAC ?? stats.pace ?? raw?.pace ?? raw?.pac),
    shooting: asInt(stats.SHO ?? stats.shooting ?? raw?.shooting ?? raw?.sho),
    passing: asInt(stats.PAS ?? stats.passing ?? raw?.passing ?? raw?.pas),
    dribbling: asInt(stats.DRI ?? stats.dribbling ?? raw?.dribbling ?? raw?.dri),
    defending: asInt(stats.DEF ?? stats.defending ?? raw?.defending ?? raw?.def),
    physical: asInt(stats.PHY ?? stats.physical ?? raw?.physical ?? raw?.phy),
    skill_moves: asInt(raw?.skill_moves),
    weak_foot: asInt(raw?.weak_foot),
    playstyles: stringList(raw?.playstyles ?? raw?.play_styles ?? raw?.playStyles ?? []),
    playstyles_plus: stringList(raw?.playstyles_plus ?? raw?.play_styles_plus ?? raw?.playStylesPlus ?? []),
    roles: stringList(raw?.roles ?? raw?.player_roles ?? raw?.role_plus ?? []),
    in_game_stats: flattenNumericStats(raw?.in_game_stats ?? raw?.detailed_stats ?? raw?.attributes ?? raw?.stats_detail ?? {}),
    traits: stringList(raw?.traits || []),
    foot: String(raw?.preferred_foot ?? raw?.foot ?? ''),
    height: String(raw?.height ?? ''),
    work_rates: String(raw?.work_rates ?? raw?.workrates ?? ''),
    price_ps: asInt(raw?.price_ps_coins ?? raw?.price_ps ?? raw?.ps_LCPrice),
    price_pc: asInt(raw?.price_pc_coins ?? raw?.price_pc ?? raw?.pc_LCPrice),
    source: API_KEY ? 'futbin-via-parse' : 'futbin-public',
    game_year: 27,
  };
}

function playerArray(payload) {
  const data = unwrap(payload);
  const raw = [data?.players, data?.results, data?.items, Array.isArray(data) ? data : null].find(Array.isArray) || [];
  return raw.map(normalizePlayer).filter((p) => p.id && p.name);
}

function normalizePrice(raw, playerId, platform = 'console') {
  const data = unwrap(raw);
  const p = data && typeof data === 'object' && !Array.isArray(data) ? data : {};
  const current = asInt(p.price ?? p.main_price ?? p.current);
  const bins = Array.isArray(p.lowest_bins) ? p.lowest_bins.map(asInt).filter(Boolean) : [];
  const range = p.price_range || {};
  const changes = p.price_changes || {};
  return {
    player_id: String(p.player_id ?? playerId),
    platform,
    current,
    low: bins.length ? Math.min(...bins) : asInt(range.min),
    high: asInt(range.max),
    change_24h_percent: Number(changes?.['24h']?.change_percent ?? p.trend_percent ?? 0) || 0,
    updated_at: p.updated_at_iso ?? p.updated_at ?? null,
    updated_text: p.updated ?? p.updated_text ?? null,
    lowest_bins: bins,
    average_price_24h: asInt(p.average_price_24h),
    source: API_KEY ? 'futbin-via-parse' : 'futbin-public',
  };
}

function normalizeHistory(raw) {
  const data = unwrap(raw);
  const series = data?.prices || data?.history || data?.points || (Array.isArray(data) ? data : []);
  if (!Array.isArray(series)) return [];
  return series
    .map((point) => ({
      time: typeof point?.timestamp === 'number' ? new Date(point.timestamp).toISOString() : String(point?.time ?? point?.timestamp ?? ''),
      price: asInt(point?.price ?? point?.value),
    }))
    .filter((p) => p.price > 0 && p.time);
}

function normalizeSbcList(raw) {
  const data = unwrap(raw);
  const sets = data?.sbcs || data?.items || data?.results || (Array.isArray(data) ? data : []);
  if (!Array.isArray(sets)) return [];
  const out = [];
  for (const set of sets) {
    const challenges = Array.isArray(set?.challenges) && set.challenges.length ? set.challenges : [set];
    for (const challenge of challenges) {
      const id = String(challenge?.id ?? set?.id ?? '');
      const title = String(challenge?.name ?? set?.name ?? '');
      if (!id || !title) continue;
      out.push({
        id,
        title,
        category: String(set?.name ?? 'SBC'),
        description: String(challenge?.description ?? set?.description ?? ''),
        reward: String(challenge?.reward ?? set?.reward?.name ?? set?.reward ?? ''),
        requirements: Array.isArray(challenge?.requirements) ? challenge.requirements.map(String) : [],
        requirements_raw: Array.isArray(challenge?.requirements) ? challenge.requirements : [],
        repeatable: Boolean(challenge?.repeatable ?? set?.repeatable),
        expires_at: challenge?.expires ?? set?.expires ?? null,
        estimated_cost: asInt(challenge?.cost_ps ?? set?.cost_ps),
        item_score: challenge?.item_score ?? null,
        source: API_KEY ? 'futbin-via-parse' : 'none',
      });
    }
  }
  return out;
}

function normalizeEvolutionList(raw) {
  const data = unwrap(raw);
  const list = data?.evolutions || data?.items || data?.results || (Array.isArray(data) ? data : []);
  if (!Array.isArray(list)) return [];
  return list
    .map((e, index) => ({
      id: String(e?.id ?? e?.evolution_id ?? index),
      title: String(e?.name ?? e?.title ?? ''),
      description: String(e?.description ?? ''),
      cost: asInt(e?.cost ?? e?.coins),
      requirements: Array.isArray(e?.requirements) ? e.requirements.map((x) => typeof x === 'string' ? x : JSON.stringify(x)) : [],
      requirements_raw: Array.isArray(e?.requirements) ? e.requirements : [],
      upgrades: Array.isArray(e?.upgrades ?? e?.boosts) ? (e.upgrades ?? e.boosts).map((x) => typeof x === 'string' ? x : JSON.stringify(x)) : [],
      upgrade_data: Array.isArray(e?.upgrade_data ?? e?.stat_upgrades ?? e?.boosts_raw) ? (e.upgrade_data ?? e.stat_upgrades ?? e.boosts_raw) : [],
      steps: Array.isArray(e?.steps) ? e.steps : [],
      expires_at: e?.expires ?? e?.expires_at ?? null,
      repeatable: Boolean(e?.repeatable),
      status: String(e?.status ?? ''),
      source: API_KEY ? 'futbin-via-parse' : 'none',
    }))
    .filter((e) => e.title);
}

function normalizeObjectives(raw) {
  const data = unwrap(raw);
  const list = data?.objectives || data?.items || data?.results || (Array.isArray(data) ? data : []);
  if (!Array.isArray(list)) return [];
  return list.map((item, index) => {
    const tasks = Array.isArray(item?.tasks ?? item?.objectives) ? (item.tasks ?? item.objectives) : [];
    return {
      id: String(item?.id ?? index),
      title: String(item?.title ?? item?.name ?? ''),
      description: String(item?.description ?? ''),
      reward: String(item?.reward?.name ?? item?.reward ?? ''),
      category: String(item?.category ?? item?.group ?? item?.type ?? ''),
      expires_at: item?.expires_at ?? item?.expires ?? null,
      task_count: asInt(item?.task_count) || tasks.length,
      tasks,
      source: API_KEY ? 'futbin-via-parse' : 'none',
    };
  }).filter((item) => item.title);
}

async function findSbc(id) {
  const raw = await provider('get_sbcs', { page: 1 }, { ttl: 120 });
  return normalizeSbcList(raw).find((item) => item.id === id) || null;
}

async function latestRelease() {
  const releaseRepo = process.env.GITHUB_RELEASE_REPO || 'sahandse/FCbaz';
  const response = await fetch('https://api.github.com/repos/' + releaseRepo + '/releases/latest', {
    headers: {
      Accept: 'application/vnd.github+json',
      'User-Agent': 'FCBaz-Backend/1.0',
      'X-GitHub-Api-Version': '2022-11-28',
    },
    signal: AbortSignal.timeout(10000),
  });
  if (response.status === 404) return { data: null, meta: { repository: releaseRepo, has_release: false } };
  if (!response.ok) throw Object.assign(new Error('github_release_lookup_failed'), { status: 502 });
  const release = await response.json();
  return {
    data: {
      tag_name: String(release?.tag_name ?? ''),
      name: String(release?.name ?? ''),
      html_url: String(release?.html_url ?? ''),
      published_at: release?.published_at ?? null,
      prerelease: release?.prerelease === true,
      draft: release?.draft === true,
    },
    meta: { repository: releaseRepo, has_release: true },
  };
}

async function handler(req, res) {
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'access-control-allow-origin': '*',
      'access-control-allow-methods': 'GET,OPTIONS',
      'access-control-allow-headers': 'content-type',
    });
    return res.end();
  }

  const url = new URL(req.url, 'http://localhost');
  const path = url.pathname;

  try {
    if (req.method !== 'GET') return send(res, 405, { error: 'method_not_allowed' });

    if (path === '/health') {
      return send(res, 200, {
        ok: true,
        provider_configured: Boolean(API_KEY),
        game_year: 27,
        account_system: false,
        local_first: true,
      });
    }

    if (path === '/api/v1/app/latest-release') {
      return send(res, 200, await latestRelease());
    }

    if (path === '/api/v1/players') {
      const raw = await provider('list_fc27_players', { page: url.searchParams.get('page') || 1, platform: url.searchParams.get('platform') || 'ps' });
      return send(res, 200, { data: playerArray(raw), meta: { game_year: 27 } });
    }

    if (path === '/api/v1/players/search') {
      const q = (url.searchParams.get('q') || '').trim();
      if (q.length < 2) return send(res, 400, { error: 'query_too_short' });
      const raw = await provider('search_players_fc27', { query: q, page: url.searchParams.get('page') || 1 });
      return send(res, 200, { data: playerArray(raw), meta: { game_year: 27 } });
    }

    if (path === '/api/v1/players/advanced') {
      const q = (url.searchParams.get('q') || '').trim();
      const params = {
        page: url.searchParams.get('page') || 1,
        min_rating: url.searchParams.get('min_rating'),
        max_rating: url.searchParams.get('max_rating'),
        min_price: url.searchParams.get('min_price'),
        max_price: url.searchParams.get('max_price'),
        position: url.searchParams.get('position'),
        league_id: url.searchParams.get('league_id'),
        club_id: url.searchParams.get('club_id'),
        nation_id: url.searchParams.get('nation_id'),
        version: url.searchParams.get('version'),
        platform: url.searchParams.get('platform') || 'ps',
        min_pace: url.searchParams.get('min_pace'),
        max_pace: url.searchParams.get('max_pace'),
        min_shooting: url.searchParams.get('min_shooting'),
        max_shooting: url.searchParams.get('max_shooting'),
        min_passing: url.searchParams.get('min_passing'),
        max_passing: url.searchParams.get('max_passing'),
        min_dribbling: url.searchParams.get('min_dribbling'),
        max_dribbling: url.searchParams.get('max_dribbling'),
        min_defending: url.searchParams.get('min_defending'),
        max_defending: url.searchParams.get('max_defending'),
        min_physical: url.searchParams.get('min_physical'),
        max_physical: url.searchParams.get('max_physical'),
        min_skills: url.searchParams.get('min_skill_moves'),
        min_weak_foot: url.searchParams.get('min_weak_foot'),
      };
      const raw = q ? await provider('search_players_fc27', { query: q, page: params.page }) : await provider('list_fc27_players', params);
      let players = playerArray(raw);
      const role = url.searchParams.get('role');
      const playStyle = url.searchParams.get('play_style');
      const playStylePlus = url.searchParams.get('play_style_plus');
      if (role) players = players.filter((p) => p.roles.some((r) => r.toLowerCase().includes(role.toLowerCase())));
      if (playStyle) players = players.filter((p) => p.playstyles.some((r) => r.toLowerCase().includes(playStyle.toLowerCase())));
      if (playStylePlus) players = players.filter((p) => p.playstyles_plus.some((r) => r.toLowerCase().includes(playStylePlus.toLowerCase())));
      const facets = {
        versions: [...new Set(players.map((p) => p.version).filter(Boolean))],
        rarities: [...new Set(players.map((p) => p.rarity).filter(Boolean))],
        card_types: [...new Set(players.map((p) => p.card_type).filter(Boolean))],
        leagues: [...new Set(players.map((p) => p.league_name).filter(Boolean))],
        clubs: [...new Set(players.map((p) => p.club_name).filter(Boolean))],
        nations: [...new Set(players.map((p) => p.nation_name).filter(Boolean))],
        playstyles: [...new Set(players.flatMap((p) => p.playstyles))],
        playstyles_plus: [...new Set(players.flatMap((p) => p.playstyles_plus))],
        roles: [...new Set(players.flatMap((p) => p.roles))],
      };
      return send(res, 200, { data: players, facets, meta: { game_year: 27 } });
    }

    if (path === '/api/v1/players/trending') {
      const raw = await provider('get_market_trends', {}, { ttl: 60 });
      const data = unwrap(raw);
      const list = Array.isArray(data?.top_movers) ? data.top_movers : [];
      return send(res, 200, { data: list.map(normalizePlayer).filter((p) => p.id && p.name) });
    }

    const versionsMatch = path.match(/^\/api\/v1\/players\/([^/]+)\/versions$/);
    if (versionsMatch) {
      const id = decodeURIComponent(versionsMatch[1]);
      const playerRaw = await provider('get_player_details', { player_id: id });
      const player = normalizePlayer(unwrap(playerRaw));
      if (!player.name) return send(res, 404, { error: 'player_not_found' });
      if (!API_KEY) return send(res, 200, { data: [player], meta: { source: 'futbin-public' } });
      try {
        const raw = await provider('search_players_fc27', { query: player.name, page: 1 });
        const versions = playerArray(raw).filter((p) => p.name.toLowerCase() === player.name.toLowerCase());
        return send(res, 200, { data: versions.length ? versions : [player] });
      } catch {
        return send(res, 200, { data: [player] });
      }
    }

    const priceHistoryMatch = path.match(/^\/api\/v1\/players\/([^/]+)\/price-history$/);
    if (priceHistoryMatch) {
      const playerId = decodeURIComponent(priceHistoryMatch[1]);
      const raw = await provider('get_player_price_history', {
        player_id: playerId,
        platform: url.searchParams.get('platform') || 'ps',
        graph_type: url.searchParams.get('graph_type') || 'daily',
      });
      return send(res, 200, { data: normalizeHistory(raw) });
    }

    const priceMatch = path.match(/^\/api\/v1\/players\/([^/]+)\/price$/);
    if (priceMatch) {
      const playerId = decodeURIComponent(priceMatch[1]);
      const platform = url.searchParams.get('platform') === 'pc' ? 'pc' : 'console';
      const raw = await provider('get_fc27_player_price', { player_id: playerId, platform: platform === 'pc' ? 'pc' : 'ps' }, { ttl: 45 });
      return send(res, 200, { data: normalizePrice(raw, playerId, platform) });
    }

    const playerMatch = path.match(/^\/api\/v1\/players\/([^/]+)$/);
    if (playerMatch) {
      const raw = await provider('get_player_details', { player_id: decodeURIComponent(playerMatch[1]) });
      const player = normalizePlayer(unwrap(raw));
      if (!player.id || !player.name) return send(res, 404, { error: 'player_not_found' });
      return send(res, 200, { data: player });
    }

    if (path === '/api/v1/club/snapshot') {
      const ids = [...new Set((url.searchParams.get('player_ids') || '').split(',').map((x) => x.trim()).filter((x) => /^\d+$/.test(x)))];
      if (!ids.length) return send(res, 400, { error: 'player_ids_required' });
      if (ids.length > 500) return send(res, 400, { error: 'too_many_player_ids', max: 500 });
      const raw = await provider('get_fc27_market_snapshot', { player_ids: ids.join(','), platform: url.searchParams.get('platform') || 'ps' }, { ttl: 45 });
      return send(res, 200, { data: unwrap(raw) });
    }

    if (path === '/api/v1/market') {
      const raw = await provider('get_market_trends', {}, { ttl: 60 });
      const data = unwrap(raw);
      return send(res, 200, { data: data?.top_movers || [], meta: { game_year: 27 } });
    }

    if (path === '/api/v1/market/cheapest') {
      const raw = await provider('list_fc27_players', {
        page: url.searchParams.get('page') || 1,
        min_rating: url.searchParams.get('min_rating') || 75,
        max_rating: url.searchParams.get('max_rating') || 99,
        min_price: url.searchParams.get('min_price') || 200,
        max_price: url.searchParams.get('max_price'),
        position: url.searchParams.get('position'),
        platform: url.searchParams.get('platform') || 'ps',
      });
      const platform = url.searchParams.get('platform') === 'pc' ? 'pc' : 'console';
      const players = playerArray(raw)
        .filter((p) => (platform === 'pc' ? p.price_pc : p.price_ps) > 0)
        .sort((a, b) => (platform === 'pc' ? a.price_pc - b.price_pc : a.price_ps - b.price_ps));
      return send(res, 200, { data: players, meta: { sorted: 'price_asc' } });
    }

    if (path === '/api/v1/sbc') {
      const raw = await provider('get_sbcs', { page: url.searchParams.get('page') || 1 }, { ttl: 120 });
      return send(res, 200, { data: normalizeSbcList(raw) });
    }

    const sbcSolutionMatch = path.match(/^\/api\/v1\/sbc\/([^/]+)\/solution$/);
    if (sbcSolutionMatch) {
      const sbc = await findSbc(decodeURIComponent(sbcSolutionMatch[1]));
      if (!sbc) return send(res, 404, { error: 'sbc_not_found' });
      const raw = await provider('fc27_sbc_solver', { sbc_id: sbc.id, sbc_name: sbc.title }, { ttl: 60 });
      return send(res, 200, { data: unwrap(raw) });
    }

    const sbcDetailMatch = path.match(/^\/api\/v1\/sbc\/([^/]+)$/);
    if (sbcDetailMatch) {
      const sbc = await findSbc(decodeURIComponent(sbcDetailMatch[1]));
      if (!sbc) return send(res, 404, { error: 'sbc_not_found' });
      return send(res, 200, { data: sbc });
    }

    if (path === '/api/v1/evolutions') {
      const raw = await provider('get_evos', {}, { ttl: 120 });
      const all = normalizeEvolutionList(raw);
      const active = url.searchParams.get('status') === 'active'
        ? all.filter((e) => !e.status || e.status.toLowerCase().includes('active'))
        : all;
      return send(res, 200, { data: active });
    }

    if (path === '/api/v1/objectives') {
      const raw = await provider('get_objectives', { page: url.searchParams.get('page') || 1 }, { ttl: 90 });
      return send(res, 200, { data: normalizeObjectives(raw) });
    }

    if (path === '/api/v1/meta/players') {
      if (!API_KEY) return send(res, 200, { data: [], meta: { source: 'none', status: 'unavailable' } });
      try {
        const raw = await provider('get_meta_players', {
          position: url.searchParams.get('position'),
          role: url.searchParams.get('role'),
          platform: url.searchParams.get('platform') || 'ps',
        }, { ttl: 90 });
        const data = unwrap(raw);
        const list = data?.players || data?.items || data?.results || (Array.isArray(data) ? data : []);
        if (!Array.isArray(list)) return send(res, 200, { data: [] });
        return send(res, 200, { data: list });
      } catch {
        return send(res, 200, { data: [], meta: { source: 'none', status: 'unavailable' } });
      }
    }

    if (path === '/api/v1/home') {
      const [trendRaw, sbcRaw, evoRaw, objectiveRaw] = await Promise.all([
        provider('get_market_trends', {}, { ttl: 60 }),
        provider('get_sbcs', { page: 1 }, { ttl: 120 }),
        provider('get_evos', {}, { ttl: 120 }),
        provider('get_objectives', { page: 1 }, { ttl: 90 }),
      ]);
      const trendData = unwrap(trendRaw);
      const trendingPlayers = (Array.isArray(trendData?.top_movers) ? trendData.top_movers : [])
        .map(normalizePlayer)
        .filter((p) => p.id && p.name)
        .slice(0, 10);
      return send(res, 200, {
        data: {
          trending_players: trendingPlayers,
          market_movers: Array.isArray(trendData?.top_movers) ? trendData.top_movers.slice(0, 10) : [],
          sbcs: normalizeSbcList(sbcRaw).slice(0, 8),
          evolutions: normalizeEvolutionList(evoRaw).slice(0, 8),
          objectives: normalizeObjectives(objectiveRaw).slice(0, 8),
        },
      });
    }

    if (path === '/api/v1/whats-hot') {
      const [sbcRaw, evoRaw, objectiveRaw] = await Promise.all([
        provider('get_sbcs', { page: 1 }, { ttl: 120 }),
        provider('get_evos', {}, { ttl: 120 }),
        provider('get_objectives', { page: 1 }, { ttl: 120 }),
      ]);
      return send(res, 200, {
        data: {
          sbcs: normalizeSbcList(sbcRaw).slice(0, 10),
          evolutions: normalizeEvolutionList(evoRaw).slice(0, 10),
          objectives: normalizeObjectives(objectiveRaw).slice(0, 10),
        },
      });
    }

    return send(res, 404, { error: 'not_found' });
  } catch (error) {
    const status = Number(error?.status) || 500;
    return send(res, status, {
      error: String(error?.message || 'internal_error'),
      message: status >= 500 ? 'در دریافت دیتای واقعی FC27 خطایی رخ داد.' : String(error?.message || 'request_failed'),
    });
  }
}

const server = http.createServer(handler);
server.listen(PORT, '0.0.0.0', () => {
  console.log('FCBaz backend listening on :' + PORT + ' (no accounts, local-first)');
});
