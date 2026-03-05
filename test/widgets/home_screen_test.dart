import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_cam/features/home/presentation/home_screen.dart';
import 'package:mirror_cam/features/home/presentation/widgets/role_selector.dart';

void main() {
  testWidgets('HomeScreen displays correctly with its elements', (
    WidgetTester tester,
  ) async {
    // Scaffold'u build etmek için bir MaterialApp ve ProviderScope sarmalayıcıya ihtiyacımız var.
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomeScreen())),
    );

    // Animasyonların bitmesini bekle
    await tester.pumpAndSettle();

    // Appbar title kontrolü
    expect(find.text('MirrorCam'), findsWidgets);

    // Ana metin kontrolü
    expect(
      find.text(
        'Telefonunuzun kamerasını kablosuz ayna olarak ekranlarda paylaşın.',
      ),
      findsOneWidget,
    );

    // İkinci bilgilendirme text kontrolü
    expect(find.text('Lütfen bu cihazın görevini seçin:'), findsOneWidget);

    // RoleSelector widget'ının varlığını kontrol et
    expect(find.byType(RoleSelector), findsOneWidget);

    // Ayarlar ikonunun varlığını kontrol et
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });
}
