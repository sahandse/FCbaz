import { readFile, writeFile } from 'node:fs/promises';

const catalogPath = 'data/live/catalog.json';
const catalog = JSON.parse(await readFile(catalogPath, 'utf8'));

function clean(value) {
  return String(value ?? '')
    .replace(/!\[[^\]]*\]\([^)]*\)/g, ' ')
    .replace(/\[([^\]]+)\]\([^)]*\)/g, '$1')
    .replace(/<[^>]+>/g, ' ')
    .replace(/^#+\s*/g, '')
    .replace(/^[-*]\s*/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

function lines(text) {
  return text
    .split(/\r?\n/)
    .map(clean)
    .filter((line) => line.length > 1);
}

async function fetchText(url) {
  const targets = [`https://r.jina.ai/${url}`, url];
  let lastError;
  for (const target of targets) {
    try {
      const response = await fetch(target, {
        headers: {
          accept: 'text/plain,text/markdown,text/html;q=0.9,*/*;q=0.8',
          'user-agent': 'FCBaz-Enrichment/1.4 (+https://github.com/sahandse/FCbaz)',
        },
        signal: AbortSignal.timeout(18000),
      });
      if (!response.ok) throw new Error(`${response.status} ${response.statusText}`);
      const text = await response.text();
      if (text.length < 250) throw new Error('response too small');
      return text;
    } catch (error) {
      lastError = error;
    }
  }
  throw lastError ?? new Error(`Unable to fetch ${url}`);
}

function coinValue(text) {
  const first = text.slice(0, 1800);
  const match = first.match(/\b(\d{1,3}(?:,\d{3})+)\b/);
  if (!match) return null;
  const value = Number(match[1].replaceAll(',', ''));
  return Number.isFinite(value) && value >= 250 ? value : null;
}

function section(rawLines, startNames, endNames, max = 30) {
  const start = rawLines.findIndex((line) =>
    startNames.some((name) => line.toLowerCase() === name.toLowerCase() || line.toLowerCase().startsWith(`${name.toLowerCase()} `)),
  );
  if (start < 0) return [];
  const out = [];
  for (let i = start + 1; i < rawLines.length && out.length < max; i++) {
    const line = rawLines[i];
    if (endNames.some((name) => line.toLowerCase() === name.toLowerCase())) break;
    if (line.length < 3) continue;
    if (/^(home|players|evolutions|sbc|objectives|news)$/i.test(line)) continue;
    if (!out.includes(line)) out.push(line);
  }
  return out;
}

function requirementLines(rawLines) {
  const explicit = rawLines.filter((line) =>
    /^(min\.|max\.|minimum|maximum|exactly|at least|at most|required|excluded|position|overall|pace|shooting|passing|dribbling|defending|physical|team rating|players)/i.test(line),
  );
  return [...new Set(explicit)].slice(0, 30);
}

function rewardLines(rawLines) {
  const rewards = section(rawLines, ['Rewards', 'Reward Details'], ['Requirements', 'Challenges'], 15)
    .filter((line) => /pack|coin|token|player|evolution|reward|pick|points|sp\b/i.test(line));
  return [...new Set(rewards)].slice(0, 12);
}

function enrichSbc(item, text) {
  const rawLines = lines(text);
  const requirements = requirementLines(rawLines);
  const rewards = rewardLines(rawLines);
  const cost = coinValue(text);
  const challengeMatch = text.match(/Challenges\s*(\d+)/i);
  const repeatableMatch = text.match(/Repeatable\s*(∞|\d+)/i);
  const scoreMatch = text.match(/Submit\s+([\d,]+)\s+Score/i);
  const description = item.description || rawLines.find((line) =>
    line.length > 35 && !line.toLowerCase().includes(String(item.title_en ?? item.title ?? '').toLowerCase()),
  ) || '';

  return {
    ...item,
    description,
    ...(requirements.length ? { requirements } : {}),
    ...(rewards.length ? { reward: rewards.join(' • ') } : {}),
    ...(cost != null ? { estimated_cost: cost, cost } : {}),
    ...(challengeMatch ? { challenge_count: Number(challengeMatch[1]) } : {}),
    ...(repeatableMatch ? { repeatable: true } : {}),
    ...(scoreMatch ? { item_score: Number(scoreMatch[1].replaceAll(',', '')) } : {}),
    details_source_url: item.source_url,
  };
}

function enrichEvolution(item, text) {
  const rawLines = lines(text);
  const requirements = section(rawLines, ['Requirements'], ['Upgrades', 'Challenges', 'Rewards'], 30);
  const upgrades = section(rawLines, ['Upgrades'], ['Challenges', 'Rewards', 'Requirements'], 40);
  const cost = coinValue(text);
  const description = item.description || rawLines.find((line) =>
    line.length > 35 && !line.toLowerCase().includes(String(item.title ?? '').toLowerCase()),
  ) || '';

  return {
    ...item,
    description,
    ...(requirements.length ? { requirements } : {}),
    ...(upgrades.length ? { upgrades } : {}),
    ...(cost != null ? { cost } : {}),
    details_source_url: item.source_url,
  };
}

function enrichObjective(item, text) {
  const rawLines = lines(text);
  const rewards = rewardLines(rawLines);
  const tasks = section(rawLines, ['Objectives', 'Tasks'], ['Rewards'], 30);
  const description = item.description || rawLines.find((line) =>
    line.length > 35 && !line.toLowerCase().includes(String(item.title ?? '').toLowerCase()),
  ) || '';
  return {
    ...item,
    description,
    ...(rewards.length ? { reward: rewards.join(' • ') } : {}),
    ...(tasks.length ? { task_count: tasks.length } : {}),
    details_source_url: item.source_url,
  };
}

async function enrichSection(key, mapper) {
  const items = Array.isArray(catalog[key]) ? catalog[key] : [];
  if (!items.length) return;
  let changed = 0;
  const result = [...items];

  for (let start = 0; start < items.length; start += 4) {
    const batch = items.slice(start, start + 4);
    const enriched = await Promise.all(batch.map(async (item) => {
      const url = String(item.source_url ?? '');
      if (!url.startsWith('https://www.fut.gg/') || /\/(sbc|evolutions|objectives)\/?$/.test(url)) {
        return item;
      }
      try {
        const text = await fetchText(url);
        changed++;
        return mapper(item, text);
      } catch (error) {
        console.warn(`[${key}] detail failed ${url}: ${error}`);
        return item;
      }
    }));
    for (let i = 0; i < enriched.length; i++) result[start + i] = enriched[i];
  }

  catalog[key] = result;
  console.log(`[${key}] enriched ${changed}/${items.length}`);
}

await enrichSection('sbcs', enrichSbc);
await enrichSection('evolutions', enrichEvolution);
await enrichSection('objectives', enrichObjective);

catalog.enriched_at = new Date().toISOString();
await writeFile(catalogPath, `${JSON.stringify(catalog, null, 2)}\n`);
console.log(`Enriched ${catalogPath}`);
