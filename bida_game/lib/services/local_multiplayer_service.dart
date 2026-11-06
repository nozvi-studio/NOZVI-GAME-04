import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'progression_service.dart';

enum MultiplayerRole { none, host, client }

enum MultiplayerConnectionState {
  disconnected,
  hosting,
  connecting,
  connected,
}

class DiscoveredRoom {
  final String ip;
  final int port;
  final String hostName;
  final DateTime lastSeen;

  DiscoveredRoom({
    required this.ip,
    required this.port,
    required this.hostName,
    required this.lastSeen,
  });
}

class LocalMultiplayerService extends ChangeNotifier {
  static final LocalMultiplayerService instance = LocalMultiplayerService._internal();

  LocalMultiplayerService._internal();

  static const int port = 8888;
  static const int broadcastPort = 8889;

  MultiplayerRole role = MultiplayerRole.none;
  MultiplayerConnectionState connectionState = MultiplayerConnectionState.disconnected;

  String? localIp;
  List<String> availableIps = [];
  ServerSocket? _serverSocket;
  Socket? _activeSocket;
  StreamSubscription? _socketSubscription;

  // Thông tin đối thủ nhận qua mạng WiFi
  String opponentName = '';
  int opponentLevel = 1;
  int opponentCoins = 1000;
  String opponentCueId = 'standard_cue';
  int opponentCueLevel = 1;

  // UDP Broadcast & Discovery
  RawDatagramSocket? _broadcastSocket;
  Timer? _broadcastTimer;
  RawDatagramSocket? _discoverySocket;
  final ValueNotifier<List<DiscoveredRoom>> discoveredRooms = ValueNotifier([]);

  // Callback nhận gói tin từ đối thủ để game xử lý
  void Function(Map<String, dynamic> data)? onMessageReceived;

  bool get isConnected => connectionState == MultiplayerConnectionState.connected;
  bool get isHost => role == MultiplayerRole.host;

  /// Lấy địa chỉ IP mạng nội bộ của máy (WiFi hoặc Hotspot)
  /// Thuật toán ưu tiên card WiFi/Hotspot và loại bỏ các dải mạng 4G/Cellular (rmnet, dummy, tun)
  Future<String?> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      final List<MapEntry<String, int>> candidates = [];
      final List<String> allIps = [];

      for (final interface in interfaces) {
        final name = interface.name.toLowerCase();
        for (final addr in interface.addresses) {
          if (addr.isLoopback || addr.type != InternetAddressType.IPv4) continue;
          final ip = addr.address;
          allIps.add(ip);

          int score = 0;
          // Ưu tiên card mạng WiFi / Hotspot
          if (name.contains('wlan') || name.contains('wifi') || name.contains('ap') || name.contains('swlan')) {
            score += 100;
          } else if (name.contains('eth') || name.contains('en')) {
            score += 70;
          } else if (name.contains('rmnet') || name.contains('ccmni') || name.contains('dummy') || name.contains('tun')) {
            score -= 100; // Mạng di động 4G/5G hoặc VPN nội bộ của nhà mạng
          }

          // Ưu tiên dải mạng LAN tiêu chuẩn
          if (ip.startsWith('192.168.')) {
            score += 50; // Dải WiFi gia đình & Hotspot phổ biến nhất
          } else if (ip.startsWith('172.')) {
            score += 20;
          } else if (ip.startsWith('10.')) {
            score += 10;
          }

          candidates.add(MapEntry(ip, score));
        }
      }

      availableIps = allIps;

      if (candidates.isNotEmpty) {
        candidates.sort((a, b) => b.value.compareTo(a.value));
        localIp = candidates.first.key;
        notifyListeners();
        return localIp;
      }
    } catch (e) {
      debugPrint('Error getting local IP: $e');
    }
    localIp = '127.0.0.1';
    notifyListeners();
    return localIp;
  }

  /// Mở phòng (Host) trên cổng 8888 và phát broadcast tìm kiếm tự động
  Future<bool> startHosting({String? roomName}) async {
    await disconnect();
    await getLocalIpAddress();

    try {
      _serverSocket = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        port,
        shared: true,
      );
      role = MultiplayerRole.host;
      connectionState = MultiplayerConnectionState.hosting;
      notifyListeners();

      _startBroadcasting(roomName: roomName ?? 'Bàn Bida #8');

      _serverSocket!.listen((Socket client) {
        if (_activeSocket != null) {
          // Chỉ cho phép 1 đối thủ kết nối cùng lúc
          client.destroy();
          return;
        }
        client.setOption(SocketOption.tcpNoDelay, true);
        _activeSocket = client;
        role = MultiplayerRole.host;
        connectionState = MultiplayerConnectionState.connected;
        _stopBroadcasting();
        notifyListeners();
        _listenToSocket(_activeSocket!);
        sendPlayerInfo();
      });

      return true;
    } catch (e) {
      debugPrint('Error startHosting: $e');
      connectionState = MultiplayerConnectionState.disconnected;
      notifyListeners();
      return false;
    }
  }

  /// Phát tín hiệu UDP Broadcast để các máy khác trong WiFi tự động phát hiện phòng
  void _startBroadcasting({required String roomName}) async {
    _stopBroadcasting();
    try {
      _broadcastSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
        reuseAddress: true,
      );
      _broadcastSocket?.broadcastEnabled = true;

      _broadcastTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
        if (_serverSocket == null || connectionState != MultiplayerConnectionState.hosting) {
          _stopBroadcasting();
          return;
        }
        final message = 'BIDA_ROOM|$localIp|$port|$roomName';
        final data = utf8.encode(message);
        try {
          _broadcastSocket?.send(
            data,
            InternetAddress('255.255.255.255'),
            broadcastPort,
          );
        } catch (_) {}
      });
    } catch (e) {
      debugPrint('Error starting UDP broadcast: $e');
    }
  }

  void _stopBroadcasting() {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    _broadcastSocket?.close();
    _broadcastSocket = null;
  }

  /// Bắt đầu lắng nghe quét phòng tự động trên mạng WiFi
  Future<void> startDiscovery() async {
    stopDiscovery();
    discoveredRooms.value = [];
    try {
      _discoverySocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        broadcastPort,
        reuseAddress: true,
      );
      _discoverySocket?.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _discoverySocket?.receive();
          if (datagram != null) {
            final text = utf8.decode(datagram.data);
            if (text.startsWith('BIDA_ROOM|')) {
              final parts = text.split('|');
              if (parts.length >= 4) {
                final hostIp = parts[1].trim();
                final hostPort = int.tryParse(parts[2].trim()) ?? port;
                final name = parts[3].trim();

                // Bỏ qua nếu là IP của chính máy này
                if (hostIp == localIp) return;

                final current = List<DiscoveredRoom>.from(discoveredRooms.value);
                final index = current.indexWhere((r) => r.ip == hostIp);
                final room = DiscoveredRoom(
                  ip: hostIp,
                  port: hostPort,
                  hostName: name,
                  lastSeen: DateTime.now(),
                );
                if (index >= 0) {
                  current[index] = room;
                } else {
                  current.add(room);
                }
                discoveredRooms.value = current;
              }
            }
          }
        }
      });
    } catch (e) {
      debugPrint('Error starting room discovery: $e');
    }
  }

  void stopDiscovery() {
    _discoverySocket?.close();
    _discoverySocket = null;
    discoveredRooms.value = [];
  }

  /// Kết nối vào phòng của đối thủ qua IP
  Future<bool> connectToHost(String hostIp) async {
    await disconnect();
    role = MultiplayerRole.client;
    connectionState = MultiplayerConnectionState.connecting;
    notifyListeners();

    try {
      // Làm sạch chuỗi IP (loại bỏ http, port, dấu phẩy, khoảng trắng do gõ bàn phím ảo)
      String cleanIp = hostIp.trim().replaceAll('http://', '').replaceAll('https://', '');
      if (cleanIp.contains(':')) {
        cleanIp = cleanIp.split(':').first.trim();
      }
      cleanIp = cleanIp.replaceAll(',', '.').replaceAll(' ', '');

      if (cleanIp.isEmpty) {
        throw Exception('Địa chỉ IP trống');
      }

      final socket = await Socket.connect(
        cleanIp,
        port,
        timeout: const Duration(seconds: 5),
      );
      socket.setOption(SocketOption.tcpNoDelay, true);
      _activeSocket = socket;
      connectionState = MultiplayerConnectionState.connected;
      stopDiscovery();
      notifyListeners();
      _listenToSocket(_activeSocket!);
      sendPlayerInfo();
      return true;
    } catch (e) {
      debugPrint('Error connectToHost: $e');
      connectionState = MultiplayerConnectionState.disconnected;
      role = MultiplayerRole.none;
      notifyListeners();
      return false;
    }
  }

  void _listenToSocket(Socket socket) {
    _socketSubscription = socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
      (line) {
        if (line.trim().isEmpty) return;
        try {
          final data = jsonDecode(line) as Map<String, dynamic>;
          if (data['type'] == 'player_info') {
            opponentName = (data['name'] as String?)?.trim() ?? 'Đối thủ';
            opponentLevel = (data['level'] as num?)?.toInt() ?? 1;
            opponentCoins = (data['coins'] as num?)?.toInt() ?? 1000;
            opponentCueId = (data['cueId'] as String?)?.trim() ?? 'standard_cue';
            opponentCueLevel = (data['cueLevel'] as num?)?.toInt() ?? 1;
            notifyListeners();
          }
          onMessageReceived?.call(data);
        } catch (e) {
          debugPrint('Error parsing message from opponent: $e');
        }
      },
      onDone: () {
        debugPrint('Opponent disconnected');
        disconnect();
      },
      onError: (err) {
        debugPrint('Socket error: $err');
        disconnect();
      },
    );
  }

  /// Gửi gói tin JSON tới đối thủ
  void sendData(Map<String, dynamic> data) {
    if (_activeSocket != null && isConnected) {
      try {
        final line = '${jsonEncode(data)}\n';
        _activeSocket!.write(line);
      } catch (e) {
        debugPrint('Error sending data: $e');
      }
    }
  }

  void sendPlayerInfo({
    String? name,
    int? level,
    int? coins,
    String? cueId,
    int? cueLevel,
  }) {
    sendData({
      'type': 'player_info',
      'name': name ?? AuthService.instance.displayName,
      'level': level ?? ProgressionService.instance.playerLevel,
      'coins': coins ?? ProgressionService.instance.coins,
      'cueId': cueId ?? ProgressionService.instance.equippedCue.id,
      'cueLevel': cueLevel ?? ProgressionService.instance.equippedCueLevel,
    });
  }

  void sendAim({required double angle, required double power}) {
    sendData({'type': 'aim', 'angle': angle, 'power': power});
  }

  void sendSpin({required double dx, required double dy}) {
    sendData({'type': 'spin', 'dx': dx, 'dy': dy});
  }

  void sendShoot({required double power}) {
    sendData({'type': 'shoot', 'power': power});
  }

  void sendBallInHand({required double x, required double y, bool placed = false}) {
    sendData({'type': 'ball_in_hand', 'x': x, 'y': y, 'placed': placed});
  }

  void sendRestart() {
    sendData({'type': 'restart'});
  }

  /// Ngắt kết nối và đóng mọi socket
  Future<void> disconnect() async {
    _stopBroadcasting();
    stopDiscovery();
    try {
      await _socketSubscription?.cancel();
      _socketSubscription = null;
      _activeSocket?.destroy();
      _activeSocket = null;
      await _serverSocket?.close();
      _serverSocket = null;
    } catch (e) {
      debugPrint('Error closing sockets: $e');
    }
    role = MultiplayerRole.none;
    connectionState = MultiplayerConnectionState.disconnected;
    opponentName = '';
    opponentLevel = 1;
    opponentCoins = 1000;
    opponentCueId = 'standard_cue';
    opponentCueLevel = 1;
    notifyListeners();
  }
}
