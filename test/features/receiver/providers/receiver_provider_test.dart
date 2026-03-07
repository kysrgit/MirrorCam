import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_cam/features/receiver/providers/receiver_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('ReceiverProvider Tests', () {
    test('setZoom should clamp value between 1.0 and 5.0 and update state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(receiverNotifierProvider.notifier);

      // Test value within range
      notifier.setZoom(2.5);
      expect(container.read(receiverNotifierProvider).zoomLevel, 2.5);

      // Test value below minimum
      notifier.setZoom(0.5);
      expect(container.read(receiverNotifierProvider).zoomLevel, 1.0);

      // Test value above maximum
      notifier.setZoom(6.0);
      expect(container.read(receiverNotifierProvider).zoomLevel, 5.0);

      // Test edge cases
      notifier.setZoom(1.0);
      expect(container.read(receiverNotifierProvider).zoomLevel, 1.0);

      notifier.setZoom(5.0);
      expect(container.read(receiverNotifierProvider).zoomLevel, 5.0);
    });
  });
}
