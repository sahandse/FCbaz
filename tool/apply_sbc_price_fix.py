from pathlib import Path
import re

screen = Path('lib/features/sbc/presentation/sbc_screen.dart')
s = screen.read_text()
old = """          const SizedBox(height: 14),
          if (sbc.itemScore != null)
            const _StateCard(
              icon: Icons.stars_rounded,
              title: 'SBC مبتنی بر Item Score',
              subtitle: 'برای این چالش Rating Combination استفاده نمی‌شود؛ Item Score فقط از داده واقعی خود چالش معتبر است.',
            )
          else
            FilledButton.icon(
              onPressed: solving ? null : _solve,
              icon: solving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_fix_high_rounded),
              label: const Text('بررسی راه‌حل واقعی Backend'),
            ),
"""
new = """          const SizedBox(height: 14),
          if (sbc.itemScore != null) ...[
            const _StateCard(
              icon: Icons.stars_rounded,
              title: 'SBC مبتنی بر Item Score',
              subtitle: 'برای این نوع چالش، راهنما بر اساس Item Score و Requirementهای واقعی منبع عمومی ساخته می‌شود.',
            ),
            const SizedBox(height: 10),
          ],
          FilledButton.icon(
            onPressed: solving ? null : _solve,
            icon: solving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_fix_high_rounded),
            label: const Text('نمایش راه‌حل و راهنمای عمومی'),
          ),
"""
if old not in s:
    raise SystemExit('SBC action block not found')
s = s.replace(old, new, 1)
s = s.replace("const Text('SOLUTION', textDirection: TextDirection.ltr, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),",
              "Text(solution.players.isEmpty ? 'PUBLIC GUIDE' : 'SOLUTION', textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),")
s = s.replace("Expanded(child: _MiniStat(label: 'TOTAL COST', value: '${solution.totalCost} C')),",
              "Expanded(child: _MiniStat(label: 'TOTAL COST', value: solution.totalCost > 0 ? '${solution.totalCost} C' : '—')),")
s = s.replace("Expanded(child: _MiniStat(label: 'REMAINING', value: '${solution.remainingCost} C')),",
              "Expanded(child: _MiniStat(label: 'REMAINING', value: solution.remainingCost > 0 ? '${solution.remainingCost} C' : '—')),")
screen.write_text(s)

pubspec = Path('pubspec.yaml')
p = pubspec.read_text()
p = re.sub(r'^version: .*$', 'version: 1.9.0+33', p, flags=re.M)
pubspec.write_text(p)
