import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../src/theme/fcbaz_theme.dart';
import '../../../src/utils/persian_formatters.dart';

class PriceAlertChoice {
  const PriceAlertChoice.set(int this.targetPrice) : remove = false;
  const PriceAlertChoice.remove() : targetPrice = null, remove = true;

  final int? targetPrice;
  final bool remove;
}

Future<PriceAlertChoice?> showPriceAlertSheet(
  BuildContext context, {
  required String playerName,
  int? currentPrice,
  int? initialTarget,
}) {
  return showModalBottomSheet<PriceAlertChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => PriceAlertSheet(
      playerName: playerName,
      currentPrice: currentPrice,
      initialTarget: initialTarget,
    ),
  );
}

class PriceAlertSheet extends StatefulWidget {
  const PriceAlertSheet({
    required this.playerName,
    this.currentPrice,
    this.initialTarget,
    super.key,
  });

  final String playerName;
  final int? currentPrice;
  final int? initialTarget;

  @override
  State<PriceAlertSheet> createState() => _PriceAlertSheetState();
}

class _PriceAlertSheetState extends State<PriceAlertSheet> {
  late final TextEditingController controller = TextEditingController(
    text: (widget.initialTarget ?? 0) > 0
        ? formatCoinsFa(widget.initialTarget!)
        : '',
  );
  bool showError = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  int? get target => parsePersianInt(controller.text);
  int get currentPrice => widget.currentPrice ?? 0;

  void _quickSet(int value) {
    if (value <= 0) return;
    controller.text = formatCoinsFa(value);
    setState(() => showError = false);
  }

  void _save() {
    final value = target;
    if (value == null || value <= 0) {
      setState(() => showError = true);
      return;
    }
    Navigator.pop(context, PriceAlertChoice.set(value));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final value = target;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 2, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: palette.primary.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(FcbazRadius.md),
                    border: Border.all(
                      color: palette.primary.withValues(alpha: .3),
                    ),
                  ),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    color: palette.primary,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'هشدار قیمت محلی',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          widget.playerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: palette.secondary.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(FcbazRadius.md),
                border: Border.all(
                  color: palette.secondary.withValues(alpha: .24),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.smartphone_rounded,
                    size: 16,
                    color: palette.secondary,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'این هشدار فقط روی همین دستگاه و با قیمت واقعی همان لحظه بررسی می‌شود. '
                      'بررسی خودکار پس‌زمینه حدود هر ۳۰ دقیقه یک‌بار و با پلتفرم پیش‌فرض تنظیمات اجرا می‌شود؛ '
                      'اگر اپ بسته باشد ممکن است دیرتر انجام شود. هیچ قیمتی پیش‌بینی یا ساخته نمی‌شود.',
                      style: TextStyle(
                        color: palette.textMuted,
                        fontSize: 10.5,
                        height: 1.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: widget.initialTarget == null,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[0-9۰-۹٠-٩,٬\\s]')),
              ],
              onChanged: (_) => setState(() => showError = false),
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: 'قیمت هدف (سکه)',
                hintText: 'مثلاً ۹۵٬۰۰۰',
                prefixIcon: const Icon(Icons.toll_rounded),
                errorText: showError
                    ? 'یک مبلغ بزرگ‌تر از صفر با ارقام فارسی یا انگلیسی وارد کن.'
                    : null,
              ),
            ),
            if (currentPrice > 0) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ActionChip(
                    label: const Text('قیمت فعلی'),
                    onPressed: () => _quickSet(currentPrice),
                  ),
                  ActionChip(
                    label: const Text('۵٪ کمتر'),
                    onPressed: () => _quickSet((currentPrice * .95).round()),
                  ),
                  ActionChip(
                    label: const Text('۱۰٪ کمتر'),
                    onPressed: () => _quickSet((currentPrice * .9).round()),
                  ),
                ],
              ),
              if (value != null && value > 0) ...[
                const SizedBox(height: 10),
                _TargetHint(current: currentPrice, target: value),
              ],
            ],
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.surfaceRaised.withValues(alpha: .6),
                borderRadius: BorderRadius.circular(FcbazRadius.md),
                border: Border.all(color: palette.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 15,
                        color: palette.primary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'پیش‌نمایش اعلان',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'قیمت هدف رسید',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                  Text(
                    value == null || value <= 0
                        ? '${widget.playerName} به [قیمت هدف] سکه رسیده است.'
                        : '${widget.playerName} به ${formatCoinsFa(value)} سکه رسیده است.',
                    style: TextStyle(
                      color: palette.textMuted,
                      fontSize: 11.5,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (widget.initialTarget != null)
                  TextButton.icon(
                    onPressed: () =>
                        Navigator.pop(context, const PriceAlertChoice.remove()),
                    icon: const Icon(Icons.notifications_off_rounded, size: 17),
                    label: const Text('حذف هشدار'),
                    style: TextButton.styleFrom(
                      foregroundColor: palette.danger,
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('انصراف'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('ذخیره هدف'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetHint extends StatelessWidget {
  const _TargetHint({required this.current, required this.target});

  final int current;
  final int target;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final reached = current <= target;
    final percent = ((target - current).abs() / current) * 100;
    final digits = percent
        .toStringAsFixed(percent >= 10 ? 0 : 1)
        .replaceFirst(RegExp(r'\.0+$'), '');
    final message = reached
        ? 'قیمت فعلی از قبل به این هدف رسیده است؛ هشدار در اولین بررسی ثبت می‌شود.'
        : 'قیمت باید حدود ${faDigits(digits)}٪ کاهش یابد تا هشدار فعال شود.';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          reached ? Icons.check_circle_rounded : Icons.info_outline_rounded,
          size: 15,
          color: reached ? palette.success : palette.textMuted,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: reached ? palette.success : palette.textMuted,
              fontSize: 10.5,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}
