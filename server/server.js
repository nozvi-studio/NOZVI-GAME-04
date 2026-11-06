const http = require('http');
const { WebSocketServer, WebSocket } = require('ws');

const PORT = process.env.PORT || 8080;

// Bộ nhớ lưu trữ Rooms & Clients
const rooms = new Map(); // roomId -> Room object
const clients = new Map(); // ws -> ClientSession object
const matchmakingQueue = []; // danh sách ws đang đợi ghép trận nhanh 1v1
const tournamentQueue = []; // danh sách ws đang đợi ghép trận tournament 6 brackets

// Tạo HTTP Server (hỗ trợ HTTP health check khi deploy lên Render/Railway/Fly.io)
const server = http.createServer((req, res) => {
  if (req.url === '/health' || req.url === '/') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      status: 'ok',
      service: 'bida-websocket-server',
      activeRooms: rooms.size,
      onlinePlayers: clients.size,
      uptime: process.uptime()
    }));
  } else {
    res.writeHead(404);
    res.end();
  }
});

const wss = new WebSocketServer({ server });

function generateRoomCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

function broadcastToRoom(room, senderWs, data) {
  const messageStr = JSON.stringify(data);
  if (room.p1 && room.p1 !== senderWs && room.p1.readyState === WebSocket.OPEN) {
    room.p1.send(messageStr);
  }
  if (room.p2 && room.p2 !== senderWs && room.p2.readyState === WebSocket.OPEN) {
    room.p2.send(messageStr);
  }
}

function sendJson(ws, data) {
  if (ws && ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(data));
  }
}

wss.on('connection', (ws) => {
  const clientId = 'player_' + Math.random().toString(36).substring(2, 9);
  clients.set(ws, {
    id: clientId,
    name: 'Cơ Thủ',
    level: 1,
    coins: 1000,
    cueId: 'standard_cue',
    cueLevel: 1,
    roomId: null,
    role: null,
    isAlive: true
  });

  console.log(`[+] Client kết nối: ${clientId} (Tổng: ${clients.size})`);
  sendJson(ws, { type: 'connected', clientId });

  ws.on('pong', () => {
    const client = clients.get(ws);
    if (client) client.isAlive = true;
  });

  ws.on('message', (raw) => {
    try {
      const data = JSON.parse(raw.toString());
      const client = clients.get(ws);
      if (!client) return;

      switch (data.type) {
        // 1. Cập nhật thông tin profile
        case 'set_profile': {
          client.id = data.clientId || client.id;
          client.name = data.name || client.name;
          client.level = data.level || client.level;
          client.coins = data.coins || client.coins;
          client.cueId = data.cueId || client.cueId || 'standard_cue';
          client.cueLevel = data.cueLevel || client.cueLevel || 1;
          if (client.roomId && rooms.has(client.roomId)) {
            const room = rooms.get(client.roomId);
            const isP1 = (client.role === 'p1' || room.p1 === ws);
            if (isP1) {
              room.p1Name = client.name;
              room.p1Level = client.level;
              room.p1Coins = client.coins;
              room.p1CueId = client.cueId;
              room.p1CueLevel = client.cueLevel;
              if (room.p2) {
                sendJson(room.p2, {
                  type: 'opponent_profile_sync',
                  opponentName: client.name,
                  opponentLevel: client.level,
                  opponentCoins: client.coins,
                  opponentCueId: client.cueId,
                  opponentCueLevel: client.cueLevel
                });
              }
            } else {
              room.p2Name = client.name;
              room.p2Level = client.level;
              room.p2Coins = client.coins;
              room.p2CueId = client.cueId;
              room.p2CueLevel = client.cueLevel;
              if (room.p1) {
                sendJson(room.p1, {
                  type: 'opponent_profile_sync',
                  opponentName: client.name,
                  opponentLevel: client.level,
                  opponentCoins: client.coins,
                  opponentCueId: client.cueId,
                  opponentCueLevel: client.cueLevel
                });
              }
            }
          }
          break;
        }

        // 2. Tạo phòng mới với mã PIN 6 số
        case 'create_room': {
          let roomCode = generateRoomCode();
          while (rooms.has(roomCode)) {
            roomCode = generateRoomCode();
          }

          const roomMode = data.mode || '1v1';
          const roomBracket = data.bracket || 1;
          const room = {
            id: roomCode,
            p1: ws,
            p2: null,
            p1Id: client.id,
            p2Id: null,
            p1Name: client.name,
            p2Name: 'Cơ Thủ 2',
            p1Level: client.level,
            p2Level: 1,
            p1Coins: client.coins,
            p2Coins: 1000,
            p1CueId: client.cueId || 'standard_cue',
            p1CueLevel: client.cueLevel || 1,
            p2CueId: 'standard_cue',
            p2CueLevel: 1,
            state: 'waiting',
            mode: roomMode,
            bracket: roomBracket,
            createdAt: Date.now(),
            disconnectTimer: null,
            lastBalls: null,
            currentTurn: 1
          };
          rooms.set(roomCode, room);

          client.roomId = roomCode;
          client.role = 'p1';

          console.log(`[Room] Tạo phòng thành công: #${roomCode} (${room.mode} B${room.bracket}) bởi ${client.name}`);
          sendJson(ws, {
            type: 'room_created',
            roomId: roomCode,
            role: 'host',
            mode: room.mode,
            bracket: room.bracket
          });
          break;
        }

        // 3. Tham gia phòng bằng mã PIN
        case 'join_room': {
          const roomCode = (data.roomId || '').toString().trim();
          const room = rooms.get(roomCode);

          if (!room) {
            sendJson(ws, { type: 'error', message: 'Phòng không tồn tại hoặc đã đóng!' });
            return;
          }

          if (room.p2 !== null && room.p2DisconnectedAt == null) {
            sendJson(ws, { type: 'error', message: 'Phòng này đã đủ 2 người chơi!' });
            return;
          }

          room.p2 = ws;
          room.p2Id = client.id;
          room.p2Name = client.name;
          room.p2Level = client.level;
          room.p2Coins = client.coins;
          room.p2CueId = client.cueId || 'standard_cue';
          room.p2CueLevel = client.cueLevel || 1;
          room.state = 'playing';

          client.roomId = roomCode;
          client.role = 'p2';

          console.log(`[Room] ${client.name} đã vào phòng #${roomCode}`);

          sendJson(ws, {
            type: 'room_joined',
            roomId: roomCode,
            role: 'client',
            mode: room.mode,
            bracket: room.bracket
          });

          if (room.p1) {
            sendJson(room.p1, {
              type: 'opponent_joined',
              opponentName: client.name,
              opponentLevel: client.level,
              opponentCoins: client.coins,
              opponentCueId: room.p2CueId,
              opponentCueLevel: room.p2CueLevel
            });
          }

          sendJson(ws, {
            type: 'opponent_joined',
            opponentName: room.p1Name,
            opponentLevel: room.p1Level,
            opponentCoins: room.p1Coins,
            opponentCueId: room.p1CueId,
            opponentCueLevel: room.p1CueLevel
          });

          const matchPayload = {
            type: 'match_start',
            roomId: roomCode,
            firstTurn: 1,
            mode: room.mode,
            bracket: room.bracket,
            opponentCueId: room.p1CueId,
            opponentCueLevel: room.p1CueLevel
          };
          if (room.p1) {
            sendJson(room.p1, {
              ...matchPayload,
              opponentCueId: room.p2CueId,
              opponentCueLevel: room.p2CueLevel
            });
          }
          sendJson(room.p2, matchPayload);
          break;
        }

        // 4. Ghép trận tự động 1v1 (Quick Match)
        case 'quick_match': {
          const queueIndex = matchmakingQueue.indexOf(ws);
          if (queueIndex !== -1) matchmakingQueue.splice(queueIndex, 1);

          if (matchmakingQueue.length > 0) {
            const opponentWs = matchmakingQueue.shift();
            const opponentClient = clients.get(opponentWs);

            if (!opponentWs || opponentWs.readyState !== WebSocket.OPEN) {
              matchmakingQueue.push(ws);
              sendJson(ws, { type: 'matchmaking_waiting', message: 'Đang tìm đối thủ 1v1...' });
              return;
            }

            const roomCode = generateRoomCode();
            const room = {
              id: roomCode,
              p1: opponentWs,
              p2: ws,
              p1Id: opponentClient ? opponentClient.id : 'p1',
              p2Id: client.id,
              p1Name: opponentClient ? opponentClient.name : 'Cơ Thủ 1',
              p2Name: client.name,
              p1Level: opponentClient ? opponentClient.level : 1,
              p2Level: client.level,
              p1Coins: opponentClient ? opponentClient.coins : 1000,
              p2Coins: client.coins,
              p1CueId: opponentClient ? (opponentClient.cueId || 'standard_cue') : 'standard_cue',
              p1CueLevel: opponentClient ? (opponentClient.cueLevel || 1) : 1,
              p2CueId: client.cueId || 'standard_cue',
              p2CueLevel: client.cueLevel || 1,
              state: 'playing',
              mode: '1v1',
              bracket: 1,
              createdAt: Date.now(),
              disconnectTimer: null,
              lastBalls: null,
              currentTurn: 1
            };
            rooms.set(roomCode, room);

            if (opponentClient) {
              opponentClient.roomId = roomCode;
              opponentClient.role = 'p1';
            }

            client.roomId = roomCode;
            client.role = 'p2';

            console.log(`[Matchmaking] Ghép thành công 1v1: ${room.p1Name} vs ${room.p2Name} trong phòng #${roomCode}`);

            sendJson(opponentWs, {
              type: 'match_found',
              roomId: roomCode,
              role: 'host',
              mode: '1v1',
              opponentName: client.name,
              opponentLevel: client.level,
              opponentCoins: client.coins,
              opponentCueId: room.p2CueId,
              opponentCueLevel: room.p2CueLevel,
              firstTurn: 1
            });

            sendJson(ws, {
              type: 'match_found',
              roomId: roomCode,
              role: 'client',
              mode: '1v1',
              opponentName: room.p1Name,
              opponentLevel: room.p1Level,
              opponentCoins: room.p1Coins,
              opponentCueId: room.p1CueId,
              opponentCueLevel: room.p1CueLevel,
              firstTurn: 1
            });
          } else {
            matchmakingQueue.push(ws);
            sendJson(ws, { type: 'matchmaking_waiting', message: 'Đang tìm đối thủ 1v1...' });
          }
          break;
        }

        // 4b. Ghép trận Tournament Online 6 Brackets
        case 'quick_match_tournament': {
          const tIdx = tournamentQueue.indexOf(ws);
          if (tIdx !== -1) tournamentQueue.splice(tIdx, 1);
          const bracket = data.bracket || 1;

          if (tournamentQueue.length > 0) {
            const opponentWs = tournamentQueue.shift();
            const opponentClient = clients.get(opponentWs);

            if (!opponentWs || opponentWs.readyState !== WebSocket.OPEN) {
              tournamentQueue.push(ws);
              sendJson(ws, { type: 'matchmaking_waiting', mode: 'tournament', bracket, message: 'Đang tìm đối thủ giải đấu Tournament...' });
              return;
            }

            const roomCode = generateRoomCode();
            const room = {
              id: roomCode,
              p1: opponentWs,
              p2: ws,
              p1Id: opponentClient ? opponentClient.id : 'p1',
              p2Id: client.id,
              p1Name: opponentClient ? opponentClient.name : 'Cơ Thủ 1',
              p2Name: client.name,
              p1Level: opponentClient ? opponentClient.level : 1,
              p2Level: client.level,
              p1Coins: opponentClient ? opponentClient.coins : 1000,
              p2Coins: client.coins,
              p1CueId: opponentClient ? (opponentClient.cueId || 'standard_cue') : 'standard_cue',
              p1CueLevel: opponentClient ? (opponentClient.cueLevel || 1) : 1,
              p2CueId: client.cueId || 'standard_cue',
              p2CueLevel: client.cueLevel || 1,
              state: 'playing',
              mode: 'tournament',
              bracket: bracket,
              createdAt: Date.now(),
              disconnectTimer: null,
              lastBalls: null,
              currentTurn: 1
            };
            rooms.set(roomCode, room);

            if (opponentClient) {
              opponentClient.roomId = roomCode;
              opponentClient.role = 'p1';
            }

            client.roomId = roomCode;
            client.role = 'p2';

            console.log(`[Tournament] Ghép thành công Tournament B${bracket}: ${room.p1Name} vs ${room.p2Name} trong phòng #${roomCode}`);

            sendJson(opponentWs, {
              type: 'match_found',
              roomId: roomCode,
              role: 'host',
              mode: 'tournament',
              bracket: bracket,
              opponentName: client.name,
              opponentLevel: client.level,
              opponentCoins: client.coins,
              opponentCueId: room.p2CueId,
              opponentCueLevel: room.p2CueLevel,
              firstTurn: 1
            });

            sendJson(ws, {
              type: 'match_found',
              roomId: roomCode,
              role: 'client',
              mode: 'tournament',
              bracket: bracket,
              opponentName: room.p1Name,
              opponentLevel: room.p1Level,
              opponentCoins: room.p1Coins,
              opponentCueId: room.p1CueId,
              opponentCueLevel: room.p1CueLevel,
              firstTurn: 1
            });
          } else {
            tournamentQueue.push(ws);
            sendJson(ws, {
              type: 'matchmaking_waiting',
              mode: 'tournament',
              bracket: bracket,
              message: 'Đang tìm đối thủ giải đấu Tournament...'
            });
          }
          break;
        }

        // 5. Hủy hàng đợi tìm trận
        case 'cancel_matchmaking': {
          const idx = matchmakingQueue.indexOf(ws);
          if (idx !== -1) matchmakingQueue.splice(idx, 1);
          const tIdx = tournamentQueue.indexOf(ws);
          if (tIdx !== -1) tournamentQueue.splice(tIdx, 1);
          sendJson(ws, { type: 'matchmaking_cancelled' });
          break;
        }

        // 6. Reconnect lại phòng đang thi đấu dở
        case 'reconnect_match': {
          const reqRoomId = (data.roomId || '').toString().trim();
          const reqClientId = data.clientId || client.id;
          const reqRole = data.role;

          if (reqRoomId && rooms.has(reqRoomId)) {
            const room = rooms.get(reqRoomId);
            if (room.state === 'playing') {
              let matched = false;
              if (reqRole === 'p1' || reqClientId === room.p1Id) {
                room.p1 = ws;
                client.roomId = reqRoomId;
                client.role = 'p1';
                matched = true;
              } else if (reqRole === 'p2' || reqClientId === room.p2Id) {
                room.p2 = ws;
                client.roomId = reqRoomId;
                client.role = 'p2';
                matched = true;
              }

              if (matched) {
                if (room.disconnectTimer) {
                  clearTimeout(room.disconnectTimer);
                  room.disconnectTimer = null;
                }
                console.log(`[Reconnect] Client ${client.name} (${client.role}) kết nối lại phòng #${reqRoomId}`);

                sendJson(ws, {
                  type: 'reconnected_success',
                  roomId: room.id,
                  role: client.role,
                  mode: room.mode,
                  bracket: room.bracket,
                  opponentName: client.role === 'p1' ? room.p2Name : room.p1Name,
                  opponentLevel: client.role === 'p1' ? room.p2Level : room.p1Level,
                  opponentCoins: client.role === 'p1' ? room.p2Coins : room.p1Coins,
                  opponentCueId: client.role === 'p1' ? room.p2CueId : room.p1CueId,
                  opponentCueLevel: client.role === 'p1' ? room.p2CueLevel : room.p1CueLevel,
                  lastBalls: room.lastBalls,
                  cueBall: room.lastCueBall,
                  currentTurn: room.currentTurn,
                  ballInHand: room.ballInHand,
                  p1Group: room.p1Group,
                  p2Group: room.p2Group,
                  breakShot: room.breakShot,
                  rackOver: room.rackOver,
                  winningPlayer: room.winningPlayer,
                  ruleMessage: room.ruleMessage
                });

                const oppWs = client.role === 'p1' ? room.p2 : room.p1;
                if (oppWs) {
                  sendJson(oppWs, {
                    type: 'opponent_reconnected',
                    message: 'Đối thủ đã kết nối lại! Tiếp tục trận đấu.'
                  });
                  sendJson(oppWs, { type: 'request_sync_state' });
                }
                return;
              }
            }
          }
          sendJson(ws, { type: 'reconnect_failed', message: 'Trận đấu không tồn tại hoặc đã kết thúc.' });
          break;
        }

        // 7. Đầu hàng / Rời trận từ Menu Setting (Xử thua công bằng)
        case 'forfeit': {
          const roomId = data.roomId || client.roomId;
          if (roomId && rooms.has(roomId)) {
            const room = rooms.get(roomId);
            const winnerRole = client.role === 'p1' ? 'p2' : 'p1';
            const targetWs = client.role === 'p1' ? room.p2 : room.p1;

            console.log(`[Forfeit] Người chơi ${client.name} (${client.role}) đầu hàng trong phòng #${roomId}. ${winnerRole} thắng!`);
            if (targetWs) {
              sendJson(targetWs, {
                type: 'opponent_forfeited',
                winnerRole,
                message: 'Đối thủ đã rời trận đấu. Bạn giành chiến thắng!'
              });
            }
            if (room.disconnectTimer) clearTimeout(room.disconnectTimer);
            rooms.delete(roomId);
          }
          break;
        }

        // 8. Đồng bộ vị trí bi
        case 'sync_balls': {
          if (client.roomId && rooms.has(client.roomId)) {
            const room = rooms.get(client.roomId);
            room.lastBalls = data.balls;
            if (data.cueBall) room.lastCueBall = data.cueBall;
            if (data.ballInHand !== undefined) room.ballInHand = data.ballInHand;
            broadcastToRoom(room, ws, data);
          }
          break;
        }

        // 8b. Đồng bộ kết quả cú đánh toàn diện
        case 'shot_result': {
          if (client.roomId && rooms.has(client.roomId)) {
            const room = rooms.get(client.roomId);
            room.lastBalls = data.balls;
            if (data.cueBall) room.lastCueBall = data.cueBall;
            if (data.nextTurn) room.currentTurn = data.nextTurn;
            if (data.ballInHand !== undefined) room.ballInHand = data.ballInHand;
            if (data.p1Group) room.p1Group = data.p1Group;
            if (data.p2Group) room.p2Group = data.p2Group;
            if (data.breakShot !== undefined) room.breakShot = data.breakShot;
            if (data.rackOver !== undefined) room.rackOver = data.rackOver;
            if (data.winningPlayer !== undefined) room.winningPlayer = data.winningPlayer;
            if (data.ruleMessage) room.ruleMessage = data.ruleMessage;
            broadcastToRoom(room, ws, data);
          }
          break;
        }

        case 'shoot': {
          if (client.roomId && rooms.has(client.roomId)) {
            const room = rooms.get(client.roomId);
            if (data.balls) room.lastBalls = data.balls;
            if (data.cueBall) room.lastCueBall = data.cueBall;
            broadcastToRoom(room, ws, data);
          }
          break;
        }

        case 'ball_in_hand': {
          if (client.roomId && rooms.has(client.roomId)) {
            const room = rooms.get(client.roomId);
            if (data.nx !== undefined && data.ny !== undefined) {
              room.lastCueBall = { nx: data.nx, ny: data.ny, sunk: false };
            }
            if (data.placed !== undefined) {
              room.ballInHand = !data.placed;
            }
            broadcastToRoom(room, ws, data);
          }
          break;
        }

        case 'request_sync_state': {
          if (client.roomId && rooms.has(client.roomId)) {
            const room = rooms.get(client.roomId);
            broadcastToRoom(room, ws, data);
          }
          break;
        }

        // 9. Relay các gói tin điều khiển
        case 'aim':
        case 'spin':
        case 'shoot':
        case 'ball_in_hand':
        case 'restart':
        case 'player_info':
        case 'chat': {
          if (client.roomId && rooms.has(client.roomId)) {
            const room = rooms.get(client.roomId);
            broadcastToRoom(room, ws, data);
          }
          break;
        }
      }
    } catch (e) {
      console.error('Lỗi phân tích cú pháp packet:', e);
    }
  });

  ws.on('close', () => {
    handleClientDisconnect(ws);
    const idx = matchmakingQueue.indexOf(ws);
    if (idx !== -1) matchmakingQueue.splice(idx, 1);
    const tIdx = tournamentQueue.indexOf(ws);
    if (tIdx !== -1) tournamentQueue.splice(tIdx, 1);
    clients.delete(ws);
    console.log(`[-] Client ngắt kết nối: ${clientId} (Còn: ${clients.size})`);
  });

  ws.on('error', (err) => {
    console.error(`Client ${clientId} error:`, err);
  });
});

function handleClientDisconnect(ws) {
  const client = clients.get(ws);
  if (!client || !client.roomId) return;

  const room = rooms.get(client.roomId);
  if (!room) return;

  if (room.state === 'playing') {
    const isP1 = ws === room.p1;
    if (isP1) {
      room.p1 = null;
    } else {
      room.p2 = null;
    }
    const targetWs = isP1 ? room.p2 : room.p1;
    if (targetWs) {
      sendJson(targetWs, {
        type: 'opponent_disconnected',
        message: 'Đối thủ bị mất kết nối tạm thời! Trận đấu vẫn diễn ra theo thời gian thực.',
        graceSeconds: 180
      });
    }
    console.log(`[Disconnect] Client ${client.name} ngắt kết nối. Phòng #${room.id} tiếp tục chạy theo thời gian thực (chờ reconnect 180s)...`);

    if (room.disconnectTimer) clearTimeout(room.disconnectTimer);
    room.disconnectTimer = setTimeout(() => {
      if (rooms.has(room.id)) {
        const activeOpp = isP1 ? room.p2 : room.p1;
        if (activeOpp) {
          sendJson(activeOpp, {
            type: 'opponent_forfeited',
            winnerRole: isP1 ? 'p2' : 'p1',
            message: 'Đối thủ không kết nối lại sau 180s. Bạn giành chiến thắng!'
          });
        }
        rooms.delete(room.id);
        console.log(`[Timeout] Đã đóng phòng #${room.id} do đối thủ không quay lại sau 180s.`);
      }
    }, 180000);
  } else {
    // Phòng ở sảnh chờ
    if (room.p1 && room.p1 !== ws) {
      sendJson(room.p1, { type: 'opponent_left', message: 'Đối thủ đã thoát phòng' });
    }
    rooms.delete(client.roomId);
  }
}

// Heartbeat ping/pong mỗi 30 giây để giữ kết nối không bị nhà mạng đóng
const heartbeatInterval = setInterval(() => {
  wss.clients.forEach((ws) => {
    const client = clients.get(ws);
    if (!client) return;

    if (client.isAlive === false) {
      console.log(`[Heartbeat] Terminate client không phản hồi: ${client.id}`);
      return ws.terminate();
    }

    client.isAlive = false;
    ws.ping();
  });
}, 30000);

wss.on('close', () => {
  clearInterval(heartbeatInterval);
});

server.listen(PORT, () => {
  console.log(`====================================================`);
  console.log(`🎱 BIDA WEBSOCKET SERVER ĐANG CHẠY TRÊN CỔNG: ${PORT}`);
  console.log(`   - HTTP Health Check: http://localhost:${PORT}/health`);
  console.log(`   - WebSocket Endpoint: ws://localhost:${PORT}`);
  console.log(`====================================================`);
});
