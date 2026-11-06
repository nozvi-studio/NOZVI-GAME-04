import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/local_multiplayer_service.dart';
import '../services/language_service.dart';

class LocalMultiplayerDialog extends StatefulWidget {
  final VoidCallback onConnected;

  const LocalMultiplayerDialog({super.key, required this.onConnected});

  @override
  State<LocalMultiplayerDialog> createState() => _LocalMultiplayerDialogState();
}

class _LocalMultiplayerDialogState extends State<LocalMultiplayerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _ipController = TextEditingController();
  final FocusNode _ipFocusNode = FocusNode();
  bool _isActionInProgress = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    LocalMultiplayerService.instance.getLocalIpAddress().then((_) {
      if (mounted) setState(() {});
    });

    _tabController.addListener(() {
      if (_tabController.index == 1) {
        LocalMultiplayerService.instance.startDiscovery();
      } else {
        LocalMultiplayerService.instance.stopDiscovery();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ipController.dispose();
    _ipFocusNode.dispose();
    LocalMultiplayerService.instance.stopDiscovery();
    super.dispose();
  }

  Future<void> _startHosting() async {
    setState(() {
      _isActionInProgress = true;
      _errorMessage = null;
    });

    final success = await LocalMultiplayerService.instance.startHosting();
    if (!mounted) return;

    setState(() {
      _isActionInProgress = false;
    });

    if (!success) {
      setState(() {
        _errorMessage = 'cant_start_hosting'.tr;
      });
    }
  }

  Future<void> _connectToHost([String? targetIp]) async {
    final ip = (targetIp ?? _ipController.text).trim();
    if (ip.isEmpty) {
      setState(() {
        _errorMessage = 'enter_host_ip'.tr;
      });
      return;
    }

    setState(() {
      _isActionInProgress = true;
      _errorMessage = null;
    });

    final success = await LocalMultiplayerService.instance.connectToHost(ip);
    if (!mounted) return;

    setState(() {
      _isActionInProgress = false;
    });

    if (success) {
      Navigator.of(context).pop();
      widget.onConnected();
    } else {
      setState(() {
        _errorMessage = 'cant_connect_ip'.tr.replaceAll('{ip}', ip);
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      String text = data.text!.trim().replaceAll(',', '.').replaceAll(' ', '');
      if (text.contains(':')) {
        text = text.split(':').first;
      }
      setState(() {
        _ipController.text = text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListenableBuilder(
        listenable: Listenable.merge([
          LocalMultiplayerService.instance,
          LanguageService.instance,
        ]),
        builder: (context, _) {
          final service = LocalMultiplayerService.instance;
          final screenSize = MediaQuery.of(context).size;
          final screenHeight = screenSize.height;
          final screenWidth = screenSize.width;

          // Nếu máy Host đã có đối thủ kết nối -> tự động vào trận
          if (service.isConnected && service.isHost) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.of(context).pop();
                widget.onConnected();
              }
            });
          }

          // Chiều cao tối ưu trên điện thoại ngang: không bao giờ tràn màn hình
          final dialogMaxHeight = math.min(screenHeight * 0.92, 520.0);
          final dialogMaxWidth = math.min(screenWidth * 0.94, 680.0);

          return Container(
            constraints: BoxConstraints(
              maxWidth: dialogMaxWidth,
              maxHeight: dialogMaxHeight,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D1B2A), Color(0xFF1B2838), Color(0xFF09131D)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF1E88E5).withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black87, blurRadius: 20, offset: Offset(0, 4)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- HEADER ---
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    color: const Color(0xFF070F18),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi, color: Color(0xFF42A5F5), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'local_multiplayer_title'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            service.disconnect();
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  // TAB BAR COMPACT
                  Container(
                    height: 34,
                    color: Colors.black26,
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xFF00E5FF),
                      indicatorWeight: 2.5,
                      labelColor: const Color(0xFF00E5FF),
                      unselectedLabelColor: Colors.white54,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                      tabs: [
                        Tab(icon: const Icon(Icons.wifi_tethering, size: 14), text: 'create_room_host'.tr),
                        Tab(icon: const Icon(Icons.login, size: 14), text: 'join_room_client'.tr),
                      ],
                    ),
                  ),

                  // TAB CONTENT
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildHostTab(service),
                        _buildJoinTab(service),
                      ],
                    ),
                  ),

                  // THÔNG BÁO LỖI (NẾU CÓ)
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      color: Colors.red.shade900.withValues(alpha: 0.9),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white, size: 13),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // =========================================================================
  // TAB TẠO PHÒNG (HOST) - BỐ CỤC 2 CỘT NGANG VỪA VẶN MOBILE LANDSCAPE
  // =========================================================================
  Widget _buildHostTab(LocalMultiplayerService service) {
    final isHosting = service.connectionState == MultiplayerConnectionState.hosting;
    final myIp = service.localIp ?? 'loading_ip'.tr;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Cột trái: Thông tin IP máy & Mẹo kết nối
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'this_device_ip'.tr,
                              style: const TextStyle(color: Colors.white54, fontSize: 9.5, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              myIp,
                              style: const TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'refresh_ip'.tr,
                        icon: const Icon(Icons.refresh, color: Color(0xFF00E5FF), size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () async {
                          await service.getLocalIpAddress();
                          if (mounted) setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A2F).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tips_and_updates, color: Color(0xFF00E676), size: 13),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'wifi_tip'.tr,
                          style: const TextStyle(color: Colors.white70, fontSize: 9, height: 1.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Cột phải: NÚT MỞ PHÒNG NỔI BẬT KHÔNG BAO GIỜ BỊ ẨN / TRÀN
          Expanded(
            flex: 5,
            child: isHosting
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E5FF)),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'broadcasting_room'.tr,
                              style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 34,
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => service.disconnect(),
                            icon: const Icon(Icons.close, size: 14),
                            label: Text('cancel_room'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 44,
                        child: FilledButton.icon(
                          onPressed: _isActionInProgress ? null : _startHosting,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF00E5FF),
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 3,
                          ),
                          icon: const Icon(Icons.wifi_tethering, size: 18),
                          label: Text(
                            'open_room_wait_opp'.tr,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'opp_auto_discover'.tr,
                        style: const TextStyle(color: Colors.white54, fontSize: 9.5),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB VÀO PHÒNG (JOIN) - 2 CỘT TỰ ĐỘNG PHÁT HIỆN & NHẬP THỦ CÔNG
  // =========================================================================
  Widget _buildJoinTab(LocalMultiplayerService service) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Cột trái: Quét phòng tự động trong WiFi (UDP Broadcast)
          Expanded(
            flex: 5,
            child: ValueListenableBuilder<List<DiscoveredRoom>>(
              valueListenable: service.discoveredRooms,
              builder: (context, rooms, _) {
                if (rooms.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E5FF)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'scanning_wifi_rooms'.tr,
                          style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'room_appear_here'.tr,
                          style: const TextStyle(color: Colors.white38, fontSize: 9),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final room = rooms.first;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00E676), width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.meeting_room, color: Color(0xFF00E676), size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              room.hostName,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Text('IP: ${room.ip}', style: const TextStyle(color: Color(0xFF00E676), fontSize: 10.5)),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 32,
                        child: FilledButton(
                          onPressed: _isActionInProgress ? null : () => _connectToHost(room.ip),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF00E676),
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text('join_table_now'.tr, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 12),

          // Cột phải: Nhập IP thủ công với bàn phím số tối ưu
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'manual_ip_entry'.tr,
                  style: const TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: TextField(
                          controller: _ipController,
                          focusNode: _ipFocusNode,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _connectToHost(),
                          autocorrect: false,
                          enableSuggestions: false,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: '192.168.1.15',
                            hintStyle: const TextStyle(color: Colors.white30, fontSize: 11.5),
                            filled: true,
                            fillColor: Colors.black38,
                            prefixIcon: const Icon(Icons.settings_ethernet, color: Color(0xFF00E5FF), size: 15),
                            prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      height: 36,
                      child: OutlinedButton(
                        onPressed: _pasteFromClipboard,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00E5FF),
                          side: const BorderSide(color: Color(0xFF00E5FF)),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: Text('paste'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 36,
                  child: FilledButton.icon(
                    onPressed: _isActionInProgress ? null : () => _connectToHost(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: EdgeInsets.zero,
                    ),
                    icon: _isActionInProgress
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87),
                          )
                        : const Icon(Icons.link, size: 15),
                    label: Text('connect_to_room'.tr, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
