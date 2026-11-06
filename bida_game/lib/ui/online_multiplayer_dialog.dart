import 'package:flutter/material.dart';
import '../services/online_multiplayer_service.dart';
import '../services/language_service.dart';

class OnlineMultiplayerDialog extends StatefulWidget {
  final void Function(String roomId, bool isHost) onConnected;

  const OnlineMultiplayerDialog({super.key, required this.onConnected});

  @override
  State<OnlineMultiplayerDialog> createState() => _OnlineMultiplayerDialogState();
}

class _OnlineMultiplayerDialogState extends State<OnlineMultiplayerDialog> {
  late final TextEditingController _serverController;
  final TextEditingController _roomPinController = TextEditingController();
  bool _isConnecting = false;
  bool _showAdvancedSettings = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final service = OnlineMultiplayerService.instance;
    // Luôn ưu tiên cổng dành riêng cho điện thoại thật kết nối qua Wi-Fi LAN
    final defaultUrl = service.lastConnectedUrl ?? OnlineMultiplayerService.realPhoneDefaultUrl;
    _serverController = TextEditingController(text: defaultUrl);

    service.onMatchStart = (roomId, isHost) {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onConnected(roomId, isHost);
      }
    };

    // Tự động kết nối sẵn cổng điện thoại thật ngay khi ấn vào chế độ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureConnected();
    });
  }

  @override
  void dispose() {
    _serverController.dispose();
    _roomPinController.dispose();
    super.dispose();
  }

  Future<void> _ensureConnected() async {
    final service = OnlineMultiplayerService.instance;
    if (service.isConnected) return;

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    final success = await service.connect(url: _serverController.text.trim());
    if (mounted) {
      setState(() {
        _isConnecting = false;
        if (!success) {
          _errorMessage = 'cant_connect_ws_error'.tr;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 700;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 32,
        vertical: isMobile ? 12 : 24,
      ),
      child: Container(
        width: 720,
        decoration: BoxDecoration(
          color: const Color(0xFF0F1E19),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF00B0FF), width: 1.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.85),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ListenableBuilder(
          listenable: Listenable.merge([
            OnlineMultiplayerService.instance,
            LanguageService.instance,
          ]),
          builder: (context, _) {
            final service = OnlineMultiplayerService.instance;

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Header
                  _buildHeader(context),

                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Server URL Configuration
                        _buildServerConfig(service),
                        const SizedBox(height: 14),

                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade900.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.redAccent),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],

                        // Main Action Cards (3 Chế Độ: Ghép Tự Động, Tạo Phòng PIN, Nhập PIN)
                        if (service.connectionState == OnlineConnectionState.findingMatch) ...[
                          _buildMatchmakingWaiting(service),
                        ] else if (service.connectionState == OnlineConnectionState.waitingInRoom) ...[
                          _buildWaitingInRoom(service),
                        ] else ...[
                          if (service.currentRoomId != null || service.isInMatch) ...[
                            _buildActiveMatchCard(service),
                            const SizedBox(height: 14),
                          ],
                          _buildOnlineModes(service),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF142B24),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(bottom: BorderSide(color: Color(0xFF00B0FF), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF00B0FF), Color(0xFF0081CB)],
              ),
            ),
            child: const Icon(Icons.public, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'online_multiplayer_title'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  'online_multiplayer_sub'.tr,
                  style: const TextStyle(color: Color(0xFF80D8FF), fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white70),
            tooltip: 'close'.tr,
          ),
        ],
      ),
    );
  }

  Widget _buildServerConfig(OnlineMultiplayerService service) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: service.isConnected ? const Color(0xFF00E676).withValues(alpha: 0.6) : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: service.isConnected
                      ? const Color(0xFF00E676)
                      : (_isConnecting ? Colors.orangeAccent : Colors.redAccent),
                  boxShadow: [
                    BoxShadow(
                      color: (service.isConnected ? const Color(0xFF00E676) : Colors.orangeAccent)
                          .withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  service.isConnected
                      ? 'server_connected_ready'.tr.replaceAll('{url}', _serverController.text.trim())
                      : (_isConnecting ? 'server_connecting'.tr : 'server_not_connected'.tr),
                  style: TextStyle(
                    color: service.isConnected ? const Color(0xFF00E676) : Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () => setState(() => _showAdvancedSettings = !_showAdvancedSettings),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showAdvancedSettings ? Icons.expand_less : Icons.settings_ethernet,
                        color: Colors.white54,
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _showAdvancedSettings ? 'close'.tr : 'change_port'.tr,
                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_showAdvancedSettings) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: TextField(
                      controller: _serverController,
                      style: const TextStyle(color: Colors.white, fontSize: 11.5),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 6),
                        border: InputBorder.none,
                        hintText: 'server_address_hint'.tr,
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isConnecting
                      ? null
                      : () async {
                          if (service.isConnected) {
                            await service.disconnect();
                          } else {
                            await _ensureConnected();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: service.isConnected ? const Color(0xFFC62828) : const Color(0xFF00B0FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isConnecting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          service.isConnected ? 'disconnect_btn'.tr : 'connect_btn'.tr,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'quick_presets'.tr,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
                _buildPresetChip('Wi-Fi LAN (192.168.1.22)', 'ws://192.168.1.22:8080'),
                _buildPresetChip('PC (127.0.0.1)', 'ws://127.0.0.1:8080'),
                _buildPresetChip('Android (10.0.2.2)', 'ws://10.0.2.2:8080'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, String url) {
    final isSelected = _serverController.text.trim() == url;
    return InkWell(
      onTap: () {
        setState(() {
          _serverController.text = url;
          _errorMessage = null;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00B0FF).withValues(alpha: 0.25) : Colors.white10,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF00B0FF) : Colors.white24,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF80D8FF) : Colors.white70,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveMatchCard(OnlineMultiplayerService service) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00305A), Color(0xFF004D8C), Color(0xFF0068AA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00E5FF), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B0FF).withValues(alpha: 0.35),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.redAccent.shade700,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fiber_manual_record, color: Colors.white, size: 10),
                    SizedBox(width: 4),
                    Text(
                      'REAL-TIME',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'active_match_in_progress'.tr.replaceAll('{room}', service.currentRoomId ?? ""),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'active_match_desc'.tr
                .replaceAll('{opp}', service.opponentName)
                .replaceAll('{lvl}', '${service.opponentLevel}'),
            style: const TextStyle(color: Color(0xFFB3E5FC), fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onConnected(service.currentRoomId ?? '', service.isHost);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: const Color(0xFF003314),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 3,
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: Text(
                    'resume_match_now'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  service.forfeitMatch();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent.shade100,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.close, size: 16),
                label: Text('forfeit_match'.tr, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineModes(OnlineMultiplayerService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- ĐẤU ONLINE 1V1 ---
        // Mode 1: Ghép Trận Nhanh (Quick Match)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF42A5F5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.flash_on, color: Color(0xFFFFD54F), size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'quick_match_1v1'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'quick_match_sub'.tr,
                      style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _ensureConnected();
                  if (service.isConnected) {
                    service.startQuickMatch();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD54F),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('find_match'.tr, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Mode 2 & 3: Tạo Phòng 1v1 PIN & Nhập Mã PIN 1v1
        Row(
          children: [
            // Tạo Phòng PIN (Host)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF132F24),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF00E676)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.add_circle, color: Color(0xFF00E676), size: 26),
                    const SizedBox(height: 4),
                    Text(
                      'create_room_1v1'.tr,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'pin_code_for_friends'.tr,
                      style: const TextStyle(color: Colors.white60, fontSize: 9.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        await _ensureConnected();
                        if (service.isConnected) {
                          service.createRoom();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('open_room'.tr, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10.5)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Nhập Mã PIN (Join)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2B36),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF00B0FF)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.login, color: Color(0xFF00B0FF), size: 26),
                    const SizedBox(height: 4),
                    Text(
                      'enter_room_pin_title'.tr,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: TextField(
                        controller: _roomPinController,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'pin_hint'.tr,
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ElevatedButton(
                      onPressed: () async {
                        final pin = _roomPinController.text.trim();
                        if (pin.isEmpty) return;
                        await _ensureConnected();
                        if (service.isConnected) {
                          service.joinRoom(pin);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B0FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('join_room_btn'.tr, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10.5)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMatchmakingWaiting(OnlineMultiplayerService service) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF00B0FF),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              color: Color(0xFF00B0FF),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'searching_worthy_opponent'.tr,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${_serverController.text.trim()} • Online Matchmaking',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              service.cancelQuickMatch();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
            ),
            child: Text('cancel_search'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingInRoom(OnlineMultiplayerService service) {
    final roomId = service.currentRoomId ?? '------';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF132F24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF00E676),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            'room_ready_title'.tr,
            style: const TextStyle(
              color: Color(0xFF00E676),
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'share_pin_with_opponent'.tr,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
            ),
            child: Text(
              roomId,
              style: const TextStyle(
                color: Color(0xFFFFD54F),
                fontWeight: FontWeight.w900,
                fontSize: 28,
                letterSpacing: 4.0,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(color: Colors.tealAccent, strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(
                'waiting_for_opponent_pin'.tr,
                style: const TextStyle(color: Colors.tealAccent, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: () {
              service.disconnect();
            },
            child: Text('cancel_and_leave_room'.tr, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
