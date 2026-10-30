import 'package:flutter/material.dart';

import '../theme/fcbaz_theme.dart';
import '../utils/persian_formatters.dart';
import 'price_delta.dart';

/// Shows a live market price together with the real 24h delta and the real
/// snapshot time. When a refresh changes the price, the surface flashes in the
/// movement direction; reduced-motion settings disable that flash.
class PriceTicker extends StatefulWidget {
  const PriceTicker({
    required this.price,
    this.changePercent,
    this.updatedAt,
    this.now,
    this.compact = false,
    super.key,
  });

  final int price;
  final double? changePercent;
  final DateTime? updatedAt;
  final DateTime? now;
  final bool compact;

  @override
  State<PriceTicker> createState() => _PriceTickerState();
}

class _PriceTickerState extends State<PriceTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flash;
  bool _rising = true;

  @override
  void initState() {
    super.initState();
    _flash = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant PriceTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.price == widget.price) return;
    _rising = widget.price > oldWidget.price;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!reduceMotion) _flash.forward(from: 0);
  }

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  String? get _freshness {
    final updatedAt = widget.updatedAt;
    if (updatedAt == null) return null;
    final now = widget.now ?? DateTime.now();
    final age = now.difference(updatedAt.toLocal());
    if (age.isNegative || age.inMinutes < 1) {
      return 'به‌روزرسانی همین حالا';
    }
    return 'به‌روزرسانی ${relativeTimeFa(updatedAt, now: now)}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final change = widget.changePercent;
    final freshness = _freshness;

    return Semantics(
      label: widget.price > 0
          ? 'قیمت ${faDigits(widget.price)} سکه'
          : 'قیمت نامشخص',
      child: AnimatedBuilder(
        animation: _flash,
        builder: (context, child) {
          final glow = (1 - _flash.value) * .16;
          final flashColor = _rising ? palette.success : palette.danger;
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 8 : 12,
              vertical: widget.compact ? 6 : 10,
            ),
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                flashColor.withValues(alpha: glow),
                palette.surfaceRaised,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.line.withValues(alpha: .8)),
            ),
            child: child,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          formatCoinsFa(widget.price),
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontSize: widget.compact ? 17 : 24,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                            letterSpacing: .2,
                            color: palette.text,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        if (widget.price > 0) ...[
                          const SizedBox(width: 5),
                          Text(
                            'Coins',
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                              fontSize: widget.compact ? 10.5 : 12,
                              fontWeight: FontWeight.w800,
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (change != null) ...[
                  const SizedBox(width: 10),
                  PriceDelta(percent: change),
                ],
              ],
            ),
            if (freshness != null) ...[
              SizedBox(height: widget.compact ? 3 : 6),
              Row(
                children: [
                  Icon(
                    Icons.update_rounded,
                    size: 12,
                    color: palette.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      freshness,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: palette.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
