import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_cam/shared/services/webrtc_service.dart';

void main() {
  group('WebRTCService', () {
    late WebRTCService webrtcService;

    setUp(() {
      webrtcService = WebRTCService();
    });

    test(
      'optimizeSdp removes VP8 and VP9, keeps H264 with correct attributes',
      () {
        final dummySdp =
            '''
v=0
o=- 4611731400430051336 2 IN IP4 127.0.0.1
s=-
t=0 0
a=extmap-allow-mixed
a=msid-semantic: WMS
m=video 9 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101
c=IN IP4 0.0.0.0
a=rtcp:9 IN IP4 0.0.0.0
a=rtpmap:96 VP8/90000
a=rtcp-fb:96 goog-remb
a=rtpmap:97 rtx/90000
a=fmtp:97 apt=96
a=rtpmap:98 VP9/90000
a=rtcp-fb:98 goog-remb
a=rtpmap:99 rtx/90000
a=fmtp:99 apt=98
a=rtpmap:100 H264/90000
a=rtcp-fb:100 goog-remb
a=fmtp:100 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=42001f
a=rtpmap:101 rtx/90000
a=fmtp:101 apt=100
'''
                .replaceAll('\n', '\r\n');

        final optimized = webrtcService.optimizeSdp(
          dummySdp,
          startBitrate: 4000,
          maxBitrate: 8000,
        );

        // VP8 and VP9 should be removed
        expect(optimized.contains('VP8'), isFalse);
        expect(optimized.contains('VP9'), isFalse);

        // H264 should still exist
        expect(optimized.contains('H264'), isTrue);

        // m=video should only have the H264 payload type (100 in this case)
        expect(optimized.contains('m=video 9 UDP/TLS/RTP/SAVPF 100'), isTrue);

        // Max bitrate attribute should be injected
        expect(optimized.contains('b=AS:8000'), isTrue);

        // profile-level-id should be updated to 640c1f (High Profile)
        expect(optimized.contains('profile-level-id=640c1f'), isTrue);

        // google bitrate attributes should be added
        expect(optimized.contains('x-google-start-bitrate=4000'), isTrue);
        expect(optimized.contains('x-google-max-bitrate=8000'), isTrue);
      },
    );
  });
}
