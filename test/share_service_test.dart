import 'package:fcbaz/src/share/share_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('ir.fcbaz.app/share');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final bytes = Uint8List.fromList([137, 80, 78, 71, 1, 2, 3]);
  const text = 'ترکیب اصلی\nST — مهدی طارمی (۸۴)';

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('passes the rendered card to the native share channel', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call;
      return 'shared';
    });

    final outcome = await ShareService().shareImage(
      pngBytes: bytes,
      fileName: 'fcbaz-squad.png',
      fallbackText: text,
    );

    expect(outcome, ShareOutcome.shared);
    expect(received?.method, 'shareImage');
    final args = received!.arguments as Map<Object?, Object?>;
    expect(args['bytes'], bytes);
    expect(args['fileName'], 'fcbaz-squad.png');
    expect(args['text'], text);
  });

  test('copies the text when native sharing raises a platform error', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'share_failed');
    });
    Object? copied;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map<Object?, Object?>)['text'];
      }
      return null;
    });

    final outcome = await ShareService().shareImage(
      pngBytes: bytes,
      fileName: 'fcbaz-squad.png',
      fallbackText: text,
    );

    expect(outcome, ShareOutcome.copiedToClipboard);
    expect(copied, text);
  });

  test('copies the text when the native channel is not registered', () async {
    Object? copied;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map<Object?, Object?>)['text'];
      }
      return null;
    });

    final outcome = await ShareService().shareImage(
      pngBytes: bytes,
      fileName: 'fcbaz-draft.png',
      fallbackText: text,
    );

    expect(outcome, ShareOutcome.copiedToClipboard);
    expect(copied, text);
  });

  test('reports an honest outcome message for every result', () {
    expect(shareOutcomeMessage(ShareOutcome.shared), contains('اشتراک‌گذاری'));
    expect(
      shareOutcomeMessage(ShareOutcome.copiedToClipboard),
      contains('کلیپ‌بورد'),
    );
    expect(shareOutcomeMessage(ShareOutcome.unavailable), contains('ممکن نشد'));
  });
}
