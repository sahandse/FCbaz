#!/usr/bin/env node
// Builds the FCBaz FC27 catalog from the public FC27 Hub snapshots.
// The site is the source of truth for base players, prices, SBCs, objectives,
// evolutions, card art, portraits and news. Existing catalog entries that the
// site does not cover (special cards) are preserved instead of being dropped.

import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { artKeyIndex, dedupeHallOfFut } from './lib/hof.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const PUBLIC_SITE = 'https://sahandse.github.io/FC27';
// FC27_SITE allows a local mirror for verification; published catalog URLs
// always point at the public hub.
const SITE = (process.env.FC27_SITE || PUBLIC_SITE).replace(/\/$/, '');
const EA_PLAYER_SOURCE = 'https://www.ea.com/games/ea-sports-fc/ratings';
// Exact FC27 Ultimate Team item cards published by EA for every rated player.
const EA_CARD_BASE =
  'https://ratings-images-prod.pulse.ea.com/FC27/components/items';
const CARD_ART_BASE =
  'https://game-assets.fut.gg/cdn-cgi/image/quality=85,format=auto,width=320/2027/futgg-player-item-card/';
const PORTRAIT_BASE = `${PUBLIC_SITE}/img/players/`;
const liveOnly = process.argv.includes('--live-only');

const localFeed = (name, value) => (process.env[name] || value).trim();
const FEEDS = {
  players: localFeed('FC27_PLAYERS_FEED', `${SITE}/data/fc27-players.json`),
  prices: localFeed('FC27_PRICES_FEED', `${SITE}/data/fc27-prices.json`),
  challenges: `${SITE}/data/fc27-challenges.json`,
  evolutions: `${SITE}/data/fc27-evolutions.json`,
  news: `${SITE}/data/fc27-news.json`,
  art: `${SITE}/data/fc27-card-art.json`,
  portraits: `${SITE}/data/available-portraits.json`,
};

const now = new Date().toISOString();

const clean = (value) => (value == null ? '' : String(value).trim());

const toEnglishDigits = (value) =>
  String(value ?? '').replace(/[۰-۹]/g, (d) => String('۰۱۲۳۴۵۶۷۸۹'.indexOf(d)));

const num = (value) => {
  if (typeof value === 'number' && Number.isFinite(value)) return Math.round(value);
  const parsed = Number(toEnglishDigits(value).replace(/[,٬\s]/g, ''));
  return Number.isFinite(parsed) ? Math.round(parsed) : 0;
};

const arr = (value) => (Array.isArray(value) ? value.map(clean).filter(Boolean) : []);

const unique = (values) => [...new Set(values.filter(Boolean))];

const titleCase = (value) =>
  clean(value)
    .replace(/[_-]+/g, ' ')
    .split(/\s+/)
    .filter(Boolean)
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');

const slug = (value) =>
  clean(value)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');

const normalizeName = (value) =>
  clean(value)
    .toLowerCase()
    .normalize('NFKD')
    .replace(/\p{Diacritic}/gu, '');

const playerKey = (player) =>
  `${normalizeName(player.name)}|${num(player.rating)}|${clean(player.position).toUpperCase()}`;

const sourceId = (url) => {
  const segments = clean(url).split('/').filter(Boolean);
  const tail = segments[segments.length - 1] || '';
  const numbers = tail.match(/\d+/g) || [];
  if (numbers.length === 0) return slug(tail);
  if (numbers.length > 1 && numbers[0] === '27') return numbers[1];
  return numbers[0];
};

const isBaseVersion = (version) => /^(gold|silver|bronze)(\s+rare)?$/i.test(clean(version));

const parseTarget = (value) => {
  const match = toEnglishDigits(value).match(/([\d,]+)/);
  return match ? num(match[1]) : 0;
};

const parseCoins = (details) => {
  for (const line of arr(details)) {
    const match = line.match(/coins?\s*cost\s*:?\s*(free|[\d,]+)/i);
    if (!match) continue;
    return /free/i.test(match[1]) ? 0 : num(match[1]);
  }
  return 0;
};

async function fetchJson(url, attempt = 1) {
  try {
    const response = await fetch(url, {
      headers: { 'user-agent': 'FCBaz-data-sync/1.0 (+https://github.com/sahandse/FCbaz)' },
      signal: AbortSignal.timeout(120_000),
    });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return await response.json();
  } catch (error) {
    if (attempt >= 3) throw new Error(`cannot fetch ${url}: ${error.message}`);
    await new Promise((resolve) => setTimeout(resolve, 2_000 * attempt));
    return fetchJson(url, attempt + 1);
  }
}

async function readJsonIfExists(file) {
  try {
    return JSON.parse(await fs.readFile(file, 'utf8'));
  } catch {
    return null;
  }
}

async function writeJson(file, value, pretty = false) {
  await fs.mkdir(path.dirname(file), { recursive: true });
  await fs.writeFile(file, `${JSON.stringify(value, null, pretty ? 2 : 0)}\n`, 'utf8');
  const size = (await fs.stat(file)).size;
  console.log(`wrote ${path.relative(ROOT, file)} (${(size / 1024 / 1024).toFixed(2)} MB)`);
}

function assertFeed(condition, message) {
  if (!condition) throw new Error(`refusing to write incomplete catalog: ${message}`);
}

function buildPriceIndex(prices) {
  const index = new Map();
  for (const quote of prices) {
    if (clean(quote.status) !== 'verified') continue;
    const coins = num(quote.coins);
    if (coins <= 0) continue;
    const cardId = clean(quote.cardId);
    if (!cardId) continue;
    const platform = clean(quote.platform).toLowerCase();
    const entry = index.get(cardId) || {};
    if (platform === 'ps' || platform === 'ps5' || platform === 'playstation') {
      entry.ps = Math.max(entry.ps || 0, coins);
    } else if (platform === 'pc') {
      entry.pc = Math.max(entry.pc || 0, coins);
    } else {
      continue;
    }
    index.set(cardId, entry);
  }
  return index;
}

function mapPlayer(sourcePlayer, priceIndex, art, portraits) {
  const id = clean(sourcePlayer.id);
  const version = titleCase(sourcePlayer.cardType);
  const stats = sourcePlayer.stats || {};
  const stat = (key) => num(stats[key]);
  const isGk = clean(sourcePlayer.pos).toUpperCase() === 'GK';
  // The hub publishes an id allow-list; only a few ids need a filename override.
  const portrait =
    portraits.files[id] || (portraits.ids.has(id) ? `${id}.png` : '');
  const sourcePortrait = clean(sourcePlayer.portraitUrl);
  const artHash = art[id];
  const officialCard = clean(
    sourcePlayer.cardImageUrl ??
      sourcePlayer.card_image_url ??
      sourcePlayer.cardImage ??
      sourcePlayer.card_image,
  );
  const positions = unique([
    clean(sourcePlayer.pos),
    ...arr(sourcePlayer.positions),
  ]);
  const sourceStats =
    sourcePlayer.inGameStats && typeof sourcePlayer.inGameStats === 'object'
      ? sourcePlayer.inGameStats
      : null;

  const player = {
    id,
    name: clean(sourcePlayer.name),
    rating: num(sourcePlayer.rat),
    position: clean(sourcePlayer.pos),
    positions: positions.length ? positions : [clean(sourcePlayer.pos)],
    club_name: clean(sourcePlayer.club),
    league_name: clean(sourcePlayer.leagueFA),
    nation_name: clean(sourcePlayer.nat),
    version,
    rarity: version,
    card_type: clean(sourcePlayer.cardType),
    // FUT.GG exposes goalkeeper stats as DIV/HAN/KIC/REF/SPD/POS; they keep the
    // same six slots used by the app so the card stays fully populated.
    pace: isGk ? stat('DIV') : stat('PAC'),
    shooting: isGk ? stat('HAN') : stat('SHO'),
    passing: isGk ? stat('KIC') : stat('PAS'),
    dribbling: isGk ? stat('REF') : stat('DRI'),
    defending: isGk ? stat('SPD') : stat('DEF'),
    physical: isGk ? stat('POS') : stat('PHY'),
    skill_moves: num(sourcePlayer.skillMoves ?? sourcePlayer.skill_moves),
    weak_foot: num(sourcePlayer.weakFoot ?? sourcePlayer.weak_foot),
    foot: clean(sourcePlayer.foot ?? sourcePlayer.preferredFoot),
    playstyles: arr(sourcePlayer.playStyles ?? sourcePlayer.play_styles),
    playstyles_plus: arr(
      sourcePlayer.playStylesPlus ?? sourcePlayer.play_styles_plus,
    ),
    source_url: EA_PLAYER_SOURCE,
  };

  if (sourceStats) {
    player.in_game_stats = Object.fromEntries(
      Object.entries(sourceStats)
        .map(([key, value]) => [key, num(value)])
        .filter(([, value]) => value > 0),
    );
  } else if (isGk) {
    player.in_game_stats = {
      DIV: stat('DIV'),
      HAN: stat('HAN'),
      KIC: stat('KIC'),
      REF: stat('REF'),
      SPD: stat('SPD'),
      POS: stat('POS'),
    };
  }
  if (portrait) {
    player.image_url = `${PORTRAIT_BASE}${portrait}`;
  } else if (sourcePortrait.startsWith('https://')) {
    // The source snapshot already verified this EA portrait for the exact id.
    player.image_url = sourcePortrait;
  }
  if (officialCard.startsWith('https://')) {
    player.card_image_url = officialCard;
  } else if (/^\d+$/.test(id)) {
    // The hub publishes an official EA card URL per player; derive the same
    // canonical URL for older snapshots that predate the field.
    player.card_image_url = `${EA_CARD_BASE}/${id}_en-GB.webp`;
  } else if (artHash && /^[a-f0-9]{64}$/i.test(artHash)) {
    player.card_image_url = `${CARD_ART_BASE}27-${id}.${artHash}.webp`;
  }

  const quote = priceIndex.get(id);
  if (quote && (quote.ps > 0 || quote.pc > 0)) {
    player.price_ps = quote.ps || 0;
    player.price_pc = quote.pc || 0;
    // Per-quote URLs/timestamps are identical for the whole feed; they are
    // exposed once at catalog level to keep the 20k-player file compact.
    player.price_source = 'fut.gg-public';
  }

  return player;
}

function previousIndexes(previousCatalog) {
  const byId = new Map();
  const byKey = new Map();
  const byName = new Map();
  for (const player of previousCatalog?.players || []) {
    if (!player?.id) continue;
    byId.set(clean(player.id), player);
    byKey.set(playerKey(player), player);
    const name = normalizeName(player.name);
    if (!byName.has(name)) byName.set(name, player);
  }
  const sbcsByUrl = new Map();
  const sbcsByName = new Map();
  for (const sbc of previousCatalog?.sbcs || []) {
    if (sbc?.source_url) sbcsByUrl.set(clean(sbc.source_url), sbc);
    const name = normalizeName(sbc?.titleEn || sbc?.title_en || sbc?.title || sbc?.name);
    if (name && !sbcsByName.has(name)) sbcsByName.set(name, sbc);
  }
  return { byId, byKey, byName, sbcsByUrl, sbcsByName };
}

function mapSbc(item, checksAt, indexes) {
  const url = clean(item.url);
  const id = `futgg-sbc-${sourceId(url)}`;
  const squads = Array.isArray(item.squads) ? item.squads : [];
  const name = clean(item.name);
  const previous =
    indexes.sbcsByUrl.get(url) ||
    indexes.sbcsByName.get(normalizeName(name)) ||
    null;

  const requirements = unique(
    squads.flatMap((squad) => {
      const fa = arr(squad.requirementsFA);
      return fa.length ? fa : arr(squad.requirements);
    }),
  );

  const guideFa = squads
    .map((squad) => {
      const title = clean(squad.nameFA) || clean(squad.name);
      const fa = arr(squad.requirementsFA);
      const reqs = (fa.length ? fa : arr(squad.requirements)).join(' • ');
      return [title, reqs].filter(Boolean).join(' — ');
    })
    .filter(Boolean);

  const siteCost = num(item.price);
  const verifiedCost = (() => {
    if (clean(previous?.cost_source) !== 'fcdata-public') return 0;
    if (!clean(previous?.cost_source_url).startsWith('https://fcdata.io/')) return 0;
    const value = num(previous?.estimated_cost) || num(previous?.cost);
    // Reject parse artifacts (the old FCData scraper sometimes captured "1").
    return value >= 1_000 && value <= 50_000_000 ? value : 0;
  })();
  const estimatedCost = siteCost > 0 ? siteCost : verifiedCost;

  return {
    id,
    title: name,
    title_en: name,
    titleFA: clean(item.nameFA),
    nameFA: clean(item.nameFA),
    category: titleCase(item.category) || 'SBC',
    description: clean(item.descriptionFA) || clean(item.description),
    description_en: clean(item.description),
    reward: clean(item.rewardFA) || clean(item.reward),
    reward_en: clean(item.reward),
    requirements,
    requirementsFA: requirements,
    repeatable: item.repeatable != null && clean(item.repeatable) !== '',
    guide_fa: guideFa,
    challenge_count: num(item.challenges) || squads.length,
    squads: squads.map((squad) => ({
      name: clean(squad.name),
      nameFA: clean(squad.nameFA),
      description: clean(squad.description),
      descriptionFA: clean(squad.descriptionFA),
      requirements: arr(squad.requirements),
      requirementsFA: arr(squad.requirementsFA),
      score: num(squad.score) || null,
      reward: clean(squad.reward),
      rewardFA: clean(squad.rewardFA),
    })),
    estimated_cost: estimatedCost > 0 ? estimatedCost : null,
    ...(siteCost > 0
      ? { cost_source: 'fut.gg-public', cost_source_url: url }
      : verifiedCost > 0
        ? { cost_source: 'fcdata-public', cost_source_url: 'https://fcdata.io/' }
        : {}),
    source_url: url,
    details_source_url: url,
    checked_at: clean(item.detail_checked_at) || checksAt,
    ...(previous?.public_solution ? { public_solution: previous.public_solution } : {}),
  };
}

function mapObjective(item, checksAt) {
  const url = clean(item.url);
  const id = `futgg-objective-${sourceId(url)}`;
  const name = clean(item.name);
  const rawTasks = Array.isArray(item.tasks) ? item.tasks : [];
  const tasks = rawTasks.map((task, index) => ({
    id: `${id}-task-${index + 1}`,
    title: clean(task.name),
    title_en: clean(task.name),
    titleFA: clean(task.nameFA),
    description: clean(task.descriptionFA) || clean(task.description),
    description_en: clean(task.description),
    target: parseTarget(task.name) || parseTarget(task.description),
    reward: clean(task.rewardFA) || clean(task.reward),
    reward_en: clean(task.reward),
  }));
  const taskRewards = unique(tasks.map((task) => task.reward));

  return {
    id,
    title: name,
    title_en: name,
    titleFA: clean(item.nameFA),
    nameFA: clean(item.nameFA),
    category: titleCase(item.category) || 'Objective',
    description: clean(item.descriptionFA) || clean(item.description),
    description_en: clean(item.description),
    reward: clean(item.rewardFA) || clean(item.reward) || taskRewards.join(' + '),
    reward_en: clean(item.reward),
    task_count: tasks.length,
    tasks,
    source_url: url,
    details_source_url: url,
    checked_at: clean(item.detail_checked_at) || checksAt,
  };
}

function mapEvolution(item, checksAt) {
  const url = clean(item.url);
  const id = `futgg-evolution-${sourceId(url)}`;
  const name = clean(item.name);
  const levels = Array.isArray(item.levels) ? item.levels : [];

  const levelUpgrades = levels.flatMap((level) => {
    const fa = arr(level.upgradesFA);
    return fa.length ? fa : arr(level.upgrades);
  });

  return {
    id,
    title: name,
    title_en: name,
    titleFA: clean(item.nameFA),
    nameFA: clean(item.nameFA),
    description: clean(item.descriptionFA) || clean(item.description),
    description_en: clean(item.description),
    cost: parseCoins(item.details),
    requirements: arr(item.requirementsFA).length
      ? arr(item.requirementsFA)
      : arr(item.requirements),
    requirementsFA: arr(item.requirementsFA),
    upgrades: unique(levelUpgrades),
    levels: levels.map((level) => ({
      name: clean(level.name),
      nameFA: clean(level.nameFA),
      tasks: arr(level.tasks),
      tasksFA: arr(level.tasksFA),
      upgrades: arr(level.upgrades),
      upgradesFA: arr(level.upgradesFA),
      training_time: clean(level.training_time),
      training_timeFA: clean(level.training_timeFA),
      ...(Array.isArray(level.options) ? { options: level.options } : {}),
      ...(level.pick_one != null ? { pick_one: level.pick_one } : {}),
    })),
    source_url: url,
    details_source_url: url,
    checked_at: checksAt,
  };
}

const NEWS_FA = {
  'fc-27-season-2-fc-heritage': {
    titleFA: 'فصل دوم آلتیمیت تیم: میراث FC',
    summaryFA: 'فصل دوم با حال‌وهوای نوستالژیک FUT و بازگشت رویدادها و آیتم‌های محبوب گذشته همراه است.',
    tagFA: '🏆 رویداد FUT',
  },
  'fc-27-ultimate-scream': {
    titleFA: 'رویداد Ultimate Scream در آلتیمیت تیم FC 27',
    summaryFA: 'جزئیات رویداد Ultimate Scream و محتوای ویژه آن در آلتیمیت تیم را دنبال کنید.',
    tagFA: '🎃 رویداد FUT',
  },
  'fc-27-the-grounds-developer-archetypes-update': {
    titleFA: 'به‌روزرسانی آرکه‌تایپ‌های توسعه‌دهنده در The Grounds — EA SPORTS FC 27',
    summaryFA:
      'آخرین تغییرات Archetype و Attribute Points را در The Grounds و Clubs بازی EA SPORTS FC 27 مرور کنید.',
    tagFA: '🏟️ The Grounds و Clubs',
  },
  'fc-27-launch-feedback-update': {
    titleFA: 'گزارش بازخوردهای اولیه و تغییرات EA SPORTS FC 27',
    summaryFA: 'مروری بر بازخوردهای بازیکنان و تغییرات اعلام‌شده برای گیم‌پلی، آلتیمیت تیم، کریر مود و بخش Clubs.',
    tagFA: '🎮 گیم‌پلی و توسعه',
  },
  'fc-27-future-stars': {
    titleFA: 'ستارگان آینده در آلتیمیت تیم FC 27',
    summaryFA: 'معرفی استعدادهای جوان، کارت‌های ویژه و محتوای Future Stars در آلتیمیت تیم.',
    tagFA: '🌟 رویداد FUT',
  },
  'fc27-title-update-v1-0-4': {
    titleFA: 'یادداشت‌های به‌روزرسانی نسخه ۱.۰.۴ بازی FC 27',
    summaryFA: 'مرور تغییرات و اصلاحات اعلام‌شده در به‌روزرسانی رسمی شماره ۱.۰.۴.',
    tagFA: '🛠️ به‌روزرسانی بازی',
  },
  'fc-27-the-grounds-developer-launch-update': {
    titleFA: 'گزارش آغاز به کار The Grounds و بخش Clubs',
    summaryFA: 'تیم سازنده درباره بازخوردهای اولیه و برنامه‌های بهبود The Grounds و Clubs توضیح می‌دهد.',
    tagFA: '🏟️ The Grounds و Clubs',
  },
  'title-update-v1-0-3': {
    titleFA: 'یادداشت‌های به‌روزرسانی نسخه ۱.۰.۳ بازی FC 27',
    summaryFA: 'مرور اصلاحات و تغییرات اعلام‌شده در به‌روزرسانی رسمی شماره ۱.۰.۳.',
    tagFA: '🛠️ به‌روزرسانی بازی',
  },
  'fc-27-fut-developer-launch-update': {
    titleFA: 'گزارش تیم سازنده آلتیمیت تیم پس از عرضه FC 27',
    summaryFA: 'تیم FUT بازخوردهای بازیکنان و تغییرات مورد بررسی پس از عرضه بازی را شرح می‌دهد.',
    tagFA: '🏆 آلتیمیت تیم',
  },
  'fc-27-gameplay-developer-launch-update': {
    titleFA: 'گزارش تیم سازنده درباره گیم‌پلی FC 27',
    summaryFA: 'مرور بازخوردهای اولیه درباره گیم‌پلی و زمینه‌های مورد بررسی تیم سازنده.',
    tagFA: '🎮 گیم‌پلی و توسعه',
  },
  'fc-27-career-mode-developer-launch-update': {
    titleFA: 'گزارش تیم سازنده درباره کریر مود FC 27',
    summaryFA: 'تغییرات و بازخوردهای اولیه مربوط به حالت کریر مود بازی را دنبال کنید.',
    tagFA: '👔 کریر مود',
  },
  'fc-27-destined-for-glory': {
    titleFA: 'رویداد Destined for Glory در آلتیمیت تیم FC 27',
    summaryFA: 'بازیکنان منتخب جامعه FC معرفی می‌شوند تا در فصل جاری آلتیمیت تیم بدرخشند.',
    tagFA: '🌟 رویداد FUT',
  },
  'fc-27-the-grounds-developer-archetypes-update': {
    titleFA: 'به‌روزرسانی آرکه‌تایپ‌های توسعه‌دهنده در The Grounds — EA SPORTS FC 27',
    summaryFA:
      'آخرین تغییرات Archetype و Attribute Points را در The Grounds و Clubs بازی EA SPORTS FC 27 مرور کنید.',
    tagFA: '🏟️ The Grounds و Clubs',
  },
};

function buildNews(siteNews, previousNews, checkedAt) {
  const previousByUrl = new Map(
    (previousNews?.items || []).map((item) => [clean(item.url), item]),
  );
  const usedUrls = new Set();
  const items = [];

  for (const raw of siteNews) {
    const url = clean(raw.url);
    const previous = previousByUrl.get(url);
    const id = url.split('/').pop() || slug(raw.title);
    const translated = NEWS_FA[id] || {};
    const item = {
      title: clean(raw.title),
      url,
      source: clean(raw.source) || 'Electronic Arts',
      published: clean(raw.published),
      summary: clean(raw.summary),
      ...(previous?.titleFA || translated.titleFA
        ? { titleFA: clean(previous?.titleFA) || translated.titleFA }
        : {}),
      ...(previous?.summaryFA || translated.summaryFA
        ? { summaryFA: clean(previous?.summaryFA) || translated.summaryFA }
        : {}),
      ...(previous?.tagFA || translated.tagFA
        ? { tagFA: clean(previous?.tagFA) || translated.tagFA }
        : {}),
      ...(previous?.image ? { image: previous.image } : {}),
      ...(previous?.fullContentFA ? { fullContentFA: previous.fullContentFA } : {}),
    };
    usedUrls.add(url);
    items.push(item);
  }

  // Keep older editorial FC27 articles that the public feed no longer lists.
  for (const item of previousNews?.items || []) {
    const url = clean(item.url);
    if (!url || usedUrls.has(url)) continue;
    usedUrls.add(url);
    items.push(item);
  }

  return {
    source: 'FC27 Hub + EA SPORTS FC',
    source_url: FEEDS.news.replace(SITE, PUBLIC_SITE),
    checked_at: checkedAt,
    items,
  };
}

async function main() {
  console.log('fetching FC27 Hub snapshots…');
  const [playersFeed, pricesFeed, challengesFeed, evolutionsFeed, newsFeed, artFeed, portraitsFeed] =
    await Promise.all([
      fetchJson(FEEDS.players),
      fetchJson(FEEDS.prices),
      fetchJson(FEEDS.challenges),
      fetchJson(FEEDS.evolutions),
      fetchJson(FEEDS.news),
      fetchJson(FEEDS.art),
      fetchJson(FEEDS.portraits),
    ]);

  const sourcePlayers = Array.isArray(playersFeed.players) ? playersFeed.players : [];
  const priceQuotes = Array.isArray(pricesFeed.prices) ? pricesFeed.prices : [];
  const sbcs = Array.isArray(challengesFeed.sections?.sbc) ? challengesFeed.sections.sbc : [];
  const objectives = Array.isArray(challengesFeed.sections?.objectives)
    ? challengesFeed.sections.objectives
    : [];
  const evolutions = Array.isArray(evolutionsFeed.evolutions) ? evolutionsFeed.evolutions : [];
  const news = Array.isArray(newsFeed.items) ? newsFeed.items : [];
  const art = artFeed.art && typeof artFeed.art === 'object' ? artFeed.art : {};
  const portraitFiles =
    portraitsFeed.files && typeof portraitsFeed.files === 'object' ? portraitsFeed.files : {};
  const portraitIds = new Set((Array.isArray(portraitsFeed.ids) ? portraitsFeed.ids : []).map(clean));
  const portraits = { ids: portraitIds, files: portraitFiles };

  const isFc27Site = /EA SPORTS FC 27/i.test(clean(playersFeed.source));
  assertFeed(sourcePlayers.length >= 18_000, `players=${sourcePlayers.length}`);
  assertFeed(priceQuotes.length >= 10_000, `price quotes=${priceQuotes.length}`);
  assertFeed(sbcs.length >= 8, `sbcs=${sbcs.length}`);
  assertFeed(objectives.length >= 10, `objectives=${objectives.length}`);
  assertFeed(evolutions.length >= 5, `evolutions=${evolutions.length}`);
  assertFeed(news.length >= 5, `news=${news.length}`);
  assertFeed(Object.keys(art).length >= 1_000, `card art=${Object.keys(art).length}`);
  assertFeed(portraitIds.size >= 1_000, `portraits=${portraitIds.size}`);
  assertFeed(isFc27Site, 'players feed is not the FC27 EA ratings snapshot');

  const priceIndex = buildPriceIndex(priceQuotes);
  assertFeed(priceIndex.size >= 5_000, `verified priced cards=${priceIndex.size}`);

  const playerIds = new Set();
  const sitePlayers = [];
  for (const sourcePlayer of sourcePlayers) {
    const player = mapPlayer(sourcePlayer, priceIndex, art, portraits);
    if (!player.id || !player.name || !player.rating || !player.position) continue;
    if (playerIds.has(player.id)) continue;
    playerIds.add(player.id);
    sitePlayers.push(player);
  }
  assertFeed(sitePlayers.length >= 18_000, `mapped players=${sitePlayers.length}`);

  const previousCatalog = await readJsonIfExists(path.join(ROOT, 'data/live/catalog.json'));
  const indexes = previousIndexes(previousCatalog);

  // The hub only publishes base cards. Preserve verified special cards that a
  // previous FUT.GG/FCDATA sync discovered, unless the site now covers the id.
  const preservedSpecials = [];
  const preservedIds = new Set();
  for (const player of previousCatalog?.players || []) {
    if (!player?.id) continue;
    const version = clean(player.version || player.rarity || player.card_type);
    if (isBaseVersion(version)) continue;
    const id = clean(player.id);
    if (playerIds.has(id) || preservedIds.has(id)) continue;
    if (!clean(player.source_url).startsWith('https://')) continue;
    preservedIds.add(id);
    preservedSpecials.push(player);
  }

  // Hall of FUT items sit outside EA's public ratings roster, so their verified
  // FUT.GG item artwork is resolved once by tool/sync_hof_card_art.mjs and
  // re-attached here so every rebuild keeps rendering the real card.
  const hofArt = await readJsonIfExists(path.join(ROOT, 'assets/data/hof-card-art.json'));
  const hofArtById = hofArt?.catalog_ids || {};
  for (const player of preservedSpecials) {
    const artwork = clean(hofArtById[player.id]);
    if (artwork) player.card_art_url = artwork;
  }

  const hofNames = Object.fromEntries(
    Object.entries(hofArt?.items || {}).map(([eaId, item]) => ['ea:' + eaId, clean(item?.name)]),
  );
  const allPlayers = dedupeHallOfFut(
    [...sitePlayers, ...preservedSpecials],
    hofNames,
    artKeyIndex(hofArt?.items),
  );
  const catalogPlayers = new Set(allPlayers.map((player) => player.id));

  const mappedSbcs = sbcs.map((item) => mapSbc(item, clean(challengesFeed.checked_at), indexes));
  const mappedObjectives = objectives.map((item) => mapObjective(item, clean(challengesFeed.checked_at)));
  const mappedEvolutions = evolutions
    .filter((item) => {
      const label = `${clean(item.name)} ${clean(item.url)}`;
      return !/\bfc[\s-]?26\b/i.test(label);
    })
    .map((item) => mapEvolution(item, clean(evolutionsFeed.checked_at)));

  assertFeed(mappedEvolutions.length >= 5, `FC27 evolutions=${mappedEvolutions.length}`);

  for (const [key, items] of [
    ['sbcs', mappedSbcs],
    ['objectives', mappedObjectives],
    ['evolutions', mappedEvolutions],
  ]) {
    const ids = new Set();
    for (const item of items) {
      assertFeed(item.id && !ids.has(item.id), `${key} has a missing/duplicate id`);
      ids.add(item.id);
      assertFeed(
        clean(item.source_url).startsWith('https://www.fut.gg/'),
        `${key} item has no verified FUT.GG source: ${item.id}`,
      );
    }
  }

  const popularPlayers = (previousCatalog?.popular_players || [])
    .map((entry) => {
      const id = clean(entry?.id);
      if (catalogPlayers.has(id)) return entry;
      const resolved = indexes.byKey.get(playerKey(entry));
      if (!resolved || !catalogPlayers.has(clean(resolved.id))) return null;
      return {
        ...entry,
        id: clean(resolved.id),
        image_url: resolved.image_url || entry.image_url || '',
        card_image_url: resolved.card_image_url || entry.card_image_url || '',
      };
    })
    .filter(Boolean);

  const sources = unique([
    `${PUBLIC_SITE}/`,
    ...[
      'fc27-players.json',
      'fc27-prices.json',
      'fc27-challenges.json',
      'fc27-evolutions.json',
      'fc27-news.json',
      'fc27-card-art.json',
      'available-portraits.json',
    ].map((name) => `${PUBLIC_SITE}/data/${name}`),
    clean(playersFeed.source_url),
    'https://www.fut.gg/',
    'https://www.fut.gg/players/',
    'https://www.fut.gg/sbc/',
    'https://www.fut.gg/objectives/',
    'https://www.fut.gg/evolutions/',
    EA_PLAYER_SOURCE,
    `${EA_CARD_BASE}/`,
    'https://game-assets.fut.gg/',
    'https://www.fut.gg/rarities/base-hall-of-fut/',
    preservedSpecials.some((player) => clean(player.price_source) === 'fcdata-public')
      ? 'https://fcdata.io/players/'
      : '',
  ]);

  const catalog = {
    game_year: 27,
    generated_at: now,
    sources,
    players: allPlayers,
    evolutions: mappedEvolutions,
    sbcs: mappedSbcs,
    objectives: mappedObjectives,
    popular_players: popularPlayers,
    player_dataset: {
      source: clean(playersFeed.source),
      source_url: clean(playersFeed.source_url),
      snapshot_date: clean(playersFeed.snapshot_date),
    },
    price_source: 'fut.gg-public',
    price_source_url: 'https://www.fut.gg/players/',
    price_updated_at: clean(pricesFeed.updated_at),
    discovery_generated_at: now,
    enriched_at: now,
    market_enriched_at: now,
    priced_players: allPlayers.filter(
      (player) => num(player.price_ps) > 0 || num(player.price_pc) > 0,
    ).length,
    enriched_from_fc27_at: now,
  };

  await writeJson(path.join(ROOT, 'data/live/catalog.json'), catalog);

  if (!liveOnly) {
    await writeJson(path.join(ROOT, 'assets/data/fc27-challenges.json'), challengesFeed, true);
    await writeJson(path.join(ROOT, 'assets/data/fc27-evolutions.json'), evolutionsFeed, true);
    await writeJson(path.join(ROOT, 'assets/data/available-portraits.json'), portraitsFeed, true);
    const previousNews = await readJsonIfExists(path.join(ROOT, 'assets/data/fc27-news.json'));
    await writeJson(
      path.join(ROOT, 'assets/data/fc27-news.json'),
      buildNews(news, previousNews, clean(newsFeed.checked_at) || now),
      true,
    );
  }

  console.log({
    players: allPlayers.length,
    site_players: sitePlayers.length,
    preserved_specials: preservedSpecials.length,
    priced_players: catalog.priced_players,
    sbcs: mappedSbcs.length,
    objectives: mappedObjectives.length,
    evolutions: mappedEvolutions.length,
    popular_players: popularPlayers.length,
    card_art: Object.keys(art).length,
    portraits: portraitIds.size,
    news: news.length,
    live_only: liveOnly,
  });
}

main().catch((error) => {
  console.error(error.message || error);
  process.exitCode = 1;
});
