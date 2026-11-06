import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'progression_service.dart';

enum OnlineConnectionState {
  disconnected,
  connecting,
  connected,
  findingMatch,
  waitingInRoom,
  inMatch,
}

class OnlineMultiplayerService extends ChangeNotifier {
  static final OnlineMultiplayerService instance = OnlineMultiplayerService._internal();

  OnlineMultiplayerService._internal() {
    _loadSavedClientInfo();
  }

  /// Cổng máy chủ WebSocket dành riêng cho Điện thoại thật kết nối qua Wi-Fi LAN
  static const String realPhoneDefaultUrl = 'ws://192.168.1.22:8080';
  String defaultServerUrl = realPhoneDefaultUrl;
  String? get lastConnectedUrl => _lastConnectedUrl;
  WebSocket? _socket;
  StreamSubscription? _socketSubscription;

  OnlineConnectionState connectionState = OnlineConnectionState.disconnected;
  bool isHost = false;
  String? currentRoomId;
  String? myClientId;
  String? _lastConnectedUrl;

  // Trạng thái phòng Tournament Online
  bool isTournamentMatch = false;
  int tournamentBracket = 1;
  int? currentTournamentBracket;

  String opponentName = 'Đối thủ Online';
  int opponentLevel = 1;
  int opponentCoins = 1000;
  String opponentCueId = 'standard_cue';
  int opponentCueLevel = 1;

  void Function(Map<String, dynamic> data)? onMessageReceived;
  void Function(String roomId, bool isHost)? onMatchStart;
  void Function(String roomId, bool isHost, Map<String, dynamic> state)? onReconnected;

  bool get isConnected =>
      connectionState == OnlineConnectionState.connected ||
      connectionState == OnlineConnectionState.waitingInRoom ||
      connectionState == OnlineConnectionState.inMatch;

  bool get isInMatch => connectionState == OnlineConnectionState.inMatch;

  Future<void> _loadSavedClientInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      myClientId = prefs.getString('online_client_id');
      if (myClientId == null) {
        myClientId = 'player_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecond % 9000))}';
        await prefs.setString('online_client_id', myClientId!);
      }
      final savedUrl = prefs.getString('online_server_url');
      if (savedUrl == null || savedUrl.contains('127.0.0.1') || savedUrl.contains('10.0.2.2')) {
        _lastConnectedUrl = realPhoneDefaultUrl;
        await prefs.setString('online_server_url', realPhoneDefaultUrl);
      } else {
        _lastConnectedUrl = savedUrl;
      }
    } catch (_) {}
  }

  Future<void> _saveActiveMatch(String roomId, bool isHost) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_online_room_id', roomId);
      await prefs.setBool('active_online_is_host', isHost);
      if (_lastConnectedUrl != null) {
        await prefs.setString('online_server_url', _lastConnectedUrl!);
      }
    } catch (_) {}
  }

  Future<void> clearActiveMatch() async {
    opponentCueId = 'standard_cue';
    opponentCueLevel = 1;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_online_room_id');
      await prefs.remove('active_online_is_host');
    } catch (_) {}
  }

  Future<String?> getSavedActiveRoomId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('active_online_room_id');
    } catch (_) {
      return null;
    }
  }

  /// Kết nối tới máy chủ WebSocket
  Future<bool> connect({String? url}) async {
    final serverUrl = url ?? _lastConnectedUrl ?? defaultServerUrl;
    _lastConnectedUrl = serverUrl;
    await disconnect(keepRoomId: true);

    connectionState = OnlineConnectionState.connecting;
    notifyListeners();

    try {
      final uri = Uri.parse(serverUrl);
      _socket = await WebSocket.connect(uri.toString()).timeout(
        const Duration(seconds: 7),
      );

      connectionState = currentRoomId != null ? OnlineConnectionState.inMatch : OnlineConnectionState.connected;
      notifyListeners();

      _listenToSocket();
      sendProfile();

      // Nếu đang có ván đấu dở dang, thử kết nối lại ngay lập tức
      final savedRoom = await getSavedActiveRoomId();
      if (savedRoom != null && savedRoom.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final savedIsHost = prefs.getBool('active_online_is_host') ?? isHost;
        reconnectMatch(roomId: savedRoom, isHost: savedIsHost);
      }

      return true;
    } catch (e) {
      debugPrint('Lỗi kết nối WebSocket: $e');
      connectionState = OnlineConnectionState.disconnected;
      notifyListeners();
      return false;
    }
  }

  void _listenToSocket() {
    _socketSubscription = _socket?.listen(
      (dynamic data) {
        try {
          final json = jsonDecode(data.toString()) as Map<String, dynamic>;
          _handleServerMessage(json);
        } catch (e) {
          debugPrint('Lỗi decode message từ WebSocket server: $e');
        }
      },
      onDone: () {
        debugPrint('WebSocket server đã đóng kết nối hoặc socket ngắt');
        // Không xóa currentRoomId để cho phép tự động reconnect khi mở lại app!
        disconnect(keepRoomId: true);
      },
      onError: (err) {
        debugPrint('Lỗi kết nối WebSocket: $err');
        disconnect(keepRoomId: true);
      },
    );
  }

  void _handleServerMessage(Map<String, dynamic> data) {
    final type = data['type'] as String?;

    switch (type) {
      case 'connected':
        myClientId ??= data['clientId']?.toString();
        break;

      case 'room_created':
        currentRoomId = data['roomId']?.toString();
        isHost = true;
        isTournamentMatch = data['mode'] == 'tournament';
        tournamentBracket = (data['bracket'] as num?)?.toInt() ?? (currentTournamentBracket ?? 1);
        connectionState = OnlineConnectionState.waitingInRoom;
        notifyListeners();
        break;

      case 'room_joined':
        currentRoomId = data['roomId']?.toString();
        isHost = false;
        isTournamentMatch = data['mode'] == 'tournament';
        tournamentBracket = (data['bracket'] as num?)?.toInt() ?? (currentTournamentBracket ?? 1);
        connectionState = OnlineConnectionState.waitingInRoom;
        notifyListeners();
        break;

      case 'opponent_joined':
        opponentName = data['opponentName']?.toString() ?? opponentName;
        opponentLevel = (data['opponentLevel'] as num?)?.toInt() ?? opponentLevel;
        opponentCoins = (data['opponentCoins'] as num?)?.toInt() ?? opponentCoins;
        opponentCueId = data['opponentCueId']?.toString() ?? opponentCueId;
        opponentCueLevel = (data['opponentCueLevel'] as num?)?.toInt() ?? opponentCueLevel;
        notifyListeners();
        break;

      case 'opponent_profile_sync':
        opponentName = data['opponentName']?.toString() ?? opponentName;
        opponentLevel = (data['opponentLevel'] as num?)?.toInt() ?? opponentLevel;
        opponentCoins = (data['opponentCoins'] as num?)?.toInt() ?? opponentCoins;
        opponentCueId = data['opponentCueId']?.toString() ?? opponentCueId;
        opponentCueLevel = (data['opponentCueLevel'] as num?)?.toInt() ?? opponentCueLevel;
        notifyListeners();
        break;

      case 'match_start':
        currentRoomId = data['roomId']?.toString() ?? currentRoomId;
        isTournamentMatch = data['mode'] == 'tournament' || isTournamentMatch;
        tournamentBracket = (data['bracket'] as num?)?.toInt() ?? (currentTournamentBracket ?? tournamentBracket);
        opponentCueId = data['opponentCueId']?.toString() ?? opponentCueId;
        opponentCueLevel = (data['opponentCueLevel'] as num?)?.toInt() ?? opponentCueLevel;
        connectionState = OnlineConnectionState.inMatch;
        if (currentRoomId != null) {
          _saveActiveMatch(currentRoomId!, isHost);
        }
        notifyListeners();
        onMatchStart?.call(currentRoomId ?? '', isHost);
        sendProfile();
        break;

      case 'match_found':
        currentRoomId = data['roomId']?.toString();
        isHost = data['role'] == 'host';
        isTournamentMatch = data['mode'] == 'tournament' || isTournamentMatch;
        tournamentBracket = (data['bracket'] as num?)?.toInt() ?? (currentTournamentBracket ?? tournamentBracket);
        opponentName = data['opponentName']?.toString() ?? opponentName;
        opponentLevel = (data['opponentLevel'] as num?)?.toInt() ?? opponentLevel;
        opponentCoins = (data['opponentCoins'] as num?)?.toInt() ?? opponentCoins;
        opponentCueId = data['opponentCueId']?.toString() ?? opponentCueId;
        opponentCueLevel = (data['opponentCueLevel'] as num?)?.toInt() ?? opponentCueLevel;
        connectionState = OnlineConnectionState.inMatch;
        if (currentRoomId != null) {
          _saveActiveMatch(currentRoomId!, isHost);
        }
        notifyListeners();
        onMatchStart?.call(currentRoomId ?? '', isHost);
        sendProfile();
        break;

      case 'matchmaking_waiting':
        connectionState = OnlineConnectionState.findingMatch;
        notifyListeners();
        break;

      case 'matchmaking_cancelled':
        connectionState = OnlineConnectionState.connected;
        notifyListeners();
        break;

      // Reconnect thành công vào phòng cũ
      case 'reconnected_success':
        currentRoomId = data['roomId']?.toString() ?? currentRoomId;
        isHost = data['role'] == 'p1' || data['role'] == 'host';
        if (data['mode'] != null) {
          isTournamentMatch = data['mode'] == 'tournament';
        }
        if (data['bracket'] != null) {
          tournamentBracket = (data['bracket'] as num?)?.toInt() ?? 1;
        }
        opponentName = data['opponentName']?.toString() ?? opponentName;
        opponentLevel = (data['opponentLevel'] as num?)?.toInt() ?? opponentLevel;
        opponentCoins = (data['opponentCoins'] as num?)?.toInt() ?? opponentCoins;
        opponentCueId = data['opponentCueId']?.toString() ?? opponentCueId;
        opponentCueLevel = (data['opponentCueLevel'] as num?)?.toInt() ?? opponentCueLevel;
        connectionState = OnlineConnectionState.inMatch;
        if (currentRoomId != null) {
          _saveActiveMatch(currentRoomId!, isHost);
        }
        notifyListeners();
        onReconnected?.call(currentRoomId ?? '', isHost, data);
        onMessageReceived?.call(data);
        break;

      case 'reconnect_failed':
        clearActiveMatch();
        currentRoomId = null;
        if (connectionState == OnlineConnectionState.inMatch) {
          connectionState = OnlineConnectionState.connected;
        }
        notifyListeners();
        break;

      // Đối thủ ngắt kết nối tạm thời (trận đấu vẫn tiếp tục!)
      case 'opponent_disconnected':
        onMessageReceived?.call(data);
        break;

      // Đối thủ đã kết nối lại
      case 'opponent_reconnected':
        onMessageReceived?.call(data);
        break;

      // Đối thủ chủ động đầu hàng / thoát trận từ Settings (Xử thắng cho mình)
      case 'opponent_forfeited':
        clearActiveMatch();
        onMessageReceived?.call(data);
        break;

      case 'opponent_left':
        // Chỉ xử lý khi đang ở phòng chờ hoặc trận đã kết thúc
        if (connectionState != OnlineConnectionState.inMatch) {
          connectionState = OnlineConnectionState.connected;
          currentRoomId = null;
          notifyListeners();
        }
        onMessageReceived?.call(data);
        break;

      default:
        // Chuyển tiếp tới game loop xử lý (aim, spin, shoot, ball_in_hand, sync_balls, v.v.)
        onMessageReceived?.call(data);
        break;
    }
  }

  void sendJson(Map<String, dynamic> data) {
    if (_socket != null && _socket?.readyState == WebSocket.open) {
      try {
        _socket?.add(jsonEncode(data));
      } catch (e) {
        debugPrint('Lỗi gửi dữ liệu qua WebSocket: $e');
      }
    }
  }

  void sendProfile() {
    sendJson({
      'type': 'set_profile',
      'clientId': myClientId,
      'name': AuthService.instance.displayName,
      'level': ProgressionService.instance.playerLevel,
      'coins': ProgressionService.instance.coins,
      'cueId': ProgressionService.instance.equippedCue.id,
      'cueLevel': ProgressionService.instance.equippedCueLevel,
      'showcasedMedals': ProgressionService.instance.showcasedMedals,
    });
  }

  void createRoom() {
    isTournamentMatch = false;
    currentTournamentBracket = null;
    sendProfile();
    sendJson({'type': 'create_room', 'mode': '1v1'});
  }

  void joinRoom(String roomId) {
    isTournamentMatch = false;
    currentTournamentBracket = null;
    sendProfile();
    sendJson({'type': 'join_room', 'roomId': roomId.trim()});
  }

  void startQuickMatch() {
    isTournamentMatch = false;
    currentTournamentBracket = null;
    sendProfile();
    sendJson({'type': 'quick_match'});
  }

  /// Tạo phòng Tournament Online theo Bracket
  void createTournamentRoom(int bracketNumber) {
    isTournamentMatch = true;
    currentTournamentBracket = bracketNumber;
    tournamentBracket = bracketNumber;
    sendProfile();
    sendJson({
      'type': 'create_room',
      'mode': 'tournament',
      'bracket': bracketNumber,
    });
  }

  /// Tham gia phòng Tournament Online bằng mã PIN
  void joinTournamentRoom(String roomId, {int bracketNumber = 1}) {
    isTournamentMatch = true;
    currentTournamentBracket = bracketNumber;
    tournamentBracket = bracketNumber;
    sendProfile();
    sendJson({
      'type': 'join_room',
      'roomId': roomId.trim(),
      'mode': 'tournament',
      'bracket': bracketNumber,
    });
  }

  /// Tìm trận nhanh Tournament Online theo Bracket
  void startTournamentQuickMatch(int bracketNumber) {
    isTournamentMatch = true;
    currentTournamentBracket = bracketNumber;
    tournamentBracket = bracketNumber;
    sendProfile();
    sendJson({
      'type': 'quick_match_tournament',
      'bracket': bracketNumber,
    });
  }

  void cancelQuickMatch() {
    sendJson({'type': 'cancel_matchmaking'});
  }

  void reconnectMatch({required String roomId, required bool isHost}) {
    sendProfile();
    sendJson({
      'type': 'reconnect_match',
      'roomId': roomId.trim(),
      'clientId': myClientId,
      'role': isHost ? 'p1' : 'p2',
    });
  }

  /// Đầu hàng / Rời trận đấu có xác nhận từ Settings (Xử thua cho mình)
  void forfeitMatch() {
    final roomId = currentRoomId;
    if (roomId != null) {
      sendJson({
        'type': 'forfeit',
        'roomId': roomId,
      });
    }
    clearActiveMatch();
    currentRoomId = null;
    isTournamentMatch = false;
    currentTournamentBracket = null;
    if (connectionState == OnlineConnectionState.inMatch) {
      connectionState = OnlineConnectionState.connected;
    }
    notifyListeners();
  }

  void sendAim({
    required double angle,
    required double power,
    String? cueId,
    int? cueLevel,
  }) {
    final payload = <String, dynamic>{
      'type': 'aim',
      'angle': angle,
      'power': power,
    };
    if (cueId != null) payload['cueId'] = cueId;
    if (cueLevel != null) payload['cueLevel'] = cueLevel;
    sendJson(payload);
  }

  void sendSpin({required double dx, required double dy}) {
    sendJson({'type': 'spin', 'dx': dx, 'dy': dy});
  }

  void sendShoot({
    required double power,
    double? angle,
    double? spinX,
    double? spinY,
    double? forceMult,
    double? spinMult,
    Map<String, dynamic>? cueBall,
    List<Map<String, dynamic>>? balls,
    String? cueId,
    int? cueLevel,
  }) {
    final payload = <String, dynamic>{
      'type': 'shoot',
      'power': power,
    };
    if (angle != null) payload['angle'] = angle;
    if (spinX != null) payload['spinX'] = spinX;
    if (spinY != null) payload['spinY'] = spinY;
    if (forceMult != null) payload['forceMult'] = forceMult;
    if (spinMult != null) payload['spinMult'] = spinMult;
    if (cueBall != null) payload['cueBall'] = cueBall;
    if (balls != null) payload['balls'] = balls;
    if (cueId != null) payload['cueId'] = cueId;
    if (cueLevel != null) payload['cueLevel'] = cueLevel;
    sendJson(payload);
  }

  void sendBallInHand({
    required double x,
    required double y,
    double? nx,
    double? ny,
    bool placed = false,
  }) {
    final payload = <String, dynamic>{
      'type': 'ball_in_hand',
      'x': x,
      'y': y,
      'placed': placed,
    };
    if (nx != null) payload['nx'] = nx;
    if (ny != null) payload['ny'] = ny;
    sendJson(payload);
  }

  void sendShotResult(Map<String, dynamic> result) {
    sendJson(result);
  }

  void sendSyncBalls(
    List<Map<String, dynamic>> balls, {
    Map<String, dynamic>? cueBall,
    bool? ballInHand,
  }) {
    final payload = <String, dynamic>{
      'type': 'sync_balls',
      'balls': balls,
    };
    if (cueBall != null) payload['cueBall'] = cueBall;
    if (ballInHand != null) payload['ballInHand'] = ballInHand;
    sendJson(payload);
  }

  void sendRestart() {
    sendJson({'type': 'restart'});
  }

  Future<void> disconnect({bool keepRoomId = false}) async {
    try {
      await _socketSubscription?.cancel();
      _socketSubscription = null;
      await _socket?.close();
      _socket = null;
    } catch (_) {}

    connectionState = OnlineConnectionState.disconnected;
    if (!keepRoomId) {
      currentRoomId = null;
      isHost = false;
      isTournamentMatch = false;
      currentTournamentBracket = null;
      opponentName = 'Đối thủ Online'; 
      clearActiveMatch();
    }   
    notifyListeners();
  }
}
