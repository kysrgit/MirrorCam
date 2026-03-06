import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_cam/core/utils/network_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NetworkUtils WiFi High Performance Methods', () {
    const MethodChannel channel = MethodChannel('com.mirrorcam/wifi');
    final List<MethodCall> log = <MethodCall>[];
    bool shouldThrow = false;

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (shouldThrow) {
          throw PlatformException(code: 'ERROR', message: 'Test error');
        }
        log.add(methodCall);
        return null;
      });
    });

    tearDown(() {
      log.clear();
      shouldThrow = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test(
      'enableWifiHighPerformance invokes enableHighPerformance method successfully',
      () async {
        await NetworkUtils.enableWifiHighPerformance();
        expect(log, hasLength(1));
        expect(log.first.method, 'enableHighPerformance');
      },
    );

    test(
      'disableWifiHighPerformance invokes disableHighPerformance method successfully',
      () async {
        await NetworkUtils.disableWifiHighPerformance();
        expect(log, hasLength(1));
        expect(log.first.method, 'disableHighPerformance');
      },
    );

    test('enableWifiHighPerformance handles PlatformException gracefully', () async {
      shouldThrow = true;
      // Should not throw
      await expectLater(NetworkUtils.enableWifiHighPerformance(), completes);
      expect(log, isEmpty);
    });

    test('disableWifiHighPerformance handles PlatformException gracefully', () async {
      shouldThrow = true;
      // Should not throw
      await expectLater(NetworkUtils.disableWifiHighPerformance(), completes);
      expect(log, isEmpty);
    });
  });
}
