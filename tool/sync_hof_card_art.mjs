#!/usr/bin/env node
// Hall of FUT items are not part of EA's public ratings roster, so the bundled
// catalog carried 42 HOF entries without artwork. FUT.GG publishes the verified
// item card for every Hall of FUT player under the same EA id, so this tool
// resolves that artwork once and stores the content-addressed path next to the
// catalog. The result is committed; rerun it when EA inducts new players.

import {writeFileSync, readFileSync} from 'node:fs';
import path from 'node:path';

const ROOT = path.resolve(import.meta.dirname, '..');
const DEST = path.join(ROOT, 'assets/data/hof-card-art.json');
const CATALOG = path.join(ROOT, 'assets/data/catalog.json');
const RARITY_PAGE = 'https://www.fut.gg/rarities/base-hall-of-fut/';
const ART_BASE = 'https://game-assets.fut.gg/2027/futgg-player-item-card/';

const reader = async (url) => {
  const response = await fetch(`https://r.jina.ai/${url}`, {
    headers: {'user-agent': 'FCBaz-HofArt/1.0 (+https://github.com/sahandse/FCbaz)'},
    signal: AbortSignal.timeout(60000),
  });
  if (!response.ok) throw new Error(`${url} -> ${response.status}`);
  return response.text();
};

const normalise = (value) =>
  String(value ?? '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]/g, '');

const slug = (value) =>
  String(value ?? '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');

// FUT.GG slugs that do not contain the display name used on the cards.
const ALIASES = {
  hulk: ['givanildovieiradesouza'],
  fredyguarin: ['freddyguarin'],
  jakubbaszczykowski: ['jakubblaszczykowski'],
};

const catalog = JSON.parse(readFileSync(CATALOG, 'utf8'));
const hof = catalog.players.filter((player) => /hall of fut/i.test(player.card_type || ''));
if (!hof.length) {
  console.error('No Hall of FUT entries in the bundled catalog; nothing to resolve.');
  process.exit(1);
}

const rarityPage = await reader(RARITY_PAGE);
const links = new Map();
for (const [, id, name, version] of rarityPage.matchAll(
  /players\/(\d+)-([a-z0-9-]+)\/27-(\d+)/g,
)) {
  links.set(id, {id, name, version});
}
console.log('FUT.GG lists', links.size, 'Base Hall of FUT items.');

const art = {};
for (const link of links.values()) {
  let html = '';
  for (let attempt = 1; attempt <= 2; attempt++) {
    try {
      html = await reader(`https://www.fut.gg/players/${link.id}-${link.name}/`);
      break;
    } catch (error) {
      if (attempt === 2) console.warn('skip', link.name, String(error.message).slice(0, 80));
    }
  }
  if (!html) continue;
  const pattern = new RegExp(`27-${link.version}\\.([0-9a-f]{64})\\.webp`);
  const hash = pattern.exec(html)?.[1];
  if (!hash) {
    console.warn('no artwork for', link.name, link.version);
    continue;
  }
  art[link.id] = {
    name: link.name.replace(/-/g, ' '),
    versionId: link.version,
    hash: hash,
    card_art_url: `${ART_BASE}27-${link.version}.${hash}.webp`,
  };
  console.log('resolved', link.name, '->', link.version);
  await new Promise((resolve) => setTimeout(resolve, 400));
}

// Map every HOF catalog entry (base label and campaign label) onto the artwork
// resolved for its EA id, so both copies of the card render the real item.
const byEaId = new Map(Object.entries(art));
const matched = {};
for (const player of hof) {
  const key = normalise(player.name);
  const candidates = [key, ...(ALIASES[key] ?? []).map(normalise)];
  const hit = [...byEaId.values()].find((entry) =>
    candidates.some((candidate) => {
      const slugged = normalise(entry.name);
      return slugged === candidate || slugged.includes(candidate) || candidate.includes(slugged);
    }),
  );
  if (hit) matched[player.id] = hit.card_art_url;
}

if (Object.keys(matched).length < hof.length * 0.9) {
  console.error(
    `Resolved artwork for ${Object.keys(matched).length} of ${hof.length} HOF cards; keeping the previous mapping.`,
  );
  process.exit(1);
}

const output = {
  source: 'game-assets.fut.gg',
  source_url: RARITY_PAGE,
  checked_at: new Date().toISOString(),
  note: 'Official FUT.GG item card artwork for the Hall of FUT roster, resolved per EA player id.',
  items: Object.fromEntries([...byEaId.entries()].sort((a, b) => Number(a[0]) - Number(b[0]))),
  catalog_ids: matched,
};
writeFileSync(DEST, JSON.stringify(output, null, 2) + '\n');
console.log('Wrote', Object.keys(matched).length, 'Hall of FUT card artworks to', path.relative(ROOT, DEST));
console.log('unmatched:', hof.filter((p) => !matched[p.id]).map((p) => p.name + ' (' + slug(p.name) + ')'));
