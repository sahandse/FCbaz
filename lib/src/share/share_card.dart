import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../theme/fcbaz_theme.dart';
import '../utils/persian_formatters.dart';

class ShareCardMetric {
  const ShareCardMetric({required this.label, required this.value});

  final String label;
  final String value;
}

class ShareCardRow {
  const ShareCardRow({
    required this.position,
    required this.name,
    required this.rating,
  });

  final String position;
  final String name;
  final int rating;
}

class ShareCardData {
  const ShareCardData({
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.metrics = const [],
    this.rows = const [],
    this.footer = 'FCBaz',
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final List<ShareCardMetric> metrics;
  final List<ShareCardRow> rows;
  final String footer;
}

String shareCardToText(ShareCardData data) {
  final buffer = StringBuffer()..writeln(data.title);
  final subtitle = data.subtitle;
  if (subtitle != null && subtitle.trim().isNotEmpty) {
    buffer.writeln(subtitle);
  }
  if (data.metrics.isNotEmpty) {
    buffer.writeln(
      data.metrics
          .map((metric) => '${metric.label}: ${metric.value}')
          .join('  |  '),
    );
  }
  if (data.rows.isNotEmpty) {
    buffer.writeln();
    for (final row in data.rows) {
      buffer.writeln('${row.position} — ${row.name} (${faDigits(row.rating)})');
    }
  }
  buffer
    ..writeln()
    ..write(data.footer);
  return buffer.toString().trim();
}

class ShareCardRenderer {
  const ShareCardRenderer();

  static const ui.Size cardSize = ui.Size(1080, 1350);
  static const double _padding = 64;
  static const double _rowsTop = 432;
  static const double _rowsBottom = 1236;

  Future<Uint8List> renderPng(ShareCardData data) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Offset.zero & cardSize);
    _paint(canvas, data);
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      cardSize.width.round(),
      cardSize.height.round(),
    );
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError('ساخت تصویر کارت اشتراک‌گذاری ناموفق بود.');
      }
      return byteData.buffer.asUint8List();
    } finally {
      image.dispose();
      picture.dispose();
    }
  }

  void _paint(ui.Canvas canvas, ShareCardData data) {
    final palette = FcbazPalette.dark;
    final contentWidth = cardSize.width - _padding * 2;

    canvas.drawRect(
      ui.Offset.zero & cardSize,
      ui.Paint()
        ..shader = ui.Gradient.linear(
          ui.Offset.zero,
          ui.Offset(0, cardSize.height),
          [palette.surface, palette.canvas],
        ),
    );

    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, cardSize.width, 10),
      ui.Paint()..color = palette.primary,
    );

    canvas.drawCircle(
      const ui.Offset(930, 96),
      280,
      ui.Paint()
        ..shader = ui.Gradient.radial(const ui.Offset(930, 96), 280, [
          palette.primary.withValues(alpha: .18),
          palette.primary.withValues(alpha: 0),
        ]),
    );

    _paintText(
      canvas,
      data.eyebrow.toUpperCase(),
      offset: const ui.Offset(_padding, 64),
      maxWidth: contentWidth,
      align: ui.TextAlign.left,
      textDirection: ui.TextDirection.ltr,
      style: TextStyle(
        color: palette.primary,
        fontSize: 30,
        fontWeight: FontWeight.w800,
        fontStyle: FontStyle.italic,
        fontFamily: 'BarlowCondensed',
        letterSpacing: 6,
      ),
    );

    _paintText(
      canvas,
      data.title,
      offset: const ui.Offset(_padding, 104),
      maxWidth: contentWidth,
      maxLines: 1,
      style: TextStyle(
        color: palette.text,
        fontSize: 60,
        fontWeight: FontWeight.w800,
        height: 1.25,
      ),
    );

    final subtitle = data.subtitle;
    if (subtitle != null) {
      _paintText(
        canvas,
        subtitle,
        offset: const ui.Offset(_padding, 196),
        maxWidth: contentWidth,
        maxLines: 1,
        style: TextStyle(
          color: palette.textMuted,
          fontSize: 30,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      );
    }

    canvas.drawRect(
      ui.Rect.fromLTWH(_padding, 262, contentWidth, 2),
      ui.Paint()..color = palette.primary.withValues(alpha: .3),
    );

    _paintMetrics(canvas, data.metrics, palette, contentWidth);
    _paintRows(canvas, data.rows, palette);

    _paintText(
      canvas,
      data.footer,
      offset: const ui.Offset(_padding, 1268),
      maxWidth: contentWidth,
      align: ui.TextAlign.center,
      maxLines: 1,
      style: TextStyle(
        color: palette.textMuted,
        fontSize: 26,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  void _paintMetrics(
    ui.Canvas canvas,
    List<ShareCardMetric> metrics,
    FcbazPalette palette,
    double contentWidth,
  ) {
    if (metrics.isEmpty) return;
    const gap = 20.0;
    const top = 292.0;
    const height = 112.0;
    final width = (contentWidth - gap * (metrics.length - 1)) / metrics.length;

    for (var i = 0; i < metrics.length; i++) {
      final left = cardSize.width - _padding - width - i * (width + gap);
      final rect = ui.Rect.fromLTWH(left, top, width, height);
      final rrect = ui.RRect.fromRectAndRadius(
        rect,
        const ui.Radius.circular(22),
      );
      canvas.drawRRect(rrect, ui.Paint()..color = palette.surfaceRaised);
      canvas.drawRRect(
        rrect,
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = palette.line,
      );

      final metric = metrics[i];
      _paintText(
        canvas,
        metric.value,
        offset: ui.Offset(left, top + 14),
        maxWidth: width,
        align: ui.TextAlign.center,
        maxLines: 1,
        style: TextStyle(
          color: palette.primary,
          fontSize: 42,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
      );
      _paintText(
        canvas,
        metric.label,
        offset: ui.Offset(left, top + 66),
        maxWidth: width,
        align: ui.TextAlign.center,
        maxLines: 1,
        style: TextStyle(
          color: palette.textMuted,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      );
    }
  }

  void _paintRows(
    ui.Canvas canvas,
    List<ShareCardRow> rows,
    FcbazPalette palette,
  ) {
    if (rows.isEmpty) return;
    final area = _rowsBottom - _rowsTop;
    final slot = area / rows.length;
    final gap = (slot * .18).clamp(6.0, 14.0);
    final rowHeight = math.min(78.0, slot - gap);
    final contentWidth = cardSize.width - _padding * 2;

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final rect = ui.Rect.fromLTWH(
        _padding,
        _rowsTop + i * slot,
        contentWidth,
        rowHeight,
      );
      final rrect = ui.RRect.fromRectAndRadius(
        rect,
        const ui.Radius.circular(18),
      );
      canvas.drawRRect(
        rrect,
        ui.Paint()..color = palette.surfaceRaised.withValues(alpha: .9),
      );
      canvas.drawRRect(
        rrect,
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = palette.line,
      );

      const badgeWidth = 92.0;
      final badgeRect = ui.Rect.fromLTWH(
        rect.left + 14,
        rect.top + (rowHeight - 46) / 2,
        badgeWidth,
        46,
      );
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(badgeRect, const ui.Radius.circular(14)),
        ui.Paint()..color = palette.primary,
      );
      _paintText(
        canvas,
        faDigits(row.rating),
        offset: ui.Offset(badgeRect.left, badgeRect.top + 5),
        maxWidth: badgeRect.width,
        align: ui.TextAlign.center,
        maxLines: 1,
        style: TextStyle(
          color: palette.onPrimary,
          fontSize: 27,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
      );

      const positionWidth = 120.0;
      _paintText(
        canvas,
        row.position,
        offset: ui.Offset(
          rect.right - 26 - positionWidth,
          rect.top + (rowHeight - 36) / 2,
        ),
        maxWidth: positionWidth,
        align: ui.TextAlign.right,
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
        style: TextStyle(
          color: palette.primary,
          fontSize: 30,
          fontWeight: FontWeight.w800,
          fontStyle: FontStyle.italic,
          fontFamily: 'BarlowCondensed',
          height: 1.2,
        ),
      );

      final nameWidth = rect.width - 28 - badgeWidth - 16 - positionWidth - 20;
      _paintText(
        canvas,
        row.name,
        offset: ui.Offset(
          rect.left + 14 + badgeWidth + 16,
          rect.top + (rowHeight - 38) / 2,
        ),
        maxWidth: nameWidth,
        maxLines: 1,
        style: TextStyle(
          color: palette.text,
          fontSize: 31,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      );
    }
  }

  void _paintText(
    ui.Canvas canvas,
    String text, {
    required TextStyle style,
    required ui.Offset offset,
    required double maxWidth,
    ui.TextAlign align = ui.TextAlign.right,
    ui.TextDirection textDirection = ui.TextDirection.rtl,
    int? maxLines,
  }) {
    if (text.trim().isEmpty || maxWidth <= 0) return;
    final resolvedStyle = style.fontFamily == null
        ? style.copyWith(fontFamily: 'Vazirmatn')
        : style;
    final painter = TextPainter(
      text: TextSpan(text: text, style: resolvedStyle),
      textDirection: textDirection,
      textAlign: align,
      textScaler: TextScaler.noScaling,
      maxLines: maxLines,
      ellipsis: maxLines == null ? null : '…',
    )..layout(minWidth: maxWidth, maxWidth: maxWidth);
    painter.paint(canvas, offset);
    painter.dispose();
  }
}
