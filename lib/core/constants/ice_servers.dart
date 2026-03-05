/// Default WebRTC ICE servers configuration.
class IceServers {
  /// Returns the default list of STUN/TURN servers.
  static const List<Map<String, dynamic>> defaultServers = [
    {
      'urls': ['stun:stun.l.google.com:19302'],
    },
  ];
}
