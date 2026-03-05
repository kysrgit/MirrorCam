import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_cam/features/receiver/services/signaling_client.dart';

void main() {
  group('SignalingClient Message Parsing', () {
    HttpServer? server;
    late SignalingClient client;
    final List<WebSocket> clientSockets = [];

    setUp(() async {
      server = await HttpServer.bind('127.0.0.1', 0);
      server!.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          final ws = await WebSocketTransformer.upgrade(request);
          clientSockets.add(ws);

          // Send valid JSON message
          ws.add(
            jsonEncode({
              'type': 'offer',
              'data': {'sdp': 'dummy'},
            }),
          );

          // Send invalid JSON message (should be ignored by try-catch)
          ws.add('invalid json {[');

          // Send another valid JSON message
          ws.add(
            jsonEncode({'type': 'candidate', 'data': <String, dynamic>{}}),
          );
        }
      });

      client = SignalingClient();
    });

    tearDown(() async {
      for (final ws in clientSockets) {
        await ws.close();
      }
      clientSockets.clear();
      await client.dispose();
      await server?.close(force: true);
    });

    test(
      'parses valid JSON messages and catches invalid ones without crashing',
      () async {
        final receivedMessages = <Map<String, dynamic>>[];
        client.messages.listen((message) {
          receivedMessages.add(message);
        });

        await client.connect('127.0.0.1', server!.port);

        // Wait for the WebSocket messages to be received and processed
        await Future<void>.delayed(const Duration(milliseconds: 500));

        // There were 3 messages sent, but only 2 of them are valid JSON maps.
        expect(receivedMessages.length, 2);
        expect(receivedMessages[0]['type'], 'offer');
        expect(receivedMessages[1]['type'], 'candidate');
      },
    );
  });
}
