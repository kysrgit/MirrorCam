import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_cam/features/home/presentation/widgets/role_selector.dart';

void main() {
  testWidgets('RoleSelector displays both Sender and Receiver options', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: RoleSelector())),
    );

    // Animasyonları bekle
    await tester.pumpAndSettle();

    // Gönderici kartını kontrol et
    expect(find.text('📷 Kamera (Gönderici)'), findsOneWidget);
    expect(
      find.text('Bu cihazın kamerasını başka bir ekrana aktarın'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);

    // Alıcı kartını kontrol et
    expect(find.text('🖥️ Ekran (Alıcı)'), findsOneWidget);
    expect(
      find.text('Başka bir cihazın kamerasını bu ekranda görün'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.desktop_windows), findsOneWidget);
  });
}
