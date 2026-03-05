import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mirror_cam/app.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MirrorCamApp()));

    // Wait for animations to finish
    await tester.pumpAndSettle();

    // Verify that the home screen loads properly
    expect(find.text('Lütfen bu cihazın görevini seçin:'), findsOneWidget);
  });
}
