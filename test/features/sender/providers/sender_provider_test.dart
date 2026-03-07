import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mirror_cam/features/sender/providers/sender_provider.dart';
import 'package:mirror_cam/features/sender/services/camera_streamer.dart';
import 'package:mocktail/mocktail.dart';

class MockCameraStreamer extends Mock implements CameraStreamer {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SenderNotifier.toggleTorch()', () {
    late ProviderContainer container;
    late MockCameraStreamer mockCameraStreamer;

    setUp(() {
      mockCameraStreamer = MockCameraStreamer();
      when(() => mockCameraStreamer.stopCamera()).thenAnswer((_) async {});

      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('updates state.isTorchOn when toggleTorch returns true', () async {
      when(() => mockCameraStreamer.toggleTorch())
          .thenAnswer((_) async => true);

      // Add listener to prevent autoDispose
      container.listen(senderNotifierProvider, (_, __) {});

      final notifier = container.read(senderNotifierProvider.notifier);

      // Replace the camera streamer with our mock.
      notifier.cameraStreamer = mockCameraStreamer;

      expect(container.read(senderNotifierProvider).isTorchOn, isFalse);

      await notifier.toggleTorch();

      expect(container.read(senderNotifierProvider).isTorchOn, isTrue);
      verify(() => mockCameraStreamer.toggleTorch()).called(1);
    });

    test('updates state.isTorchOn when toggleTorch returns false', () async {
      when(() => mockCameraStreamer.toggleTorch())
          .thenAnswer((_) async => false);

      // Add listener to prevent autoDispose
      container.listen(senderNotifierProvider, (_, __) {});

      final notifier = container.read(senderNotifierProvider.notifier);

      notifier.cameraStreamer = mockCameraStreamer;

      // Force state to true initially for the test.
      // We can't mutate state directly from outside, so we'll mock toggleTorch to return true, then false.

      when(() => mockCameraStreamer.toggleTorch())
          .thenAnswer((_) async => true);
      await notifier.toggleTorch();
      expect(container.read(senderNotifierProvider).isTorchOn, isTrue);

      // Now mock it to return false
      when(() => mockCameraStreamer.toggleTorch())
          .thenAnswer((_) async => false);
      await notifier.toggleTorch();

      expect(container.read(senderNotifierProvider).isTorchOn, isFalse);
      verify(() => mockCameraStreamer.toggleTorch()).called(2);
    });
  });
}
