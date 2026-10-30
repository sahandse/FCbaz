import 'package:flutter/services.dart';

enum ShareOutcome { shared, copiedToClipboard, unavailable }

class ShareService {
  ShareService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('ir.fcbaz.app/share');

  final MethodChannel _channel;

  Future<ShareOutcome> shareImage({
    required Uint8List pngBytes,
    required String fileName,
    required String fallbackText,
  }) async {
    try {
      final result = await _channel.invokeMethod<String>('shareImage', {
        'bytes': pngBytes,
        'fileName': fileName,
        'text': fallbackText,
      });
      if (result == 'shared') return ShareOutcome.shared;
    } on MissingPluginException {
      // The native channel exists only on Android; fall back to text below.
    } on PlatformException {
      // Native sharing failed; the text fallback still works.
    }

    try {
      await Clipboard.setData(ClipboardData(text: fallbackText));
      return ShareOutcome.copiedToClipboard;
    } catch (_) {
      return ShareOutcome.unavailable;
    }
  }
}

String shareOutcomeMessage(ShareOutcome outcome) => switch (outcome) {
  ShareOutcome.shared => 'پنجره اشتراک‌گذاری باز شد.',
  ShareOutcome.copiedToClipboard =>
    'اشتراک‌گذاری تصویری در دسترس نبود؛ متن ترکیب در کلیپ‌بورد کپی شد.',
  ShareOutcome.unavailable => 'ساخت کارت اشتراک‌گذاری ممکن نشد.',
};
