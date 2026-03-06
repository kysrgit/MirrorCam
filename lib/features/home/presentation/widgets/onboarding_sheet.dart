import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../settings/providers/settings_provider.dart';

/// İlk açılışta veya yardım butonuna basıldığında gösterilen rehber
class OnboardingSheet extends ConsumerStatefulWidget {
  const OnboardingSheet({super.key});

  /// Rehberi bottom sheet olarak açar
  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const OnboardingSheet(),
    );
  }

  @override
  ConsumerState<OnboardingSheet> createState() => _OnboardingSheetState();
}

class _OnboardingSheetState extends ConsumerState<OnboardingSheet> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding() {
    ref.read(settingsNotifierProvider.notifier).setHasSeenOnboarding(true);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold/Card benzeri yapı
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(100),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              children: const [
                _OnboardingPage(
                  title: 'MirrorCam Nedir?',
                  description:
                      'Telefonunuzu kablosuz aynaya dönüştürün!\n\nBir cihaz kamera olur, diğeri ekran. Kameranın gördüğü görüntü anında ekranda belirir.',
                  icon: Icons.devices,
                  color: Colors.blueAccent,
                ),
                _OnboardingPage(
                  title: 'Ne Gerekli?',
                  description:
                      '✅ İki cihaz gerekli (telefon + tablet veya telefon)\n\n✅ Her iki cihaz AYNI WiFi ağına bağlı olmalı\n\n❌ İnternet bağlantısı, Bluetooth veya mobil veri gerekmez.',
                  icon: Icons.wifi,
                  color: Colors.greenAccent,
                ),
                _OnboardingPage(
                  title: 'Nasıl Kullanılır?',
                  description:
                      '1️⃣ Bir cihazda "Gönderici" modunu seçin.\n\n2️⃣ Diğer cihazda "Alıcı" modunu seçin.\n\n3️⃣ Alıcı ekranında QR kodu okutun.\n\n4️⃣ Bağlantı otomatik kurulur!',
                  icon: Icons.qr_code_scanner,
                  color: Colors.amber,
                ),
                _OnboardingPage(
                  title: 'İpuçları',
                  description:
                      '🔦 Fener: Alıcıdan göndericinin fenerini açın.\n🪞 Ayna Modu: Çift dokunarak yatay çevirin.\n🔍 Zoom: Ekranda sıkıştırarak yakınlaştırın.\n⚙️ Kalite: Ayarlardan akıcılığı seçin.',
                  icon: Icons.lightbulb_outline,
                  color: Colors.orangeAccent,
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SmoothPageIndicator(
                  controller: _pageController,
                  count: 4,
                  effect: ExpandingDotsEffect(
                    activeDotColor: Theme.of(context).colorScheme.primary,
                    dotColor: Colors.grey.withAlpha(100),
                    dotHeight: 8,
                    dotWidth: 8,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage == 3) {
                      _finishOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(_currentPage == 3 ? '🚀 Başla!' : 'İleri'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 80, color: color),
          ),
          const SizedBox(height: 48),
          Text(
            title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
