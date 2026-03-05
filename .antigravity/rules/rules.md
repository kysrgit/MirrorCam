## Öğrenilmiş Dersler (Postmortem)

### 🐛 SDP Munging Uyumluluk Sorunu (Android 16+)
- **Tarih:** 2026-03-05
- **Sorun:** Manuel SDP string manipulation (codec reorder, bitrate inject) bazı
  cihazlarda/Android versiyonlarında WebRTC engine tarafından "geçersiz format"
  olarak reddediliyor. Sender sessizce hata fırlatıyor, Offer gönderilmiyor,
  Receiver timeout alıyor.
- **Çözüm:** SDP optimizasyonu MUTLAKA try-catch ile sarılmalı. Hata durumunda
  orijinal (dokunulmamış) SDP ile fallback yapılmalı.
- **Kural:** WebRTC SDP'ye dokunulan HER yerde (Offer ve Answer) bu fallback
  mekanizması ZORUNLU. Asla "ya çalışır ya crash" bırakma.
- **Alternatif:** SDP munging yerine RTCRtpSender.setParameters() API'si ile
  codec/bitrate ayarlamayı tercih et (daha güvenli, standartlara uygun).

```dart
// ✅ DOĞRU YAKLAŞIM — Her zaman fallback ile
Future<RTCSessionDescription> createOfferSafe(RTCPeerConnection pc) async {
  final offer = await pc.createOffer();
  
  try {
    final optimized = _optimizeSdp(offer.sdp!);
    final optimizedDesc = RTCSessionDescription(optimized, offer.type);
    await pc.setLocalDescription(optimizedDesc);
    _logger.info('Optimized SDP applied successfully');
    return optimizedDesc;
  } catch (e) {
    _logger.warn('SDP optimization rejected by device, using original: $e');
    await pc.setLocalDescription(offer);
    return offer;
  }
}
```

```dart
// 🆕 Modern yaklaşım: SDP'ye dokunmadan codec/bitrate ayarla
// RTCRtpSender.setParameters() API kullanımı

Future<void> applyBitrateConstraints(RTCPeerConnection pc) async {
  final senders = await pc.getSenders();
  for (final sender in senders) {
    if (sender.track?.kind == 'video') {
      final params = sender.parameters;
      
      // Bitrate ayarla — SDP'ye dokunmadan!
      for (final encoding in params.encodings) {
        encoding.maxBitrate = 8000000;  // 8 Mbps
        encoding.minBitrate = 4000000;  // 4 Mbps
      }
      
      // Degradation preference
      params.degradationPreference = RTCDegradationPreference.MAINTAIN_RESOLUTION;
      
      await sender.setParameters(params);
    }
  }
}
```
