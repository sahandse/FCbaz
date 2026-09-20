import http from 'node:http';
import { GoogleAuth } from 'google-auth-library';

const PORT = Number(process.env.PORT || 8787);
const API_KEY = process.env.PARSE_API_KEY || '';
const SCRAPER_ID = process.env.PARSE_SCRAPER_ID || '21963078-8a17-40ff-a896-9b0b0ec3e828';
const CACHE_TTL = Math.max(10, Number(process.env.CACHE_TTL_SECONDS || 60));
const PROVIDER_BASE = 'https://api.parse.bot/scraper/' + SCRAPER_ID + '/';
const SUPABASE_URL = (process.env.SUPABASE_URL || '').replace(/\/$/, '');
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || '';
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || '';
const FIREBASE_PROJECT_ID = process.env.FIREBASE_PROJECT_ID || '';
const FIREBASE_CLIENT_EMAIL = process.env.FIREBASE_CLIENT_EMAIL || '';
const FIREBASE_PRIVATE_KEY = (process.env.FIREBASE_PRIVATE_KEY || '').replace(/\\n/g, '\n');
const CRON_SECRET = process.env.CRON_SECRET || '';


const cache = new Map();

function send(res, status, body, extraHeaders = {}) {
  const payload = JSON.stringify(body);
  res.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'cache-control': status === 200 ? 'public, max-age=30' : 'no-store',
    'access-control-allow-origin': '*',
    ...extraHeaders,
  });
  res.end(payload);
}

async function readJsonBody(req) {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  const raw = Buffer.concat(chunks).toString('utf8').trim();
  if (!raw) return {};
  try {
    return JSON.parse(raw);
  } catch {
    throw Object.assign(new Error('invalid_json_body'), { status: 400 });
  }
}

function cloudConfigured() {
  return Boolean(SUPABASE_URL && SUPABASE_ANON_KEY && SUPABASE_SERVICE_ROLE_KEY);
}

async function supabaseAuth(path, { method = 'GET', body, bearer } = {}) {
  if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
    throw Object.assign(new Error('account_backend_not_configured'), { status: 503 });
  }

  const response = await fetch(SUPABASE_URL + '/auth/v1' + path, {
    method,
    headers: {
      'apikey': SUPABASE_ANON_KEY,
      'Authorization': 'Bearer ' + (bearer || SUPABASE_ANON_KEY),
      'Content-Type': 'application/json',
    },
    body: body ? JSON.stringify(body) : undefined,
    signal: AbortSignal.timeout(12000),
  });

  const text = await response.text();
  let json = {};
  try { json = text ? JSON.parse(text) : {}; } catch {}

  if (!response.ok) {
    const error = new Error(
      json?.msg || json?.message || json?.error_description || json?.error || 'auth_failed'
    );
    error.status = response.status;
    throw error;
  }

  return json;
}

async function requireUser(req) {
  const auth = String(req.headers.authorization || '');
  if (!auth.startsWith('Bearer ')) {
    throw Object.assign(new Error('authentication_required'), { status: 401 });
  }
  const token = auth.slice(7).trim();
  if (!token) {
    throw Object.assign(new Error('authentication_required'), { status: 401 });
  }
  const user = await supabaseAuth('/user', { bearer: token });
  return { user, token };
}

async function supabaseRest(path, { method = 'GET', body, prefer } = {}) {
  if (!cloudConfigured()) {
    throw Object.assign(new Error('cloud_sync_not_configured'), { status: 503 });
  }

  const response = await fetch(SUPABASE_URL + '/rest/v1/' + path, {
    method,
    headers: {
      'apikey': SUPABASE_SERVICE_ROLE_KEY,
      'Authorization': 'Bearer ' + SUPABASE_SERVICE_ROLE_KEY,
      'Content-Type': 'application/json',
      ...(prefer ? { 'Prefer': prefer } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
    signal: AbortSignal.timeout(12000),
  });

  const text = await response.text();
  let json = null;
  try { json = text ? JSON.parse(text) : null; } catch {}

  if (!response.ok) {
    const error = new Error(json?.message || json?.hint || 'cloud_request_failed');
    error.status = response.status;
    throw error;
  }
  return json;
}

async function registerDevice(userId, token, platform = 'android') {
  if (!token) return;
  await supabaseRest('fcbaz_devices?on_conflict=token', {
    method: 'POST',
    prefer: 'resolution=merge-duplicates,return=minimal',
    body: {
      user_id: userId,
      token,
      platform,
      updated_at: new Date().toISOString(),
    },
  });
}

let firebaseAuthClient = null;
async function fcmAccessToken() {
  if (!FIREBASE_PROJECT_ID || !FIREBASE_CLIENT_EMAIL || !FIREBASE_PRIVATE_KEY) {
    throw Object.assign(new Error('firebase_not_configured'), { status: 503 });
  }

  if (!firebaseAuthClient) {
    const auth = new GoogleAuth({
      credentials: {
        client_email: FIREBASE_CLIENT_EMAIL,
        private_key: FIREBASE_PRIVATE_KEY,
      },
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    });
    firebaseAuthClient = await auth.getClient();
  }

  const token = await firebaseAuthClient.getAccessToken();
  return typeof token === 'string' ? token : token?.token;
}

async function sendFcm(token, { title, body, data = {} }) {
  const accessToken = await fcmAccessToken();
  const response = await fetch(
    'https://fcm.googleapis.com/v1/projects/' +
      encodeURIComponent(FIREBASE_PROJECT_ID) +
      '/messages:send',
    {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer ' + accessToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
          data: Object.fromEntries(
            Object.entries(data).map(([k, v]) => [k, String(v)])
          ),
          android: {
            priority: 'high',
            notification: {
              channel_id: 'price_alerts',
            },
          },
        },
      }),
      signal: AbortSignal.timeout(12000),
    },
  );

  const text = await response.text();
  let json = {};
  try { json = text ? JSON.parse(text) : {}; } catch {}
  if (!response.ok) {
    const error = new Error(json?.error?.message || 'fcm_send_failed');
    error.status = response.status;
    throw error;
  }
  return json;
}

function providerNotConfigured(res) {
  send(res, 503, {
    error: 'provider_not_configured',
    message: 'Real FC27 data provider is not configured.',
  });
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

function firstObject(value) {
  if (!value || typeof value !== 'object') return null;
  if (Array.isArray(value)) return null;
  return value;
}

function unwrap(payload) {
  if (payload && typeof payload === 'object' && 'data' in payload) return payload.data;
  return payload;
}

async function provider(endpoint, params = {}, { ttl = CACHE_TTL } = {}) {
  if (!API_KEY) throw Object.assign(new Error('provider_not_configured'), { status: 503 });

  const url = new URL(PROVIDER_BASE + endpoint);
  for (const [key, value] of Object.entries(params)) {
    if (value === undefined || value === null || value === '') continue;
    url.searchParams.set(key, String(value));
  }

  const key = url.toString();
  const cached = cache.get(key);
  const now = Date.now();
  if (cached && now - cached.at < ttl * 1000) return cached.value;

  const response = await fetch(url, {
    headers: {
      'X-API-Key': API_KEY,
      'Accept': 'application/json',
      'User-Agent': 'FCBaz/1.0',
    },
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
    error.providerBody = body;
    throw error;
  }

  cache.set(key, { at: now, value: body });
  return body;
}

function stringList(value) {
  if (!Array.isArray(value)) return [];
  return value.map((x) => {
    if (x && typeof x === 'object') {
      return String(x.name ?? x.title ?? x.label ?? '');
    }
    return String(x ?? '');
  }).filter(Boolean);
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

function normalizePlayer(raw) {
  const stats = raw?.stats || raw?.face_stats || {};
  const positions = raw?.alternative_positions || raw?.positions || [];
  const playStylesRaw = raw?.playstyles || raw?.play_styles || raw?.playStyles || [];
  const playStylesPlusRaw = raw?.playstyles_plus || raw?.play_styles_plus || raw?.playStylesPlus || [];
  const rolesRaw = raw?.roles || raw?.player_roles || raw?.role_plus || [];
  const inGameRaw =
    raw?.in_game_stats ||
    raw?.detailed_stats ||
    raw?.attributes ||
    raw?.stats_detail ||
    {};

  return {
    id: String(raw?.id ?? raw?.player_id ?? ''),
    name: String(raw?.name ?? ''),
    rating: asInt(raw?.rating ?? raw?.overall),
    position: String(raw?.position ?? '').replaceAll('+', ''),
    positions: Array.isArray(positions) ? positions.map(String) : [],
    club_name: String(raw?.club ?? raw?.club_name ?? ''),
    league_name: String(raw?.league ?? raw?.league_name ?? ''),
    nation_name: String(raw?.nation ?? raw?.nation_name ?? ''),
    version: String(raw?.version ?? raw?.rarity ?? ''),
    rarity: String(raw?.rarity ?? raw?.rarity_name ?? ''),
    card_type: String(raw?.card_type ?? raw?.type ?? raw?.quality ?? ''),
    image_url: String(raw?.image_large ?? raw?.image ?? ''),
    card_image_url: String(raw?.card_image_large_url ?? raw?.card_image_url ?? raw?.card_image ?? ''),
    pace: asInt(stats.PAC ?? stats.pace ?? raw?.pace),
    shooting: asInt(stats.SHO ?? stats.shooting ?? raw?.shooting),
    passing: asInt(stats.PAS ?? stats.passing ?? raw?.passing),
    dribbling: asInt(stats.DRI ?? stats.dribbling ?? raw?.dribbling),
    defending: asInt(stats.DEF ?? stats.defending ?? raw?.defending),
    physical: asInt(stats.PHY ?? stats.physical ?? raw?.physical),
    skill_moves: asInt(raw?.skill_moves),
    weak_foot: asInt(raw?.weak_foot),
    playstyles: stringList(playStylesRaw),
    playstyles_plus: stringList(playStylesPlusRaw),
    roles: stringList(rolesRaw),
    in_game_stats: flattenNumericStats(inGameRaw),
    traits: stringList(raw?.traits || []),
    foot: String(raw?.preferred_foot ?? raw?.foot ?? ''),
    height: String(raw?.height ?? ''),
    work_rates: String(raw?.work_rates ?? raw?.workrates ?? ''),
    price_ps: asInt(raw?.price_ps_coins ?? raw?.price_ps),
    price_pc: asInt(raw?.price_pc_coins ?? raw?.price_pc),
    trend_ps: raw?.trend_ps ?? null,
    trend_pc: raw?.trend_pc ?? null,
    source: 'futbin-via-parse',
    game_year: 27,
  };
}

function playerArray(payload) {
  const data = unwrap(payload);
  const candidates = [
    data?.players,
    data?.results,
    data?.items,
    Array.isArray(data) ? data : null,
  ];
  const raw = candidates.find(Array.isArray) || [];
  return raw.map(normalizePlayer).filter((p) => p.id && p.name);
}

function normalizePrice(raw, playerId, platform = 'console') {
  const data = unwrap(raw);
  const p = firstObject(data) || {};
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
    updated_at: p.updated_at_iso ?? null,
    updated_text: p.updated ?? p.updated_text ?? null,
    lowest_bins: bins,
    average_price_24h: asInt(p.average_price_24h),
    source: 'futbin-via-parse',
  };
}

function normalizeHistory(raw) {
  const data = unwrap(raw);
  const series = data?.prices || data?.history || data?.points || (Array.isArray(data) ? data : []);
  if (!Array.isArray(series)) return [];
  return series.map((point) => ({
    time: typeof point?.timestamp === 'number'
      ? new Date(point.timestamp).toISOString()
      : String(point?.time ?? point?.timestamp ?? ''),
    price: asInt(point?.price ?? point?.value),
  })).filter((p) => p.price > 0 && p.time);
}

function normalizeSbcList(raw) {
  const data = unwrap(raw);
  const sets = data?.sbcs || data?.items || data?.results || (Array.isArray(data) ? data : []);
  if (!Array.isArray(sets)) return [];

  const out = [];
  for (const set of sets) {
    const challenges = Array.isArray(set?.challenges) && set.challenges.length
      ? set.challenges
      : [set];

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
        requirements: Array.isArray(challenge?.requirements)
          ? challenge.requirements.map(String)
          : [],
        repeatable: Boolean(challenge?.repeatable ?? set?.repeatable),
        expires_at: challenge?.expires ?? set?.expires ?? null,
        estimated_cost: asInt(challenge?.cost_ps ?? set?.cost_ps),
        item_score: challenge?.item_score ?? null,
        guide_fa: [],
        solver_name: title,
        source: 'futbin-via-parse',
      });
    }
  }
  return out;
}

async function findSbc(id) {
  const raw = await provider('get_sbcs', { page: 1 }, { ttl: 120 });
  return normalizeSbcList(raw).find((item) => item.id === id) || null;
}

function normalizeEvolutionList(raw) {
  const data = unwrap(raw);
  const list = data?.evolutions || data?.items || data?.results || (Array.isArray(data) ? data : []);
  if (!Array.isArray(list)) return [];
  return list.map((e, index) => ({
    id: String(e?.id ?? e?.evolution_id ?? index),
    title: String(e?.name ?? e?.title ?? ''),
    description: String(e?.description ?? ''),
    cost: asInt(e?.cost ?? e?.coins),
    requirements: Array.isArray(e?.requirements)
      ? e.requirements.map((x) => typeof x === 'string' ? x : JSON.stringify(x))
      : [],
    requirements_raw: Array.isArray(e?.requirements) ? e.requirements : [],
    upgrades: Array.isArray(e?.upgrades ?? e?.boosts)
      ? (e.upgrades ?? e.boosts).map((x) => typeof x === 'string' ? x : JSON.stringify(x))
      : [],
    steps: Array.isArray(e?.steps) ? e.steps : [],
    expires_at: e?.expires ?? e?.expires_at ?? null,
    repeatable: Boolean(e?.repeatable),
    status: String(e?.status ?? ''),
    source: 'futbin-via-parse',
  })).filter((e) => e.title);
}

async function handler(req, res) {
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'access-control-allow-origin': '*',
      'access-control-allow-methods': 'GET,POST,OPTIONS',
      'access-control-allow-headers': 'content-type,authorization',
    });
    return res.end();
  }

  const url = new URL(req.url, 'http://localhost');
  const path = url.pathname;

  try {
    if (path === '/health') {
      return send(res, 200, {
        ok: true,
        provider_configured: Boolean(API_KEY),
        game_year: 27,
      });
    }

    if (path === '/api/v1/account/register' && req.method === 'POST') {
      const body = await readJsonBody(req);
      const email = String(body?.email || '').trim();
      const password = String(body?.password || '');

      if (!email || password.length < 8) {
        return send(res, 400, {
          error: 'invalid_credentials',
          message: 'Email and password with at least 8 characters are required.',
        });
      }

      const data = await supabaseAuth('/signup', {
        method: 'POST',
        body: { email, password },
      });

      return send(res, 200, {
        data: {
          access_token: data?.access_token || '',
          refresh_token: data?.refresh_token || '',
          user: data?.user || null,
          email_confirmation_required: !data?.access_token,
        },
      });
    }

    if (path === '/api/v1/account/login' && req.method === 'POST') {
      const body = await readJsonBody(req);
      const email = String(body?.email || '').trim();
      const password = String(body?.password || '');

      const data = await supabaseAuth('/token?grant_type=password', {
        method: 'POST',
        body: { email, password },
      });

      return send(res, 200, {
        data: {
          access_token: data?.access_token || '',
          refresh_token: data?.refresh_token || '',
          user: data?.user || null,
        },
      });
    }

    if (path === '/api/v1/account/me' && req.method === 'GET') {
      const { user } = await requireUser(req);
      return send(res, 200, {
        data: {
          id: user?.id || '',
          email: user?.email || '',
          created_at: user?.created_at || null,
        },
      });
    }

    if (path === '/api/v1/account/sync' && req.method === 'POST') {
      const { user } = await requireUser(req);
      const body = await readJsonBody(req);
      const snapshot = body?.snapshot;

      if (!snapshot || typeof snapshot !== 'object') {
        return send(res, 400, { error: 'snapshot_required' });
      }

      const updatedAt = new Date().toISOString();
      await supabaseRest('fcbaz_user_sync?on_conflict=user_id', {
        method: 'POST',
        prefer: 'resolution=merge-duplicates,return=minimal',
        body: {
          user_id: user.id,
          snapshot,
          updated_at: updatedAt,
        },
      });

      return send(res, 200, {
        data: {
          updated_at: updatedAt,
          item_count: Object.keys(snapshot?.data || {}).length,
        },
      });
    }

    if (path === '/api/v1/account/sync' && req.method === 'GET') {
      const { user } = await requireUser(req);
      const rows = await supabaseRest(
        'fcbaz_user_sync?user_id=eq.' +
          encodeURIComponent(user.id) +
          '&select=snapshot,updated_at&limit=1'
      );

      const row = Array.isArray(rows) ? rows[0] : null;
      return send(res, 200, { data: row || null });
    }

    if (path === '/api/v1/push/register-device' && req.method === 'POST') {
      const { user } = await requireUser(req);
      const body = await readJsonBody(req);
      const token = String(body?.token || '').trim();

      if (!token) return send(res, 400, { error: 'device_token_required' });

      await registerDevice(user.id, token, String(body?.platform || 'android'));
      return send(res, 200, { data: { registered: true } });
    }

    if (path === '/api/v1/push/check-price-alerts' && req.method === 'POST') {
      const secret = String(req.headers['x-cron-secret'] || '');
      if (!CRON_SECRET || secret !== CRON_SECRET) {
        return send(res, 401, { error: 'invalid_cron_secret' });
      }

      if (!API_KEY) return providerNotConfigured(res);
      if (!cloudConfigured()) {
        return send(res, 503, { error: 'cloud_sync_not_configured' });
      }

      const syncRows = await supabaseRest(
        'fcbaz_user_sync?select=user_id,snapshot&limit=1000'
      );
      let checked = 0;
      let pushed = 0;

      for (const row of Array.isArray(syncRows) ? syncRows : []) {
        const rawWatchlist = row?.snapshot?.data?.fcbaz_market_watchlist;
        if (!rawWatchlist || typeof rawWatchlist !== 'string') continue;

        let watchlist = [];
        try { watchlist = JSON.parse(rawWatchlist); } catch { continue; }
        if (!Array.isArray(watchlist)) continue;

        const devices = await supabaseRest(
          'fcbaz_devices?user_id=eq.' +
            encodeURIComponent(String(row.user_id)) +
            '&select=token'
        );
        const tokens = (Array.isArray(devices) ? devices : [])
          .map((d) => String(d?.token || ''))
          .filter(Boolean);
        if (!tokens.length) continue;

        for (const item of watchlist) {
          const playerId = String(item?.player_id || '');
          const target = asInt(item?.target_price);
          if (!playerId || !target) continue;

          try {
            const marketRaw = await provider(
              'get_fc27_player_price',
              { player_id: playerId, platform: 'ps' },
              { ttl: 45 },
            );
            const price = normalizePrice(marketRaw, playerId, 'console');
            checked++;

            if (price.current > 0 && price.current <= target) {
              for (const token of tokens) {
                try {
                  await sendFcm(token, {
                    title: 'FCBaz • قیمت هدف رسید',
                    body:
                      String(item?.player_name || 'بازیکن') +
                      ' به ' +
                      price.current +
                      ' Coins رسید.',
                    data: {
                      type: 'price_alert',
                      player_id: playerId,
                      price: price.current,
                      target_price: target,
                    },
                  });
                  pushed++;
                } catch {}
              }
            }
          } catch {}
        }
      }

      return send(res, 200, { data: { checked, pushed } });
    }

    if (!API_KEY) return providerNotConfigured(res);

    if (path === '/api/v1/players/advanced') {
      const query = (url.searchParams.get('q') || '').trim();
      const baseParams = {
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
        rarity: url.searchParams.get('rarity'),
        card_type: url.searchParams.get('card_type'),
        sort_by_price: url.searchParams.get('sort_by_price'),
        platform: url.searchParams.get('platform') || 'ps',
      };

      const raw = query.length >= 2
        ? await provider('search_players_fc27', {
            query,
            page: baseParams.page,
          })
        : await provider('list_fc27_players', baseParams);

      let players = playerArray(raw);

      const detailFiltersActive = [
        'play_style',
        'play_style_plus',
        'role',
        'min_skill_moves',
        'min_weak_foot',
        'min_pace',
        'max_pace',
        'min_shooting',
        'max_shooting',
        'min_passing',
        'max_passing',
        'min_dribbling',
        'max_dribbling',
        'min_defending',
        'max_defending',
        'min_physical',
        'max_physical',
      ].some((key) => (url.searchParams.get(key) || '').trim() !== '');

      if (detailFiltersActive && players.length) {
        const enriched = await Promise.all(
          players.slice(0, 30).map(async (p) => {
            try {
              const detailRaw = await provider(
                'get_player_details',
                { player_id: p.id, year: 27 },
                { ttl: 120 },
              );
              const detailData = unwrap(detailRaw);
              return normalizePlayer(detailData?.player ?? detailData);
            } catch {
              return p;
            }
          }),
        );
        players = enriched;
      }

      const textEq = (actual, expected) =>
        !expected ||
        String(actual || '').toLowerCase() === String(expected).toLowerCase();

      const textContains = (actual, expected) =>
        !expected ||
        String(actual || '').toLowerCase().includes(String(expected).toLowerCase());

      const includesText = (list, expected) => {
        if (!expected) return true;
        const target = String(expected).toLowerCase();
        return Array.isArray(list) &&
          list.some((x) => String(x).toLowerCase().includes(target));
      };

      const minRating = asInt(url.searchParams.get('min_rating'));
      const maxRating = asInt(url.searchParams.get('max_rating'));
      const minPrice = asInt(url.searchParams.get('min_price'));
      const maxPrice = asInt(url.searchParams.get('max_price'));
      const platform = url.searchParams.get('platform') === 'pc' ? 'pc' : 'ps';

      const minStat = (key) => asInt(url.searchParams.get('min_' + key));
      const maxStat = (key) => asInt(url.searchParams.get('max_' + key));

      players = players.filter((p) => {
        const price = platform === 'pc' ? p.price_pc : p.price_ps;
        const position = url.searchParams.get('position');
        const league = url.searchParams.get('league');
        const club = url.searchParams.get('club');
        const nation = url.searchParams.get('nation');
        const version = url.searchParams.get('version');
        const rarity = url.searchParams.get('rarity');
        const cardType = url.searchParams.get('card_type');
        const playStyle = url.searchParams.get('play_style');
        const playStylePlus = url.searchParams.get('play_style_plus');
        const role = url.searchParams.get('role');
        const minSkillMoves = asInt(url.searchParams.get('min_skill_moves'));
        const minWeakFoot = asInt(url.searchParams.get('min_weak_foot'));

        if (minRating && p.rating < minRating) return false;
        if (maxRating && p.rating > maxRating) return false;
        if (minPrice && (!price || price < minPrice)) return false;
        if (maxPrice && (!price || price > maxPrice)) return false;

        if (
          position &&
          p.position !== position &&
          !p.positions.includes(position)
        ) return false;

        if (!textContains(p.league_name, league)) return false;
        if (!textContains(p.club_name, club)) return false;
        if (!textContains(p.nation_name, nation)) return false;
        if (!textEq(p.version, version)) return false;
        if (!textEq(p.rarity, rarity)) return false;
        if (!textEq(p.card_type, cardType)) return false;
        if (!includesText(p.playstyles, playStyle)) return false;
        if (!includesText(p.playstyles_plus, playStylePlus)) return false;
        if (!includesText(p.roles, role)) return false;

        if (minSkillMoves && p.skill_moves < minSkillMoves) return false;
        if (minWeakFoot && p.weak_foot < minWeakFoot) return false;

        for (const stat of ['pace','shooting','passing','dribbling','defending','physical']) {
          const min = minStat(stat);
          const max = maxStat(stat);
          const value = Number(p?.[stat] || 0);
          if (min && value < min) return false;
          if (max && value > max) return false;
        }

        return true;
      });

      const sort = url.searchParams.get('sort') || 'rating_desc';
      const statValue = (p, key) => Number(p?.[key] || 0);

      const sorters = {
        rating_desc: (a, b) => b.rating - a.rating,
        rating_asc: (a, b) => a.rating - b.rating,
        price_asc: (a, b) =>
          (platform === 'pc' ? a.price_pc : a.price_ps) -
          (platform === 'pc' ? b.price_pc : b.price_ps),
        price_desc: (a, b) =>
          (platform === 'pc' ? b.price_pc : b.price_ps) -
          (platform === 'pc' ? a.price_pc : a.price_ps),
        pace: (a, b) => statValue(b, 'pace') - statValue(a, 'pace'),
        shooting: (a, b) => statValue(b, 'shooting') - statValue(a, 'shooting'),
        passing: (a, b) => statValue(b, 'passing') - statValue(a, 'passing'),
        dribbling: (a, b) => statValue(b, 'dribbling') - statValue(a, 'dribbling'),
        defending: (a, b) => statValue(b, 'defending') - statValue(a, 'defending'),
        physical: (a, b) => statValue(b, 'physical') - statValue(a, 'physical'),
      };

      players.sort(sorters[sort] || sorters.rating_desc);

      const facets = {
        versions: [...new Set(players.map((p) => p.version).filter(Boolean))].sort(),
        rarities: [...new Set(players.map((p) => p.rarity).filter(Boolean))].sort(),
        card_types: [...new Set(players.map((p) => p.card_type).filter(Boolean))].sort(),
        leagues: [...new Set(players.map((p) => p.league_name).filter(Boolean))].sort(),
        clubs: [...new Set(players.map((p) => p.club_name).filter(Boolean))].sort(),
        nations: [...new Set(players.map((p) => p.nation_name).filter(Boolean))].sort(),
        playstyles: [...new Set(players.flatMap((p) => p.playstyles || []).filter(Boolean))].sort(),
        playstyles_plus: [...new Set(players.flatMap((p) => p.playstyles_plus || []).filter(Boolean))].sort(),
        roles: [...new Set(players.flatMap((p) => p.roles || []).filter(Boolean))].sort(),
      };

      return send(res, 200, {
        data: players,
        meta: {
          source: 'futbin-via-parse',
          game_year: 27,
          page: Number(baseParams.page),
          facets,
        },
      });
    }

    if (path === '/api/v1/players/trending') {
      const raw = await provider('get_market_trends', {}, { ttl: 60 });
      const data = unwrap(raw);
      const candidates = [
        ...(Array.isArray(data?.top_movers) ? data.top_movers : []),
        ...(Array.isArray(data?.popular_players) ? data.popular_players : []),
        ...(Array.isArray(data?.trending_players) ? data.trending_players : []),
      ];

      const ids = [];
      for (const row of candidates) {
        const id = String(row?.player_id ?? row?.id ?? '');
        if (id && /^\d+$/.test(id) && !ids.includes(id)) ids.push(id);
        if (ids.length >= 12) break;
      }

      const details = await Promise.all(
        ids.map(async (id) => {
          try {
            const detailRaw = await provider(
              'get_player_details',
              { player_id: id, year: 27 },
              { ttl: 120 },
            );
            const detailData = unwrap(detailRaw);
            return normalizePlayer(detailData?.player ?? detailData);
          } catch {
            return null;
          }
        }),
      );

      return send(res, 200, {
        data: details.filter((p) => p && p.id && p.name),
        meta: { source: 'futbin-via-parse', game_year: 27 },
      });
    }

    if (path === '/api/v1/players') {
      const raw = await provider('list_fc27_players', {
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
        sort_by_price: url.searchParams.get('sort_by_price'),
        platform: url.searchParams.get('platform') || 'ps',
      });
      return send(res, 200, { data: playerArray(raw), meta: { source: 'futbin-via-parse', game_year: 27 } });
    }

    if (path === '/api/v1/players/search') {
      const q = (url.searchParams.get('q') || '').trim();
      if (q.length < 2) return send(res, 400, { error: 'query_too_short' });
      const raw = await provider('search_players_fc27', {
        query: q,
        page: url.searchParams.get('page') || 1,
      });
      return send(res, 200, { data: playerArray(raw), meta: { source: 'futbin-via-parse', game_year: 27 } });
    }

    const playerVersions = path.match(/^\/api\/v1\/players\/([^/]+)\/versions$/);
    if (playerVersions) {
      const id = decodeURIComponent(playerVersions[1]);
      const detailRaw = await provider('get_player_details', { player_id: id, year: 27 });
      const detailData = unwrap(detailRaw);
      const base = detailData?.player ?? detailData;
      const embedded =
        detailData?.versions ||
        detailData?.other_versions ||
        detailData?.related_cards ||
        detailData?.cards ||
        [];

      let versions = Array.isArray(embedded)
        ? embedded.map(normalizePlayer).filter((p) => p.id && p.name)
        : [];

      if (!versions.length && base?.name) {
        const searchRaw = await provider('search_players_fc27', {
          query: String(base.name),
          page: 1,
        });
        versions = playerArray(searchRaw).filter((p) =>
          p.name.toLowerCase() === String(base.name).toLowerCase()
        );
      }

      const unique = [];
      const seen = new Set();
      for (const item of versions) {
        if (!item.id || seen.has(item.id)) continue;
        seen.add(item.id);
        unique.push(item);
      }

      unique.sort((a, b) => b.rating - a.rating);
      return send(res, 200, {
        data: unique,
        meta: { source: 'futbin-via-parse', game_year: 27 },
      });
    }

    const playerMatch = path.match(/^\/api\/v1\/players\/([^/]+)$/);
    if (playerMatch) {
      const id = decodeURIComponent(playerMatch[1]);
      const raw = await provider('get_player_details', { player_id: id, year: 27 });
      const data = unwrap(raw);
      const player = normalizePlayer(data?.player ?? data);
      return send(res, 200, { data: player, meta: { source: 'futbin-via-parse', game_year: 27 } });
    }

    const marketPlayer = path.match(/^\/api\/v1\/market\/players\/([^/]+)$/);
    if (marketPlayer) {
      const id = decodeURIComponent(marketPlayer[1]);
      const platform = url.searchParams.get('platform') || 'console';
      if (platform === 'pc') {
        const raw = await provider('get_player_details', { player_id: id, year: 27 });
        const data = unwrap(raw);
        const prices = data?.prices?.pc || {};
        return send(res, 200, {
          data: {
            player_id: id,
            platform: 'pc',
            current: asInt(prices?.price ?? prices?.current),
            low: asInt(prices?.range?.min),
            high: asInt(prices?.range?.max),
            change_24h_percent: Number(prices?.trend ?? 0) || 0,
            updated_at: null,
            source: 'futbin-via-parse',
          },
        });
      }
      const raw = await provider('get_fc27_player_price', { player_id: id });
      return send(res, 200, { data: normalizePrice(raw, id, 'console') });
    }

    const historyMatch = path.match(/^\/api\/v1\/market\/players\/([^/]+)\/history$/);
    if (historyMatch) {
      const id = decodeURIComponent(historyMatch[1]);
      const platform = url.searchParams.get('platform') === 'pc' ? 'pc' : 'ps';
      const range = url.searchParams.get('range') || '7d';
      const graph_type = range === '24h' ? 'hourly_graph' : 'daily_graph';
      const raw = await provider('get_player_price_history', {
        player_id: id,
        year: 27,
        platform,
        graph_type,
      });
      return send(res, 200, { data: normalizeHistory(raw), meta: { source: 'futbin-via-parse' } });
    }

    if (path === '/api/v1/club/snapshot') {
      const rawIds = (url.searchParams.get('player_ids') || '').trim();
      const ids = [...new Set(rawIds.split(',').map((x) => x.trim()).filter((x) => /^\d+$/.test(x)))];
      if (!ids.length) return send(res, 400, { error: 'player_ids_required' });
      if (ids.length > 500) return send(res, 400, { error: 'too_many_player_ids', max: 500 });

      const platform = url.searchParams.get('platform') === 'pc' ? 'pc' : 'ps';
      const raw = await provider('get_fc27_market_snapshot', {
        player_ids: ids.join(','),
        year: 27,
        platform,
      }, { ttl: 45 });

      const data = unwrap(raw);
      const players = Array.isArray(data?.players) ? data.players : [];
      return send(res, 200, {
        data: players.map((p) => ({
          player_id: String(p?.player_id ?? ''),
          price: p?.price == null ? null : asInt(p.price),
        })),
        meta: {
          source: 'futbin-via-parse',
          game_year: 27,
          platform,
          timestamp: data?.timestamp ?? Date.now(),
        },
      });
    }

    if (path === '/api/v1/market') {
      const raw = await provider('get_market_trends', {});
      const data = unwrap(raw);
      return send(res, 200, {
        data: data?.top_movers || [],
        meta: {
          source: 'futbin-via-parse',
          console_index: data?.console ?? data?.console_index ?? null,
          pc_index: data?.pc ?? data?.pc_index ?? null,
        },
      });
    }

    if (path === '/api/v1/market/cheapest') {
      const raw = await provider('list_fc27_players', {
        page: url.searchParams.get('page') || 1,
        min_rating: url.searchParams.get('min_rating') || 75,
        max_rating: url.searchParams.get('max_rating') || 99,
        min_price: url.searchParams.get('min_price') || 200,
        max_price: url.searchParams.get('max_price') || 15000000,
        position: url.searchParams.get('position'),
        sort_by_price: 'asc',
        platform: url.searchParams.get('platform') === 'pc' ? 'pc' : 'ps',
      });
      const players = playerArray(raw).filter((p) => (url.searchParams.get('platform') === 'pc' ? p.price_pc : p.price_ps) > 0);
      return send(res, 200, { data: players, meta: { source: 'futbin-via-parse', sorted: 'price_asc' } });
    }

    if (path === '/api/v1/sbc') {
      const raw = await provider('get_sbcs', { page: url.searchParams.get('page') || 1 }, { ttl: 120 });
      return send(res, 200, { data: normalizeSbcList(raw), meta: { source: 'futbin-via-parse' } });
    }

    const sbcSolution = path.match(/^\/api\/v1\/sbc\/([^/]+)\/solution$/);
    if (sbcSolution) {
      const id = decodeURIComponent(sbcSolution[1]);
      const sbc = await findSbc(id);
      if (!sbc) return send(res, 404, { error: 'sbc_not_found' });

      const raw = await provider('fc27_sbc_solver', {
        sbc_name: sbc.solver_name,
        max_age_minutes: url.searchParams.get('max_age_minutes') || 10,
      }, { ttl: 30 });
      const data = unwrap(raw);
      const ownedIds = new Set(
        (url.searchParams.get('owned_ids') || '')
          .split(',')
          .map((x) => x.trim())
          .filter(Boolean),
      );
      const solutionPlayers = Array.isArray(data?.players)
        ? data.players.map((p) => ({
            player_id: String(p?.player_id ?? p?.id ?? ''),
            name: String(p?.name ?? ''),
            rating: asInt(p?.rating),
            price: asInt(p?.first_market_price ?? p?.price),
          })).filter((p) => p.player_id)
        : [];
      const ownedSolutionIds = solutionPlayers
        .filter((p) => ownedIds.has(p.player_id))
        .map((p) => p.player_id);
      const remainingCost = solutionPlayers
        .filter((p) => !ownedIds.has(p.player_id))
        .reduce((sum, p) => sum + p.price, 0);

      return send(res, 200, {
        data: {
          total_cost: asInt(data?.total_cost),
          remaining_cost: remainingCost,
          player_ids: solutionPlayers.map((p) => p.player_id),
          players: solutionPlayers,
          owned_player_ids: ownedSolutionIds,
          notes: [
            data?.message,
            data?.solution_status,
          ].filter(Boolean).map(String),
          item_score: data?.item_score ?? null,
          verification: data?.verification ?? null,
          search_complete: data?.search_complete ?? false,
          proven_optimal: data?.proven_optimal ?? false,
          source: 'futbin-via-parse',
        },
      });
    }

    const sbcDetail = path.match(/^\/api\/v1\/sbc\/([^/]+)$/);
    if (sbcDetail) {
      const sbc = await findSbc(decodeURIComponent(sbcDetail[1]));
      if (!sbc) return send(res, 404, { error: 'sbc_not_found' });
      return send(res, 200, { data: sbc });
    }

    if (path === '/api/v1/evolutions') {
      const raw = await provider('get_evos', {}, { ttl: 120 });
      const all = normalizeEvolutionList(raw);
      const active = url.searchParams.get('status') === 'active'
        ? all.filter((e) => !e.status || e.status.toLowerCase().includes('active'))
        : all;
      return send(res, 200, { data: active, meta: { source: 'futbin-via-parse' } });
    }

    if (path === '/api/v1/app/latest-release') {
      const releaseRepo = process.env.GITHUB_RELEASE_REPO || 'sahandse/FCbaz';
      const releaseUrl = 'https://api.github.com/repos/' + releaseRepo + '/releases/latest';

      const response = await fetch(releaseUrl, {
        headers: {
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'FCBaz-Backend/1.0',
          'X-GitHub-Api-Version': '2022-11-28',
        },
        signal: AbortSignal.timeout(10000),
      });

      if (response.status === 404) {
        return send(res, 200, {
          data: null,
          meta: { repository: releaseRepo, has_release: false },
        });
      }

      if (!response.ok) {
        return send(res, 502, {
          error: 'github_release_lookup_failed',
          status: response.status,
        });
      }

      const release = await response.json();
      return send(res, 200, {
        data: {
          tag_name: String(release?.tag_name ?? ''),
          name: String(release?.name ?? ''),
          html_url: String(release?.html_url ?? ''),
          published_at: release?.published_at ?? null,
          prerelease: release?.prerelease === true,
          draft: release?.draft === true,
        },
        meta: { repository: releaseRepo, has_release: true },
      });
    }

    if (path === '/api/v1/objectives') {
      const raw = await provider('get_objectives', {
        page: url.searchParams.get('page') || 1,
      }, { ttl: 90 });
      const data = unwrap(raw);
      const list =
        data?.objectives ||
        data?.items ||
        data?.results ||
        (Array.isArray(data) ? data : []);

      const objectives = Array.isArray(list)
        ? list.map((x, index) => ({
            id: String(x?.id ?? x?.objective_id ?? index),
            title: String(x?.name ?? x?.title ?? ''),
            description: String(x?.description ?? ''),
            reward: String(
              x?.reward?.name ??
              x?.reward_description ??
              x?.reward ??
              ''
            ),
            expires_at: x?.expires ?? x?.expires_at ?? null,
            task_count: asInt(x?.task_count ?? x?.tasks_count ?? x?.tasks?.length),
            category: String(x?.category ?? x?.group ?? 'Objective'),
            source: 'futbin-via-parse',
          })).filter((x) => x.title)
        : [];

      return send(res, 200, {
        data: objectives,
        meta: {
          source: 'futbin-via-parse',
          game_year: 27,
        },
      });
    }

    if (path === '/api/v1/home') {
      const [trendRaw, sbcRaw, evoRaw, objectiveRaw] = await Promise.all([
        provider('get_market_trends', {}, { ttl: 60 }),
        provider('get_sbcs', { page: 1 }, { ttl: 120 }),
        provider('get_evos', {}, { ttl: 120 }),
        provider('get_objectives', { page: 1 }, { ttl: 90 }),
      ]);

      const trendData = unwrap(trendRaw);
      const moversRaw = Array.isArray(trendData?.top_movers)
        ? trendData.top_movers
        : [];

      const moverIds = [];
      for (const row of moversRaw) {
        const id = String(row?.player_id ?? row?.id ?? '');
        if (id && /^\d+$/.test(id) && !moverIds.includes(id)) {
          moverIds.push(id);
        }
        if (moverIds.length >= 8) break;
      }

      const moverDetails = await Promise.all(
        moverIds.map(async (id) => {
          try {
            const detailRaw = await provider(
              'get_player_details',
              { player_id: id, year: 27 },
              { ttl: 120 },
            );
            const detailData = unwrap(detailRaw);
            return normalizePlayer(detailData?.player ?? detailData);
          } catch {
            return null;
          }
        }),
      );

      const objectiveData = unwrap(objectiveRaw);
      const objectiveList =
        objectiveData?.objectives ||
        objectiveData?.items ||
        objectiveData?.results ||
        (Array.isArray(objectiveData) ? objectiveData : []);

      const objectives = Array.isArray(objectiveList)
        ? objectiveList.slice(0, 6).map((x, index) => ({
            id: String(x?.id ?? x?.objective_id ?? index),
            title: String(x?.name ?? x?.title ?? ''),
            description: String(x?.description ?? ''),
            reward: String(
              x?.reward?.name ??
              x?.reward_description ??
              x?.reward ??
              ''
            ),
            expires_at: x?.expires ?? x?.expires_at ?? null,
            task_count: asInt(x?.task_count ?? x?.tasks_count ?? x?.tasks?.length),
          })).filter((x) => x.title)
        : [];

      return send(res, 200, {
        data: {
          trending_players: moverDetails.filter((p) => p && p.id && p.name),
          market_movers: moversRaw.slice(0, 8),
          sbcs: normalizeSbcList(sbcRaw).slice(0, 6),
          evolutions: normalizeEvolutionList(evoRaw).slice(0, 6),
          objectives,
        },
        meta: {
          source: 'futbin-via-parse',
          game_year: 27,
        },
      });
    }

    if (path === '/api/v1/whats-hot') {
      const [sbcRaw, evoRaw, objRaw] = await Promise.all([
        provider('get_sbcs', { page: 1 }, { ttl: 120 }),
        provider('get_evos', {}, { ttl: 120 }),
        provider('get_objectives', { page: 1 }, { ttl: 120 }),
      ]);
      const sbcs = normalizeSbcList(sbcRaw).slice(0, 8).map((x) => ({
        type: 'sbc',
        title: x.title,
        summary: x.description,
        expires_at: x.expires_at,
      }));
      const evos = normalizeEvolutionList(evoRaw).slice(0, 8).map((x) => ({
        type: 'evolution',
        title: x.title,
        summary: x.description,
        expires_at: x.expires_at,
      }));
      const objData = unwrap(objRaw);
      const objectivesRaw = objData?.objectives || objData?.items || objData?.results || (Array.isArray(objData) ? objData : []);
      const objectives = Array.isArray(objectivesRaw) ? objectivesRaw.slice(0, 8).map((x) => ({
        type: 'objective',
        title: String(x?.name ?? x?.title ?? ''),
        summary: String(x?.description ?? ''),
        expires_at: x?.expires ?? x?.expires_at ?? null,
      })) : [];

      return send(res, 200, {
        data: [...sbcs, ...evos, ...objectives].filter((x) => x.title),
        meta: { source: 'futbin-via-parse', game_year: 27 },
      });
    }

    return send(res, 404, { error: 'not_found' });
  } catch (error) {
    const status = Number(error?.status || 500);
    send(res, status >= 400 && status < 600 ? status : 500, {
      error: error?.message || 'server_error',
      provider_error: error?.providerBody ?? undefined,
    });
  }
}

http.createServer(handler).listen(PORT, '0.0.0.0', () => {
  console.log('FCBaz backend listening on :' + PORT);
});
