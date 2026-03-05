# MirrorCam

MirrorCam, telefonunuzun kamerasını yerel ağ üzerinden (Wi-Fi) kablosuz bir şekilde diğer cihazlara (akıllı TV, tablet, bilgisayar veya diğer telefonlar) yansıtmanızı sağlayan açık kaynaklı bir Flutter uygulamasıdır. 

WebRTC ve WebSocket (Custom Signaling) altyapısı kullanarak ultra düşük gecikme ile yüksek performanslı video aktarımı sağlar.

---

## Özellikler

- **İki Mod (Sender / Receiver):** Aynı uygulamayı hem kamera gönderici (Sender) hem de ekran alıcı (Receiver) olarak kullanabilirsiniz.
- **Ultra Düşük Gecikme:** WebRTC DataChannel üzerinden gecikme ölçümü ve SDP optimizasyonu ile en aza indirilmiş gecikme süresi.
- **Kamera Kontrolleri:** Ön/Arka kamera değişimi (Toggle Camera) ve el feneri (Flash) açıp kapatma desteği. 
- **Görüntü Ayarları:** Receiver cihazında görüntüyü döndürme, yatayda ayna efekti (Mirror) uygulama ve 1.0x - 5.0x arası yakınlaştırma (Zoom) özelliği.
- **Hızlı Bağlantı:** Sender'ın ekranındaki veya yayın yaptığı IP tabanlı QR kodu okutularak hızlı eşleşme.
- **Otomatik Yeniden Bağlanma (Auto-Reconnect):** Bağlantı kopmalarında veya zayıf internet durumlarında Exponential Backoff sistemi ile kesintileri en aza indirme.
- **Ekran Uyanık Tutma (Wakelock):** Yayın sırasında cihazın uykuya dalmasını engeller.

---

## Teknolojiler ve Mimari

Bu proje Flutter ile geliştirilmiştir ve **Domain Driven Design (DDD) Feature-First** mimari standardını benimser.

- **State Management:** Riverpod (`flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`)
- **Real-time İletişim:** `flutter_webrtc`
- **Sinyalleşme Sunucusu:** Yerel ağda oluşturulan Dart tabanlı WebSocket / HTTP sunucusu (`shelf`, `shelf_web_socket`) ve istemci modülü (`web_socket_channel`)
- **Kare Kod Tarama (QR):** `mobile_scanner` ve QR kod oluşturma için `qr_flutter`
- **İzin Yönetimi:** `permission_handler`
- **UI / UX Bileşenleri:** `flutter_animate`, Google Fonts, standart Flutter animasyonları (Hero, vb.)

### Klasör Yapısı (Feature-First)

```
lib/
├── core/            # Uygulamanın çekirdek dosyaları (Theme, Utils, Logger)
├── features/        # Ana özelliklerin bulunduğu klasör (Home, Sender, Receiver, Settings)
└── shared/          # Özellikler arası paylaşılan servis ve widget'lar (WebRTC, Ses)
```

---

## Kurulum ve Başlama

### Gereksinimler
- **Flutter SDK:** ^3.0.0 (Null Safety aktif)
- **Dart SDK:** ^3.0.0
- **Android / iOS:** Test edilebilir fiziksel bir cihaz (Kamera / WebRTC donanım ivmesi için emülatörler yerine gerçek cihaz önerilir).

### Adımlar

1. **Bağımlılıkları İndirin:**
   ```bash
   flutter pub get
   ```

2. **Riverpod Code Generation Çalıştırın:**
   Eğer özelliklerde değişiklik yaparsanız state generator'ü yenilemek için:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. **Uygulamayı Başlatın:**
   Fiziksel cihazınızın bağlı olduğundan emin olun.
   ```bash
   flutter run
   ```

---

## Kullanım

1. Her iki cihazın da **Aynı Wi-Fi (Yerel Ağ)** üzerinde olduğundan emin olun.
2. Kamera yansıtmak istediğiniz cihazda uygulamayı açıp **"📷 Kamera (Gönderici)"** modunu seçin.
3. Ekranda bir IP adresi ve bir **QR Kod** belirecektir.
4. Görüntüyü izlemek istediğiniz cihazda uygulamayı açıp **"🖥️ Ekran (Alıcı)"** modunu seçin.
5. Alıcı cihazın kamerasını kullanarak, Gönderici cihazdaki QR Kodu **okutun**.
6. Eşleşme saniyeler içinde sağlanacak ve yüksek kaliteli canlı video akışı başlayacaktır!

---

## Hata Ayıklama (Tests)

Uygulamanın çalışır durumda olup olmadığını, parse ve UI testlerini kontrol etmek için:

```bash
flutter test
```

## Lisans

Bu proje MIT Lisansı altında açık kaynak olarak dağıtılmaktadır.
