import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Standalone Dart WebSocket Server for 8-Ball Billiards
/// Hỗ trợ: Ghép trận ngẫu nhiên 1v1, Phòng mã PIN 6 số,
/// Đồng bộ theo thời gian thực (Real-time), Reconnect khi bị ngắt kết nối tạm thời,
/// và Xử thua công bằng khi đầu hàng từ Menu Cài đặt (Forfeit).
void main(List<String> args) async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);

  print('====================================================');
  print('🎱 DART BIDA WEBSOCKET SERVER ĐANG CHẠY TRÊN CỔNG: $port');
  print('   - HTTP Health Check: http://localhost:$port/health');
  print('   - WebSocket Endpoint: ws://localhost:$port');
  print('====================================================');

  final rooms = <String, Room>{};
  final clients = <WebSocket, ClientSession>{};
  final matchmakingQueue = <WebSocket>[];
  final tournamentQueue = <WebSocket>[];

  server.listen((HttpRequest request) async {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      final ws = await WebSocketTransformer.upgrade(request);
      final clientId = 'dart_player_${Random().nextInt(999999)}';
      final session = ClientSession(id: clientId);
      clients[ws] = session;

      print('[+] Client kết nối: $clientId (Tổng: ${clients.length})');
      sendJson(ws, {'type': 'connected', 'clientId': clientId});

      ws.listen(
        (data) {
          try {
            final json = jsonDecode(data.toString()) as Map<String, dynamic>;
            final type = json['type'] as String?;

            switch (type) {
              case 'set_profile':
                session.id = json['clientId']?.toString() ?? session.id;
                session.name = json['name']?.toString() ?? session.name;
                session.level = (json['level'] as num?)?.toInt() ?? session.level;
                session.coins = (json['coins'] as num?)?.toInt() ?? session.coins;
                session.cueId = json['cueId']?.toString() ?? session.cueId;
                session.cueLevel = (json['cueLevel'] as num?)?.toInt() ?? session.cueLevel;
                if (session.roomId != null && rooms.containsKey(session.roomId)) {
                  final room = rooms[session.roomId]!;
                  final isP1 = (session.role == 'p1' || room.p1 == ws);
                  if (isP1) {
                    room.p1Name = session.name;
                    room.p1Level = session.level;
                    room.p1Coins = session.coins;
                    room.p1CueId = session.cueId;
                    room.p1CueLevel = session.cueLevel;
                    if (room.p2 != null) {
                      sendJson(room.p2!, {
                        'type': 'opponent_profile_sync',
                        'opponentName': session.name,
                        'opponentLevel': session.level,
                        'opponentCoins': session.coins,
                        'opponentCueId': session.cueId,
                        'opponentCueLevel': session.cueLevel,
                      });
                    }
                  } else {
                    room.p2Name = session.name;
                    room.p2Level = session.level;
                    room.p2Coins = session.coins;
                    room.p2CueId = session.cueId;
                    room.p2CueLevel = session.cueLevel;
                    if (room.p1 != null) {
                      sendJson(room.p1!, {
                        'type': 'opponent_profile_sync',
                        'opponentName': session.name,
                        'opponentLevel': session.level,
                        'opponentCoins': session.coins,
                        'opponentCueId': session.cueId,
                        'opponentCueLevel': session.cueLevel,
                      });
                    }
                  }
                }
                break;

              case 'create_room':
                var code = (100000 + Random().nextInt(900000)).toString();
                while (rooms.containsKey(code)) {
                  code = (100000 + Random().nextInt(900000)).toString();
                }
                final roomMode = json['mode']?.toString() ?? '1v1';
                final roomBracket = (json['bracket'] as num?)?.toInt() ?? 1;
                final room = Room(id: code, p1: ws, mode: roomMode, bracket: roomBracket);
                room.p1Id = session.id;
                room.p1Name = session.name;
                room.p1Level = session.level;
                room.p1Coins = session.coins;
                room.p1CueId = session.cueId;
                room.p1CueLevel = session.cueLevel;
                rooms[code] = room;

                session.roomId = code;
                session.role = 'p1';
                print('[Room] Tạo phòng #${code} (${room.mode} B${room.bracket}) bởi ${session.name}');
                sendJson(ws, {
                  'type': 'room_created',
                  'roomId': code,
                  'role': 'host',
                  'mode': room.mode,
                  'bracket': room.bracket,
                });
                break;

              case 'join_room':
                final code = json['roomId']?.toString().trim() ?? '';
                final room = rooms[code];
                if (room == null) {
                  sendJson(ws, {'type': 'error', 'message': 'Phòng không tồn tại hoặc đã đóng!'});
                  return;
                }
                if (room.p2 != null && room.p2DisconnectedAt == null) {
                  sendJson(ws, {'type': 'error', 'message': 'Phòng này đã đủ người!'});
                  return;
                }
                room.p2 = ws;
                room.p2Id = session.id;
                room.p2Name = session.name;
                room.p2Level = session.level;
                room.p2Coins = session.coins;
                room.p2CueId = session.cueId;
                room.p2CueLevel = session.cueLevel;
                room.state = 'playing';

                session.roomId = code;
                session.role = 'p2';

                sendJson(ws, {
                  'type': 'room_joined',
                  'roomId': code,
                  'role': 'client',
                  'mode': room.mode,
                  'bracket': room.bracket,
                });
                if (room.p1 != null) {
                  sendJson(room.p1!, {
                    'type': 'opponent_joined',
                    'opponentName': session.name,
                    'opponentLevel': session.level,
                    'opponentCoins': session.coins,
                    'opponentCueId': session.cueId,
                    'opponentCueLevel': session.cueLevel,
                  });
                }
                sendJson(ws, {
                  'type': 'opponent_joined',
                  'opponentName': room.p1Name,
                  'opponentLevel': room.p1Level,
                  'opponentCoins': room.p1Coins,
                  'opponentCueId': room.p1CueId,
                  'opponentCueLevel': room.p1CueLevel,
                });
                final startMsg = {
                  'type': 'match_start',
                  'roomId': code,
                  'firstTurn': 1,
                  'mode': room.mode,
                  'bracket': room.bracket,
                  'opponentCueId': room.p1CueId,
                  'opponentCueLevel': room.p1CueLevel,
                };
                if (room.p1 != null) {
                  sendJson(room.p1!, {
                    ...startMsg,
                    'opponentCueId': room.p2CueId,
                    'opponentCueLevel': room.p2CueLevel,
                  });
                }
                sendJson(room.p2!, startMsg);
                break;

              case 'quick_match':
                matchmakingQueue.remove(ws);
                if (matchmakingQueue.isNotEmpty) {
                  final oppWs = matchmakingQueue.removeAt(0);
                  final oppSession = clients[oppWs];
                  var code = (100000 + Random().nextInt(900000)).toString();
                  final room = Room(id: code, p1: oppWs, p2: ws, mode: '1v1');
                  room.state = 'playing';
                  room.p1Id = oppSession?.id ?? 'p1';
                  room.p1Name = oppSession?.name ?? 'Cơ Thủ 1';
                  room.p1Level = oppSession?.level ?? 1;
                  room.p1Coins = oppSession?.coins ?? 1000;
                  room.p1CueId = oppSession?.cueId ?? 'standard_cue';
                  room.p1CueLevel = oppSession?.cueLevel ?? 1;
                  room.p2Id = session.id;
                  room.p2Name = session.name;
                  room.p2Level = session.level;
                  room.p2Coins = session.coins;
                  room.p2CueId = session.cueId;
                  room.p2CueLevel = session.cueLevel;
                  rooms[code] = room;

                  if (oppSession != null) {
                    oppSession.roomId = code;
                    oppSession.role = 'p1';
                  }
                  session.roomId = code;
                  session.role = 'p2';

                  sendJson(oppWs, {
                    'type': 'match_found',
                    'roomId': code,
                    'role': 'host',
                    'mode': '1v1',
                    'opponentName': session.name,
                    'opponentLevel': session.level,
                    'opponentCoins': session.coins,
                    'opponentCueId': session.cueId,
                    'opponentCueLevel': session.cueLevel,
                    'firstTurn': 1,
                  });
                  sendJson(ws, {
                    'type': 'match_found',
                    'roomId': code,
                    'role': 'client',
                    'mode': '1v1',
                    'opponentName': oppSession?.name ?? 'Đối thủ',
                    'opponentLevel': oppSession?.level ?? 1,
                    'opponentCoins': oppSession?.coins ?? 1000,
                    'opponentCueId': oppSession?.cueId ?? 'standard_cue',
                    'opponentCueLevel': oppSession?.cueLevel ?? 1,
                    'firstTurn': 1,
                  });
                } else {
                  matchmakingQueue.add(ws);
                  sendJson(ws, {'type': 'matchmaking_waiting', 'message': 'Đang tìm đối thủ 1v1...'});
                }
                break;

              case 'quick_match_tournament':
                tournamentQueue.remove(ws);
                final bracket = (json['bracket'] as num?)?.toInt() ?? 1;
                if (tournamentQueue.isNotEmpty) {
                  final oppWs = tournamentQueue.removeAt(0);
                  final oppSession = clients[oppWs];
                  var code = (100000 + Random().nextInt(900000)).toString();
                  final room = Room(id: code, p1: oppWs, p2: ws, mode: 'tournament', bracket: bracket);
                  room.state = 'playing';
                  room.p1Id = oppSession?.id ?? 'p1';
                  room.p1Name = oppSession?.name ?? 'Cơ Thủ 1';
                  room.p1Level = oppSession?.level ?? 1;
                  room.p1Coins = oppSession?.coins ?? 1000;
                  room.p1CueId = oppSession?.cueId ?? 'standard_cue';
                  room.p1CueLevel = oppSession?.cueLevel ?? 1;
                  room.p2Id = session.id;
                  room.p2Name = session.name;
                  room.p2Level = session.level;
                  room.p2Coins = session.coins;
                  room.p2CueId = session.cueId;
                  room.p2CueLevel = session.cueLevel;
                  rooms[code] = room;

                  if (oppSession != null) {
                    oppSession.roomId = code;
                    oppSession.role = 'p1';
                  }
                  session.roomId = code;
                  session.role = 'p2';

                  sendJson(oppWs, {
                    'type': 'match_found',
                    'roomId': code,
                    'role': 'host',
                    'mode': 'tournament',
                    'bracket': bracket,
                    'opponentName': session.name,
                    'opponentLevel': session.level,
                    'opponentCoins': session.coins,
                    'opponentCueId': session.cueId,
                    'opponentCueLevel': session.cueLevel,
                    'firstTurn': 1,
                  });
                  sendJson(ws, {
                    'type': 'match_found',
                    'roomId': code,
                    'role': 'client',
                    'mode': 'tournament',
                    'bracket': bracket,
                    'opponentName': oppSession?.name ?? 'Đối thủ',
                    'opponentLevel': oppSession?.level ?? 1,
                    'opponentCoins': oppSession?.coins ?? 1000,
                    'opponentCueId': oppSession?.cueId ?? 'standard_cue',
                    'opponentCueLevel': oppSession?.cueLevel ?? 1,
                    'firstTurn': 1,
                  });
                } else {
                  tournamentQueue.add(ws);
                  sendJson(ws, {
                    'type': 'matchmaking_waiting',
                    'mode': 'tournament',
                    'bracket': bracket,
                    'message': 'Đang tìm đối thủ giải đấu Tournament...',
                  });
                }
                break;

              case 'cancel_matchmaking':
                matchmakingQueue.remove(ws);
                tournamentQueue.remove(ws);
                sendJson(ws, {'type': 'matchmaking_cancelled'});
                break;

              // Reconnect lại phòng đang thi đấu dở
              case 'reconnect_match':
                final reqRoomId = json['roomId']?.toString().trim();
                final reqClientId = json['clientId']?.toString() ?? session.id;
                final reqRole = json['role']?.toString();

                if (reqRoomId != null && rooms.containsKey(reqRoomId)) {
                  final room = rooms[reqRoomId]!;
                  if (room.state == 'playing') {
                    bool matched = false;
                    if (reqRole == 'p1' || reqClientId == room.p1Id) {
                      room.p1 = ws;
                      room.p1DisconnectedAt = null;
                      session.roomId = reqRoomId;
                      session.role = 'p1';
                      matched = true;
                    } else if (reqRole == 'p2' || reqClientId == room.p2Id) {
                      room.p2 = ws;
                      room.p2DisconnectedAt = null;
                      session.roomId = reqRoomId;
                      session.role = 'p2';
                      matched = true;
                    }

                    if (matched) {
                      room.disconnectTimer?.cancel();
                      room.disconnectTimer = null;
                      print('[Reconnect] Client ${session.name} (${session.role}) kết nối lại phòng #$reqRoomId');

                      sendJson(ws, {
                        'type': 'reconnected_success',
                        'roomId': room.id,
                        'role': session.role,
                        'mode': room.mode,
                        'bracket': room.bracket,
                        'opponentName': session.role == 'p1' ? room.p2Name : room.p1Name,
                        'opponentLevel': session.role == 'p1' ? room.p2Level : room.p1Level,
                        'opponentCoins': session.role == 'p1' ? room.p2Coins : room.p1Coins,
                        'opponentCueId': session.role == 'p1' ? room.p2CueId : room.p1CueId,
                        'opponentCueLevel': session.role == 'p1' ? room.p2CueLevel : room.p1CueLevel,
                        'lastBalls': room.lastBalls,
                        'cueBall': room.lastCueBall,
                        'currentTurn': room.currentTurn,
                        'ballInHand': room.ballInHand,
                        'p1Group': room.p1Group,
                        'p2Group': room.p2Group,
                        'breakShot': room.breakShot,
                        'rackOver': room.rackOver,
                        'winningPlayer': room.winningPlayer,
                        'ruleMessage': room.ruleMessage,
                      });

                      final opp = session.role == 'p1' ? room.p2 : room.p1;
                      if (opp != null) {
                        sendJson(opp, {
                          'type': 'opponent_reconnected',
                          'message': 'Đối thủ đã kết nối lại! Tiếp tục trận đấu.',
                        });
                        sendJson(opp, {'type': 'request_sync_state'});
                      }
                      return;
                    }
                  }
                }
                sendJson(ws, {'type': 'reconnect_failed', 'message': 'Trận đấu không tồn tại hoặc đã kết thúc.'});
                break;

              // Đầu hàng / Rời trận từ Menu Setting (Xử thua cho người gửi)
              case 'forfeit':
                final roomId = json['roomId']?.toString() ?? session.roomId;
                if (roomId != null && rooms.containsKey(roomId)) {
                  final room = rooms[roomId]!;
                  final winnerRole = session.role == 'p1' ? 'p2' : 'p1';
                  final target = session.role == 'p1' ? room.p2 : room.p1;

                  print('[Forfeit] Người chơi ${session.name} (${session.role}) đã đầu hàng tại phòng #$roomId. $winnerRole thắng!');
                  if (target != null) {
                    sendJson(target, {
                      'type': 'opponent_forfeited',
                      'winnerRole': winnerRole,
                      'message': 'Đối thủ đã rời trận đấu. Bạn giành chiến thắng!',
                    });
                  }
                  room.disconnectTimer?.cancel();
                  rooms.remove(roomId);
                }
                break;

              case 'sync_balls':
                if (session.roomId != null && rooms.containsKey(session.roomId)) {
                  final room = rooms[session.roomId]!;
                  room.lastBalls = json['balls'] as List<dynamic>?;
                  if (json['cueBall'] != null) {
                    room.lastCueBall = json['cueBall'] as Map<String, dynamic>?;
                  }
                  if (json['ballInHand'] != null) {
                    room.ballInHand = json['ballInHand'] == true;
                  }
                  final target = ws == room.p1 ? room.p2 : room.p1;
                  if (target != null) sendJson(target, json);
                }
                break;

              case 'shot_result':
                if (session.roomId != null && rooms.containsKey(session.roomId)) {
                  final room = rooms[session.roomId]!;
                  room.lastBalls = json['balls'] as List<dynamic>?;
                  if (json['cueBall'] != null) {
                    room.lastCueBall = json['cueBall'] as Map<String, dynamic>?;
                  }
                  if (json['nextTurn'] != null) {
                    room.currentTurn = (json['nextTurn'] as num).toInt();
                  }
                  if (json['ballInHand'] != null) {
                    room.ballInHand = json['ballInHand'] == true;
                  }
                  if (json['p1Group'] != null) room.p1Group = json['p1Group']?.toString();
                  if (json['p2Group'] != null) room.p2Group = json['p2Group']?.toString();
                  if (json['breakShot'] != null) room.breakShot = json['breakShot'] == true;
                  if (json['rackOver'] != null) room.rackOver = json['rackOver'] == true;
                  if (json['winningPlayer'] != null) {
                    room.winningPlayer = (json['winningPlayer'] as num?)?.toInt();
                  }
                  if (json['ruleMessage'] != null) {
                    room.ruleMessage = json['ruleMessage']?.toString();
                  }
                  final target = ws == room.p1 ? room.p2 : room.p1;
                  if (target != null) sendJson(target, json);
                }
                break;

              case 'shoot':
                if (session.roomId != null && rooms.containsKey(session.roomId)) {
                  final room = rooms[session.roomId]!;
                  if (json['balls'] != null) {
                    room.lastBalls = json['balls'] as List<dynamic>?;
                  }
                  if (json['cueBall'] != null) {
                    room.lastCueBall = json['cueBall'] as Map<String, dynamic>?;
                  }
                  final target = ws == room.p1 ? room.p2 : room.p1;
                  if (target != null) sendJson(target, json);
                }
                break;

              case 'ball_in_hand':
                if (session.roomId != null && rooms.containsKey(session.roomId)) {
                  final room = rooms[session.roomId]!;
                  if (json['nx'] != null && json['ny'] != null) {
                    room.lastCueBall = {'nx': json['nx'], 'ny': json['ny'], 'sunk': false};
                  }
                  if (json['placed'] != null) {
                    room.ballInHand = json['placed'] != true;
                  }
                  final target = ws == room.p1 ? room.p2 : room.p1;
                  if (target != null) sendJson(target, json);
                }
                break;

              case 'request_sync_state':
                if (session.roomId != null && rooms.containsKey(session.roomId)) {
                  final room = rooms[session.roomId]!;
                  final target = ws == room.p1 ? room.p2 : room.p1;
                  if (target != null) sendJson(target, json);
                }
                break;

              case 'aim':
              case 'spin':
              case 'restart':
              case 'player_info':
              case 'chat':
                if (session.roomId != null && rooms.containsKey(session.roomId)) {
                  final room = rooms[session.roomId]!;
                  final target = ws == room.p1 ? room.p2 : room.p1;
                  if (target != null) {
                    sendJson(target, json);
                  }
                }
                break;
            }
          } catch (e) {
            print('Lỗi xử lý packet: $e');
          }
        },
        onDone: () {
          matchmakingQueue.remove(ws);
          tournamentQueue.remove(ws);
          if (session.roomId != null && rooms.containsKey(session.roomId)) {
            final room = rooms[session.roomId]!;
            if (room.state == 'playing') {
              final isP1 = ws == room.p1;
              if (isP1) {
                room.p1 = null;
                room.p1DisconnectedAt = DateTime.now();
              } else {
                room.p2 = null;
                room.p2DisconnectedAt = DateTime.now();
              }
              final target = isP1 ? room.p2 : room.p1;
              if (target != null) {
                sendJson(target, {
                  'type': 'opponent_disconnected',
                  'message': 'Đối thủ bị mất kết nối tạm thời! Trận đấu vẫn diễn ra theo thời gian thực.',
                  'graceSeconds': 180,
                });
              }
              print('[Disconnect] Client ${session.name} ngắt kết nối. Phòng #${room.id} tiếp tục chạy theo thời gian thực (chờ reconnect 180s)...');

              // Bắt đầu đếm ngược 180s nếu không reconnect
              room.disconnectTimer?.cancel();
              room.disconnectTimer = Timer(const Duration(seconds: 180), () {
                if (rooms.containsKey(room.id)) {
                  final activeOpp = isP1 ? room.p2 : room.p1;
                  if (activeOpp != null) {
                    sendJson(activeOpp, {
                      'type': 'opponent_forfeited',
                      'winnerRole': isP1 ? 'p2' : 'p1',
                      'message': 'Đối thủ không kết nối lại sau 180s. Bạn giành chiến thắng!',
                    });
                  }
                  rooms.remove(room.id);
                  print('[Timeout] Đã đóng phòng #${room.id} do đối thủ bỏ trận.');
                }
              });
            } else {
              // Phòng đang đợi khách ở sảnh
              if (room.p1 != null && room.p1 != ws) {
                sendJson(room.p1!, {'type': 'opponent_left', 'message': 'Đối thủ đã thoát'});
              }
              rooms.remove(session.roomId);
            }
          }
          clients.remove(ws);
          print('[-] Client ngắt kết nối socket: ${session.id} (Còn: ${clients.length})');
        },
      );
    } else {
      // HTTP Health check
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'status': 'ok',
          'service': 'bida-dart-websocket-server',
          'onlineClients': clients.length,
          'activeRooms': rooms.length,
        }))
        ..close();
    }
  });
}

void sendJson(WebSocket ws, Map<String, dynamic> data) {
  try {
    ws.add(jsonEncode(data));
  } catch (_) {}
}

class ClientSession {
  String id;
  String name = 'Cơ Thủ';
  int level = 1;
  int coins = 1000;
  String cueId = 'standard_cue';
  int cueLevel = 1;
  String? roomId;
  String? role;

  ClientSession({required this.id});
}

class Room {
  final String id;
  WebSocket? p1;
  WebSocket? p2;
  String p1Id = '';
  String p2Id = '';
  String p1Name = 'Cơ Thủ 1';
  String p2Name = 'Cơ Thủ 2';
  int p1Level = 1;
  int p2Level = 1;
  int p1Coins = 1000;
  int p2Coins = 1000;
  String p1CueId = 'standard_cue';
  int p1CueLevel = 1;
  String p2CueId = 'standard_cue';
  int p2CueLevel = 1;
  String state = 'waiting';
  DateTime createdAt;
  DateTime? p1DisconnectedAt;
  DateTime? p2DisconnectedAt;
  Timer? disconnectTimer;
  List<dynamic>? lastBalls;
  Map<String, dynamic>? lastCueBall;
  int currentTurn = 1;
  bool ballInHand = false;
  String? p1Group;
  String? p2Group;
  bool breakShot = true;
  bool rackOver = false;
  int? winningPlayer;
  String? ruleMessage;

  String mode = '1v1';
  int bracket = 1;

  Room({
    required this.id,
    required this.p1,
    this.p2,
    this.mode = '1v1',
    this.bracket = 1,
  }) : createdAt = DateTime.now();
}
