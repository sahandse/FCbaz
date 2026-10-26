// Hall of FUT is published by FUT.GG as one item per inductee, but the FCBaz
// catalogue has received each card twice (the Gallery "Base" row and a campaign
// row) with conflicting placeholder coin values. These helpers collapse the
// duplicates by the artwork version id and clear the unverified price.

export const cleanHof = (value) =>
  value == null ? '' : String(value).trim();

export const num = (value) => {
  const parsed = Number(cleanHof(value).replace(/[,٬\s]/g, ''));
  return Number.isFinite(parsed) ? Math.round(parsed) : 0;
};

export const hallOfFutLabel = (player) =>
  /hall of fut/i.test(cleanHof(player.card_type || player.version || player.rarity));

const normaliseName = (value) =>
  cleanHof(value)
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]/g, '');

// Resolves a discovered Hall of FUT row to its EA item id even when the row
// carries no artwork yet: the FUT.GG display name either matches or contains
// the catalogue name (for example "Santos" inside "Giovani dos Santos").
const lookupArtKey = (name, artKeysByName) => {
  const key = normaliseName(name);
  if (key.length < 4 || !artKeysByName) return '';
  const exact = artKeysByName.get(key);
  if (exact) return exact;
  for (const [artName, eaKey] of artKeysByName) {
    if (Math.min(artName.length, key.length) < 4) continue;
    if (artName.includes(key) || key.includes(artName)) return eaKey;
  }
  return '';
};

export function artKeyIndex(items = {}) {
  const index = new Map();
  for (const [eaId, item] of Object.entries(items)) {
    const key = normaliseName(item?.name);
    if (key) index.set(key, String(eaId));
  }
  return index;
}

export const hallOfFutKey = (player, artKeysByName) => {
  const artwork = cleanHof(player.card_art_url).match(/futgg-player-item-card\/27-(\d+)\./);
  if (artwork) return 'ea:' + artwork[1];
  const resolved = lookupArtKey(player.name, artKeysByName);
  if (resolved) return 'ea:' + resolved;
  return [
    'name',
    cleanHof(player.name)
      .toLowerCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/[^a-z0-9]/g, ''),
    num(player.rating),
    cleanHof(player.position).toUpperCase(),
  ].join(':');
};

export function mergeHallOfFutEntry(entries, displayNames = {}, artKeysByName) {
  const preferred =
    entries.find((entry) => /base-hall-of-fut/i.test(cleanHof(entry.id))) || entries[0];
  const merged = {...preferred};
  for (const entry of entries) {
    // The campaign copy can carry the full display name ("Giovani dos Santos")
    // while the Gallery row is reduced to a surname ("Santos").
    if (cleanHof(entry.name).length > cleanHof(merged.name).length) merged.name = entry.name;
    if (!cleanHof(merged.card_art_url) && cleanHof(entry.card_art_url)) merged.card_art_url = entry.card_art_url;
    if (!cleanHof(merged.nation_name) && cleanHof(entry.nation_name)) merged.nation_name = entry.nation_name;
    if (!cleanHof(merged.club_name) && cleanHof(entry.club_name)) merged.club_name = entry.club_name;
    if (!cleanHof(merged.league_name) && cleanHof(entry.league_name)) merged.league_name = entry.league_name;
  }
  // FUT.GG's item page title is authoritative for the display name.
  const displayName = cleanHof(displayNames[hallOfFutKey(merged, artKeysByName)]);
  if (displayName) merged.name = displayName;
  // Gallery items are earned through the token store and have no verified
  // market quote, so a placeholder coin value must never be published.
  merged.price_ps = 0;
  merged.price_pc = 0;
  merged.market_price = 0;
  merged.price_status = 'unavailable';
  merged.price_note = 'Hall of FUT items have no verified market quote.';
  delete merged.price_source;
  delete merged.price_source_url;
  delete merged.price_updated_at;
  return merged;
}

export function dedupeHallOfFut(players, displayNames = {}, artKeysByName) {
  const groups = new Map();
  for (const player of players) {
    if (!hallOfFutLabel(player)) continue;
    const key = hallOfFutKey(player, artKeysByName);
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key).push(player);
  }
  if (!groups.size) return players;

  const emitted = new Set();
  const output = [];
  for (const player of players) {
    if (!hallOfFutLabel(player)) {
      output.push(player);
      continue;
    }
    const key = hallOfFutKey(player, artKeysByName);
    if (emitted.has(key)) continue;
    emitted.add(key);
    output.push(mergeHallOfFutEntry(groups.get(key), displayNames, artKeysByName));
  }
  return output;
}
