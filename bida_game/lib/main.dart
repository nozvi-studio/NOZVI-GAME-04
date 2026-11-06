import 'dart:math' as math;
import 'dart:async' as async;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart' hide Transform;
import 'package:forge2d/forge2d.dart' as forge2d;

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'models/cue_model.dart';
import 'models/bot_stage_model.dart';
import 'models/daily_puzzle_model.dart';
import 'services/progression_service.dart';
import 'services/local_multiplayer_service.dart';
import 'services/auth_service.dart';
import 'ui/player_profile_bar.dart';
import 'ui/bot_stages_dialog.dart';
import 'ui/daily_puzzle_dialog.dart';
import 'ui/local_multiplayer_dialog.dart';
import 'ui/auth_screen.dart';
import 'ui/aim_ruler_slider.dart';
import 'ui/ball_3d_renderer.dart';
import 'services/audio_manager.dart';
import 'ui/combo_banner_overlay.dart';
import 'models/tournament_model.dart';
import 'services/online_multiplayer_service.dart';
// import 'ui/online_multiplayer_dialog.dart';
import 'models/legendary_trickshot_model.dart';
import 'ui/legendary_trickshot_dialog.dart';
import 'ui/billiard_vfx_component.dart';
import 'services/language_service.dart';
import 'ui/language_selector_dialog.dart';
import 'models/table_skin_model.dart';
import 'ui/table_skin_component.dart';
import 'ui/responsive_layout_helper.dart';

enum BallGroup { solids, stripes }

// Khởi tạo instance của game ở ngoài cùng để UI có thể lắng nghe trạng thái (Turn-base)
final BilliardGame gameInstance = BilliardGame();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  await ProgressionService.instance.init();
  await LanguageService.instance.init();
  try {
    await AuthService.instance.init();
    final hasNet = await AuthService.hasNetworkConnection();
    if (!hasNet && !AuthService.instance.isLoggedIn) {
      await AuthService.instance.loginAsGuest();
    }
  } catch (e) {
    debugPrint('AuthService initialization error: $e');
  }
  try {
    await AudioManager.instance.initialize();
  } catch (e) {
    debugPrint('AudioManager initialization error: $e');
  }
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(
    ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        return MaterialApp(
          key: ValueKey(LanguageService.instance.currentCode),
          locale: Locale(LanguageService.instance.currentCode),
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            return Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => AudioManager.instance.onUserInteraction(),
              child: child ?? const SizedBox.shrink(),
            );
          },
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0E1217),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00E676),
              secondary: Color(0xFF00B0FF),
              surface: Color(0xFF161B22),
              onSurface: Colors.white,
            ),
          ),
          home: const AuthGate(),
        );
      },
    ),
  );
}


/// Cổng kiểm tra đăng nhập: Phải đăng nhập mới được vào Main Menu
/// Khi không có wifi hay mạng, tự động vào account guest
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Giữ bảng đăng nhập hiển thị khi khởi động game
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        if (AuthService.instance.isLoggedIn) {
          return const BilliardHome();
        }
        return const AuthScreen();
      },
    );
  }
}

class BilliardHome extends StatefulWidget {
  const BilliardHome({super.key});

  @override
  State<BilliardHome> createState() => _BilliardHomeState();
}

class _BilliardHomeState extends State<BilliardHome> with WidgetsBindingObserver {
  bool showGame = false;
  bool hasStartedGameOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive) {
      gameInstance.onAppPaused();
      AudioManager.instance.pauseBgm();
    } else if (state == AppLifecycleState.resumed) {
      gameInstance.onAppResumed();
      AudioManager.instance.resumeBgm();
    }
  }

  void _startPlayerMatch() {
    hasStartedGameOnce = true;
    gameInstance.startPlayerMatch();
    setState(() => showGame = true);
  }

  void _startBotStage(BotStageModel stage) {
    hasStartedGameOnce = true;
    gameInstance.startBotStage(stage);
    setState(() => showGame = true);
  }

  void _startDailyPuzzle(DailyPuzzleModel puzzle) {
    hasStartedGameOnce = true;
    gameInstance.startDailyPuzzle(puzzle);
    setState(() => showGame = true);
  }

  void _startLegendaryTrickshot(LegendaryTrickshotModel shot) {
    hasStartedGameOnce = true;
    gameInstance.startLegendaryTrickshot(shot);
    setState(() => showGame = true);
  }

  void _startLocalMultiplayerMatch() {
    hasStartedGameOnce = true;
    gameInstance.startLocalMultiplayer();
    setState(() => showGame = true);
  }

  // void _startOnlineTournamentMatch(TournamentBracketStage stage, String roomId, bool isHost) {
  //   if (OnlineMultiplayerService.instance.currentRoomId == roomId &&
  //       gameInstance.isOnlineMultiplayer.value &&
  //       !gameInstance.rackOver) {
  //     _resumeActiveOnlineMatch();
  //     return;
  //   }
  //   gameInstance.startOnlineMultiplayer(
  //     roomId: roomId,
  //     isHost: isHost,
  //     tournamentStage: stage,
  //   );
  //   setState(() => showGame = true);
  // }

  // void _startOnlineMultiplayerMatch(String roomId, bool isHost) {
  //   if (OnlineMultiplayerService.instance.currentRoomId == roomId &&
  //       gameInstance.isOnlineMultiplayer.value &&
  //       !gameInstance.rackOver) {
  //     _resumeActiveOnlineMatch();
  //     return;
  void _confirmExitAndForfeitMatch() {
    if (!gameInstance.rackOver) {
      if (gameInstance.isOnlineMultiplayer.value) {
        OnlineMultiplayerService.instance.forfeitMatch();
        final myIdx = OnlineMultiplayerService.instance.isHost ? 1 : 2;
        gameInstance.declareLoss(myIdx);
      } else if (gameInstance.activeDailyPuzzle != null || gameInstance.activeLegendaryTrickshot != null) {
        gameInstance.winningPlayer = 2;
        gameInstance.rackOver = true;
        gameInstance.ruleMessage.value = 'forfeit_trickshot_exit'.tr;
        gameInstance.matchVersion.value++;
      } else {
        final myIdx = (gameInstance.isLocalMultiplayer.value && !LocalMultiplayerService.instance.isHost) ? 2 : 1;
        gameInstance.declareLoss(myIdx);
      }
    }
    setState(() => showGame = false);
  }

  void _requestExitToMenu(BuildContext context) {
    if (gameInstance.rackOver) {
      setState(() => showGame = false);
    } else {
      _showConfirmExitMatch(
        context,
        onHome: _confirmExitAndForfeitMatch,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (showGame) {
              _requestExitToMenu(context);
            }
          },
          child: Stack(
            children: [
              // 1. GAME SCREEN: Luôn duy trì trong cây Widget bằng Offstage sau khi ván đấu được kích hoạt
              // Nhờ đó, Flame GameLoop và Box2D tiếp tục chạy theo thời gian thực (real-time)
              // không bao giờ bị unmount, không bao giờ bị đứng game khi thoát ra menu chính.
              if (hasStartedGameOnce)
                Positioned.fill(
                  child: Offstage(
                    offstage: !showGame,
                    child: _buildGameScreen(
                      context,
                      onHome: () => _requestExitToMenu(context),
                    ),
                  ),
                ),

              // 2. MAIN MENU SCREEN: Hiển thị khi showGame == false
              if (!showGame)
                Positioned.fill(
                  child: Scaffold(
                    body: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0F1318), Color(0xFF161C24), Color(0xFF0A0D12)],
                        ),
                      ),
                      child: SafeArea(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final layout = ResponsiveLayoutHelper.of(context, constraints);
                            final isLandscape = constraints.maxWidth >= 540;
                            final compact = layout.isCompact;
                                                        final upscale = layout.upscaleFactor;

                            return Column(
                              children: [
                                // --- THANH TRẠNG THÁI TRÊN CÙNG (KHÔNG ĐÈ NỘI DUNG THẺ) ---
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: compact ? 12 : 20,
                                    vertical: compact ? 4 : 8,
                                  ),
                                  child: Row(
                                    children: [
                                      // Nút chọn ngôn ngữ nổi bật độc quyền ở Main Menu
                                      ListenableBuilder(
                                        listenable: LanguageService.instance,
                                        builder: (context, _) => InkWell(
                                          onTap: () => LanguageSelectorDialog.show(context),
                                          borderRadius: BorderRadius.circular(18),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: isLandscape ? 10 : 8,
                                              vertical: isLandscape ? 6 : 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0D1E18).withValues(alpha: 0.95),
                                              borderRadius: BorderRadius.circular(18),
                                              border: Border.all(
                                                color: const Color(0xFF00E5FF).withValues(alpha: 0.7),
                                                width: 1.5,
                                              ),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.black45,
                                                  blurRadius: 6,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  LanguageService.instance.currentLanguage.flag,
                                                  style: TextStyle(fontSize: isLandscape ? 16 : 14),
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  LanguageService.instance.currentLanguage.nativeName,
                                                  style: TextStyle(
                                                    color: const Color(0xFF00E5FF),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: isLandscape ? 12 : 11,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                                const SizedBox(width: 3),
                                                const Icon(Icons.arrow_drop_down, color: Color(0xFF00E5FF), size: 16),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Thanh thông tin người chơi LỚN, RÕ RÀNG, PHÙ HỢP MỌI LOẠI ĐIỆN THOẠI
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerRight,
                                            child: PlayerProfileBar(
                                              compact: !isLandscape,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),



                                // --- THẺ BIDA NỈ XANH VIỀN GỖ VÀNG CỔ ĐIỂN (CHUẨN MOBILE, KHÔNG TRÀN MÀN HÌNH) ---
                                Expanded(
                                  child: Center(
                                    child: SingleChildScrollView(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: compact ? 10 : 20,
                                        vertical: compact ? 4 : 10,
                                      ),
                                      child: Container(
                                        constraints: BoxConstraints(
                                          maxWidth: isLandscape
                                              ? math.min(constraints.maxWidth * 0.92, 860.0)
                                              : 440,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: compact ? 14 : 24,
                                          vertical: compact ? 12 : 22,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF11633F),
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(
                                            color: const Color(0xFFB77A35),
                                            width: compact ? 4.0 : 6.0,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black54,
                                              blurRadius: 20,
                                              offset: Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: isLandscape
                                            ? _buildLandscapeMenuContent(compact, upscale)
                                            : _buildPortraitMenuContent(compact, upscale),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }



  // /// BANNER THÔNG BÁO TRẬN ĐẤU ONLINE ĐANG CHẠY REAL-TIME
  // Widget _buildActiveOnlineMatchBanner({required bool compact}) {
  //   return ListenableBuilder(
  //     listenable: Listenable.merge([
  //       OnlineMultiplayerService.instance,
  //       gameInstance.matchVersion,
  //       gameInstance.isOnlineMultiplayer,
  //     ]),
  //     builder: (context, _) {
  //       final service = OnlineMultiplayerService.instance;
  //       final hasActive = (service.isInMatch || service.currentRoomId != null) &&
  //           gameInstance.isOnlineMultiplayer.value &&
  //           !gameInstance.rackOver;
  //
  //       if (!hasActive) return const SizedBox.shrink();
  //
  //       return Padding(
  //         padding: EdgeInsets.symmetric(
  //           horizontal: compact ? 12 : 20,
  //           vertical: compact ? 3 : 5,
  //         ),
  //         child: Container(
  //           width: double.infinity,
  //           constraints: const BoxConstraints(maxWidth: 720),
  //           padding: EdgeInsets.symmetric(
  //             horizontal: compact ? 12 : 16,
  //             vertical: compact ? 6 : 8,
  //           ),
  //           decoration: BoxDecoration(
  //             gradient: const LinearGradient(
  //               colors: [Color(0xFF003366), Color(0xFF004B8D), Color(0xFF0072BA)],
  //             ),
  //             borderRadius: BorderRadius.circular(12),
  //             border: Border.all(color: const Color(0xFF00E5FF), width: 1.6),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: const Color(0xFF00B0FF).withValues(alpha: 0.4),
  //                 blurRadius: 10,
  //                 spreadRadius: 1,
  //               ),
  //             ],
  //           ),
  //           child: Row(
  //             children: [
  //               // Nhãn REAL-TIME nhấp nháy
  //               Container(
  //                 padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
  //                 decoration: BoxDecoration(
  //                   color: Colors.redAccent.shade700,
  //                   borderRadius: BorderRadius.circular(6),
  //                   boxShadow: const [
  //                     BoxShadow(color: Colors.redAccent, blurRadius: 6),
  //                   ],
  //                 ),
  //                 child: const Row(
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: [
  //                     Icon(Icons.fiber_manual_record, color: Colors.white, size: 10),
  //                     SizedBox(width: 4),
  //                     Text(
  //                       'REAL-TIME',
  //                       style: TextStyle(
  //                         color: Colors.white,
  //                         fontSize: 9.5,
  //                         fontWeight: FontWeight.w900,
  //                         letterSpacing: 0.8,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //               SizedBox(width: compact ? 8 : 12),
  //               Expanded(
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: [
  //                     FittedBox(
  //                       fit: BoxFit.scaleDown,
  //                       alignment: Alignment.centerLeft,
  //                       child: Text(
  //                         'Trận đấu Online #${service.currentRoomId ?? ""} đang diễn ra',
  //                         style: TextStyle(
  //                           color: Colors.white,
  //                           fontSize: compact ? 12 : 13.5,
  //                           fontWeight: FontWeight.w800,
  //                         ),
  //                       ),
  //                     ),
  //                     Text(
  //                       'vs ${service.opponentName} (Lv.${service.opponentLevel}) • Bàn đấu vẫn tiếp tục!',
  //                       style: TextStyle(
  //                         color: const Color(0xFF80D8FF),
  //                         fontSize: compact ? 9.5 : 11,
  //                       ),
  //                       maxLines: 1,
  //                       overflow: TextOverflow.ellipsis,
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //               SizedBox(width: compact ? 6 : 10),
  //               FilledButton.icon(
  //                 onPressed: _resumeActiveOnlineMatch,
  //                 style: FilledButton.styleFrom(
  //                   backgroundColor: const Color(0xFF00E676),
  //                   foregroundColor: const Color(0xFF003314),
  //                   padding: EdgeInsets.symmetric(
  //                     horizontal: compact ? 10 : 14,
  //                     vertical: compact ? 6 : 8,
  //                   ),
  //                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  //                   elevation: 3,
  //                 ),
  //                 icon: const Icon(Icons.play_arrow_rounded, size: 18),
  //                 label: Text(
  //                   'QUAY LẠI TRẬN',
  //                   style: TextStyle(
  //                     fontSize: compact ? 11 : 12.5,
  //                     fontWeight: FontWeight.w900,
  //                   ),
  //                 ),
  //               ),
  //               SizedBox(width: compact ? 4 : 8),
  //               IconButton(
  //                 tooltip: 'Rời trận (Xử thua)',
  //                 icon: const Icon(Icons.close, color: Colors.white70),
  //                 iconSize: compact ? 18 : 20,
  //                 padding: EdgeInsets.zero,
  //                 constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
  //                 onPressed: () {
  //                   _showConfirmOnlineForfeit(context, onHome: () => setState(() {}));
  //                 },
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  /// NỘI DUNG GIAO DIỆN NGANG (LANDSCAPE - CHUẨN ĐIỆN THOẠI KHÔNG CUỘN & FLEXFI UPSCALE)
  Widget _buildLandscapeMenuContent(bool compact, [double upscaleFactor = 1.0]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Cột Trái: Logo Bi 8 + Tên Game + Subtitle
        SizedBox(
          width: (compact ? 190.0 : 225.0) * upscaleFactor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: (compact ? 52.0 : 68.0) * upscaleFactor,
                height: (compact ? 52.0 : 68.0) * upscaleFactor,
                padding: EdgeInsets.all(5 * upscaleFactor),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                  border: Border.all(color: Colors.white70, width: 2 * upscaleFactor),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 10),
                  ],
                ),
                child: Image.asset('assets/images/ball_8.png'),
              ),
              SizedBox(height: (compact ? 6.0 : 10.0) * upscaleFactor),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '8 POOL BILLIARDS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: (compact ? 18.0 : 22.0) * upscaleFactor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8 * upscaleFactor,
                  ),
                ),
              ),
              SizedBox(height: 3 * upscaleFactor),
              Text(
                'choose_match'.tr,
                style: TextStyle(
                  color: const Color(0xFFFFD166),
                  fontSize: 10.5 * upscaleFactor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: (compact ? 12.0 : 20.0) * upscaleFactor),

        // Cột Phải: Các Nút chế độ xếp dạng Grid vừa vặn tuyệt đối
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hàng 1: P1 vs P2 & Đấu Mạng Local
              Row(
                children: [
                  Expanded(
                    child: _buildMenuButton(
                      icon: Icons.people,
                      label: 'p1_vs_p2'.tr,
                      detail: 'p1_vs_p2_desc'.tr,
                      background: const Color(0xFF1D4ED8),
                      onPressed: _startPlayerMatch,
                      compact: compact,
                      upscaleFactor: upscaleFactor,
                    ),
                  ),
                  SizedBox(width: (compact ? 8.0 : 12.0) * upscaleFactor),
                  Expanded(
                    child: _buildMenuButton(
                      icon: Icons.wifi_tethering,
                      label: 'local_wifi'.tr,
                      detail: 'local_wifi_desc'.tr,
                      background: const Color(0xFF00897B),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => LocalMultiplayerDialog(
                            onConnected: _startLocalMultiplayerMatch,
                          ),
                        );
                      },
                      compact: compact,
                      upscaleFactor: upscaleFactor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: (compact ? 6.0 : 8.0) * upscaleFactor),
              // Hàng 2: 10 Ải Thử Thách Bot & Thế Bi Hàng Ngày
              Row(
                children: [
                  Expanded(
                    child: _buildMenuButton(
                      icon: Icons.military_tech,
                      label: 'bot_stages'.tr,
                      detail: 'bot_stages_desc'.tr,
                      background: const Color(0xFFE65100),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => BotStagesDialog(
                            onSelectStage: _startBotStage,
                          ),
                        );
                      },
                      compact: compact,
                      upscaleFactor: upscaleFactor,
                    ),
                  ),
                  SizedBox(width: (compact ? 8.0 : 12.0) * upscaleFactor),
                  Expanded(
                    child: _buildMenuButton(
                      icon: Icons.event_note,
                      label: 'daily_puzzle'.tr,
                      detail: 'daily_puzzle_desc'.tr,
                      background: const Color(0xFF7B1FA2),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => DailyPuzzleDialog(
                            onStartPuzzle: _startDailyPuzzle,
                          ),
                        );
                      },
                      compact: compact,
                      upscaleFactor: upscaleFactor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: (compact ? 6.0 : 8.0) * upscaleFactor),
              // Hàng 3: Thế Đánh Huyền Thoại (Nổi Bật Toàn Chiều Ngang)
              _buildMenuButton(
                icon: Icons.auto_awesome,
                label: '⭐ ${'legendary_trickshot'.tr.toUpperCase()} ${'legendary_trickshot_count_badge'.tr}',
                detail: 'legendary_trickshot_desc'.tr,
                background: const Color(0xFFB71C1C),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => LegendaryTrickshotDialog(
                      onSelectTrickshot: _startLegendaryTrickshot,
                    ),
                  );
                },
                compact: compact,
                upscaleFactor: upscaleFactor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// NỘI DUNG GIAO DIỆN DỌC (PORTRAIT - FLEXFI UPSCALE)
  Widget _buildPortraitMenuContent(bool compact, [double upscaleFactor = 1.0]) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: (compact ? 52.0 : 64.0) * upscaleFactor,
          height: (compact ? 52.0 : 64.0) * upscaleFactor,
          padding: EdgeInsets.all(5 * upscaleFactor),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
            border: Border.all(color: Colors.white70, width: 2 * upscaleFactor),
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 10),
            ],
          ),
          child: Image.asset('assets/images/ball_8.png'),
        ),
        SizedBox(height: 8 * upscaleFactor),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '8 POOL BILLIARDS',
            style: TextStyle(
              color: Colors.white,
              fontSize: (compact ? 18.0 : 22.0) * upscaleFactor,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
        ),
        SizedBox(height: 2 * upscaleFactor),
        Text(
          'choose_match'.tr,
          style: TextStyle(
            color: const Color(0xFFFFD166),
            fontSize: (compact ? 10.0 : 11.5) * upscaleFactor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: (compact ? 8.0 : 12.0) * upscaleFactor),
        _buildMenuButton(
          icon: Icons.auto_awesome,
          label: '⭐ ${'legendary_trickshot'.tr.toUpperCase()} ${'legendary_trickshot_count_badge'.tr}',
          detail: 'legendary_trickshot_desc'.tr,
          background: const Color(0xFFB71C1C),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => LegendaryTrickshotDialog(
                onSelectTrickshot: _startLegendaryTrickshot,
              ),
            );
          },
          compact: compact,
          upscaleFactor: upscaleFactor,
        ),
        SizedBox(height: (compact ? 6.0 : 8.0) * upscaleFactor),
        _buildMenuButton(
          icon: Icons.people,
          label: 'p1_vs_p2'.tr,
          detail: 'p1_vs_p2_desc'.tr,
          background: const Color(0xFF1D4ED8),
          onPressed: _startPlayerMatch,
          compact: compact,
          upscaleFactor: upscaleFactor,
        ),
        SizedBox(height: (compact ? 6.0 : 8.0) * upscaleFactor),
        _buildMenuButton(
          icon: Icons.military_tech,
          label: 'bot_stages'.tr,
          detail: 'bot_stages_desc'.tr,
          background: const Color(0xFFE65100),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => BotStagesDialog(
                onSelectStage: _startBotStage,
              ),
            );
          },
          compact: compact,
          upscaleFactor: upscaleFactor,
        ),
        SizedBox(height: (compact ? 6.0 : 8.0) * upscaleFactor),
        _buildMenuButton(
          icon: Icons.event_note,
          label: 'daily_puzzle'.tr,
          detail: 'daily_puzzle_desc'.tr,
          background: const Color(0xFF7B1FA2),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => DailyPuzzleDialog(
                onStartPuzzle: _startDailyPuzzle,
              ),
            );
          },
          compact: compact,
          upscaleFactor: upscaleFactor,
        ),
        SizedBox(height: (compact ? 6.0 : 8.0) * upscaleFactor),
        _buildMenuButton(
          icon: Icons.wifi_tethering,
          label: 'local_wifi'.tr,
          detail: 'local_wifi_desc'.tr,
          background: const Color(0xFF00897B),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => LocalMultiplayerDialog(
                onConnected: _startLocalMultiplayerMatch,
              ),
            );
          },
          compact: compact,
          upscaleFactor: upscaleFactor,
        ),
      ],
    );
  }
}

/// Nút menu 4 màu phong cách cổ điển, co giãn tối ưu cho Mobile & Flexfi Upscale
Widget _buildMenuButton({
  required IconData icon,
  required String label,
  required String detail,
  required Color background,
  required VoidCallback onPressed,
  bool compact = false,
  double upscaleFactor = 1.0,
}) {
  return SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: (compact ? 10.0 : 14.0) * upscaleFactor,
          vertical: (compact ? 8.0 : 12.0) * upscaleFactor,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10 * upscaleFactor)),
        elevation: 3,
      ),
      child: Row(
        children: [
          Icon(icon, size: (compact ? 22.0 : 26.0) * upscaleFactor),
          SizedBox(width: (compact ? 8.0 : 12.0) * upscaleFactor),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: (compact ? 13.0 : 15.0) * upscaleFactor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  detail,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: (compact ? 9.5 : 11.0) * upscaleFactor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: (compact ? 18.0 : 22.0) * upscaleFactor),
        ],
      ),
    ),
  );
}

Widget _buildGameScreen(BuildContext context, {required VoidCallback onHome}) {
  return Scaffold(
    backgroundColor: const Color(0xFF121212),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = ResponsiveLayoutHelper.of(context, constraints);
          final compactLayout = layout.isCompact;
          final ultraCompact = layout.isUltraCompact;
          final upscale = layout.upscaleFactor;

          final screenPadding = (layout.screenWidth * 0.012).clamp(
            ultraCompact ? 3.0 : 5.0,
            12.0 * upscale,
          );
          final topBarSpacing = ultraCompact ? 2.5 : (compactLayout ? 4.0 : 6.0);

          return Center(
            child: Padding(
              padding: EdgeInsets.all(screenPadding),
              child: Stack(
                children: [
                  Column(
                    children: [
                      _buildControlBar(
                        context,
                        compact: compactLayout,
                        ultraCompact: ultraCompact,
                        upscaleFactor: upscale,
                        onHome: onHome,
                      ),
                      SizedBox(height: topBarSpacing),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, rowConstraints) {
                            final rowWidth = rowConstraints.maxWidth;
                            final rowHeight = rowConstraints.maxHeight;

                            // 1. Surface Duo với bản lề vật lý dọc (Vertical Hinge / Dual Screen)
                            if (layout.isVerticalHinge && layout.hingeBounds != null) {
                              final hinge = layout.hingeBounds!;
                              final leftWidth = math.max(120.0, hinge.left - screenPadding);
                              final tableH = math.min(rowHeight, leftWidth / 2.0);
                              final tableW = tableH * 2.0;

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Màn hình trái: Bàn bida 2:1
                                  SizedBox(
                                    width: leftWidth,
                                    child: Center(
                                      child: SizedBox(
                                        width: tableW,
                                        height: tableH,
                                        child: _buildTableDecoratedBox(
                                          ultraCompact: ultraCompact,
                                          upscale: upscale,
                                          onHome: onHome,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Khoảng trống an toàn của bản lề vật lý
                                  SizedBox(width: math.max(10.0, hinge.width)),
                                  // Màn hình phải: Bàn điều khiển chuyên dụng
                                  Expanded(
                                    child: Center(
                                      child: SizedBox(
                                        height: tableH,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            _buildInteractivePowerControl(
                                              compact: compactLayout,
                                              ultraCompact: ultraCompact,
                                              upscale: upscale,
                                            ),
                                            const SizedBox(width: 14),
                                            _buildInteractiveRightControls(
                                              context,
                                              compact: compactLayout,
                                              ultraCompact: ultraCompact,
                                              upscale: upscale,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }

                            // 2. Chế độ Flexfi Upscale Thích Ứng Toàn Diện (Z Fold, Duo, Tablet, Mobile)
                            final metrics = layout.computeTableMetrics(
                              availableWidth: rowWidth,
                              availableHeight: rowHeight,
                            );

                            return Center(
                              child: SizedBox(
                                width: metrics.stationWidth,
                                height: metrics.stationHeight,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Cột trái: Thanh kéo lực cơ (Khớp hoàn hảo với chiều cao bàn)
                                    SizedBox(
                                      width: metrics.powerControlWidth,
                                      child: _buildInteractivePowerControl(
                                        compact: compactLayout,
                                        ultraCompact: ultraCompact,
                                        upscale: upscale,
                                      ),
                                    ),
                                    SizedBox(width: metrics.sideSpacing),

                                    // Cột giữa: Bàn bida hiển thị tối đa (2:1)
                                    SizedBox(
                                      width: metrics.tableWidth,
                                      height: metrics.tableHeight,
                                      child: _buildTableDecoratedBox(
                                        ultraCompact: ultraCompact,
                                        upscale: upscale,
                                        onHome: onHome,
                                      ),
                                    ),
                                    SizedBox(width: metrics.sideSpacing),

                                    // Cột phải: Thước ngắm & Áp-phê (Khớp hoàn hảo với chiều cao bàn)
                                    SizedBox(
                                      width: metrics.aimControlWidth,
                                      child: _buildInteractiveRightControls(
                                        context,
                                        compact: compactLayout,
                                        ultraCompact: ultraCompact,
                                        upscale: upscale,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

Widget _buildInteractivePowerControl({
  required bool compact,
  required bool ultraCompact,
  required double upscale,
}) {
  return ListenableBuilder(
    listenable: Listenable.merge([
      gameInstance.currentTurn,
      gameInstance.isLocalMultiplayer,
      gameInstance.isOnlineMultiplayer,
      gameInstance.isBotMode,
      gameInstance.isShotInProgressNotifier,
      gameInstance.isBallInHandNotifier,
      LocalMultiplayerService.instance,
      OnlineMultiplayerService.instance,
    ]),
    builder: (context, child) {
      final isMultiplayer = gameInstance.isLocalMultiplayer.value || gameInstance.isOnlineMultiplayer.value;
      final isBot = gameInstance.isBotMode.value;

      final bool isLocked;
      if (isMultiplayer) {
        isLocked = !gameInstance.isMyTurn || gameInstance.shotInProgress || gameInstance.ballInHand;
      } else if (isBot) {
        isLocked = (gameInstance.currentTurn.value == 2) || gameInstance.shotInProgress || gameInstance.ballInHand;
      } else {
        // Chế độ 1vs1 cùng 1 máy (Pass & Play):
        // Giữ chức năng khoá và làm mờ khi bi đang lăn (chờ đối thủ hết lượt cho công bằng)
        // hoặc khi đang trong trạng thái đặt bi cái (ballInHand).
        // Ngay sau khi đặt bi cái xuống bàn (ballInHand = false), lập tức mở khoá (100% sáng rõ) để đánh!
        isLocked = gameInstance.shotInProgress || gameInstance.ballInHand;
      }

      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) {
          if (gameInstance.ballInHand && !gameInstance.shotInProgress && gameInstance.canUserControl) {
            gameInstance.ballInHand = false;
            gameInstance.movingCueBall = false;
            gameInstance.cueBall.isAiming = true;
            gameInstance._updateAimVector(gameInstance.ballRadius * 2);
          }
        },
        child: IgnorePointer(
          ignoring: isLocked,
          child: AnimatedOpacity(
            opacity: isLocked ? 0.35 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: child,
          ),
        ),
      );
    },
    child: _buildPowerControl(
      compact: compact,
      ultraCompact: ultraCompact,
      upscaleFactor: upscale,
    ),
  );
}

Widget _buildInteractiveRightControls(
  BuildContext context, {
  required bool compact,
  required bool ultraCompact,
  required double upscale,
}) {
  return ListenableBuilder(
    listenable: Listenable.merge([
      gameInstance.currentTurn,
      gameInstance.isLocalMultiplayer,
      gameInstance.isOnlineMultiplayer,
      gameInstance.isBotMode,
      gameInstance.isShotInProgressNotifier,
      gameInstance.isBallInHandNotifier,
      LocalMultiplayerService.instance,
      OnlineMultiplayerService.instance,
    ]),
    builder: (context, child) {
      final isMultiplayer = gameInstance.isLocalMultiplayer.value || gameInstance.isOnlineMultiplayer.value;
      final isBot = gameInstance.isBotMode.value;

      final bool isLocked;
      if (isMultiplayer) {
        isLocked = !gameInstance.isMyTurn || gameInstance.shotInProgress || gameInstance.ballInHand;
      } else if (isBot) {
        isLocked = (gameInstance.currentTurn.value == 2) || gameInstance.shotInProgress || gameInstance.ballInHand;
      } else {
        isLocked = gameInstance.shotInProgress || gameInstance.ballInHand;
      }

      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) {
          if (gameInstance.ballInHand && !gameInstance.shotInProgress && gameInstance.canUserControl) {
            gameInstance.ballInHand = false;
            gameInstance.movingCueBall = false;
            gameInstance.cueBall.isAiming = true;
            gameInstance._updateAimVector(gameInstance.ballRadius * 2);
          }
        },
        child: IgnorePointer(
          ignoring: isLocked,
          child: AnimatedOpacity(
            opacity: isLocked ? 0.35 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: child,
          ),
        ),
      );
    },
    child: _buildRightSideControls(
      context,
      compact: compact,
      ultraCompact: ultraCompact,
      upscaleFactor: upscale,
    ),
  );
}

Widget _buildTableDecoratedBox({
  required bool ultraCompact,
  required double upscale,
  required VoidCallback onHome,
}) {
  return Stack(
    children: [
      DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            (ultraCompact ? 12 : 20) * upscale,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.65),
              blurRadius: 18 * upscale,
              spreadRadius: 2 * upscale,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            (ultraCompact ? 12 : 20) * upscale,
          ),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              gameInstance.currentTurn,
              gameInstance.isLocalMultiplayer,
              gameInstance.isOnlineMultiplayer,
              LocalMultiplayerService.instance,
              OnlineMultiplayerService.instance,
            ]),
            builder: (context, child) {
              final isMultiplayer = gameInstance.isLocalMultiplayer.value || gameInstance.isOnlineMultiplayer.value;
              final isLocked = isMultiplayer && !gameInstance.isMyTurn;
              return IgnorePointer(
                ignoring: isLocked,
                child: child,
              );
            },
            child: GameWidget(game: gameInstance),
          ),
        ),
      ),
      ComboBannerOverlay(
        comboNotifier: gameInstance.comboNotifier,
      ),
      _buildRackOverlay(onHome: onHome),
      _buildLockedOpponentBanner(ultraCompact: ultraCompact, upscale: upscale),
      _buildRuleMessageBanner(ultraCompact: ultraCompact, upscale: upscale),
    ],
  );
}

Widget _buildLockedOpponentBanner({
  required bool ultraCompact,
  required double upscale,
}) {
  return ListenableBuilder(
    listenable: Listenable.merge([
      gameInstance.currentTurn,
      gameInstance.isLocalMultiplayer,
      gameInstance.isOnlineMultiplayer,
      gameInstance.isBallInHandNotifier,
      LocalMultiplayerService.instance,
      OnlineMultiplayerService.instance,
      LanguageService.instance,
    ]),
    builder: (context, _) {
      final isMultiplayer = gameInstance.isLocalMultiplayer.value || gameInstance.isOnlineMultiplayer.value;
      if (!isMultiplayer ||
          gameInstance.isMyTurn ||
          gameInstance.rackOver) {
        return const SizedBox.shrink();
      }
      final oppName = gameInstance.isOnlineMultiplayer.value
          ? OnlineMultiplayerService.instance.opponentName
          : (LocalMultiplayerService.instance.opponentName.isNotEmpty
              ? LocalMultiplayerService.instance.opponentName
              : (LocalMultiplayerService.instance.isHost ? 'guest_p2'.tr : 'host_p1'.tr));

      final isBallInHand = gameInstance.ballInHand;
      return Positioned(
        top: (ultraCompact ? 8.0 : 14.0) * upscale,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: (ultraCompact ? 10.0 : 16.0) * upscale,
              vertical: (ultraCompact ? 4.0 : 7.0) * upscale,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xE6B91C1C), Color(0xE67F1D1D)],
              ),
              borderRadius: BorderRadius.circular(20 * upscale),
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.8),
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12 * upscale,
                  height: 12 * upscale,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 8 * upscale),
                Icon(Icons.lock, color: Colors.white, size: 14 * upscale),
                SizedBox(width: 4 * upscale),
                Text(
                  isBallInHand
                      ? (switch (LanguageService.instance.currentCode) {
                          'zh' => '对手 $oppName 正在自由摆球...',
                          'ja' => '相手 $oppName がボールを配置中...',
                          'ko' => '상대 $oppName 님이 공을 배치 중...',
                          'en' => 'OPPONENT $oppName IS PLACING BALL...',
                          _ => 'ĐỐI THỦ $oppName ĐANG ĐẶT BI...',
                        })
                      : (switch (LanguageService.instance.currentCode) {
                          'zh' => '轮到 $oppName（等待中...）',
                          'ja' => '$oppName のターン（待機中...）',
                          'ko' => '$oppName 님의 턴 (대기 중...)',
                          'en' => "$oppName'S TURN (WAITING...)",
                          _ => 'LƯỢT CỦA $oppName (ĐANG CHỜ...)',
                        }),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: (ultraCompact ? 10.0 : 12.0) * upscale,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Thanh thông báo popup mờ dần rồi biến mất:
/// Mỗi thông báo luật chơi/lượt đánh xuất hiện dạng popup nảy nhẹ, duy trì trong 2.0 giây
/// rồi mờ dần (fade-out) cho đến khi biến mất hoàn toàn, giải phóng tầm nhìn bàn đấu.
class RuleMessagePopupBanner extends StatefulWidget {
  final bool ultraCompact;
  final double upscale;

  const RuleMessagePopupBanner({
    super.key,
    required this.ultraCompact,
    required this.upscale,
  });

  @override
  State<RuleMessagePopupBanner> createState() => _RuleMessagePopupBannerState();
}

class _RuleMessagePopupBannerState extends State<RuleMessagePopupBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  async.Timer? _dismissTimer;
  String _currentMessage = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 550),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeInCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    gameInstance.ruleMessage.addListener(_onMessageChanged);
    gameInstance.matchVersion.addListener(_onMatchVersionChanged);
    LanguageService.instance.addListener(_onLanguageChanged);

    // Kích hoạt popup thông báo ban đầu khi vào trận
    if (!gameInstance.rackOver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _triggerMessagePopup();
        }
      });
    }
  }

  void _onMessageChanged() {
    if (!mounted) return;
    _triggerMessagePopup();
  }

  void _onMatchVersionChanged() {
    if (!mounted) return;
    if (gameInstance.rackOver) {
      _dismissTimer?.cancel();
      _controller.reset();
      if (_currentMessage.isNotEmpty) {
        setState(() {
          _currentMessage = '';
        });
      }
    }
  }

  void _onLanguageChanged() {
    if (!mounted) return;
    if (_controller.value > 0) {
      final newMsg = LanguageService.instance.localizeRuleMessage(gameInstance.ruleMessage.value);
      if (newMsg != _currentMessage) {
        setState(() {
          _currentMessage = newMsg;
        });
      }
    }
  }

  void _triggerMessagePopup() {
    if (gameInstance.rackOver) return;

    final raw = gameInstance.ruleMessage.value;
    final localized = LanguageService.instance.localizeRuleMessage(raw);

    _dismissTimer?.cancel();

    if (localized.isEmpty) {
      _controller.reset();
      setState(() {
        _currentMessage = '';
      });
      return;
    }

    setState(() {
      _currentMessage = localized;
    });

    // Xuất hiện dạng popup mượt mà
    _controller.forward(from: 0.0);

    // Duy trì trong 2.0s rồi mờ dần cho đến khi biến mất hoàn toàn
    _dismissTimer = async.Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    gameInstance.ruleMessage.removeListener(_onMessageChanged);
    gameInstance.matchVersion.removeListener(_onMatchVersionChanged);
    LanguageService.instance.removeListener(_onLanguageChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: (widget.ultraCompact ? 5.0 : 10.0) * widget.upscale,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          if (_controller.isDismissed || _currentMessage.isEmpty) {
            return const SizedBox.shrink();
          }
          return IgnorePointer(
            ignoring: _controller.value < 0.1,
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: child,
                  ),
                ),
              ),
            ),
          );
        },
        child: GestureDetector(
          onTap: () {
            // Cho phép người chơi chạm vào để ẩn ngay nếu muốn
            _dismissTimer?.cancel();
            _controller.reverse();
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(6 * widget.upscale),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: (widget.ultraCompact ? 8.0 : 12.0) * widget.upscale,
                vertical: (widget.ultraCompact ? 3.0 : 6.0) * widget.upscale,
              ),
              child: Text(
                _currentMessage,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: (widget.ultraCompact ? 10.5 : 12.5) * widget.upscale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildRuleMessageBanner({
  required bool ultraCompact,
  required double upscale,
}) {
  return RuleMessagePopupBanner(
    ultraCompact: ultraCompact,
    upscale: upscale,
  );
}

Widget _buildRightSideControls(
  BuildContext context, {
  bool compact = false,
  bool ultraCompact = false,
  double upscaleFactor = 1.0,
}) {
  return AimRulerSliderControl(
    game: gameInstance,
    compact: compact,
    ultraCompact: ultraCompact,
    upscaleFactor: upscaleFactor,
    onOpenSpinDialog: () {
      if (!gameInstance.canUserControl) return;
      _showCueSpinDialog(context);
    },
  );
}

Widget _buildPowerControl({
  bool compact = false,
  bool ultraCompact = false,
  double upscaleFactor = 1.0,
}) {
  final controlWidth = (ultraCompact ? 36.0 : (compact ? 44.0 : 52.0)) * upscaleFactor;
  return ListenableBuilder(
    listenable: Listenable.merge([
      gameInstance.currentTurn,
      ProgressionService.instance,
      gameInstance.player2CueId,
      gameInstance.player2CueLevel,
      OnlineMultiplayerService.instance,
      LocalMultiplayerService.instance,
      gameInstance.isBotMode,
    ]),
    builder: (context, _) {
      final (activeCue, activeLevel) = gameInstance.getActivePlayerCue();
      final playerTag = () {
        if (gameInstance.isOnlineMultiplayer.value || gameInstance.isLocalMultiplayer.value) {
          return gameInstance.isMyTurn ? 'P1' : 'P2';
        } else if (gameInstance.isBotMode.value) {
          return gameInstance.currentTurn.value == 2 ? 'BOT' : 'P1';
        } else {
          return gameInstance.currentTurn.value == 2 ? 'P2' : 'P1';
        }
      }();

      return Container(
        width: controlWidth,
        padding: EdgeInsets.symmetric(
          horizontal: (ultraCompact ? 2.5 : (compact ? 4 : 5)) * upscaleFactor,
          vertical: (ultraCompact ? 4 : (compact ? 6 : 8)) * upscaleFactor,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF14171C),
          borderRadius: BorderRadius.circular(ultraCompact ? 10 : 14),
          border: Border.all(
            color: activeCue.rarity.color.withValues(alpha: 0.65),
            width: 1.2,
          ),
          boxShadow: [
            const BoxShadow(
              color: Colors.black54,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
            BoxShadow(
              color: activeCue.auraColor.withValues(alpha: 0.22),
              blurRadius: 8,
              spreadRadius: 0.5,
            ),
          ],
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            if (!gameInstance.canUserControl) {
              return;
            }
            gameInstance.beginPowerDrag(details.localPosition.dy);
          },
          onPanUpdate: (details) {
            if (!gameInstance.canUserControl) {
              return;
            }
            gameInstance.updatePowerDrag(details.localPosition.dy);
          },
          onPanEnd: (_) {
            if (!gameInstance.canUserControl) {
              return;
            }
            gameInstance.endPowerDrag();
            gameInstance.shootWithPower();
          },
          onPanCancel: () {
            if (!gameInstance.canUserControl) {
              return;
            }
            gameInstance.endPowerDrag();
          },
          child: ValueListenableBuilder<double>(
            valueListenable: gameInstance.shotPower,
            builder: (context, power, child) {
              final powerColor = power > 0.80
                  ? Colors.redAccent
                  : power > 0.45
                      ? Colors.amber
                      : const Color(0xFF00E676);

              return Column(
                children: [
                  // Huy hiệu người chơi & Cấp độ cơ đang đánh
                  Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    padding: EdgeInsets.symmetric(
                      horizontal: ultraCompact ? 2 : 3,
                      vertical: 1.0,
                    ),
                    decoration: BoxDecoration(
                      color: activeCue.rarity.color.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: activeCue.rarity.color.withValues(alpha: 0.70),
                        width: 0.8,
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        ultraCompact ? playerTag : '$playerTag Lv$activeLevel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ultraCompact ? 7.0 : (compact ? 8.0 : 9.0),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.flash_on,
                    color: powerColor,
                    size: ultraCompact ? 13 : (compact ? 15 : 18),
                  ),
                  const SizedBox(height: 1),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ultraCompact ? 2 : 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: powerColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: powerColor.withValues(alpha: 0.6),
                        width: 0.7,
                      ),
                    ),
                    child: Text(
                      '${(power * 100).round()}%',
                      style: TextStyle(
                        color: powerColor,
                        fontSize: ultraCompact ? 8.0 : (compact ? 9.0 : 10.5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: ultraCompact ? 3 : 5),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Thanh đo lực neon
                        Container(
                          width: (ultraCompact ? 5.5 : (compact ? 7.0 : 8.5)) * upscaleFactor,
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: Colors.white24, width: 0.6),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2.5),
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                Container(color: Colors.white10),
                                FractionallySizedBox(
                                  heightFactor: power,
                                  widthFactor: 1.0,
                                  alignment: Alignment.bottomCenter,
                                  child: DecoratedBox(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Color(0xFF00E676),
                                          Colors.amber,
                                          Colors.redAccent,
                                        ],
                                        stops: [0.0, 0.6, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                                for (var mark = 1; mark < 10; mark++)
                                  Positioned.fill(
                                    child: Align(
                                      alignment: Alignment(0, 1.0 - mark / 5.0),
                                      child: Container(
                                        height: 1,
                                        color: Colors.black45,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: ultraCompact ? 3 : (compact ? 4 : 6)),
                        // Cây cơ bida tương tác - lún sâu theo lực
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final trackHeight = constraints.maxHeight;
                              // Khi tăng lực từ 5% -> 100%, cây cơ lún sâu xuống dọc theo thanh lực
                              final maxTravel = trackHeight * 0.72;
                              final normalizedPower =
                                  ((power - 0.05) / 0.95).clamp(0.0, 1.0);
                              final pullOffset = normalizedPower * maxTravel;

                              final stickWidth = (ultraCompact ? 10.0 : (compact ? 12.0 : 15.0)) * upscaleFactor;

                              return ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: Stack(
                                  alignment: Alignment.topCenter,
                                  children: [
                                    // Rãnh cơ bóng mờ tinh tế
                                    Container(
                                      width: stickWidth,
                                      decoration: BoxDecoration(
                                        color: Colors.black38,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.white10,
                                          width: 0.6,
                                        ),
                                      ),
                                    ),
                                    // Vệt sáng năng lượng chạy phía trên đầu cơ khi lún xuống
                                    if (pullOffset > 2)
                                      Positioned(
                                        top: 0,
                                        height: pullOffset,
                                        width: stickWidth * 0.65,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(2),
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                powerColor.withValues(alpha: 0.12),
                                                powerColor.withValues(alpha: 0.70),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    // Cây cơ di chuyển lún sâu xuống theo lực kéo
                                    Transform.translate(
                                      offset: Offset(0, pullOffset),
                                      child: _CueStickWidget(
                                        height: trackHeight,
                                        width: stickWidth,
                                        cue: activeCue,
                                        level: activeLevel,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}

class _CueStickWidget extends StatelessWidget {
  final double height;
  final double width;
  final CueModel cue;
  final int level;

  const _CueStickWidget({
    required this.height,
    this.width = 16.0,
    required this.cue,
    this.level = 1,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _VerticalCueStickPainter(cue: cue, level: level),
    );
  }
}

class _VerticalCueStickPainter extends CustomPainter {
  final CueModel cue;
  final int level;

  _VerticalCueStickPainter({required this.cue, required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centerX = w / 2;

    // Bán kính côn từ ngọn đến chuôi
    final topR = (w * 0.22).clamp(2.5, 4.0);
    final botR = (w * 0.44).clamp(5.0, 8.0);

    double radiusAt(double y) =>
        topR + (botR - topR) * (y / h).clamp(0.0, 1.0);

    void drawSection({
      required double yTop,
      required double yBot,
      required List<Color> colors,
      List<double>? stops,
    }) {
      if (yBot <= yTop) return;
      final rTop = radiusAt(yTop);
      final rBot = radiusAt(yBot);
      final path = Path()
        ..moveTo(centerX - rTop, yTop)
        ..lineTo(centerX + rTop, yTop)
        ..lineTo(centerX + rBot, yBot)
        ..lineTo(centerX - rBot, yBot)
        ..close();

      final maxR = math.max(rTop, rBot);
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: colors,
          stops: stops,
        ).createShader(
          Rect.fromLTWH(centerX - maxR, yTop, maxR * 2, yBot - yTop),
        );

      canvas.drawPath(path, paint);
    }

    // ==========================================
    // 0. HÀO QUANG LINH THẠCH XUNG QUANH CƠ (Lv >= 3)
    // ==========================================
    if (level >= 3) {
      final isMax = level == 10;
      final auraWidth = (w * 0.55).clamp(6.0, 12.0);
      final auraColor = cue.auraColor;

      final auraPaint = Paint()
        ..color = auraColor.withValues(
            alpha: isMax ? 0.35 : (level >= 6 ? 0.24 : 0.15))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isMax ? 6.0 : 3.5);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(centerX, h * 0.5),
            width: w + auraWidth * 0.5,
            height: h - 10,
          ),
          Radius.circular(w * 0.4),
        ),
        auraPaint,
      );

      // Cột sáng tia năng lượng chạy hai bên
      if (level >= 6) {
        final lineP = Paint()
          ..color = auraColor.withValues(alpha: isMax ? 0.65 : 0.42)
          ..strokeWidth = isMax ? 1.6 : 1.0
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(centerX - radiusAt(h * 0.3) - 1.2, 14),
          Offset(centerX - radiusAt(h * 0.9) - 1.2, h - 14),
          lineP,
        );
        canvas.drawLine(
          Offset(centerX + radiusAt(h * 0.3) + 1.2, 14),
          Offset(centerX + radiusAt(h * 0.9) + 1.2, h - 14),
          lineP,
        );
      }
    }

    // ==========================================
    // 1. ĐẦU LƠ (Chalk Tip) ở đỉnh gậy: y = 0 -> y = 6.0
    // ==========================================
    final tipH = 6.0;
    final tipR = radiusAt(tipH);
    final tipPath = Path()
      ..moveTo(centerX - radiusAt(0), 0)
      ..lineTo(centerX + radiusAt(0), 0)
      ..lineTo(centerX + tipR, tipH)
      ..lineTo(centerX - tipR, tipH)
      ..close();

    final tipColor = cue.tipColor;
    canvas.drawPath(
      tipPath,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.2, -0.4),
          radius: 0.9,
          colors: [
            Color.lerp(tipColor, Colors.white, 0.45) ?? tipColor,
            tipColor,
            Color.lerp(tipColor, Colors.black, 0.40) ?? tipColor,
          ],
        ).createShader(Rect.fromLTWH(centerX - tipR, 0, tipR * 2, tipH)),
    );

    // ==========================================
    // 2. PHÍP CƠ TRẮNG (Ivory Ferrule): y = 6.0 -> y = 16.0
    // ==========================================
    drawSection(
      yTop: 6.0,
      yBot: 16.0,
      colors: const [
        Color(0xFFE0E0E0),
        Color(0xFFFFFFFF),
        Color(0xFFF5F5F5),
        Color(0xFFBDBDBD),
      ],
      stops: const [0.0, 0.35, 0.65, 1.0],
    );

    // Đai vàng nẹp chân phíp cơ (Lv >= 5)
    if (level >= 5) {
      drawSection(
        yTop: 14.5,
        yBot: 16.0,
        colors: const [
          Color(0xFFFFD54F),
          Color(0xFFFFF9C4),
          Color(0xFFB8860B),
        ],
      );
    }

    // ==========================================
    // 3. NGỌN CƠ (Shaft): y = 16.0 -> y = h * 0.52
    // ==========================================
    final shaftBot = h * 0.52;
    final baseShaft = cue.shaftColors.isNotEmpty
        ? cue.shaftColors
        : const [Color(0xFFDF9E52), Color(0xFFC78438)];

    final shaft3D = [
      baseShaft.first,
      baseShaft.length > 1 ? baseShaft[1] : baseShaft.first,
      Colors.white.withValues(alpha: 0.45),
      baseShaft.last,
      const Color(0xFF3E2723),
    ];
    drawSection(
      yTop: 16.0,
      yBot: shaftBot,
      colors: shaft3D,
      stops: const [0.0, 0.28, 0.50, 0.78, 1.0],
    );

    // ------------------------------------------
    // HỌA TIẾT CONCEPT ANIME TRÊN NGỌN CƠ
    // ------------------------------------------
    switch (cue.animeConcept) {
      case CueAnimeConcept.katanaSamurai:
        final hamonPaint = Paint()
          ..color = const Color(0xFFFF1744).withValues(
              alpha: level >= 6 ? 0.95 : 0.80)
          ..style = PaintingStyle.stroke
          ..strokeWidth = level >= 7 ? 1.2 : 0.9;
        final hamonPath = Path()..moveTo(centerX, 18.0);
        for (double hy = 18.0; hy < shaftBot - 8.0; hy += 11.0) {
          hamonPath.quadraticBezierTo(
              centerX - 1.4, hy + 2.8, centerX, hy + 5.5);
          hamonPath.quadraticBezierTo(
              centerX + 1.4, hy + 8.2, centerX, hy + 11.0);
        }
        canvas.drawPath(hamonPath, hamonPaint);

        if (level >= 5) {
          drawSection(
            yTop: shaftBot - 7.0,
            yBot: shaftBot,
            colors: const [
              Color(0xFFFFD54F),
              Color(0xFFFFF9C4),
              Color(0xFFB8860B)
            ],
          );
        }
        if (level >= 8) {
          final runeP = Paint()
            ..color = Colors.white.withValues(alpha: 0.85)
            ..strokeWidth = 0.8;
          for (double ry = 28.0; ry < shaftBot - 14.0; ry += 16.0) {
            canvas.drawLine(
                Offset(centerX - 1.0, ry), Offset(centerX + 1.0, ry + 2.0), runeP);
          }
        }
        break;

      case CueAnimeConcept.cyberNeo:
        final laserP = Paint()
          ..color = const Color(0xFF00E5FF).withValues(
              alpha: level >= 6 ? 0.95 : 0.80)
          ..strokeWidth = level >= 6 ? 1.4 : 1.0;
        canvas.drawLine(
            Offset(centerX, 18.0), Offset(centerX, shaftBot - 2), laserP);
        if (level >= 4) {
          final nodeP = Paint()..color = const Color(0xFFE040FB);
          for (double ny = 30.0; ny < shaftBot - 12.0; ny += 20.0) {
            canvas.drawCircle(Offset(centerX, ny), 1.2, nodeP);
            canvas.drawCircle(
                Offset(centerX, ny), 0.6, Paint()..color = Colors.white);
          }
        }
        break;

      case CueAnimeConcept.dragonFlame:
        final flameP = Paint()
          ..color = const Color(0xFFFF6D00).withValues(
              alpha: level >= 6 ? 0.95 : 0.80)
          ..strokeWidth = 1.3;
        canvas.drawLine(
            Offset(centerX, 18.0), Offset(centerX, shaftBot - 2), flameP);
        final emberP = Paint()
          ..color = const Color(0xFFFFD54F)
          ..strokeWidth = 0.8;
        for (double ey = 25.0; ey < shaftBot - 10.0; ey += 16.0) {
          canvas.drawLine(
              Offset(centerX - 1.2, ey), Offset(centerX + 1.2, ey - 2.0), emberP);
        }
        break;

      case CueAnimeConcept.arcaneMagic:
        final manaP = Paint()
          ..color = const Color(0xFFB388FF).withValues(alpha: 0.85)
          ..strokeWidth = 1.1;
        canvas.drawLine(
            Offset(centerX, 18.0), Offset(centerX, shaftBot - 2), manaP);
        if (level >= 4) {
          final starP = Paint()..color = const Color(0xFFFF80AB);
          for (double sy = 28.0; sy < shaftBot - 12.0; sy += 18.0) {
            canvas.drawCircle(Offset(centerX, sy), 1.0, starP);
          }
        }
        break;

      case CueAnimeConcept.mechaGundam:
        final mechP = Paint()
          ..color = const Color(0xFF76FF03).withValues(alpha: 0.85)
          ..strokeWidth = 1.1;
        canvas.drawLine(
            Offset(centerX, 18.0), Offset(centerX, shaftBot - 2), mechP);
        break;

      case CueAnimeConcept.sakuraZen:
        final petalP = Paint()
          ..color = const Color(0xFFFF80AB).withValues(alpha: 0.85);
        for (double py = 26.0; py < shaftBot - 10.0; py += 18.0) {
          canvas.drawCircle(
              Offset(centerX + (py % 36 == 0 ? 1.0 : -1.0), py), 1.2, petalP);
        }
        break;

      case CueAnimeConcept.shadowVoid:
        final voidP = Paint()
          ..color = const Color(0xFF7C4DFF).withValues(alpha: 0.90)
          ..strokeWidth = 1.2;
        canvas.drawLine(
            Offset(centerX, 18.0), Offset(centerX, shaftBot - 2), voidP);
        break;

      case CueAnimeConcept.frostCryo:
        final frostP = Paint()
          ..color = const Color(0xFF80D8FF).withValues(alpha: 0.90)
          ..strokeWidth = 1.2;
        canvas.drawLine(
            Offset(centerX, 18.0), Offset(centerX, shaftBot - 2), frostP);
        break;

      case CueAnimeConcept.classic:
        final grainP = Paint()
          ..color = const Color(0xFF6D4C41).withValues(alpha: 0.4)
          ..strokeWidth = 0.6;
        canvas.drawLine(
            Offset(centerX - 1.0, 18.0), Offset(centerX - 1.0, shaftBot - 2), grainP);
        canvas.drawLine(
            Offset(centerX + 1.0, 18.0), Offset(centerX + 1.0, shaftBot - 2), grainP);
        break;
    }

    // ==========================================
    // 4. KHỚP REN KIM LOẠI / VÀNH TSUBA (Joint)
    // ==========================================
    final jointTop = shaftBot;
    final jointBot = shaftBot + 10.0;

    if (cue.animeConcept == CueAnimeConcept.katanaSamurai) {
      final tsubaW = (radiusAt(jointTop) * 2.8).clamp(8.0, 15.0);
      final tsubaRect = Rect.fromCenter(
        center: Offset(centerX, jointTop + 4.5),
        width: tsubaW,
        height: 4.5,
      );
      final tsubaRRect =
          RRect.fromRectAndRadius(tsubaRect, const Radius.circular(2.0));
      canvas.drawRRect(tsubaRRect, Paint()..color = const Color(0xFFFFD54F));
      canvas.drawRRect(
        tsubaRRect,
        Paint()
          ..color = Colors.black87
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7,
      );
      if (level >= 6) {
        canvas.drawCircle(
            Offset(centerX - tsubaW * 0.3, jointTop + 4.5), 0.7, Paint()..color = const Color(0xFFB8860B));
        canvas.drawCircle(
            Offset(centerX + tsubaW * 0.3, jointTop + 4.5), 0.7, Paint()..color = const Color(0xFFB8860B));
      }
    } else {
      drawSection(
        yTop: jointTop,
        yBot: jointTop + 2.5,
        colors: const [Color(0xFFEEEEEE), Color(0xFF9E9E9E), Color(0xFF616161)],
      );
      drawSection(
        yTop: jointTop + 2.5,
        yBot: jointBot - 2.5,
        colors: level >= 5
            ? const [Color(0xFFFFD54F), Color(0xFFFFF9C4), Color(0xFFB8860B)]
            : const [Color(0xFF303030), Color(0xFF151515), Color(0xFF000000)],
      );
      drawSection(
        yTop: jointBot - 2.5,
        yBot: jointBot,
        colors: const [Color(0xFFEEEEEE), Color(0xFF9E9E9E), Color(0xFF616161)],
      );
      if (level >= 6) {
        canvas.drawCircle(
            Offset(centerX, jointTop + 5.0),
            radiusAt(jointTop) * 0.35,
            Paint()..color = cue.auraColor);
      }
    }

    // ==========================================
    // 5. CHUÔI CƠ (Butt Sleeve): y = jointBot -> y = h - 14.0
    // ==========================================
    final buttTop = jointBot;
    final buttBot = h - 14.0;
    final baseHandle = cue.handleColors.isNotEmpty
        ? cue.handleColors
        : const [Color(0xFF2979FF), Color(0xFF0D47A1)];

    final handle3D = [
      baseHandle.first,
      baseHandle.length > 1 ? baseHandle[1] : baseHandle.first,
      Colors.white.withValues(alpha: 0.35),
      baseHandle.last,
      Colors.black87,
    ];
    drawSection(
      yTop: buttTop,
      yBot: buttBot,
      colors: handle3D,
      stops: const [0.0, 0.28, 0.50, 0.78, 1.0],
    );

    // ------------------------------------------
    // VÙNG TAY QUẤN CƠ (Grip Wrap) & HỌA TIẾT ANIME
    // ------------------------------------------
    final wrapTop = buttTop + (buttBot - buttTop) * 0.16;
    final wrapBot = buttTop + (buttBot - buttTop) * 0.84;

    drawSection(
      yTop: wrapTop,
      yBot: wrapBot,
      colors: const [
        Color(0xFF1E2126),
        Color(0xFF2C3238),
        Color(0xFF14171A),
      ],
    );

    switch (cue.animeConcept) {
      case CueAnimeConcept.katanaSamurai:
        final tsukaLace = Paint()
          ..color = const Color(0xFFFFD54F).withValues(
              alpha: level >= 6 ? 0.92 : 0.78)
          ..style = PaintingStyle.stroke
          ..strokeWidth = level >= 6 ? 1.2 : 0.9;
        final diamondH = 8.5;
        for (double dy = wrapTop + 4.0; dy < wrapBot - diamondH; dy += diamondH) {
          final r = radiusAt(dy + diamondH * 0.5) * 0.75;
          final p = Path()
            ..moveTo(centerX, dy)
            ..lineTo(centerX + r, dy + diamondH * 0.5)
            ..lineTo(centerX, dy + diamondH)
            ..lineTo(centerX - r, dy + diamondH * 0.5)
            ..close();
          canvas.drawPath(p, tsukaLace);

          if (level >= 5) {
            canvas.drawCircle(
                Offset(centerX, dy + diamondH * 0.5), 1.0, Paint()..color = const Color(0xFFFF1744));
          }
        }
        break;

      case CueAnimeConcept.cyberNeo:
        final cyanBus = Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.90)
          ..strokeWidth = 1.1;
        final magBus = Paint()
          ..color = const Color(0xFFE040FB).withValues(alpha: 0.90)
          ..strokeWidth = 1.1;
        final rW = radiusAt((wrapTop + wrapBot) * 0.5) * 0.45;
        canvas.drawLine(
            Offset(centerX - rW, wrapTop + 4), Offset(centerX - rW, wrapBot - 4), cyanBus);
        canvas.drawLine(
            Offset(centerX + rW, wrapTop + 4), Offset(centerX + rW, wrapBot - 4), magBus);
        for (double my = wrapTop + 10.0; my < wrapBot - 8.0; my += 14.0) {
          canvas.drawLine(
              Offset(centerX - rW, my), Offset(centerX + rW, my + 3.0), cyanBus..strokeWidth = 0.7);
          canvas.drawCircle(
              Offset(centerX - rW, my), 1.1, Paint()..color = Colors.white);
          canvas.drawCircle(
              Offset(centerX + rW, my + 3.0), 1.1, Paint()..color = const Color(0xFF00E5FF));
        }
        break;

      case CueAnimeConcept.dragonFlame:
        final scaleP = Paint()
          ..color = const Color(0xFFFFD600).withValues(
              alpha: level >= 6 ? 0.90 : 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        for (double sy = wrapTop + 4.0; sy < wrapBot - 8.0; sy += 7.5) {
          final r = radiusAt(sy) * 0.65;
          final p = Path()
            ..moveTo(centerX - r, sy)
            ..lineTo(centerX, sy + 3.2)
            ..lineTo(centerX + r, sy);
          canvas.drawPath(p, scaleP);
        }
        break;

      case CueAnimeConcept.mechaGundam:
        final hazardP = Paint()
          ..color = const Color(0xFFFF6D00).withValues(alpha: 0.90)
          ..strokeWidth = 1.8;
        for (double hy = wrapTop + 4.0; hy < wrapBot - 8.0; hy += 9.0) {
          final r = radiusAt(hy) * 0.70;
          canvas.drawLine(
              Offset(centerX - r, hy), Offset(centerX + r, hy + 4.0), hazardP);
        }
        break;

      case CueAnimeConcept.arcaneMagic:
        final ringP = Paint()
          ..color = const Color(0xFFB388FF).withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        for (double ay = wrapTop + 6.0; ay < wrapBot - 6.0; ay += 12.0) {
          final r = radiusAt(ay) * 0.65;
          canvas.drawOval(
              Rect.fromCenter(center: Offset(centerX, ay), width: r * 2, height: 3.0),
              ringP);
          canvas.drawCircle(
              Offset(centerX, ay), 0.9, Paint()..color = const Color(0xFFFF80AB));
        }
        break;

      case CueAnimeConcept.sakuraZen:
        final sakuraP = Paint()
          ..color = const Color(0xFFFF80AB).withValues(alpha: 0.90);
        final goldCenterP = Paint()..color = const Color(0xFFFFD54F);
        for (double py = wrapTop + 6.0; py < wrapBot - 6.0; py += 14.0) {
          final xOffset = (py % 28 == 0 ? 1.5 : -1.5);
          canvas.drawCircle(Offset(centerX + xOffset, py), 1.4, sakuraP);
          canvas.drawCircle(Offset(centerX + xOffset, py), 0.6, goldCenterP);
        }
        break;

      case CueAnimeConcept.shadowVoid:
        final voidP = Paint()
          ..color = const Color(0xFF7C4DFF).withValues(alpha: 0.85)
          ..strokeWidth = 1.0;
        for (double vy = wrapTop + 6.0; vy < wrapBot - 6.0; vy += 11.0) {
          final r = radiusAt(vy) * 0.6;
          canvas.drawLine(
              Offset(centerX - r, vy), Offset(centerX + r, vy + 2.0), voidP);
          canvas.drawCircle(
              Offset(centerX, vy + 1.0), 0.8, Paint()..color = Colors.white70);
        }
        break;

      case CueAnimeConcept.frostCryo:
        final frostP = Paint()
          ..color = const Color(0xFF80D8FF).withValues(alpha: 0.90)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        for (double fy = wrapTop + 6.0; fy < wrapBot - 6.0; fy += 10.0) {
          final r = radiusAt(fy) * 0.6;
          final p = Path()
            ..moveTo(centerX, fy - 2)
            ..lineTo(centerX + r, fy)
            ..lineTo(centerX, fy + 2)
            ..lineTo(centerX - r, fy)
            ..close();
          canvas.drawPath(p, frostP);
        }
        break;

      case CueAnimeConcept.classic:
        final trimP = Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: 0.80)
          ..strokeWidth = 0.9;
        canvas.drawLine(
            Offset(centerX - radiusAt(wrapTop) * 0.7, wrapTop + 4),
            Offset(centerX + radiusAt(wrapTop) * 0.7, wrapTop + 4),
            trimP);
        canvas.drawLine(
            Offset(centerX - radiusAt(wrapBot) * 0.7, wrapBot - 4),
            Offset(centerX + radiusAt(wrapBot) * 0.7, wrapBot - 4),
            trimP);
        break;
    }

    // ==========================================
    // 6. BỊT ĐÁY CHUÔI (Butt Cap): y = buttBot -> y = h - 6.0
    // ==========================================
    drawSection(
      yTop: buttBot,
      yBot: h - 6.0,
      colors: level >= 5
          ? const [Color(0xFFFFD54F), Color(0xFFFFF9C4), Color(0xFFB8860B)]
          : const [Color(0xFFFFFFFF), Color(0xFFE0E0E0), Color(0xFF9E9E9E)],
    );

    // ==========================================
    // 7. ĐỆM CAO SU & KHẢM ĐÁ QUÝ ĐUÔI CƠ (Bumper & Gemstone)
    // ==========================================
    final bumpR = radiusAt(h);
    final bumperPath = Path()
      ..moveTo(centerX - radiusAt(h - 6.0), h - 6.0)
      ..lineTo(centerX + radiusAt(h - 6.0), h - 6.0)
      ..lineTo(centerX + bumpR, h - 2.0)
      ..quadraticBezierTo(centerX, h + 2.0, centerX - bumpR, h - 2.0)
      ..close();
    canvas.drawPath(
      bumperPath,
      Paint()..color = const Color(0xFF141414),
    );

    // Lv >= 5: KHẢM VIÊN NGỌC LINH HỒN Ở ĐUÔI CHUÔI CƠ (Butt Gemstone Bezel)
    if (level >= 5) {
      final gemColor = switch (cue.animeConcept) {
        CueAnimeConcept.katanaSamurai => const Color(0xFFFF1744),
        CueAnimeConcept.cyberNeo => const Color(0xFF00E5FF),
        CueAnimeConcept.dragonFlame => const Color(0xFFFF6D00),
        CueAnimeConcept.arcaneMagic => const Color(0xFFB388FF),
        CueAnimeConcept.shadowVoid => const Color(0xFF7C4DFF),
        CueAnimeConcept.mechaGundam => const Color(0xFF76FF03),
        CueAnimeConcept.sakuraZen => const Color(0xFFFF80AB),
        CueAnimeConcept.frostCryo => const Color(0xFF80D8FF),
        CueAnimeConcept.classic => const Color(0xFFFFD54F),
      };

      final gemRadius = (bumpR * 0.55).clamp(2.5, 4.2);
      final gemCenter = Offset(centerX, h - 3.2);

      // Đĩa vàng 24K đỡ ngọc
      canvas.drawCircle(
          gemCenter, gemRadius + 1.0, Paint()..color = const Color(0xFFFFD54F));
      // Viên đá quý đa diện
      canvas.drawCircle(gemCenter, gemRadius, Paint()..color = gemColor);
      // Điểm lóe sáng phản chiếu trên mặt đá
      canvas.drawCircle(
        Offset(gemCenter.dx - gemRadius * 0.35, gemCenter.dy - gemRadius * 0.35),
        gemRadius * 0.35,
        Paint()..color = Colors.white.withValues(alpha: 0.95),
      );

      // Cấp 10 Tối Thượng: Ngôi sao sáng 4 cánh (Star Glint) rực rỡ trên viên ngọc
      if (level == 10) {
        final starPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 1.0;
        final starLen = gemRadius + 2.0;
        canvas.drawLine(Offset(gemCenter.dx - starLen, gemCenter.dy),
            Offset(gemCenter.dx + starLen, gemCenter.dy), starPaint);
        canvas.drawLine(Offset(gemCenter.dx, gemCenter.dy - starLen),
            Offset(gemCenter.dx, gemCenter.dy + starLen), starPaint);
      }
    }

    // ==========================================
    // 8. ĐƯỜNG PHẢN QUANG 3D (Glossy Highlight)
    // ==========================================
    final shinePath = Path()
      ..moveTo(centerX - topR * 0.35, 2.0)
      ..lineTo(centerX - topR * 0.10, 2.0)
      ..lineTo(centerX - botR * 0.10, h - 8.0)
      ..lineTo(centerX - botR * 0.35, h - 8.0)
      ..close();
    canvas.drawPath(
      shinePath,
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );
  }

  @override
  bool shouldRepaint(covariant _VerticalCueStickPainter oldDelegate) =>
      oldDelegate.cue != cue || oldDelegate.level != level;
}



void _showCueSpinDialog(BuildContext context) {
  final screenH = MediaQuery.of(context).size.height;
  final isShort = screenH < 400;
  final isVeryShort = screenH < 340;
  final ballBoxSize = isVeryShort ? 140.0 : (isShort ? 170.0 : 230.0);
  final cueBallSize = isVeryShort ? 120.0 : (isShort ? 150.0 : 200.0);

  showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: const Color(0xFF1B2026),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isShort ? 12 : 18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'spin_control_title'.tr,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isShort ? 15 : 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'spin_control_instruction'.tr,
                style: TextStyle(color: Colors.white60, fontSize: isShort ? 10.5 : 12),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: isShort ? 8 : 14),
              // Khung hiển thị quả bi cái tương tác (Tự động co giãn theo chiều cao màn hình)
              SizedBox(
                width: ballBoxSize,
                height: ballBoxSize,
                child: ValueListenableBuilder<Offset>(
                  valueListenable: gameInstance.cueSpin,
                  builder: (context, spin, child) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) =>
                        _updateSpinFromTouch(details.localPosition, ballBoxSize),
                    onPanUpdate: (details) =>
                        _updateSpinFromTouch(details.localPosition, ballBoxSize),
                    onPanEnd: (_) => gameInstance.commitCueSpin(),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Vỏ nền bi cái với viền phát sáng nhẹ
                        Container(
                          width: cueBallSize,
                          height: cueBallSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyanAccent.withValues(alpha: 0.25),
                                blurRadius: isShort ? 12 : 18,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/cue_ball.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        // Trục tọa độ và vòng tròn ranh giới an toàn
                        IgnorePointer(
                          child: CustomPaint(
                            size: Size(cueBallSize, cueBallSize),
                            painter: _CueBallGuidePainter(),
                          ),
                        ),
                        // Chấm đỏ đánh dấu điểm chạm cơ
                        Builder(
                          builder: (context) {
                            final maxRadius = (cueBallSize / 2.0) * 0.80;
                            return Transform.translate(
                              offset: Offset(
                                spin.dx * maxRadius,
                                spin.dy * maxRadius,
                              ),
                              child: Container(
                                width: isShort ? 20 : 26,
                                height: isShort ? 20 : 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.redAccent.withValues(alpha: 0.9),
                                  border: Border.all(color: Colors.white, width: isShort ? 1.8 : 2.5),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black54,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Container(
                                    width: isShort ? 4 : 6,
                                    height: isShort ? 4 : 6,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: isShort ? 6 : 10),
              // Nhãn trạng thái xoáy thời gian thực
              ValueListenableBuilder<Offset>(
                valueListenable: gameInstance.cueSpin,
                builder: (context, spin, child) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: isShort ? 8 : 12, vertical: isShort ? 3 : 5),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      '${_describeSpin(spin)} (dx: ${spin.dx >= 0 ? '+' : ''}${spin.dx.toStringAsFixed(2)}, dy: ${spin.dy >= 0 ? '+' : ''}${spin.dy.toStringAsFixed(2)})',
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: isShort ? 10.5 : 12.0,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: isShort ? 8 : 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.check, size: isShort ? 16 : 18),
                  label: Text('done'.tr),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0E5B3A),
                    padding: EdgeInsets.symmetric(vertical: isShort ? 8 : 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _describeSpin(Offset spin) {
  return LanguageService.instance.describeSpin(spin);
}

class _CueBallGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final linePaint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 1.0;

    // Trục chữ thập tâm bi
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.85),
      Offset(center.dx, center.dy + radius * 0.85),
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius * 0.85, center.dy),
      Offset(center.dx + radius * 0.85, center.dy),
      linePaint,
    );

    // Vòng tròn an toàn tiếp xúc cơ (tránh tẹt cơ ngoài rìa)
    final circlePaint = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius * 0.80, circlePaint);
    canvas.drawCircle(center, radius * 0.40, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void _updateSpinFromTouch(Offset localPosition, double controlSize) {
  if (!gameInstance.canUserControl) return;
  final center = Offset(controlSize / 2, controlSize / 2);
  final ballRadius = (controlSize / 2) * 0.82;
  final offset = localPosition - center;
  final distance = offset.distance;
  final maxRadius = ballRadius * 0.80; // Giữ đầu cơ an toàn trên mặt bi cái
  final limited = distance > maxRadius
      ? offset * (maxRadius / distance)
      : offset;
  gameInstance.setCueSpin(Offset(limited.dx / maxRadius, limited.dy / maxRadius));
}

MatchRewardResult? _lastMatchReward;

Widget _buildRackOverlay({VoidCallback? onHome}) {
  return ListenableBuilder(
    listenable: Listenable.merge([
      gameInstance.matchVersion,
      LanguageService.instance,
    ]),
    builder: (context, child) {
      if (!gameInstance.rackOver) {
        return const SizedBox.shrink();
      }

      final reward = _lastMatchReward;

      String titleText;
      final bool isLocalMulti = gameInstance.isLocalMultiplayer.value;
      final bool isOnlineMulti = gameInstance.isOnlineMultiplayer.value;
      final bool isMultiplayer = isLocalMulti || isOnlineMulti;
      final bool isHost = isOnlineMulti
          ? OnlineMultiplayerService.instance.isHost
          : LocalMultiplayerService.instance.isHost;
      final bool isLocalWinner = isMultiplayer
          ? (isHost
              ? gameInstance.winningPlayer == 1
              : gameInstance.winningPlayer == 2)
          : (gameInstance.winningPlayer == 1);

      if (gameInstance.activeDailyPuzzle != null) {
        titleText = gameInstance.winningPlayer == 1
            ? 'daily_puzzle_win'.tr
            : 'daily_puzzle_fail'.tr;
      } else if (gameInstance.activeLegendaryTrickshot != null) {
        final shot = gameInstance.activeLegendaryTrickshot!;
        titleText = gameInstance.winningPlayer == 1
            ? 'trickshot_win'.tr.replaceAll('{player}', shot.playerName.toUpperCase())
            : 'trickshot_fail'.tr;
      } else if (gameInstance.activeTournamentStage != null) {
        final stage = gameInstance.activeTournamentStage!;
        final stageTitle = LanguageService.instance.localizeStageTitle(stage.title);
        titleText = gameInstance.winningPlayer == 1
            ? (stage.bracketNumber == 5
                ? 'tournament_champion_title'.tr
                : 'bracket_passed'.tr.replaceAll('{stage}', stageTitle).replaceAll('{num}', '${stage.bracketNumber}'))
            : 'bracket_failed'.tr.replaceAll('{num}', '${stage.bracketNumber}');
      } else if (gameInstance.activeBotStage != null) {
        titleText = gameInstance.winningPlayer == 1
            ? 'stage_passed_title'.tr.replaceAll('{num}', '${gameInstance.activeBotStage!.stageNumber}')
            : 'bot_won_title'.tr.replaceAll('{bot}', gameInstance.activeBotStage!.botName.toUpperCase());
      } else if (isMultiplayer) {
        final oppName = isOnlineMulti
            ? OnlineMultiplayerService.instance.opponentName
            : (LocalMultiplayerService.instance.opponentName.isNotEmpty
                ? LocalMultiplayerService.instance.opponentName
                : (isHost ? 'guest'.tr : 'host'.tr));
        titleText = gameInstance.winningPlayer == null
            ? 'match_over'.tr
            : (isLocalWinner
                ? 'match_win_opp'.tr.replaceAll('{opp}', oppName)
                : 'match_lose_opp'.tr.replaceAll('{opp}', oppName));
      } else {
        titleText = gameInstance.winningPlayer == null
            ? 'match_over'.tr
            : (gameInstance.winningPlayer == 1
                ? 'victory'.tr
                : (gameInstance.isBotMode.value
                    ? 'bot_won'.tr
                    : 'defeat'.tr));
      }

      final subtitleText = gameInstance.activeDailyPuzzle != null
          ? 'shots_taken'.tr.replaceAll('{current}', '${gameInstance.dailyPuzzleShotsTaken}').replaceAll('{max}', '${gameInstance.activeDailyPuzzle!.maxShotsAllowed}')
          : (gameInstance.activeLegendaryTrickshot != null
              ? '🎯 ${LanguageService.instance.localizeTrickshotTitle(gameInstance.activeLegendaryTrickshot!.id, gameInstance.activeLegendaryTrickshot!.title)}'
              : '${'score'.tr}  ${gameInstance.playerScores[1] ?? 0} - ${gameInstance.playerScores[2] ?? 0}');

      final screenHeight = MediaQuery.of(context).size.height;
      final isShort = screenHeight < 520;
      final isVeryShort = screenHeight < 360;
      final equippedTable = ProgressionService.instance.equippedTable;
      final tableConcept = equippedTable.animeConcept;

      List<Color> dialogGradient;
      Color borderColor;
      Color glowShadowColor;
      String? conceptBadgeText;

      switch (tableConcept) {
        case TableAnimeConcept.cyberTokyo:
          dialogGradient = const [Color(0xFF071B26), Color(0xFF030D14)];
          borderColor = const Color(0xFF00E5FF);
          glowShadowColor = const Color(0x6600E5FF);
          conceptBadgeText = '⚡ CYBER VICTORY // 電脳完勝';
          break;
        case TableAnimeConcept.sakuraZen:
          dialogGradient = const [Color(0xFF2E0D1B), Color(0xFF19060E)];
          borderColor = const Color(0xFFF48FB1);
          glowShadowColor = const Color(0x66F48FB1);
          conceptBadgeText = '🌸 SAKURA TRIUMPH // 桜華無双';
          break;
        case TableAnimeConcept.dragonLava:
          dialogGradient = const [Color(0xFF2E0D03), Color(0xFF190601)];
          borderColor = const Color(0xFFFF6D00);
          glowShadowColor = const Color(0x66FF6D00);
          conceptBadgeText = '🔥 DRAGON ASCENT // 龍神降臨';
          break;
        case TableAnimeConcept.arcaneGrimoire:
          dialogGradient = const [Color(0xFF1E0D33), Color(0xFF0E041A)];
          borderColor = const Color(0xFFB388FF);
          glowShadowColor = const Color(0x667C4DFF);
          conceptBadgeText = '✨ ARCANE MASTERY // 魔導制覇';
          break;
        case TableAnimeConcept.shadowVoid:
          dialogGradient = const [Color(0xFF150A21), Color(0xFF08030D)];
          borderColor = const Color(0xFFBA68C8);
          glowShadowColor = const Color(0x666A1B9A);
          conceptBadgeText = '🌑 SHADOW MONARCH // 影の君主';
          break;
        case TableAnimeConcept.mechaEva:
          dialogGradient = const [Color(0xFF0F1A12), Color(0xFF070D08)];
          borderColor = const Color(0xFF76FF03);
          glowShadowColor = const Color(0x6676FF03);
          conceptBadgeText = '🛡️ SYSTEM CLEAR // 殲滅完了';
          break;
        case TableAnimeConcept.classic:
          dialogGradient = const [Color(0xFF133E32), Color(0xFF0D251E)];
          borderColor = Colors.amber;
          glowShadowColor = const Color(0x55000000);
          conceptBadgeText = null;
          break;
      }

      return Positioned.fill(
        child: Container(
          color: Colors.black.withValues(alpha: 0.75),
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isVeryShort ? 4 : (isShort ? 8 : 16),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isVeryShort ? 360 : (isShort ? 390 : 430),
                maxHeight: screenHeight * 0.94,
              ),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: dialogGradient,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor, width: 2),
                  boxShadow: [
                    BoxShadow(color: glowShadowColor, blurRadius: 18, spreadRadius: 1),
                    const BoxShadow(color: Colors.black87, blurRadius: 20),
                  ],
                ),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: isShort ? 14 : 20,
                    vertical: isVeryShort ? 6 : (isShort ? 10 : 16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (conceptBadgeText != null && isLocalWinner) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: borderColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 1),
                          ),
                          child: Text(
                            conceptBadgeText,
                            style: TextStyle(
                              color: borderColor,
                              fontSize: isVeryShort ? 9.5 : (isShort ? 10.5 : 12),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                      Icon(
                        isLocalWinner
                            ? Icons.emoji_events
                            : Icons.sentiment_dissatisfied,
                        color: isLocalWinner ? borderColor : Colors.redAccent,
                        size: isVeryShort ? 28 : (isShort ? 32 : 46),
                      ),
                      SizedBox(height: isVeryShort ? 1 : (isShort ? 2 : 5)),
                      Text(
                        titleText,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isVeryShort ? 14.5 : (isShort ? 16 : 19),
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isVeryShort ? 1 : 2),
                      Text(
                        subtitleText,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isVeryShort ? 11 : (isShort ? 12 : 14),
                        ),
                      ),

                      // Phần thưởng
                      if (reward != null) ...[
                        SizedBox(height: isVeryShort ? 4 : (isShort ? 6 : 10)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isShort ? 10 : 14,
                            vertical: isVeryShort ? 4 : (isShort ? 5 : 8),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            children: [
                              if (reward.customMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  margin: EdgeInsets.only(bottom: isVeryShort ? 2 : (isShort ? 4 : 6)),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD54F).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    LanguageService.instance.localizeCustomRewardMessage(reward.customMessage!),
                                    style: TextStyle(
                                      color: const Color(0xFFFFD54F),
                                      fontWeight: FontWeight.bold,
                                      fontSize: isVeryShort ? 9 : (isShort ? 9.5 : 10.5),
                                    ),
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  'rewards'.tr,
                                  style: TextStyle(
                                    color: const Color(0xFFFFD54F),
                                    fontSize: isVeryShort ? 8.5 : (isShort ? 9 : 10),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                SizedBox(height: isVeryShort ? 2 : (isShort ? 3 : 5)),
                              ],
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isShort ? 6 : 8,
                                      vertical: isVeryShort ? 1.5 : (isShort ? 2 : 3),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '+${reward.earnedXP} XP',
                                      style: TextStyle(
                                        color: const Color(0xFF69F0AE),
                                        fontWeight: FontWeight.bold,
                                        fontSize: isVeryShort ? 10 : (isShort ? 11 : 12.5),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: isShort ? 6 : 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isShort ? 6 : 8,
                                      vertical: isVeryShort ? 1.5 : (isShort ? 2 : 3),
                                    ),
                                    decoration: BoxDecoration(
                                      color: (reward.earnedCoins >= 0
                                              ? Colors.amber
                                              : Colors.redAccent)
                                          .withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.monetization_on,
                                          color: reward.earnedCoins >= 0
                                              ? const Color(0xFFFFD54F)
                                              : const Color(0xFFFF5252),
                                          size: isVeryShort ? 11 : (isShort ? 12 : 14),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          reward.earnedCoins >= 0
                                              ? '+${reward.earnedCoins}'
                                              : '${reward.earnedCoins}',
                                          style: TextStyle(
                                            color: reward.earnedCoins >= 0
                                                ? const Color(0xFFFFD54F)
                                                : const Color(0xFFFF5252),
                                            fontWeight: FontWeight.bold,
                                            fontSize: isVeryShort ? 10 : (isShort ? 11 : 12.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (reward.bonusDiamonds > 0) ...[
                                    SizedBox(width: isShort ? 6 : 8),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isShort ? 6 : 8,
                                        vertical: isVeryShort ? 1.5 : (isShort ? 2 : 3),
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.lightBlue.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.diamond,
                                            color: const Color(0xFF29B6F6),
                                            size: isVeryShort ? 11 : (isShort ? 12 : 14),
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            '+${reward.bonusDiamonds}',
                                            style: TextStyle(
                                              color: const Color(0xFF81D4FA),
                                              fontWeight: FontWeight.bold,
                                              fontSize: isVeryShort ? 10 : (isShort ? 11 : 12.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (reward.didLevelUp) ...[
                                SizedBox(height: isVeryShort ? 3 : (isShort ? 4 : 6)),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: isVeryShort ? 1.5 : (isShort ? 2 : 3),
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '🎉 ${'level'.tr.toUpperCase()} ${reward.newLevel}! (+${reward.bonusDiamonds} ${'diamonds'.tr})',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900,
                                      fontSize: isVeryShort ? 9 : (isShort ? 9.5 : 10.5),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      SizedBox(height: isVeryShort ? 6 : (isShort ? 8 : 12)),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: isShort ? 8 : 10,
                        runSpacing: isShort ? 6 : 8,
                        children: [
                          if (onHome != null) ...[
                            OutlinedButton.icon(
                              onPressed: () {
                                if (gameInstance.isLocalMultiplayer.value) {
                                  LocalMultiplayerService.instance.disconnect();
                                }
                                onHome();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: const BorderSide(color: Colors.white30),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isShort ? 12 : 16,
                                  vertical: isVeryShort ? 4 : (isShort ? 6 : 9),
                                ),
                                minimumSize: Size(0, isVeryShort ? 28 : (isShort ? 32 : 40)),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: Icon(Icons.home, size: isVeryShort ? 14 : (isShort ? 15 : 18)),
                              label: Text(
                                'main_menu'.tr,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isVeryShort ? 10.5 : (isShort ? 11.5 : 13),
                                ),
                              ),
                            ),
                          ],
                          FilledButton.icon(
                            onPressed: () {
                              if (gameInstance.isOnlineMultiplayer.value) {
                                OnlineMultiplayerService.instance.sendRestart();
                              } else if (gameInstance.isLocalMultiplayer.value) {
                                LocalMultiplayerService.instance.sendRestart();
                              }
                              gameInstance.restartMatch();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF00E676),
                              foregroundColor: Colors.black87,
                              padding: EdgeInsets.symmetric(
                                horizontal: isShort ? 14 : 18,
                                vertical: isVeryShort ? 4 : (isShort ? 6 : 9),
                              ),
                              minimumSize: Size(0, isVeryShort ? 28 : (isShort ? 32 : 40)),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: Icon(Icons.replay, size: isVeryShort ? 14 : (isShort ? 15 : 18)),
                            label: Text(
                              'play_again'.tr,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: isVeryShort ? 10.5 : (isShort ? 11.5 : 13),
                              ),
                            ),
                          ),
                          // Nút chuyển Ải / Bracket tiếp theo cho các chế độ chơi Offline
                          if (isLocalWinner) ...[
                            if (gameInstance.activeBotStage != null &&
                                gameInstance.activeBotStage!.stageNumber < BotStageCatalog.stages.length) ...[
                              Builder(
                                builder: (context) {
                                  final nextStageNum = gameInstance.activeBotStage!.stageNumber + 1;
                                  final nextStage = BotStageCatalog.stages.firstWhere(
                                    (s) => s.stageNumber == nextStageNum,
                                    orElse: () => BotStageCatalog.stages.first,
                                  );
                                  return FilledButton.icon(
                                    onPressed: () => gameInstance.startBotStage(nextStage),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFB300),
                                      foregroundColor: Colors.black87,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isShort ? 14 : 18,
                                        vertical: isVeryShort ? 4 : (isShort ? 6 : 9),
                                      ),
                                      minimumSize: Size(0, isVeryShort ? 28 : (isShort ? 32 : 40)),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: Icon(Icons.arrow_forward, size: isVeryShort ? 14 : (isShort ? 15 : 18)),
                                    label: Text(
                                      'next_stage'.tr.replaceAll('{num}', '$nextStageNum'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: isVeryShort ? 10.5 : (isShort ? 11.5 : 13),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ] else if (gameInstance.activeTournamentStage != null &&
                                gameInstance.activeTournamentStage!.bracketNumber < 5) ...[
                              Builder(
                                builder: (context) {
                                  final nextBracketNum = gameInstance.activeTournamentStage!.bracketNumber + 1;
                                  final nextStage = TournamentCatalog.getByBracket(nextBracketNum);
                                  return FilledButton.icon(
                                    onPressed: () => gameInstance.startTournamentStage(nextStage),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFD54F),
                                      foregroundColor: Colors.black87,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isShort ? 14 : 18,
                                        vertical: isVeryShort ? 4 : (isShort ? 6 : 9),
                                      ),
                                      minimumSize: Size(0, isVeryShort ? 28 : (isShort ? 32 : 40)),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: Icon(
                                      nextBracketNum == 5 ? Icons.emoji_events : Icons.arrow_forward,
                                      size: isVeryShort ? 14 : (isShort ? 15 : 18),
                                    ),
                                    label: Text(
                                      nextBracketNum == 5
                                          ? 'finals'.tr
                                          : 'next_bracket'.tr.replaceAll('{num}', '$nextBracketNum'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: isVeryShort ? 10.5 : (isShort ? 11.5 : 13),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ] else if (gameInstance.activeLegendaryTrickshot != null) ...[
                              Builder(
                                builder: (context) {
                                  final list = LegendaryTrickshotCatalog.trickshots;
                                  final curIdx = list.indexWhere((s) => s.id == gameInstance.activeLegendaryTrickshot!.id);
                                  if (curIdx >= 0 && curIdx < list.length - 1) {
                                    final nextShot = list[curIdx + 1];
                                    return FilledButton.icon(
                                      onPressed: () => gameInstance.startLegendaryTrickshot(nextShot),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(0xFFFF80AB),
                                        foregroundColor: Colors.black87,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isShort ? 14 : 18,
                                          vertical: isVeryShort ? 4 : (isShort ? 6 : 9),
                                        ),
                                        minimumSize: Size(0, isVeryShort ? 28 : (isShort ? 32 : 40)),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: Icon(Icons.arrow_forward, size: isVeryShort ? 14 : (isShort ? 15 : 18)),
                                      label: Text(
                                        'next_trickshot'.tr,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: isVeryShort ? 10.5 : (isShort ? 11.5 : 13),
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildControlBar(
  BuildContext context, {
  bool compact = false,
  bool ultraCompact = false,
  double upscaleFactor = 1.0,
  required VoidCallback onHome,
}) {
  return ListenableBuilder(
    listenable: LanguageService.instance,
    builder: (context, _) {
      return ValueListenableBuilder<int>(
        valueListenable: gameInstance.groupVersion,
        builder: (context, _, child) {
          return ValueListenableBuilder<int>(
            valueListenable: gameInstance.currentTurn,
            builder: (context, turn, child) {
          // Giao diện thanh trạng thái riêng cho Thế Bi Hàng Ngày (Daily Trickshot)
          if (gameInstance.activeDailyPuzzle != null) {
            final puzzle = gameInstance.activeDailyPuzzle!;
            return Container(
              height: (ultraCompact ? 48.0 : (compact ? 58.0 : 66.0)) * upscaleFactor.clamp(0.95, 1.15),
              padding: EdgeInsets.symmetric(horizontal: ultraCompact ? 6 : 12, vertical: ultraCompact ? 2 : 3),
              decoration: BoxDecoration(
                color: const Color(0xE620252A),
                borderRadius: BorderRadius.circular(ultraCompact ? 8 : 12),
                border: Border.all(color: const Color(0xFFAB47BC), width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3)),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'main_menu'.tr,
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    iconSize: ultraCompact ? 18 : 22,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: onHome,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7B1FA2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'DAILY PUZZLE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                LanguageService.instance.localizeStageTitle(puzzle.title),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: ultraCompact ? 11 : 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          puzzle.description,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: ultraCompact ? 9 : 10.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFD54F)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sports_baseball, color: Color(0xFFFFD54F), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${'turn'.tr}: ${gameInstance.dailyPuzzleShotsTaken} / ${puzzle.maxShotsAllowed}',
                          style: const TextStyle(
                            color: Color(0xFFFFD54F),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'restart'.tr,
                    icon: const Icon(Icons.refresh, color: Color(0xFF69F0AE)),
                    iconSize: ultraCompact ? 18 : 22,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () {
                      gameInstance.startDailyPuzzle(puzzle);
                    },
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: '${'hint'.tr}: ${puzzle.hint}',
                    icon: const Icon(Icons.lightbulb, color: Color(0xFFFFEB3B)),
                    iconSize: ultraCompact ? 18 : 22,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('💡 ${'hint'.tr}: ${puzzle.hint}'),
                          backgroundColor: const Color(0xFF4A148C),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'settings_title'.tr,
                    icon: const Icon(Icons.settings),
                    color: Colors.white,
                    iconSize: ultraCompact ? 16 : (compact ? 19 : 22),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tightFor(
                      width: ultraCompact ? 28 : (compact ? 32 : 38),
                      height: ultraCompact ? 28 : (compact ? 32 : 38),
                    ),
                    style: IconButton.styleFrom(backgroundColor: Colors.black54),
                    onPressed: () => _showSettings(context, onHome: onHome),
                  ),
                ],
              ),
            );
          }

          // Giao diện thanh trạng thái riêng cho Chế Độ Thế Đánh Huyền Thoại
          if (gameInstance.activeLegendaryTrickshot != null) {
            final shot = gameInstance.activeLegendaryTrickshot!;
            final locPocket = LanguageService.instance.localizePocketName(shot.targetPocketName);
            return Container(
              height: (ultraCompact ? 48.0 : (compact ? 58.0 : 66.0)) * upscaleFactor.clamp(0.95, 1.15),
              padding: EdgeInsets.symmetric(horizontal: ultraCompact ? 6 : 10, vertical: ultraCompact ? 2 : 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2A0808), Color(0xFF4A1010), Color(0xFF1F0505)],
                ),
                borderRadius: BorderRadius.circular(ultraCompact ? 8 : 12),
                border: Border.all(color: const Color(0xFFFFD700), width: 1.6),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 3)),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'main_menu'.tr,
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    iconSize: ultraCompact ? 18 : 22,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: onHome,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    shot.playerAvatar,
                    style: TextStyle(fontSize: ultraCompact ? 16 : 22),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                LanguageService.instance.localizeMasterName(shot.masterName).toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF3E1200),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                LanguageService.instance.localizeTrickshotTitle(shot.id, shot.title),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: ultraCompact ? 11 : 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E676),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '🎯 ${'pot_ball'.tr} #${shot.targetBallNumber}',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (shot.obstacleBallNumbers.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF5252),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '🚫 ${'avoid_ball'.tr} #${shot.obstacleBallNumbers.join(',')}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${LanguageService.instance.localizeTrickshotHint(shot.id, shot.techniqueNotes)} • ${'pot_ball'.tr} #${shot.targetBallNumber} -> $locPocket',
                          style: TextStyle(
                            color: const Color(0xFFFFE082),
                            fontSize: ultraCompact ? 8.5 : 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Nút ĐẶT LẠI THẾ BI để người chơi luyện tập liên tục
                  FilledButton.icon(
                    onPressed: () {
                      gameInstance.restartMatch();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB300),
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(
                        horizontal: ultraCompact ? 6 : 10,
                        vertical: ultraCompact ? 2 : 6,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: Icon(Icons.refresh, size: ultraCompact ? 12 : 15),
                    label: Text(
                      'reset_shot'.tr,
                      style: TextStyle(
                        fontSize: ultraCompact ? 9 : 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: '${'hint'.tr}: ${LanguageService.instance.localizeTrickshotHint(shot.id, shot.techniqueNotes)}',
                    icon: const Icon(Icons.lightbulb, color: Color(0xFFFFD700)),
                    iconSize: ultraCompact ? 18 : 22,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('🎯 ${LanguageService.instance.localizeMasterName(shot.masterName)}: ${LanguageService.instance.localizeTrickshotHint(shot.id, shot.techniqueNotes)}'),
                          backgroundColor: const Color(0xFF5D1010),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'settings_title'.tr,
                    icon: const Icon(Icons.settings),
                    color: Colors.white,
                    iconSize: ultraCompact ? 16 : (compact ? 19 : 22),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tightFor(
                      width: ultraCompact ? 28 : (compact ? 32 : 38),
                      height: ultraCompact ? 28 : (compact ? 32 : 38),
                    ),
                    style: IconButton.styleFrom(backgroundColor: Colors.black54),
                    onPressed: () => _showSettings(context, onHome: onHome),
                  ),
                ],
              ),
            );
          }

          return ListenableBuilder(
            listenable: Listenable.merge([
              ProgressionService.instance,
              LocalMultiplayerService.instance,
              OnlineMultiplayerService.instance,
              gameInstance.isLocalMultiplayer,
              gameInstance.isOnlineMultiplayer,
              gameInstance.player2CueId,
              gameInstance.player2CueLevel,
              gameInstance.matchVersion,
              gameInstance.groupVersion,
              LanguageService.instance,
            ]),
            builder: (context, _) {
              // Tên hiển thị người chơi P1 và P2 theo chế độ
              String p1Name = 'Player 1';
              String p2Name = 'Player 2';
              int p1Level = ProgressionService.instance.playerLevel;
              int p1Coins = ProgressionService.instance.coins;
              int p2Level = 1;
              int p2Coins = 1200;

              // Thông tin gậy cơ P1 và P2
              CueModel p1Cue = ProgressionService.instance.equippedCue;
              int p1CueLevel = gameInstance.isPassAndPlay
                  ? 1
                  : ProgressionService.instance.equippedCueLevel;
              CueModel p2Cue = CueCatalog.getById(gameInstance.player2CueId.value);
              int p2CueLevel = gameInstance.isPassAndPlay
                  ? 1
                  : gameInstance.player2CueLevel.value;

              if (gameInstance.activeTournamentStage != null) {
                final tour = gameInstance.activeTournamentStage!;
                p2Name = tour.opponentName;
                p2Cue = tour.opponentCue;
                p2CueLevel = tour.opponentLevel;
                p2Level = tour.opponentLevel;
              } else if (gameInstance.activeBotStage != null) {
                p2Name = gameInstance.activeBotStage!.botName;
                p2Cue = gameInstance.activeBotStage!.cue;
                p2CueLevel = gameInstance.activeBotStage!.stageNumber;
                p2Level = gameInstance.activeBotStage!.stageNumber;
              } else if (gameInstance.isBotMode.value) {
                final isHard = gameInstance.botDifficulty.value == 2;
                p2Name = isHard ? 'bot_hard'.tr : 'bot_easy'.tr;
                p2Cue = CueCatalog.getById(isHard ? 'dragon_god' : 'frostbite');
                p2CueLevel = isHard ? 4 : 2;
                p2Level = isHard ? 6 : 2;
              } else if (gameInstance.isOnlineMultiplayer.value) {
                final oppCueId = OnlineMultiplayerService.instance.opponentCueId;
                final oppCueLvl = OnlineMultiplayerService.instance.opponentCueLevel;
                final oppCue = CueCatalog.getById(oppCueId);
                p2Name = OnlineMultiplayerService.instance.opponentName;
                if (OnlineMultiplayerService.instance.isHost) {
                  p1Cue = ProgressionService.instance.equippedCue;
                  p1CueLevel = ProgressionService.instance.equippedCueLevel;
                  p2Cue = oppCue;
                  p2CueLevel = oppCueLvl;
                } else {
                  p1Cue = oppCue;
                  p1CueLevel = oppCueLvl;
                  p2Cue = ProgressionService.instance.equippedCue;
                  p2CueLevel = ProgressionService.instance.equippedCueLevel;
                  p1Name = OnlineMultiplayerService.instance.opponentName;
                  p2Name = 'you'.tr;
                }
              } else if (gameInstance.isLocalMultiplayer.value) {
                final oppCueId = LocalMultiplayerService.instance.opponentCueId;
                final oppCueLvl = LocalMultiplayerService.instance.opponentCueLevel;
                final oppCue = CueCatalog.getById(oppCueId);
                final oppName = LocalMultiplayerService.instance.opponentName.isNotEmpty
                    ? LocalMultiplayerService.instance.opponentName
                    : (LocalMultiplayerService.instance.isHost ? 'guest_p2'.tr : 'host_p1'.tr);
                if (LocalMultiplayerService.instance.isHost) {
                  p1Cue = ProgressionService.instance.equippedCue;
                  p1CueLevel = ProgressionService.instance.equippedCueLevel;
                  p2Cue = oppCue;
                  p2CueLevel = oppCueLvl;
                  p2Name = oppName;
                } else {
                  p1Cue = oppCue;
                  p1CueLevel = oppCueLvl;
                  p2Cue = ProgressionService.instance.equippedCue;
                  p2CueLevel = ProgressionService.instance.equippedCueLevel;
                  p1Name = oppName;
                  p2Name = 'you'.tr;
                }
              }

              return Container(
                height: (ultraCompact ? 48.0 : (compact ? 58.0 : 66.0)) * upscaleFactor.clamp(0.95, 1.15),
                padding: EdgeInsets.symmetric(
                  horizontal: ultraCompact ? 4 : 8,
                  vertical: ultraCompact ? 2 : 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xE620252A),
                  borderRadius: BorderRadius.circular(ultraCompact ? 8 : 12),
                  border: Border.all(color: Colors.white24),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildPlayerCard(
                        p1Name,
                        Colors.blue,
                        turn == 1,
                        gameInstance.playerScores[1] ?? 0,
                        gameInstance.groupLabel(1),
                        gameInstance.groupBalls(1),
                        false,
                        level: p1Level,
                        coins: p1Coins,
                        cue: p1Cue,
                        cueLevel: p1CueLevel,
                        compact: compact,
                        ultraCompact: ultraCompact,
                        upscaleFactor: upscaleFactor,
                        onTapCue: null, // Chỉ được đổi cơ ở ngoài main menu, không được đổi giữa trận đấu
                      ),
                    ),
                    SizedBox(width: ultraCompact ? 2 : 4),
                    // Nút Âm thanh nhanh
                    ValueListenableBuilder<bool>(
                      valueListenable: AudioManager.instance.isMusicEnabled,
                      builder: (context, musicOn, _) {
                        return ValueListenableBuilder<bool>(
                          valueListenable: AudioManager.instance.isSfxEnabled,
                          builder: (context, sfxOn, _) {
                            final anyOn = musicOn || sfxOn;
                            return IconButton(
                              tooltip: anyOn ? 'audio_on'.tr : 'audio_off'.tr,
                              icon: Icon(
                                anyOn ? Icons.volume_up : Icons.volume_off,
                                color: anyOn ? const Color(0xFFFFD54F) : Colors.white38,
                              ),
                              iconSize: ultraCompact ? 16 : (compact ? 19 : 22),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints.tightFor(
                                width: ultraCompact ? 28 : (compact ? 32 : 38),
                                height: ultraCompact ? 28 : (compact ? 32 : 38),
                              ),
                              style: IconButton.styleFrom(backgroundColor: Colors.black54),
                              onPressed: () => _showSettings(context, onHome: onHome),
                            );
                          },
                        );
                      },
                    ),
                    SizedBox(width: ultraCompact ? 2 : 4),
                    // Nút Cài đặt ở giữa (Shop đã đưa về góc phải màn hình chính theo yêu cầu)
                    IconButton(
                      tooltip: 'settings_title'.tr,
                      icon: const Icon(Icons.settings),
                      color: Colors.white,
                      iconSize: ultraCompact ? 16 : (compact ? 19 : 22),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints.tightFor(
                        width: ultraCompact ? 28 : (compact ? 32 : 38),
                        height: ultraCompact ? 28 : (compact ? 32 : 38),
                      ),
                      style: IconButton.styleFrom(backgroundColor: Colors.black54),
                      onPressed: () => _showSettings(context, onHome: onHome),
                    ),
                    SizedBox(width: ultraCompact ? 2 : 6),
                    Expanded(
                      child: _buildPlayerCard(
                        p2Name,
                        Colors.red,
                        turn == 2,
                        gameInstance.playerScores[2] ?? 0,
                        gameInstance.groupLabel(2),
                        gameInstance.groupBalls(2),
                        true,
                        level: p2Level,
                        coins: p2Coins,
                        cue: p2Cue,
                        cueLevel: p2CueLevel,
                        compact: compact,
                        ultraCompact: ultraCompact,
                        upscaleFactor: upscaleFactor,
                        onTapCue: null, // Chỉ được đổi cơ ở ngoài main menu, không được đổi giữa trận đấu
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
    },
  );
}

void _showSettings(BuildContext context, {required VoidCallback onHome}) {
  showDialog<void>(
    context: context,
    builder: (context) => ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) => AlertDialog(
        backgroundColor: const Color(0xFF1E2328),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.tune, color: Color(0xFFFFD54F)),
            const SizedBox(width: 8),
            Text(
              'settings_title'.tr,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Nhạc nền (BGM)
              ValueListenableBuilder<bool>(
                valueListenable: AudioManager.instance.isMusicEnabled,
                builder: (context, musicOn, _) {
                  return ValueListenableBuilder<double>(
                    valueListenable: AudioManager.instance.musicVolume,
                    builder: (context, musicVol, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    musicOn ? Icons.music_note : Icons.music_off,
                                    color: musicOn ? const Color(0xFFFFD54F) : Colors.white38,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'bgm_title'.tr,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                                  ),
                                ],
                              ),
                              Switch(
                                value: musicOn,
                                activeThumbColor: const Color(0xFFFFD54F),
                                onChanged: (_) {
                                  AudioManager.instance.toggleMusic();
                                },
                              ),
                            ],
                          ),
                          if (musicOn)
                            Row(
                              children: [
                                const Icon(Icons.volume_down, color: Colors.white54, size: 16),
                                Expanded(
                                  child: Slider(
                                    value: musicVol,
                                    min: 0.0,
                                    max: 1.0,
                                    activeColor: const Color(0xFFFFD54F),
                                    inactiveColor: Colors.white24,
                                    onChanged: (v) {
                                      AudioManager.instance.setMusicVolume(v);
                                    },
                                  ),
                                ),
                                const Icon(Icons.volume_up, color: Colors.white54, size: 16),
                              ],
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
              const Divider(color: Colors.white24, height: 16),
              // 2. Hiệu ứng âm thanh (SFX)
              ValueListenableBuilder<bool>(
                valueListenable: AudioManager.instance.isSfxEnabled,
                builder: (context, sfxOn, _) {
                  return ValueListenableBuilder<double>(
                    valueListenable: AudioManager.instance.sfxVolume,
                    builder: (context, sfxVol, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    sfxOn ? Icons.volume_up : Icons.volume_off,
                                    color: sfxOn ? const Color(0xFF00E5FF) : Colors.white38,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'sfx_title'.tr,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                                  ),
                                ],
                              ),
                              Switch(
                                value: sfxOn,
                                activeThumbColor: const Color(0xFF00E5FF),
                                onChanged: (_) {
                                  AudioManager.instance.toggleSfx();
                                },
                              ),
                            ],
                          ),
                          if (sfxOn)
                            Row(
                              children: [
                                const Icon(Icons.volume_down, color: Colors.white54, size: 16),
                                Expanded(
                                  child: Slider(
                                    value: sfxVol,
                                    min: 0.0,
                                    max: 1.0,
                                    activeColor: const Color(0xFF00E5FF),
                                    inactiveColor: Colors.white24,
                                    onChanged: (v) {
                                      AudioManager.instance.setSfxVolume(v);
                                    },
                                  ),
                                ),
                                const Icon(Icons.volume_up, color: Colors.white54, size: 16),
                              ],
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
              const Divider(color: Colors.white24, height: 20),
              Text(
                'match_actions'.tr,
                style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // 1. Nút "Xử thua": CHỈ CÓ KHẢ NĂNG XỬ THUA KHI ĐẤU HOTSPOT LOCAL LAN
                  if (gameInstance.isLocalMultiplayer.value && !gameInstance.isOnlineMultiplayer.value)
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showDeclareLoss(context);
                      },
                      icon: const Icon(Icons.flag, size: 16, color: Colors.orangeAccent),
                      label: Text('surrender_lan'.tr),
                    ),

                  // 2. Nút "Menu chính":
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onHome();
                    },
                    icon: const Icon(Icons.home, size: 16),
                    label: Text('main_menu'.tr),
                  ),

                  // 3. Nút "Bắt đầu lại":
                  if (!gameInstance.isOnlineMultiplayer.value)
                    FilledButton.icon(
                      onPressed: () {
                        gameInstance.restartMatch();
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.restart_alt, size: 16),
                      label: Text('restart'.tr),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('close'.tr, style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    ),
  );
}

// void _showConfirmOnlineForfeit(BuildContext context, {required VoidCallback onHome}) {
//   showDialog<void>(
//     context: context,
//     builder: (dialogCtx) => AlertDialog(
//       backgroundColor: const Color(0xFF1E2328),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       title: const Row(
//         children: [
//           Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
//           SizedBox(width: 8),
//           Text('Xác nhận rời trận', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
//         ],
//       ),
//       content: const Text(
//         'Bạn có chắc chắn muốn rời trận đấu Online không?\n\n'
//         '⚠️ NẾU XÁC NHẬN, BẠN SẼ BỊ XỬ THUA NGAY LẬP TỨC và đối thủ còn lại sẽ giành chiến thắng!',
//         style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(dialogCtx),
//           child: const Text('Tiếp tục chơi', style: TextStyle(color: Colors.white70)),
//         ),
//         FilledButton(
//           style: FilledButton.styleFrom(
//             backgroundColor: const Color(0xFFC62828),
//             foregroundColor: Colors.white,
//           ),
//           onPressed: () {
//             Navigator.pop(dialogCtx);
//             // Gửi gói tin forfeit lên WebSocket server
//             OnlineMultiplayerService.instance.forfeitMatch();
//             // Ghi nhận thua cho bản thân
//             final myIdx = OnlineMultiplayerService.instance.isHost ? 1 : 2;
//             gameInstance.declareLoss(myIdx);
//             onHome();
//           },
//           child: const Text('Rời trận (Xử thua)', style: TextStyle(fontWeight: FontWeight.bold)),
//         ),
//       ],
//     ),
//   );
// }

void _showConfirmExitMatch(BuildContext context, {required VoidCallback onHome}) {
  showDialog<void>(
    context: context,
    builder: (dialogCtx) => ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) => AlertDialog(
        backgroundColor: const Color(0xFF1E2328),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFFF5252), width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252), size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'exit_match_title'.tr,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          'exit_match_content'.tr,
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'stay_in_match'.tr,
              style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              onHome();
            },
            child: Text(
              'confirm_forfeit_exit'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ),
  );
}

void _showDeclareLoss(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) => ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) => AlertDialog(
        title: Text('surrender_lan'.tr),
        content: Text(
          switch (LanguageService.instance.currentCode) {
            'zh' => '哪位玩家被判负？',
            'ja' => 'どちらのプレイヤーを不戦敗としますか？',
            'ko' => '어느 플레이어를 몰수패로 처리합니까?',
            'en' => 'Which player forfeits this rack?',
            _ => 'Player nào bị xử thua trận này?',
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              gameInstance.declareLoss(1);
              Navigator.pop(context);
            },
            child: Text('${'player_1'.tr} ${'defeat'.tr.toLowerCase()}'),
          ),
          TextButton(
            onPressed: () {
              gameInstance.declareLoss(2);
              Navigator.pop(context);
            },
            child: Text('${'player_2'.tr} ${'defeat'.tr.toLowerCase()}'),
          ),
        ],
      ),
    ),
  );
}

// ignore: unused_element
void _showCueSelectorDialog(BuildContext context, {required bool forPlayer2}) {
  showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final isP2 = forPlayer2;
          final currentCueId = isP2
              ? gameInstance.player2CueId.value
              : ProgressionService.instance.equippedCue.id;
          final currentLevel = isP2
              ? gameInstance.player2CueLevel.value
              : ProgressionService.instance.equippedCueLevel;

          final screenWidth = MediaQuery.of(context).size.width;
          final screenHeight = MediaQuery.of(context).size.height;

          return AlertDialog(
            backgroundColor: const Color(0xFF181C22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            title: Row(
              children: [
                Icon(
                  Icons.sports_baseball,
                  color: isP2 ? const Color(0xFFFF5252) : const Color(0xFF29B6F6),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isP2 ? 'select_cue_p2'.tr : 'select_cue_p1'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            content: SizedBox(
              width: math.min(screenWidth * 0.92, 440),
              height: math.min(screenHeight * 0.70, 420),
              child: ListView.separated(
                itemCount: CueCatalog.allCues.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final cue = CueCatalog.allCues[index];
                  final isSelected = cue.id == currentCueId;

                  return Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cue.rarity.color.withValues(alpha: 0.16)
                          : const Color(0xFF222933),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? cue.rarity.color : Colors.white12,
                        width: isSelected ? 1.5 : 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: cue.rarity.color.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: cue.rarity.color, width: 0.6),
                              ),
                              child: Text(
                                cue.rarity.displayName.toUpperCase(),
                                style: TextStyle(
                                  color: cue.rarity.color,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                cue.localizedName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00E676).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFF00E676), width: 0.7),
                                ),
                                child: Text(
                                  'equipped'.tr.toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFF00E676),
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        // Dải màu thân cơ (Shaft visual preview)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Container(
                            height: 5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  cue.tipColor,
                                  ...cue.shaftColors,
                                  ...cue.handleColors,
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            _buildStatMiniItem('force'.tr, cue.baseStats.force, const Color(0xFFFF7043)),
                            const SizedBox(width: 8),
                            _buildStatMiniItem('aim'.tr, cue.baseStats.aim, const Color(0xFF42A5F5)),
                            const SizedBox(width: 8),
                            _buildStatMiniItem('spin'.tr, cue.baseStats.spin, const Color(0xFFAB47BC)),
                            const Spacer(),
                            if (isP2 && isSelected) ...[
                              Row(
                                children: [
                                  Text('${'level'.tr}: ', style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold)),
                                  DropdownButton<int>(
                                    value: currentLevel,
                                    dropdownColor: const Color(0xFF1E2328),
                                    isDense: true,
                                    underline: const SizedBox.shrink(),
                                    style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 11, fontWeight: FontWeight.bold),
                                    items: [for (int i = 1; i <= 10; i++) DropdownMenuItem(value: i, child: Text('Lv.$i'))],
                                    onChanged: (newLv) {
                                      if (newLv != null) {
                                        gameInstance.player2CueLevel.value = newLv;
                                        setDialogState(() {});
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ] else if (!isSelected) ...[
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: cue.rarity.color.withValues(alpha: 0.3),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  minimumSize: const Size(54, 24),
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    side: BorderSide(color: cue.rarity.color, width: 0.8),
                                  ),
                                ),
                                onPressed: () {
                                  if (isP2) {
                                    gameInstance.setPlayer2Cue(cue.id, currentLevel);
                                  } else {
                                    ProgressionService.instance.equipCue(cue.id);
                                    gameInstance.matchVersion.value++;
                                  }
                                  setDialogState(() {});
                                },
                                child: Text('select'.tr, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            actions: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF29B6F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text('close'.tr),
              ),

            ],
          );
        },
      );
    },
  );
}

Widget _buildStatMiniItem(String label, double val, Color color) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('$label ', style: const TextStyle(color: Colors.white54, fontSize: 9)),
      Text(
        val.toStringAsFixed(1),
        style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.bold),
      ),
    ],
  );
}

Widget _buildPlayerCard(
  String name,
  Color color,
  bool isTurn,
  int score,
  String groupLabel,
  List<int> groupBalls,
  bool alignRight, {
  int level = 1,
  int coins = 1200,
  CueModel? cue,
  int cueLevel = 1,
  bool compact = false,
  bool ultraCompact = false,
  double upscaleFactor = 1.0,
  VoidCallback? onTapCue,
}) {
  final ballBoxSize = (ultraCompact ? 15.0 : (compact ? 18.0 : 22.0)) * upscaleFactor;
  final ballImgSize = (ultraCompact ? 13.0 : (compact ? 16.0 : 20.0)) * upscaleFactor;
  final nameFontSize = (ultraCompact ? 9.5 : (compact ? 11.0 : 12.0)) * upscaleFactor;
  final detailFontSize = (ultraCompact ? 7.0 : (compact ? 8.0 : 9.0)) * upscaleFactor;

  final cardWidget = Container(
    padding: EdgeInsets.symmetric(
      horizontal: ultraCompact ? 3 : 5,
      vertical: ultraCompact ? 1 : 2,
    ),
    decoration: BoxDecoration(
      color: color.withValues(alpha: isTurn ? 0.16 : 0.04),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: color.withValues(alpha: isTurn ? 0.8 : 0.18),
        width: isTurn ? 1.2 : 0.7,
      ),
    ),
    child: Row(
      textDirection: alignRight ? TextDirection.rtl : TextDirection.ltr,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Cột thông tin người chơi: Level, Tên, Tiền ($), Tỷ số
        Expanded(
          flex: 5,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: alignRight
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // 1. Dòng Level + Tên người chơi
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isTurn && !alignRight)
                      Icon(
                        Icons.arrow_forward_ios,
                        color: const Color(0xFF00E676),
                        size: ultraCompact ? 8 : 10,
                      ),
                    if (isTurn && !alignRight) SizedBox(width: ultraCompact ? 2 : 3),
                    // Huy hiệu Level nhỏ gọn
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ultraCompact ? 3 : 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        'Lv.$level',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ultraCompact ? 6.8 : 8.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 3.5),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: (ultraCompact ? 80.0 : (compact ? 100.0 : 130.0)) * upscaleFactor,
                      ),
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: nameFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isTurn && alignRight) SizedBox(width: ultraCompact ? 2 : 3),
                    if (isTurn && alignRight)
                      Icon(
                        Icons.arrow_back_ios,
                        color: const Color(0xFF00E676),
                        size: ultraCompact ? 8 : 10,
                      ),
                  ],
                ),
                // 2. Dòng Tiền Vàng ($) & Tỷ số (lấp đầy vị trí còn trống)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.monetization_on,
                      color: const Color(0xFFFFD54F),
                      size: ultraCompact ? 9 : 11,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      _formatPlayerCardCoins(coins),
                      style: TextStyle(
                        color: const Color(0xFFFFE082),
                        fontSize: detailFontSize,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      ' • ',
                      style: TextStyle(color: Colors.white38, fontSize: detailFontSize),
                    ),
                    Text(
                      '${'score'.tr}: $score',
                      style: TextStyle(color: Colors.white70, fontSize: detailFontSize),
                    ),
                  ],
                ),
                // 3. Phân loại bi mục tiêu (Bi trơn / Bi sọc)
                if (groupLabel.isNotEmpty)
                  Text(
                    groupLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFFFFD54F),
                      fontSize: detailFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 2),
        // Cột bi mục tiêu của người chơi
        Expanded(
          flex: 5,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: alignRight
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: Wrap(
              alignment: WrapAlignment.spaceAround,
              runAlignment: WrapAlignment.center,
              spacing: ultraCompact ? 1.5 : 2.5,
              runSpacing: 1.0,
              textDirection: alignRight
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              children: [
                for (final number in groupBalls)
                  Opacity(
                    opacity: gameInstance.isBallPocketed(number) ? 0.25 : 1,
                    child: Container(
                      width: ballBoxSize,
                      height: ballBoxSize,
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(ballBoxSize / 2),
                        border: Border.all(color: Colors.white24, width: 0.6),
                      ),
                      child: Image.asset(
                        'assets/images/ball_$number.png',
                        width: ballImgSize,
                        height: ballImgSize,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            number.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: (ultraCompact ? 6.5 : 8.0) * upscaleFactor,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
  if (onTapCue != null) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTapCue,
      child: cardWidget,
    );
  }
  return cardWidget;
}

String _formatPlayerCardCoins(int amount) {
  if (amount >= 1000000) {
    return '\$${(amount / 1000000).toStringAsFixed(1)}M';
  } else if (amount >= 10000) {
    return '\$${(amount / 1000).toStringAsFixed(1)}k';
  } else {
    return '\$${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }
}

/// Quản lý thông báo luật chơi và lượt đấu:
/// Tự động kích hoạt notifyListeners() mỗi khi có thông báo mới (kể cả cùng nội dung)
/// để thanh thông báo luôn thực hiện hiệu ứng popup và mờ dần biến mất cho mỗi thông báo.
class RuleMessageNotifier extends ValueNotifier<String> {
  RuleMessageNotifier(super.value);

  int _version = 0;
  int get version => _version;

  @override
  set value(String newValue) {
    _version++;
    if (value == newValue) {
      notifyListeners();
    } else {
      super.value = newValue;
    }
  }

  void postMessage(String msg) {
    value = msg;
  }
}

class BilliardGame extends Forge2DGame with PanDetector {
  BilliardGame()
    : super(
        gravity: Vector2.zero(),
        contactListener: BilliardContactListener(),
      );

  // Quản lý hiệu ứng vật lý thị giác (VFX): Sóng kích va chạm, bụi lơ, gợn nảy băng, vệt mờ tốc độ cao
  final BilliardVfxComponent vfx = BilliardVfxComponent();

  // Biến quản lý lượt chơi (Turn base)
  ValueNotifier<int> currentTurn = ValueNotifier<int>(1);
  ValueNotifier<bool> isBotMode = ValueNotifier<bool>(false);
  ValueNotifier<int> botDifficulty = ValueNotifier<int>(1);
  RuleMessageNotifier ruleMessage = RuleMessageNotifier(
    'Player 1: break shot',
  );
  ValueNotifier<double> shotPower = ValueNotifier<double>(0.05);
  ValueNotifier<Offset> cueSpin = ValueNotifier<Offset>(Offset.zero);
  ValueNotifier<int> groupVersion = ValueNotifier<int>(0);
  ValueNotifier<int> matchVersion = ValueNotifier<int>(0);
  final Map<int, int> playerScores = {1: 0, 2: 0};
  int? winningPlayer;

  // Cây gậy cơ và cấp độ riêng cho Player 2 (chế độ Pass & Play 2 người trên cùng thiết bị)
  final ValueNotifier<String> player2CueId = ValueNotifier<String>('phoenix_flame');
  final ValueNotifier<int> player2CueLevel = ValueNotifier<int>(2);

  void setPlayer2Cue(String cueId, [int level = 1]) {
    player2CueId.value = cueId;
    player2CueLevel.value = level.clamp(1, 10);
    matchVersion.value++;
  }

  // Chế độ Ải Bot Campaign, Thế Bi Hàng Ngày, Mạng Local WiFi, Tournament, Online WebSocket
  BotStageModel? activeBotStage;
  DailyPuzzleModel? activeDailyPuzzle;
  LegendaryTrickshotModel? activeLegendaryTrickshot;
  TournamentBracketStage? activeTournamentStage;
  int dailyPuzzleShotsTaken = 0;
  final ValueNotifier<bool> isLocalMultiplayer = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isOnlineMultiplayer = ValueNotifier<bool>(false);

  // Quản lý vòng đời ứng dụng và mô phỏng vật lý thời gian thực khi thoát / ấn Home
  bool isAppPaused = false;
  bool isCatchingUp = false;
  DateTime? _appPausedTime;
  bool _skipNextDt = false;
  double _shotElapsedTime = 0.0;

  // Vết bóng mờ lần bắn trước (Ghost Trail Replay) cho Trickshot & Daily Puzzle
  double? previousShotAimAngle;
  Vector2? previousShotAimVector;
  double? previousShotPower;
  Offset? previousShotSpin;
  bool showPreviousShotGhost = false;

  // Trạng thái nhắm mượt mà của Bot AI
  double targetBotAngle = 0.0;
  double targetBotPower = 0.40;

  void onAppPaused() {
    _appPausedTime = DateTime.now();
    isAppPaused = true;
    _skipNextDt = true;
    resetAllInputGestures();
    try {
      pauseEngine();
    } catch (_) {}
  }

  void onAppResumed() {
    isAppPaused = false;
    _skipNextDt = true;
    try {
      resumeEngine();
    } catch (_) {}

    final pauseTime = _appPausedTime;
    _appPausedTime = null;

    if (pauseTime != null && shotInProgress) {
      final elapsed = DateTime.now().difference(pauseTime).inMilliseconds / 1000.0;
      if (elapsed > 0.05) {
        _catchUpRealtimePhysics(elapsed);
      }
    }

    if (isBotMode.value && currentTurn.value == 2 && !shotInProgress && !rackOver) {
      botWaitTime = 0.2;
      botState = 0;
    }

    resetAllInputGestures();
    _sanitizeAllBallBodies();
  }

  void resetAllInputGestures() {
    dragStart = null;
    dragCurrent = null;
    if (movingCueBall) {
      movingCueBall = false;
    }
    powerDragStartY = null;
    if (!shotInProgress) {
      shotPower.value = 0.05;
    }
    settledTime = 0;
    _skipNextDt = true;

    if (!shotInProgress && _hasGameLoaded && physicsReady) {
      cueBall.isAiming = true;
      _updateAimVector(ballRadius * 2);
    }
  }

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    super.lifecycleStateChange(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive) {
      onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      onAppResumed();
    }
  }

  void _catchUpRealtimePhysics(double elapsedSeconds) {
    if (!_hasGameLoaded || !physicsReady || !shotInProgress) return;

    // Giới hạn thời gian bù tối đa 3.0 giây (~180 bước) để phản hồi tức thì và không làm giật khung hình
    final double duration = elapsedSeconds.clamp(0.0, 3.0);
    const double stepDt = 0.0166667;
    final int steps = (duration / stepDt).round();

    isCatchingUp = true;
    try {
      for (int i = 0; i < steps; i++) {
        super.update(stepDt);
        _checkContinuousPocketDrops();
        _keepBallsInsideTable();
        _applyClothPhysics(stepDt);

        if (shotInProgress) {
          _shotElapsedTime += stepDt;
          final cueStopped = _bodyStopped(cueBall.body) && cueBall.isSunkAnimComplete;
          final ballsStopped = poolBalls.every(
            (ball) => ball.isRemoved || (_bodyStopped(ball.body) && ball.isSunkAnimComplete),
          );
          if (cueStopped && ballsStopped) {
            settledTime += stepDt;
            if (settledTime > 0.25) {
              _shotElapsedTime = 0.0;
              if (isOnlineMultiplayer.value && !isMyTurn) {
                shotInProgress = false;
              } else {
                finishShot();
              }
              break;
            }
          } else {
            settledTime = 0;
          }

          if (_shotElapsedTime > 10.0) {
            cueBall.body.linearVelocity.setZero();
            cueBall.body.angularVelocity = 0;
            for (final ball in poolBalls) {
              ball.body.linearVelocity.setZero();
              ball.body.angularVelocity = 0;
            }
            _shotElapsedTime = 0.0;
            finishShot();
            break;
          }
        } else {
          break;
        }
      }
    } finally {
      isCatchingUp = false;
    }

    _sanitizeAllBallBodies();
  }

  void _sanitizeAllBallBodies() {
    if (!_hasGameLoaded || !physicsReady) return;
    try {
      final defaultCuePos = Vector2(size.x * 0.3, size.y * 0.5);
      _sanitizeBody(cueBall.body, defaultCuePos);
      if (cueBall.activeSpin.dx.isNaN || cueBall.activeSpin.dy.isNaN) {
        cueBall.activeSpin = Offset.zero;
      }
      if (cueBall.drawFollowForce.x.isNaN || cueBall.drawFollowForce.y.isNaN) {
        cueBall.drawFollowForce.setZero();
      }
      if (!cueBall.orientation.isValid) {
        cueBall.orientation.reset();
      }

      for (final ball in poolBalls) {
        if (ball.isRemoved) continue;
        _sanitizeBody(ball.body, Vector2(size.x * 0.7, size.y * 0.5));
        if (!ball.orientation.isValid) {
          ball.orientation.reset();
        }
      }
    } catch (e) {
      debugPrint('Error sanitizing ball bodies: $e');
    }
  }

  void _sanitizeBody(Body body, Vector2 fallbackPos) {
    final pos = body.position;
    if (pos.x.isNaN || pos.y.isNaN || pos.x.isInfinite || pos.y.isInfinite) {
      body.setTransform(fallbackPos, 0);
    }
    final vel = body.linearVelocity;
    if (vel.x.isNaN || vel.y.isNaN || vel.x.isInfinite || vel.y.isInfinite) {
      vel.setZero();
    } else if (vel.length > maximumBallSpeed) {
      vel.normalize();
      vel.scale(maximumBallSpeed);
    }
    final ang = body.angularVelocity;
    if (ang.isNaN || ang.isInfinite) {
      body.angularVelocity = 0;
    }
  }

  bool get isMyTurn {
    if (isOnlineMultiplayer.value) {
      final isHost = OnlineMultiplayerService.instance.isHost;
      return (isHost && currentTurn.value == 1) || (!isHost && currentTurn.value == 2);
    }
    if (isLocalMultiplayer.value) {
      final isHost = LocalMultiplayerService.instance.isHost;
      return (isHost && currentTurn.value == 1) || (!isHost && currentTurn.value == 2);
    }
    return true;
  }

  /// Kiểm tra có đang trong chế độ 1vs1 chơi chung trên cùng 1 máy (Pass & Play) hay không
  bool get isPassAndPlay =>
      !isOnlineMultiplayer.value &&
      !isLocalMultiplayer.value &&
      !isBotMode.value &&
      activeDailyPuzzle == null &&
      activeLegendaryTrickshot == null &&
      activeTournamentStage == null;

  /// Lấy cây gậy cơ và cấp độ tương ứng của người chơi đang trong lượt đánh (đồng bộ chính xác cho cả 2 máy)
  (CueModel cue, int level) getActivePlayerCue() {
    if (isOnlineMultiplayer.value) {
      if (isMyTurn) {
        return (
          ProgressionService.instance.equippedCue,
          ProgressionService.instance.equippedCueLevel,
        );
      } else {
        final oppCueId = OnlineMultiplayerService.instance.opponentCueId;
        final oppLevel = OnlineMultiplayerService.instance.opponentCueLevel;
        return (CueCatalog.getById(oppCueId), oppLevel);
      }
    } else if (isLocalMultiplayer.value) {
      if (isMyTurn) {
        return (
          ProgressionService.instance.equippedCue,
          ProgressionService.instance.equippedCueLevel,
        );
      } else {
        final oppCueId = LocalMultiplayerService.instance.opponentCueId;
        final oppLevel = LocalMultiplayerService.instance.opponentCueLevel;
        return (CueCatalog.getById(oppCueId), oppLevel);
      }
    } else if (isBotMode.value && currentTurn.value == 2) {
      if (activeTournamentStage != null) {
        return (
          activeTournamentStage!.opponentCue,
          activeTournamentStage!.opponentLevel.clamp(1, 10),
        );
      } else if (activeBotStage != null) {
        return (
          activeBotStage!.cue,
          activeBotStage!.stageNumber.clamp(1, 10),
        );
      }
      final isHard = botDifficulty.value == 2;
      return (
        CueCatalog.getById(isHard ? 'dragon_god' : 'frostbite'),
        isHard ? 4 : 2,
      );
    } else if (isPassAndPlay) {
      // Chế độ 1vs1 trên cùng 1 máy (Pass & Play): Cả 2 người chơi bắt buộc chỉ được dùng gậy Level 1
      if (currentTurn.value == 2) {
        return (
          CueCatalog.getById(player2CueId.value),
          1, // Cố định gậy Level 1 cho Player 2
        );
      } else {
        return (
          ProgressionService.instance.equippedCue,
          1, // Cố định gậy Level 1 cho Player 1
        );
      }
    } else if (currentTurn.value == 2) {
      // Chế độ 2 người chơi trên cùng thiết bị (Pass & Play): Player 2 sử dụng cây gậy riêng của Player 2
      return (
        CueCatalog.getById(player2CueId.value),
        player2CueLevel.value,
      );
    } else {
      // Lượt Player 1: Sử dụng cây gậy đã trang bị trong Túi đồ / Shop
      return (
        ProgressionService.instance.equippedCue,
        ProgressionService.instance.equippedCueLevel,
      );
    }
  }

  bool get canUserControl =>
      !shotInProgress &&
      !rackOver &&
      !(isBotMode.value && currentTurn.value == 2) &&
      isMyTurn;

  double _lastSyncAimTime = 0.0;
  double _lastSyncAimAngle = 0.0;
  double _lastSyncAimPower = 0.0;

  void _handleIncomingNetworkPacket(Map<String, dynamic> data) {
    if (!_hasGameLoaded) return;
    if (data['cueId'] != null) {
      final cid = data['cueId'].toString();
      final clvl = (data['cueLevel'] as num?)?.toInt() ?? 1;
      if (isOnlineMultiplayer.value) {
        OnlineMultiplayerService.instance.opponentCueId = cid;
        OnlineMultiplayerService.instance.opponentCueLevel = clvl;
      } else if (isLocalMultiplayer.value) {
        LocalMultiplayerService.instance.opponentCueId = cid;
        LocalMultiplayerService.instance.opponentCueLevel = clvl;
      }
    }
    final type = data['type'] as String?;
    if (type == 'aim') {
      aimAngle = (data['angle'] as num).toDouble();
      shotPower.value = (data['power'] as num).toDouble();
      cueBall.isAiming = true;
      cueBall.strokeDistance = maxDragDistance * shotPower.value;
      _updateAimVector(ballRadius * 2);
    } else if (type == 'spin') {
      final spin = Offset(
        (data['dx'] as num).toDouble(),
        (data['dy'] as num).toDouble(),
      );
      cueSpin.value = spin;
      cueBall.spinInfluence = spin;
    } else if (type == 'ball_in_hand') {
      final double x;
      final double y;
      if (data['nx'] != null && data['ny'] != null && size.x > 0 && size.y > 0) {
        x = (data['nx'] as num).toDouble() * size.x;
        y = (data['ny'] as num).toDouble() * size.y;
      } else {
        x = (data['x'] as num).toDouble();
        y = (data['y'] as num).toDouble();
      }
      final placed = (data['placed'] as bool?) ?? false;
      cueBall.isSunk = false;
      cueBall.body.setTransform(Vector2(x, y), 0);
      cueBall.body.linearVelocity.setZero();
      cueBall.body.angularVelocity = 0;
      cueBall.body.clearForces();
      cueBall.body.setAwake(true);
      if (placed) {
        ballInHand = false;
        movingCueBall = false;
        cueBall.isAiming = true;
      }
      _updateAimVector(ballRadius * 2);
    } else if (type == 'shoot') {
      final power = (data['power'] as num).toDouble();
      final angle = (data['angle'] as num?)?.toDouble();
      final spinX = (data['spinX'] as num?)?.toDouble();
      final spinY = (data['spinY'] as num?)?.toDouble();
      final forceMult = (data['forceMult'] as num?)?.toDouble();
      final spinMult = (data['spinMult'] as num?)?.toDouble();
      final cueBallData = data['cueBall'] as Map<String, dynamic>?;
      final ballsData = (data['balls'] as List?)?.cast<Map<String, dynamic>>();

      if (cueBallData != null && size.x > 0 && size.y > 0) {
        final cnx = (cueBallData['nx'] as num?)?.toDouble() ?? 0.25;
        final cny = (cueBallData['ny'] as num?)?.toDouble() ?? 0.5;
        cueBall.isSunk = false;
        cueBall.body.setTransform(Vector2(cnx * size.x, cny * size.y), 0);
        cueBall.body.linearVelocity.setZero();
        cueBall.body.angularVelocity = 0;
      }
      if (ballsData != null && ballsData.isNotEmpty) {
        _applyBallsSync(ballsData);
      }
      if (angle != null) {
        aimAngle = angle;
      }
      if (spinX != null && spinY != null) {
        cueSpin.value = Offset(spinX, spinY);
        cueBall.spinInfluence = cueSpin.value;
      }
      shotPower.value = power;
      shootWithPower(
        fromNetwork: true,
        networkAngle: angle,
        networkPower: power,
        networkSpin: (spinX != null && spinY != null) ? Offset(spinX, spinY) : null,
        networkForceMult: forceMult,
        networkSpinMult: spinMult,
      );
    } else if (type == 'shot_result') {
      _applyShotResult(data);
    } else if (type == 'sync_balls') {
      final balls = (data['balls'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _applyBallsSync(balls);
    } else if (type == 'reconnected_success') {
      ruleMessage.value = '✅ Đã kết nối lại vào trận đấu thành công!';
      _applyFullMatchState(data);
    } else if (type == 'request_sync_state') {
      if (isOnlineMultiplayer.value && !shotInProgress) {
        final balls = _collectBallsState();
        final cueBallPos = {
          'nx': size.x > 0 ? (cueBall.body.position.x / size.x) : 0.25,
          'ny': size.y > 0 ? (cueBall.body.position.y / size.y) : 0.5,
          'sunk': cueBall.isSunk,
        };
        OnlineMultiplayerService.instance.sendSyncBalls(
          balls,
          cueBall: cueBallPos,
          ballInHand: ballInHand,
        );
      }
    } else if (type == 'opponent_disconnected') {
      ruleMessage.value = '⚠️ Đối thủ bị ngắt kết nối! Trận đấu vẫn tiếp tục theo thời gian thực...';
    } else if (type == 'opponent_reconnected') {
      ruleMessage.value = '✅ Đối thủ đã kết nối lại! Tiếp tục thi đấu.';
    } else if (type == 'opponent_forfeited') {
      // Đối thủ đã rời trận từ Menu Setting hoặc timeout: Mình giành chiến thắng!
      final oppIdx = OnlineMultiplayerService.instance.isHost ? 2 : 1;
      declareLoss(oppIdx);
      ruleMessage.value = '🏆 Đối thủ đã rời trận! Bạn giành chiến thắng!';
      _processMatchRewards();
      OnlineMultiplayerService.instance.clearActiveMatch();
    } else if (type == 'restart') {
      restartMatch();
    }
  }

  List<Map<String, dynamic>> _collectBallsState() {
    final ballStates = <Map<String, dynamic>>[
      {
        'num': 0,
        'nx': size.x > 0 ? (cueBall.body.position.x / size.x) : 0.25,
        'ny': size.y > 0 ? (cueBall.body.position.y / size.y) : 0.5,
        'x': cueBall.body.position.x,
        'y': cueBall.body.position.y,
        'sunk': cueBall.isSunk,
      },
    ];
    for (final b in poolBalls) {
      ballStates.add({
        'num': b.number,
        'nx': size.x > 0 ? (b.body.position.x / size.x) : 0.5,
        'ny': size.y > 0 ? (b.body.position.y / size.y) : 0.5,
        'x': b.body.position.x,
        'y': b.body.position.y,
        'sunk': b.isSunk,
      });
    }
    return ballStates;
  }

  void _applyBallsSync(List<Map<String, dynamic>> balls) {
    for (final item in balls) {
      final bNum = item['num'] as int?;
      final double x;
      final double y;
      if (item['nx'] != null && item['ny'] != null && size.x > 0 && size.y > 0) {
        x = (item['nx'] as num).toDouble() * size.x;
        y = (item['ny'] as num).toDouble() * size.y;
      } else {
        x = (item['x'] as num?)?.toDouble() ?? 0.0;
        y = (item['y'] as num?)?.toDouble() ?? 0.0;
      }
      final sunk = (item['sunk'] as bool?) ?? false;
      if (bNum == 0) {
        cueBall.isSunk = sunk;
        cueBall.body.setTransform(Vector2(x, y), 0);
        cueBall.body.linearVelocity.setZero();
        cueBall.body.angularVelocity = 0;
        cueBall.body.clearForces();
      } else if (bNum != null) {
        for (final b in poolBalls) {
          if (b.number == bNum) {
            if (sunk && !b.isSunk) {
              b.instantSunk();
            } else if (!sunk) {
              if (b.isSunk) {
                b.resetSunkState();
              }
              b.body.setTransform(Vector2(x, y), 0);
              b.body.linearVelocity.setZero();
              b.body.angularVelocity = 0;
              b.body.clearForces();
            }
            break;
          }
        }
      }
    }
  }

  void _applyShotResult(Map<String, dynamic> data) {
    _applyFullMatchState(data);
  }

  void _applyFullMatchState(Map<String, dynamic> data) {
    shotInProgress = false;
    _shotElapsedTime = 0.0;
    settledTime = 0.0;

    // 1. Dừng triệt để mọi vận tốc bi & đồng bộ vị trí (khi đã khởi tạo Box2D components)
    if (_hasGameLoaded) {
      cueBall.body.linearVelocity.setZero();
      cueBall.body.angularVelocity = 0;
      cueBall.body.clearForces();
      for (final b in poolBalls) {
        if (!b.isRemoved) {
          b.body.linearVelocity.setZero();
          b.body.angularVelocity = 0;
          b.body.clearForces();
        }
      }

      // 2. Đồng bộ vị trí tất cả các bi theo tọa độ chuẩn hóa
      final balls = (data['balls'] as List?)?.cast<Map<String, dynamic>>() ??
          (data['lastBalls'] as List?)?.cast<Map<String, dynamic>>() ??
          [];
      if (balls.isNotEmpty) {
        _applyBallsSync(balls);
      }

      // 3. Đồng bộ bi cái
      final cueBallData = (data['cueBall'] as Map<String, dynamic>?) ??
          (data['lastCueBall'] as Map<String, dynamic>?);
      if (cueBallData != null && size.x > 0 && size.y > 0) {
        final cnx = (cueBallData['nx'] as num?)?.toDouble() ?? 0.25;
        final cny = (cueBallData['ny'] as num?)?.toDouble() ?? 0.5;
        final cSunk = (cueBallData['sunk'] as bool?) ?? false;
        cueBall.isSunk = cSunk;
        cueBall.body.setTransform(Vector2(cnx * size.x, cny * size.y), 0);
        cueBall.body.linearVelocity.setZero();
        cueBall.body.angularVelocity = 0;
        cueBall.body.clearForces();
      }
    }

    // 4. Đồng bộ luật chơi và lượt
    final nextTurn = (data['nextTurn'] as num?)?.toInt() ??
        (data['currentTurn'] as num?)?.toInt() ??
        currentTurn.value;
    currentTurn.value = nextTurn;
    if (data['ballInHand'] != null) {
      ballInHand = (data['ballInHand'] as bool?) ?? false;
    }
    if (data['breakShot'] != null) {
      breakShot = (data['breakShot'] as bool?) ?? false;
    }
    if (data['rackOver'] != null) {
      rackOver = (data['rackOver'] as bool?) ?? false;
    }
    if (data['winningPlayer'] != null) {
      winningPlayer = (data['winningPlayer'] as num?)?.toInt();
    }

    if (data['p1Group'] != null) {
      playerGroups[1] = data['p1Group'] == 'solids' ? BallGroup.solids : BallGroup.stripes;
    }
    if (data['p2Group'] != null) {
      playerGroups[2] = data['p2Group'] == 'solids' ? BallGroup.solids : BallGroup.stripes;
    }

    // 5. Cập nhật thông báo theo góc nhìn người chơi
    final oppName = OnlineMultiplayerService.instance.opponentName;
    if (rackOver) {
      if (winningPlayer != null) {
        final myIdx = OnlineMultiplayerService.instance.isHost ? 1 : 2;
        ruleMessage.value = winningPlayer == myIdx
            ? '🏆 Bạn đã chiến thắng trận đấu!'
            : 'Đối thủ $oppName đã chiến thắng!';
      }
      _processMatchRewards();
    } else if (isMyTurn) {
      if (_hasGameLoaded) {
        cueBall.isAiming = true;
        _updateAimVector(ballRadius * 2);
      }
      ruleMessage.value = ballInHand
          ? 'Đấu Online: Lượt của bạn (Đặt bi tuỳ ý!)'
          : 'Đấu Online: Lượt của bạn!';
    } else {
      if (_hasGameLoaded) {
        cueBall.isAiming = true;
        _updateAimVector(ballRadius * 2);
      }
      ruleMessage.value = ballInHand
          ? 'Đấu Online: $oppName đang đặt bi...'
          : 'Đấu Online: Lượt của $oppName...';
    }

    groupVersion.value++;
    matchVersion.value++;
  }

  void initMultiplayer() {
    LocalMultiplayerService.instance.onMessageReceived = _handleIncomingNetworkPacket;
    OnlineMultiplayerService.instance.onMessageReceived = _handleIncomingNetworkPacket;
  }

  void syncAim({required double angle, required double power, bool force = false}) {
    final now = DateTime.now().millisecondsSinceEpoch.toDouble();
    if (!force && (now - _lastSyncAimTime < 25.0) && (angle - _lastSyncAimAngle).abs() < 0.005 && (power - _lastSyncAimPower).abs() < 0.01) {
      return;
    }
    _lastSyncAimTime = now;
    _lastSyncAimAngle = angle;
    _lastSyncAimPower = power;
    final (cue, level) = getActivePlayerCue();
    if (isOnlineMultiplayer.value) {
      OnlineMultiplayerService.instance.sendAim(
        angle: angle,
        power: power,
        cueId: cue.id,
        cueLevel: level,
      );
    } else if (isLocalMultiplayer.value) {
      LocalMultiplayerService.instance.sendAim(angle: angle, power: power);
    }
  }

  void syncSpin({required double dx, required double dy}) {
    if (isOnlineMultiplayer.value) {
      OnlineMultiplayerService.instance.sendSpin(dx: dx, dy: dy);
    } else if (isLocalMultiplayer.value) {
      LocalMultiplayerService.instance.sendSpin(dx: dx, dy: dy);
    }
  }

  void syncShoot({
    required double power,
    double? angle,
    double? spinX,
    double? spinY,
    double? forceMult,
    double? spinMult,
    String? cueId,
    int? cueLevel,
  }) {
    if (isOnlineMultiplayer.value) {
      final cueBallPos = {
        'nx': size.x > 0 ? (cueBall.body.position.x / size.x) : 0.25,
        'ny': size.y > 0 ? (cueBall.body.position.y / size.y) : 0.5,
      };
      final balls = _collectBallsState();
      OnlineMultiplayerService.instance.sendShoot(
        power: power,
        angle: angle ?? aimAngle,
        spinX: spinX ?? cueSpin.value.dx,
        spinY: spinY ?? cueSpin.value.dy,
        forceMult: forceMult,
        spinMult: spinMult,
        cueBall: cueBallPos,
        balls: balls,
        cueId: cueId,
        cueLevel: cueLevel,
      );
    } else if (isLocalMultiplayer.value) {
      LocalMultiplayerService.instance.sendShoot(power: power);
    }
  }

  void syncBallInHand({required double x, required double y, bool placed = false}) {
    final nx = size.x > 0 ? (x / size.x) : 0.25;
    final ny = size.y > 0 ? (y / size.y) : 0.5;
    if (isOnlineMultiplayer.value) {
      OnlineMultiplayerService.instance.sendBallInHand(
        x: x,
        y: y,
        nx: nx,
        ny: ny,
        placed: placed,
      );
    } else if (isLocalMultiplayer.value) {
      LocalMultiplayerService.instance.sendBallInHand(x: x, y: y, placed: placed);
    }
  }

  late CueBall cueBall;
  final List<PoolBall> poolBalls = [];
  List<Pocket> pockets = [];
  List<Wall> walls = [];
  SpriteComponent? tableSpriteComponent;
  Vector2? _lastConfiguredSize;
  Vector2? dragStart;
  Vector2? dragCurrent;
  final ValueNotifier<bool> isShotInProgressNotifier = ValueNotifier<bool>(false);
  bool get shotInProgress => isShotInProgressNotifier.value;
  set shotInProgress(bool value) {
    if (isShotInProgressNotifier.value != value) {
      isShotInProgressNotifier.value = value;
    }
  }

  double settledTime = 0;
  bool breakShot = true;
  bool rackOver = false;

  final ValueNotifier<bool> isBallInHandNotifier = ValueNotifier<bool>(false);
  bool get ballInHand => isBallInHandNotifier.value;
  set ballInHand(bool value) {
    if (isBallInHandNotifier.value != value) {
      isBallInHandNotifier.value = value;
    }
  }

  bool movingCueBall = false;
  final Map<int, BallGroup> playerGroups = {};
  bool objectBallHitRailThisShot = false;
  int objectBallsHitRails = 0;

  // Quản lý Combo ăn nhiều bi trong 1 lượt đánh (CHỈ TÍNH KHI ĂN CÁC BI CÙNG LOẠI)
  final List<PoolBall> currentShotPocketedBalls = [];
  int get currentShotPocketedCount => currentShotPocketedBalls.length;
  final ValueNotifier<ComboEvent?> comboNotifier = ValueNotifier<ComboEvent?>(null);

  void handleBallPocketed(PoolBall ball) {
    if (!isCatchingUp) {
      AudioManager.instance.playPocket();
    }
    currentShotPocketedBalls.add(ball);
    _evaluateCombo();
  }

  void _evaluateCombo() {
    // 1. Bi cái rơi lỗ (foul scratch) -> Tuyệt đối không tính combo
    if (cueBall.pocketedThisShot || cueBall.isSunk) {
      comboNotifier.value = null;
      return;
    }

    // 2. Có bi đen 8 rơi lỗ -> Không tính combo
    if (currentShotPocketedBalls.any((b) => b.number == 8)) {
      comboNotifier.value = null;
      return;
    }

    // Phải ăn từ 2 bi trở lên mới xét combo
    if (currentShotPocketedBalls.length < 2) {
      return;
    }

    final currentPlayer = currentTurn.value;
    final playerGroup = getPlayerGroup(currentPlayer);

    if (playerGroup != null) {
      // Trường hợp ĐÃ chia nhóm bi:
      // BẮT BUỘC toàn bộ các bi vào lỗ trong lượt này phải CÙNG LOẠI và thuộc nhóm bi của người chơi
      final allSamePlayerGroup = currentShotPocketedBalls.every(
        (b) => ballGroup(b.number) == playerGroup,
      );

      if (!allSamePlayerGroup) {
        // Ăn bi khác loại (bi đối thủ hoặc lẫn lộn trơn/sọc) -> HỦY combo
        comboNotifier.value = null;
        return;
      }
    } else {
      // Trường hợp CHƯA chia nhóm bi (Bàn mở / Phá bi):
      // BẮT BUỘC toàn bộ các bi vào lỗ trong lượt này phải CÙNG MỘT LOẠI (hoặc toàn bi trơn 1-7, hoặc toàn bi sọc 9-15)
      final firstGrp = ballGroup(currentShotPocketedBalls.first.number);
      if (firstGrp == null) {
        comboNotifier.value = null;
        return;
      }

      final allSameGroup = currentShotPocketedBalls.every(
        (b) => ballGroup(b.number) == firstGrp,
      );

      if (!allSameGroup) {
        // Ăn 2 bi khác loại (1 bi trơn + 1 bi sọc) -> HỦY combo
        comboNotifier.value = null;
        return;
      }
    }

    final count = currentShotPocketedBalls.length;
    String title = 'DOUBLE POT!';
    String subtitle = 'Ăn 2 bi cùng loại!';
    if (count == 3) {
      title = 'TRIPLE POT!';
      subtitle = 'Ăn 3 bi cùng loại!';
    } else if (count >= 4) {
      title = 'MEGA COMBO!';
      subtitle = 'Thần cơ bida đỉnh cao!';
    }

    comboNotifier.value = ComboEvent(
      count: count,
      title: title,
      subtitle: subtitle,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    ProgressionService.instance.unlockAchievement('combo_hunter');
    ProgressionService.instance.unlockMedal('sharpshooter');
    if (!isCatchingUp) {
      AudioManager.instance.playCombo(count);
    }
  }

  double maxDragDistance = 180.0;
  final ValueNotifier<double> aimAngleNotifier = ValueNotifier<double>(0.0);
  double get aimAngle => aimAngleNotifier.value;
  set aimAngle(double val) => aimAngleNotifier.value = val;

  // Tinh chỉnh vật lý thực tế: Lực cơ, gia tốc và độ trớn lăn mượt mà tự nhiên
  static const double rollingVelocityMultiplier = 1.0;
  // Độ hãm ma sát nỉ Simonis: Giảm từ 135.0 xuống 68.0 để bi lăn trớn dài và mượt như thực tế
  static const double rollingDeceleration = 68.0;
  // Tốc độ đánh tối thiểu nâng lên 120.0 để cú chạm nhẹ nhất vẫn lướt được 3-4 thân bi
  static const double minimumShotSpeed = 120.0;
  // Tốc độ bắn tối đa chuẩn lực giải đấu
  static const double maximumShotSpeed = 1500.0;
  static const double stopAngularVelocity = 0.08;
  static const double powerCurveExponent = 1.35; // Lực lên cơ đều tay và dễ kiểm soát
  // Vận tốc trần tối đa cho phép các cây cơ cấp cao đạt lực tối đa (x1.5) mà không bị phanh gắt
  static const double maximumBallSpeed = 2400.0;
  double? powerDragStartY;

  // Quản lý trạng thái Bot
  double botWaitTime = 0;
  int botState = 0; // 0: Đang phân tích, 1: Đang ngắm và lên cơ

  // Khai báo kích thước động
  late double ballRadius;
  late Vector2 playAreaTopLeft;
  late Vector2 playAreaBottomRight;
  bool physicsReady = false;
  bool _hasGameLoaded = false;
  bool get hasGameLoaded => _hasGameLoaded;

  @override
  Color backgroundColor() => const Color(0xFF090D10);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Tăng giới hạn dịch chuyển mỗi frame (tránh bị Forge2D kẹp cứng gây khựng giật khi bi bay nhanh)
    forge2d.maxTranslation = 180.0;
    forge2d.maxTranslationSquared = 32400.0;
    BilliardContactListener.activeGame = this;

    final tableSprite = await Sprite.load('pool_table.png');
    tableSpriteComponent = SpriteComponent(sprite: tableSprite, size: size, priority: -2);
    add(tableSpriteComponent!);
    add(TableSkinComponent());
    add(vfx);

    _reconfigureTableForSize(size, initialLoad: true);

    if (activeDailyPuzzle != null) {
      ruleMessage.value = 'Thế bi: ${activeDailyPuzzle!.title}';
      dailyPuzzleShotsTaken = 0;
      breakShot = false;
      _setupDailyPuzzle(activeDailyPuzzle!);
    } else if (activeLegendaryTrickshot != null) {
      final shot = activeLegendaryTrickshot!;
      final avoidText = shot.obstacleBallNumbers.isNotEmpty
          ? ' (Tránh rơi bi #${shot.obstacleBallNumbers.join(', #')})'
          : '';
      ruleMessage.value = '🎯 ${shot.playerName}: Ăn bi ${shot.targetBallNumber} vào ${shot.targetPocketName}$avoidText';
      breakShot = false;
      _setupLegendaryTrickshot(activeLegendaryTrickshot!);
    } else {
      spawnTriangleBalls();
      _resetCueBall();
    }

    _hasGameLoaded = true;
    _updateAimVector(ballRadius * 2);
    initMultiplayer();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x <= 0 || size.y <= 0) return;
    if (_lastConfiguredSize == null ||
        (_lastConfiguredSize!.x - size.x).abs() > 1.0 ||
        (_lastConfiguredSize!.y - size.y).abs() > 1.0) {
      _reconfigureTableForSize(size);
    }
  }

  void _reconfigureTableForSize(Vector2 newSize, {bool initialLoad = false}) {
    final oldSize = _lastConfiguredSize?.clone();
    _lastConfiguredSize = newSize.clone();
    tableSpriteComponent?.size = newSize;

    final double paddingX = newSize.x * 0.0574;
    final double paddingY = newSize.y * 0.1034;
    playAreaTopLeft = Vector2(paddingX, paddingY);
    playAreaBottomRight = Vector2(newSize.x - paddingX, newSize.y - paddingY);

    ballRadius = newSize.y * 0.0235;

    // Tái cấu hình băng và lỗ theo kích thước mới
    for (final w in walls) {
      if (w.isMounted && !w.isRemoved && !w.isRemoving) {
        w.removeFromParent();
      }
    }
    walls.clear();
    walls = createBoundaries();
    addAll(walls);

    for (final p in pockets) {
      if (p.isMounted && !p.isRemoved && !p.isRemoving) {
        p.removeFromParent();
      }
    }
    pockets.clear();
    pockets = createPockets();
    addAll(pockets);

    // Cập nhật lại bán kính vật lý cho các bi
    for (final ball in poolBalls) {
      ball.updateRadius(ballRadius);
    }
    try {
      if (cueBall.isMounted) {
        cueBall.updateRadius(ballRadius);
      }
    } catch (_) {}

    if (!initialLoad && !shotInProgress && _hasGameLoaded && physicsReady) {
      if (activeDailyPuzzle != null) {
        _setupDailyPuzzle(activeDailyPuzzle!);
      } else if (activeLegendaryTrickshot != null) {
        _setupLegendaryTrickshot(activeLegendaryTrickshot!);
      } else if (breakShot) {
        spawnTriangleBalls();
        _resetCueBall();
      } else if (oldSize != null && oldSize.x > 0 && oldSize.y > 0) {
        // Tự động upscale / downscale tọa độ các bi trên bàn khi gập/mở thiết bị (Z Fold, Surface Duo)
        final double kx = newSize.x / oldSize.x;
        final double ky = newSize.y / oldSize.y;
        if ((kx - 1.0).abs() > 0.001 || (ky - 1.0).abs() > 0.001) {
          for (final ball in poolBalls) {
            if (ball.isMounted && !ball.isSunk) {
              final pos = ball.body.position;
              ball.body.setTransform(Vector2(pos.x * kx, pos.y * ky), ball.body.angle);
              ball.body.linearVelocity = Vector2(ball.body.linearVelocity.x * kx, ball.body.linearVelocity.y * ky);
            }
          }
          try {
            if (cueBall.isMounted && !cueBall.isSunk) {
              final pos = cueBall.body.position;
              cueBall.body.setTransform(Vector2(pos.x * kx, pos.y * ky), cueBall.body.angle);
              cueBall.body.linearVelocity = Vector2(cueBall.body.linearVelocity.x * kx, cueBall.body.linearVelocity.y * ky);
            }
          } catch (_) {}
          _updateAimVector(ballRadius * 2);
        }
      }
    }
  }

  List<Wall> createBoundaries() {
    final sx = size.x;
    final sy = size.y;

    // Tọa độ chuẩn xác của 6 băng bida và má lỗ đo từ pool_table.png (662x377)
    final cushionTop = sy * 0.1034;
    final cushionBot = sy * 0.8912;
    final cushionLeft = sx * 0.0574;
    final cushionRight = sx * 0.9411;

    // Tỉ lệ vát mũi băng 4 lỗ góc rộng rãi, thông thoáng (~34.3px miệng lỗ)
    const xCut = 0.0950;
    const yCut = 0.1660;

    // 1. Băng Trên - Trái (Top-Left Cushion):
    final pTLFacing = Vector2(sx * 0.0650, sy * 0.0620);
    final pTLNose = Vector2(sx * xCut, cushionTop);
    final pTMLeftNose = Vector2(sx * 0.4600, cushionTop);
    final pTMLeftFacing = Vector2(sx * 0.4740, sy * 0.0680);

    // 2. Băng Trên - Phải (Top-Right Cushion):
    final pTMRightFacing = Vector2(sx * 0.5260, sy * 0.0680);
    final pTMRightNose = Vector2(sx * 0.5400, cushionTop);
    final pTRNose = Vector2(sx * (1.0 - xCut), cushionTop);
    final pTRFacing = Vector2(sx * (1.0 - 0.0650), sy * 0.0620);

    // 3. Băng Ngắn - Phải (Right Cushion):
    final pTRSideFacing = Vector2(sx * (1.0 - 0.0350), sy * 0.1140);
    final pRTopNose = Vector2(cushionRight, sy * yCut);
    final pRBotNose = Vector2(cushionRight, sy * (1.0 - yCut));
    final pBRSideFacing = Vector2(sx * (1.0 - 0.0350), sy * (1.0 - 0.1140));

    // 4. Băng Dưới - Phải (Bottom-Right Cushion):
    final pBRFacing = Vector2(sx * (1.0 - 0.0650), sy * (1.0 - 0.0620));
    final pBRNose = Vector2(sx * (1.0 - xCut), cushionBot);
    final pBMRightNose = Vector2(sx * 0.5400, cushionBot);
    final pBMRightFacing = Vector2(sx * 0.5260, sy * (1.0 - 0.0680));

    // 5. Băng Dưới - Trái (Bottom-Left Cushion):
    final pBMLeftFacing = Vector2(sx * 0.4740, sy * (1.0 - 0.0680));
    final pBMLeftNose = Vector2(sx * 0.4600, cushionBot);
    final pBLNose = Vector2(sx * xCut, cushionBot);
    final pBLFacing = Vector2(sx * 0.0650, sy * (1.0 - 0.0620));

    // 6. Băng Ngắn - Trái (Left Cushion):
    final pBLSideFacing = Vector2(sx * 0.0350, sy * (1.0 - 0.1140));
    final pLBotNose = Vector2(cushionLeft, sy * (1.0 - yCut));
    final pLTopNose = Vector2(cushionLeft, sy * yCut);
    final pTLSideFacing = Vector2(sx * 0.0350, sy * 0.1140);

    return [
      // Băng Trên - Trái
      Wall(pTLFacing, pTLNose, restitution: 0.25, friction: 0.25, isFacing: true),
      Wall(pTLNose, pTMLeftNose),
      Wall(pTMLeftNose, pTMLeftFacing, restitution: 0.25, friction: 0.25, isFacing: true),

      // Băng Trên - Phải
      Wall(pTMRightFacing, pTMRightNose, restitution: 0.25, friction: 0.25, isFacing: true),
      Wall(pTMRightNose, pTRNose),
      Wall(pTRNose, pTRFacing, restitution: 0.25, friction: 0.25, isFacing: true),

      // Băng Ngắn - Phải
      Wall(pTRSideFacing, pRTopNose, restitution: 0.25, friction: 0.25, isFacing: true),
      Wall(pRTopNose, pRBotNose),
      Wall(pRBotNose, pBRSideFacing, restitution: 0.25, friction: 0.25, isFacing: true),

      // Băng Dưới - Phải
      Wall(pBRFacing, pBRNose, restitution: 0.25, friction: 0.25, isFacing: true),
      Wall(pBRNose, pBMRightNose),
      Wall(pBMRightNose, pBMRightFacing, restitution: 0.25, friction: 0.25, isFacing: true),

      // Băng Dưới - Trái
      Wall(pBMLeftFacing, pBMLeftNose, restitution: 0.25, friction: 0.25, isFacing: true),
      Wall(pBMLeftNose, pBLNose),
      Wall(pBLNose, pBLFacing, restitution: 0.25, friction: 0.25, isFacing: true),

      // Băng Ngắn - Trái
      Wall(pBLSideFacing, pLBotNose, restitution: 0.25, friction: 0.25, isFacing: true),
      Wall(pLBotNose, pLTopNose),
      Wall(pLTopNose, pTLSideFacing, restitution: 0.25, friction: 0.25, isFacing: true),

      // Vách chặn an toàn lòng 6 lỗ (Pocket Cups / Backstops)
      Wall(pTLFacing, Vector2(sx * 0.015, sy * 0.030), restitution: 0.10, friction: 0.40),
      Wall(Vector2(sx * 0.015, sy * 0.030), pTLSideFacing, restitution: 0.10, friction: 0.40),

      Wall(pTRFacing, Vector2(sx * 0.985, sy * 0.030), restitution: 0.10, friction: 0.40),
      Wall(Vector2(sx * 0.985, sy * 0.030), pTRSideFacing, restitution: 0.10, friction: 0.40),

      Wall(pBLFacing, Vector2(sx * 0.015, sy * 0.970), restitution: 0.10, friction: 0.40),
      Wall(Vector2(sx * 0.015, sy * 0.970), pBLSideFacing, restitution: 0.10, friction: 0.40),

      Wall(pBRFacing, Vector2(sx * 0.985, sy * 0.970), restitution: 0.10, friction: 0.40),
      Wall(Vector2(sx * 0.985, sy * 0.970), pBRSideFacing, restitution: 0.10, friction: 0.40),

      Wall(pTMLeftFacing, Vector2(sx * 0.4740, sy * 0.025), restitution: 0.10, friction: 0.40),
      Wall(Vector2(sx * 0.4740, sy * 0.025), Vector2(sx * 0.5260, sy * 0.025), restitution: 0.10, friction: 0.40),
      Wall(Vector2(sx * 0.5260, sy * 0.025), pTMRightFacing, restitution: 0.10, friction: 0.40),

      Wall(pBMLeftFacing, Vector2(sx * 0.4740, sy * 0.975), restitution: 0.10, friction: 0.40),
      Wall(Vector2(sx * 0.4740, sy * 0.975), Vector2(sx * 0.5260, sy * 0.975), restitution: 0.10, friction: 0.40),
      Wall(Vector2(sx * 0.5260, sy * 0.975), pBMRightFacing, restitution: 0.10, friction: 0.40),
    ];
  }

  List<Pocket> createPockets() {
    final double cornerPocketRadius = ballRadius * 2.50;
    final double middlePocketRadius = ballRadius * 1.80;
    final double cornerDropDist = ballRadius * 2.30;
    final double middleDropDist = ballRadius * 1.55;

    final p0 = Vector2(size.x * 0.0520, size.y * 0.0915);
    final p1 = Vector2(size.x * 0.4985, size.y * 0.0756);
    final p2 = Vector2(size.x * 0.9480, size.y * 0.0915);
    final p3 = Vector2(size.x * 0.0520, size.y * 0.9085);
    final p4 = Vector2(size.x * 0.4988, size.y * 0.9159);
    final p5 = Vector2(size.x * 0.9480, size.y * 0.9085);

    return [
      Pocket(
        p0,
        cornerPocketRadius,
        dropDistance: cornerDropDist,
      ),
      Pocket(
        p1,
        middlePocketRadius,
        isMiddle: true,
        dropDistance: middleDropDist,
      ),
      Pocket(
        p2,
        cornerPocketRadius,
        dropDistance: cornerDropDist,
      ),
      Pocket(
        p3,
        cornerPocketRadius,
        dropDistance: cornerDropDist,
      ),
      Pocket(
        p4,
        middlePocketRadius,
        isMiddle: true,
        dropDistance: middleDropDist,
      ),
      Pocket(
        p5,
        cornerPocketRadius,
        dropDistance: cornerDropDist,
      ),
    ];
  }

  void spawnTriangleBalls() {
    final startX = size.x * 0.70;
    final centerY = size.y / 2;
    final hitboxR = ballRadius * 0.88;
    // Khoảng cách tâm giữa 2 bi chạm nhau: 2 * hitboxR + 0.12 (triệt tiêu va chạm trùng lặp Box2D)
    final spacing = hitboxR * 2.0 + 0.12;
    final dx = spacing * 0.8660254; // cos(30 deg) = sqrt(3)/2

    // Thứ tự xếp bi chuẩn quốc tế 8-ball: Bi 8 nằm chính giữa hàng thứ 3 (row 2, col 1)
    const rackOrder = [1, 9, 2, 3, 8, 10, 4, 11, 5, 12, 13, 6, 14, 7, 15];

    final Map<int, Vector2> rackPositions = {};
    int idx = 0;
    for (int row = 0; row < 5; row++) {
      for (int col = 0; col <= row; col++) {
        final x = startX + row * dx;
        final y = centerY + (col - row / 2.0) * spacing;
        rackPositions[rackOrder[idx]] = Vector2(x, y);
        idx++;
      }
    }

    if (poolBalls.length == 15) {
      // TÁI SỬ DỤNG 15 BI CÓ SẴN - KHÔNG XÓA ASYNC, KHÔNG TẠO CHỒNG CHÉO TRÁNH NỔ BI
      for (final ball in poolBalls) {
        final pos = rackPositions[ball.number] ?? Vector2(startX, centerY);
        ball.updateRadius(ballRadius);
        ball.resetSunkState();
        ball.pocketedThisShot = false;
        try {
          ball.body.setTransform(pos, 0);
          ball.body.linearVelocity.setZero();
          ball.body.angularVelocity = 0;
          ball.body.clearForces();
          ball.body.setAwake(true);
        } catch (_) {}
      }
    } else {
      // Lần đầu tiên khi chưa có đủ 15 bi
      for (final b in poolBalls) {
        if (b.isMounted && !b.isRemoved && !b.isRemoving) {
          b.removeFromParent();
        }
      }
      poolBalls.clear();

      for (int number = 1; number <= 15; number++) {
        final pos = rackPositions[number] ?? Vector2(startX, centerY);
        final ball = PoolBall(
          pos,
          'ball_$number.png',
          ballRadius,
          number,
        );
        poolBalls.add(ball);
        add(ball);
      }
    }
  }

  void _resetCueBall({Vector2? customPos}) {
    final pos = customPos ?? Vector2(size.x * 0.25, size.y / 2);
    try {
      if (cueBall.isMounted) {
        cueBall.updateRadius(ballRadius);
        cueBall.resetSunkState();
        cueBall.pocketedThisShot = false;
        cueBall.hitObjectThisShot = false;
        cueBall.firstObjectBallHit = null;
        cueBall.hasCollidedBall = false;
        cueBall.drawFollowTimer = 0;
        cueBall.drawFollowForce = Vector2.zero();
        cueBall.activeSpin = Offset.zero;
        cueBall.spinInfluence = Offset.zero;
        cueBall.body.setTransform(pos, 0);
        cueBall.body.linearVelocity.setZero();
        cueBall.body.angularVelocity = 0;
        cueBall.body.clearForces();
        cueBall.body.setAwake(true);
        cueBall.isAiming = true;
        _updateAimVector(ballRadius * 2);
        return;
      } else {
        cueBall.initialPosition.setFrom(pos);
        cueBall.isAiming = true;
        _updateAimVector(ballRadius * 2);
        return;
      }
    } catch (_) {}

    cueBall = CueBall(pos, ballRadius);
    add(cueBall);
    cueBall.isAiming = true;
    _updateAimVector(ballRadius * 2);
  }

  void _setupDailyPuzzle(DailyPuzzleModel puzzle) {
    if (poolBalls.length != 15) {
      spawnTriangleBalls();
    }
    final puzzleBallNumbers = puzzle.balls.map((b) => b.ballNumber).toSet();
    final Map<int, Vector2> puzzlePositions = {};
    for (final cfg in puzzle.balls) {
      puzzlePositions[cfg.ballNumber] = Vector2(size.x * cfg.normX, size.y * cfg.normY);
    }

    for (final ball in poolBalls) {
      ball.updateRadius(ballRadius);
      if (puzzleBallNumbers.contains(ball.number)) {
        final pos = puzzlePositions[ball.number]!;
        ball.initialPosition.setFrom(pos);
        ball.resetSunkState();
        ball.pocketedThisShot = false;
        try {
          if (ball.isMounted) {
            ball.body.setTransform(pos, 0);
            ball.body.linearVelocity.setZero();
            ball.body.angularVelocity = 0;
            ball.body.clearForces();
            ball.body.setAwake(true);
          }
        } catch (_) {}
      } else {
        ball.initialPosition.setValues(-1000, -1000);
        ball.instantSunk();
        ball.pocketedThisShot = false;
        try {
          if (ball.isMounted) {
            ball.body.setTransform(Vector2(-1000, -1000), 0);
            ball.body.linearVelocity.setZero();
            ball.body.angularVelocity = 0;
            ball.body.clearForces();
            ball.body.setAwake(false);
          }
        } catch (_) {}
      }
    }

    _resetCueBall(
      customPos: Vector2(
        size.x * puzzle.cueBallNormX,
        size.y * puzzle.cueBallNormY,
      ),
    );
  }

  void _setupLegendaryTrickshot(LegendaryTrickshotModel shot) {
    if (poolBalls.length != 15) {
      spawnTriangleBalls();
    }
    final trickshotBallNumbers = shot.balls.map((b) => b.ballNumber).toSet();
    final Map<int, Vector2> trickshotPositions = {};
    for (final cfg in shot.balls) {
      trickshotPositions[cfg.ballNumber] = Vector2(size.x * cfg.normX, size.y * cfg.normY);
    }

    for (final ball in poolBalls) {
      ball.updateRadius(ballRadius);
      if (trickshotBallNumbers.contains(ball.number)) {
        final pos = trickshotPositions[ball.number]!;
        ball.initialPosition.setFrom(pos);
        ball.resetSunkState();
        ball.pocketedThisShot = false;
        try {
          if (ball.isMounted) {
            ball.body.setTransform(pos, 0);
            ball.body.linearVelocity.setZero();
            ball.body.angularVelocity = 0;
            ball.body.clearForces();
            ball.body.setAwake(true);
          }
        } catch (_) {}
      } else {
        ball.initialPosition.setValues(-1000, -1000);
        ball.instantSunk();
        ball.pocketedThisShot = false;
        try {
          if (ball.isMounted) {
            ball.body.setTransform(Vector2(-1000, -1000), 0);
            ball.body.linearVelocity.setZero();
            ball.body.angularVelocity = 0;
            ball.body.clearForces();
            ball.body.setAwake(false);
          }
        } catch (_) {}
      }
    }

    _resetCueBall(
      customPos: Vector2(
        size.x * shot.cueBallNormX,
        size.y * shot.cueBallNormY,
      ),
    );

    // Tự động căn chỉnh góc ngắm, lực và áp-phê gợi ý của cơ thủ huyền thoại
    aimAngle = shot.suggestedAimAngle;
    aimAngleNotifier.value = shot.suggestedAimAngle;
    shotPower.value = shot.suggestedPower;
    cueSpin.value = shot.suggestedSpin;
    try {
      cueBall.spinInfluence = shot.suggestedSpin;
      cueBall.isAiming = true;
    } catch (_) {}
    _updateAimVector(ballRadius * 2);
  }

  @override
  void update(double dt) {
    if (isAppPaused) {
      return;
    }

    // Giới hạn safeDt: Khi người chơi chuyển app qua lại, dt có thể tăng đột biến lên vài giây
    // Nếu truyền dt lớn vào Box2D (world.stepDt), solver vật lý sẽ nổ tung, bi bay xuyên bàn hoặc NaN
    // Ở 60 FPS thông thường, dt ~ 0.0166s nằm trọn trong [0.001, 0.033], hoàn toàn không ảnh hưởng vật lý
    final double safeDt = (_skipNextDt || dt > 0.05) ? 0.0166 : dt.clamp(0.001, 0.033);
    _skipNextDt = false;

    // Khử trùng tọa độ và vận tốc NaN/Infinity nếu có
    if (_hasGameLoaded && physicsReady) {
      _sanitizeAllBallBodies();
    }

    if (!_hasGameLoaded) {
      super.update(safeDt);
      return;
    }
    if (!physicsReady) {
      super.update(safeDt);
      physicsReady =
          cueBall.isMounted && poolBalls.every((ball) => ball.isMounted);
      if (physicsReady) {
        if (activeDailyPuzzle != null) {
          _setupDailyPuzzle(activeDailyPuzzle!);
        } else if (activeLegendaryTrickshot != null) {
          _setupLegendaryTrickshot(activeLegendaryTrickshot!);
        }
      }
      return;
    }

    // Chống xuyên băng triệt để bằng Sub-stepping: Khi bi di chuyển ở tốc độ cao (> 350 px/s),
    // chia nhỏ bước thời gian thành 2 sub-steps để va chạm nảy băng chuẩn xác 100% tự nhiên
    final maxSpeed = math.max(
      cueBall.body.linearVelocity.length,
      poolBalls.fold<double>(
        0.0,
        (maxV, b) => b.isRemoved ? maxV : math.max(maxV, b.body.linearVelocity.length),
      ),
    );
    final int subSteps = (shotInProgress && maxSpeed > 350.0) ? 2 : 1;
    final double stepDt = safeDt / subSteps;

    for (int s = 0; s < subSteps; s++) {
      if (s > 0) {
        world.physicsWorld.stepDt(stepDt);
      } else {
        super.update(stepDt);
      }
      _checkContinuousPocketDrops();
      _applyClothPhysics(stepDt);
    }
    _keepBallsInsideTable();

    // Ghi nhận vệt mờ tốc độ cao của bi cái và các bi mục tiêu (xóa ngay khi vào lỗ hoặc chậm)
    if (physicsReady && !cueBall.isSunk) {
      vfx.recordBallPosition(0, cueBall.body.position, cueBall.body.linearVelocity.length);
    } else {
      vfx.clearBallTrail(0);
    }
    for (final ball in poolBalls) {
      if (!ball.isRemoved && !ball.isSunk && ball.isMounted) {
        vfx.recordBallPosition(ball.number, ball.body.position, ball.body.linearVelocity.length);
      } else {
        vfx.clearBallTrail(ball.number);
      }
    }

    if (!shotInProgress) {
      _shotElapsedTime = 0.0;
      _maybeTakeBotTurn(safeDt);
      return;
    }

    // Cơ chế Watchdog bảo hiểm: Nếu cơ đánh kéo dài bất thường do lag hoặc chuyển app
    _shotElapsedTime += safeDt;
    if (_shotElapsedTime > 14.0) {
      if (cueBall.body.linearVelocity.length < 15.0) {
        cueBall.body.linearVelocity.setZero();
      }
      for (final ball in poolBalls) {
        if (!ball.isRemoved && ball.body.linearVelocity.length < 15.0) {
          ball.body.linearVelocity.setZero();
        }
      }
    }
    if (_shotElapsedTime > 18.0) {
      cueBall.body.linearVelocity.setZero();
      cueBall.body.angularVelocity = 0;
      for (final ball in poolBalls) {
        if (!ball.isRemoved) {
          ball.body.linearVelocity.setZero();
          ball.body.angularVelocity = 0;
          if (ball.isSunk && !ball.isSunkAnimComplete) {
            ball.completeSunkAnim();
          }
        }
      }
      if (cueBall.isSunk && !cueBall.isSunkAnimComplete) {
        cueBall.completeSunkAnim();
      }
      _shotElapsedTime = 0.0;
      finishShot();
      return;
    }

    final cueStopped = _bodyStopped(cueBall.body) && cueBall.isSunkAnimComplete;
    final ballsStopped = poolBalls.every(
      (ball) => ball.isRemoved || (_bodyStopped(ball.body) && ball.isSunkAnimComplete),
    );
    if (cueStopped && ballsStopped) {
      settledTime += safeDt;
      if (settledTime > 0.25) {
        _shotElapsedTime = 0.0;
        if (isOnlineMultiplayer.value && !isMyTurn) {
          // Là người quan sát trong trận online: Không tự ý tính luật độc lập
          // Chờ gói tin shot_result từ đối thủ gửi sang để đảm bảo đồng bộ 100%
          shotInProgress = false;
        } else {
          finishShot();
        }
      }
    } else {
      settledTime = 0;
    }
  }

  bool _bodyStopped(Body body) {
    final vel = body.linearVelocity;
    final ang = body.angularVelocity;
    if (vel.x.isNaN || vel.y.isNaN || vel.x.isInfinite || vel.y.isInfinite ||
        ang.isNaN || ang.isInfinite) {
      vel.setZero();
      body.angularVelocity = 0;
      return true;
    }
    // Dừng bi dứt khoát khi vận tốc rất thấp (< 1.2 px/s)
    // Loại bỏ hoàn toàn cảm giác phải chờ 2-3 giây nhìn bi nhích từng pixel mới chuyển lượt
    if (vel.length < 1.2) {
      vel.setZero();
      body.angularVelocity = 0;
      return true;
    }
    return vel.length < 1.2 && ang.abs() < stopAngularVelocity;
  }

  void _applyClothPhysics(double dt) {
    if (!_hasGameLoaded) return;
    _resolveBallOverlaps();
    _applyClothPhysicsToBody(cueBall.body, dt);
    for (final ball in poolBalls) {
      if (ball.isRemoved) {
        continue;
      }
      _applyClothPhysicsToBody(ball.body, dt);
    }
  }

  /// Triệt tiêu chồng lấn bi (De-penetration Solver) và làm mượt va chạm:
  /// Ngăn chặn hiện tượng bi đè xuyên nhau, giật rung xung đột hay nảy nổ bất thường khi phá bi / chụm bi
  /// Giữ nguyên 100% các hằng số vật lý cốt lõi (restitution 0.90, friction 0.16, mass).
  void _resolveBallOverlaps() {
    if (!physicsReady) return;

    final activeBalls = <dynamic>[];
    if (!cueBall.isSunk && cueBall.isMounted) {
      activeBalls.add(cueBall);
    }
    for (final ball in poolBalls) {
      if (!ball.isRemoved && !ball.isSunk && ball.isMounted) {
        activeBalls.add(ball);
      }
    }

    final len = activeBalls.length;
    if (len < 2) return;

    final minDist = ballRadius * 1.76; // 2 * hitboxRadius (hitboxRadius = 0.88 * ballRadius)
    final minDist2 = minDist * minDist;

    for (int i = 0; i < len; i++) {
      final dynamic ballA = activeBalls[i];
      final Body bodyA = ballA.body;
      final posA = bodyA.position;

      for (int j = i + 1; j < len; j++) {
        final dynamic ballB = activeBalls[j];
        final Body bodyB = ballB.body;
        final posB = bodyB.position;

        final dx = posB.x - posA.x;
        final dy = posB.y - posA.y;
        final d2 = dx * dx + dy * dy;

        if (d2 < minDist2 && d2 > 0.000001) {
          final d = math.sqrt(d2);
          final overlap = minDist - d;
          if (overlap > 0.02) {
            final nx = dx / d;
            final ny = dy / d;

            // Nới tách vị trí 2 bi nhẹ nhàng đối xứng
            final nudge = overlap * 0.5 * 0.65;
            posA.x -= nx * nudge;
            posA.y -= ny * nudge;
            posB.x += nx * nudge;
            posB.y += ny * nudge;

            bodyA.setTransform(posA, bodyA.angle);
            bodyB.setTransform(posB, bodyB.angle);

            // Làm mượt vận tốc xuyên thấu để loại bỏ xung đột giật nảy vô lý
            final velA = bodyA.linearVelocity;
            final velB = bodyB.linearVelocity;
            final relVelNorm = (velB.x - velA.x) * nx + (velB.y - velA.y) * ny;
            if (relVelNorm < 0) {
              final damp = relVelNorm * 0.5;
              velA.x += nx * damp;
              velA.y += ny * damp;
              velB.x -= nx * damp;
              velB.y -= ny * damp;
            }
          }
        }
      }
    }
  }

  void _applyClothPhysicsToBody(Body body, double dt) {
    final velocity = body.linearVelocity;
    if (velocity.x.isNaN || velocity.y.isNaN || velocity.x.isInfinite || velocity.y.isInfinite) {
      velocity.setZero();
      return;
    }
    final speed = velocity.length;
    if (speed <= 0) {
      return;
    }

    if (body == cueBall.body) {
      // 1. Áp dụng lực giật lùi (Trô) hoặc đẩy tới (Cu-lê) sau khi chạm bi mục tiêu
      if (cueBall.drawFollowTimer > 0) {
        cueBall.drawFollowTimer -= dt;
        final factor = (cueBall.drawFollowTimer / 0.45).clamp(0.0, 1.0);
        velocity.add(cueBall.drawFollowForce * (factor * dt));
      }

      // 2. Độ xoáy hao mòn dần do ma sát với mặt vải nỉ
      final decayY = math.exp(-1.8 * dt);
      final decayX = math.exp(-0.5 * dt);
      cueBall.activeSpin = Offset(
        cueBall.activeSpin.dx * decayX,
        cueBall.activeSpin.dy * decayY,
      );

      // 3. Trước va chạm: nếu có xoáy giật lùi (trô) thì hãm rất nhẹ tự nhiên
      if (!cueBall.hasCollidedBall && cueBall.activeSpin.dy > 0.1) {
        final brake = cueBall.activeSpin.dy * 3.5 * dt;
        final reducedSpeed = math.max(0.0, speed - brake);
        if (speed > 0) {
          velocity.scale(reducedSpeed / speed);
        }
      }
    }

    // 4. Kháng lăn khí động học và vi cản mặt vải nỉ (vi sai hàm số mũ)
    final dragFactor = math.exp(-0.035 * dt);

    // 5. Ma sát lăn tự nhiên không giật khựng (Zero Sudden Braking):
    // Khi bi chậm dần (speed < 36), lực hãm tự động giảm mượt dần theo đường cong tỉ lệ
    // giúp bi lướt êm và dừng nhẹ nhàng như bi thật, loại bỏ hoàn toàn hiện tượng phanh gấp.
    final lowSpeedEase = speed < 36.0 ? (speed / 36.0) : 1.0;
    // Tăng nhẹ lực hãm khi bi lăn rất chậm (< 12 px/s) để bi dừng tự nhiên và dứt khoát
    final extraDamping = speed < 12.0 ? (12.0 - speed) * 1.8 * dt : 0.0;
    final decelStep = (rollingDeceleration * lowSpeedEase * dt) + extraDamping;

    var nextSpeed = (speed * dragFactor) - decelStep;

    // Khi vận tốc rất nhỏ (< 1.2 px/s), dừng bi dứt khoát mượt mà
    if (nextSpeed < 1.2 || nextSpeed.isNaN || nextSpeed.isInfinite) {
      velocity.setZero();
      body.angularVelocity = 0;
    } else {
      if (nextSpeed > maximumBallSpeed) {
        nextSpeed = maximumBallSpeed;
      }
      velocity.scale(nextSpeed / speed);
    }
  }

  void _keepBallsInsideTable() {
    if (!_hasGameLoaded) return;
    if (!cueBall.isSunk) {
      _keepBodyInsideTable(cueBall);
    }
    for (final ball in poolBalls) {
      if (!ball.isRemoved && !ball.isSunk) {
        _keepBodyInsideTable(ball);
      }
    }
  }

  void _keepBodyInsideTable(BodyComponent ball) {
    final body = ball.body;
    final position = body.position;
    if (position.x.isNaN || position.y.isNaN || position.x.isInfinite || position.y.isInfinite) {
      body.setTransform(Vector2(size.x * 0.5, size.y * 0.5), 0);
      body.linearVelocity.setZero();
      body.angularVelocity = 0;
      return;
    }
    // Vùng bao an toàn ngoài cùng (mép gỗ ngoài của bàn)
    final minX = size.x * 0.015;
    final maxX = size.x * 0.985;
    final minY = size.y * 0.025;
    final maxY = size.y * 0.975;
    var corrected = false;

    if (position.x < minX) {
      position.x = minX;
      corrected = true;
    } else if (position.x > maxX) {
      position.x = maxX;
      corrected = true;
    }
    if (position.y < minY) {
      position.y = minY;
      corrected = true;
    } else if (position.y > maxY) {
      position.y = maxY;
      corrected = true;
    }

    if (corrected) {
      body.setTransform(position, 0);
      body.setAwake(true);
    }
  }

  void _checkContinuousPocketDrops() {
    for (final pocket in pockets) {
      if (!cueBall.isSunk && canBallEnterPocket(cueBall.body, pocket)) {
        vfx.clearBallTrail(0);
        cueBall.sinkIntoPocket(pocket.position);
        cueBall.pocketedThisShot = true;
        if (!isCatchingUp) {
          AudioManager.instance.playPocket();
        }
        comboNotifier.value = null;
        vfx.addPocketDrop(pocket.position, pocket.dropDistance);
      }
      for (final ball in poolBalls) {
        if (!ball.isRemoved &&
            !ball.isSunk &&
            canBallEnterPocket(ball.body, pocket)) {
          vfx.clearBallTrail(ball.number);
          ball.sinkIntoPocket(pocket.position);
          ball.pocketedThisShot = true;
          handleBallPocketed(ball);
          vfx.addPocketDrop(pocket.position, pocket.dropDistance);
        }
      }
    }
  }

  bool canBallEnterPocket(Body ballBody, Pocket pocket) {
    final ballPos = ballBody.position;
    if (ballPos.x.isNaN || ballPos.y.isNaN || ballPos.x.isInfinite || ballPos.y.isInfinite) {
      return false;
    }
    final pocketPos = pocket.position;
    final dist = (ballPos - pocketPos).length;
    return dist <= pocket.dropDistance;
  }

  void resetCueSpin() {
    cueSpin.value = Offset.zero;
    if (_hasGameLoaded) {
      cueBall.spinInfluence = Offset.zero;
      cueBall.activeSpin = Offset.zero;
    }
  }

  void switchTurn() {
    resetCueSpin();
    currentTurn.value = currentTurn.value == 1 ? 2 : 1;
    _updateTurnRuleMessage();
  }

  void _updateTurnRuleMessage() {
    if (rackOver || activeDailyPuzzle != null || activeLegendaryTrickshot != null) return;
    if (isOnlineMultiplayer.value) {
      final oppName = OnlineMultiplayerService.instance.opponentName;
      ruleMessage.value = isMyTurn
          ? (ballInHand ? 'Đấu mạng: Lượt của bạn (Đặt bi tuỳ ý!)' : 'Đấu mạng: Lượt của bạn')
          : 'Đấu mạng: Lượt của $oppName...';
    } else if (isLocalMultiplayer.value) {
      final oppName = LocalMultiplayerService.instance.opponentName.isNotEmpty
          ? LocalMultiplayerService.instance.opponentName
          : (LocalMultiplayerService.instance.isHost ? 'guest_p2'.tr : 'host_p1'.tr);
      ruleMessage.value = isMyTurn
          ? (ballInHand ? 'Đấu mạng: Lượt của bạn (Đặt bi tuỳ ý!)' : 'Đấu mạng: Lượt của bạn')
          : 'Đấu mạng: Lượt của $oppName...';
    } else if (isBotMode.value && currentTurn.value == 2) {
      final botTitle = activeTournamentStage?.opponentName ??
          activeBotStage?.botName ??
          (botDifficulty.value == 2 ? 'bot_hard'.tr : 'bot_easy'.tr);
      ruleMessage.value = 'Lượt $botTitle';
    } else {
      ruleMessage.value = 'Lượt Player ${currentTurn.value}';
    }
  }

  void startPlayerMatch() {
    activeBotStage = null;
    activeDailyPuzzle = null;
    activeLegendaryTrickshot = null;
    activeTournamentStage = null;
    isLocalMultiplayer.value = false;
    isOnlineMultiplayer.value = false;
    isBotMode.value = false;
    player2CueLevel.value = 1; // Khóa cấp độ gậy P2 về Level 1 cho chế độ 1vs1 cùng máy
    restartMatch();
  }

  void startBotStage(BotStageModel stage) {
    activeBotStage = stage;
    activeDailyPuzzle = null;
    activeLegendaryTrickshot = null;
    activeTournamentStage = null;
    isLocalMultiplayer.value = false;
    isOnlineMultiplayer.value = false;
    isBotMode.value = true;
    botDifficulty.value = stage.stageNumber <= 3 ? 1 : 2;
    restartMatch();
  }

  void startDailyPuzzle(DailyPuzzleModel puzzle) {
    activeDailyPuzzle = puzzle;
    dailyPuzzleShotsTaken = 0;
    activeBotStage = null;
    activeLegendaryTrickshot = null;
    activeTournamentStage = null;
    isLocalMultiplayer.value = false;
    isOnlineMultiplayer.value = false;
    isBotMode.value = false;
    restartMatch();
  }

  void startLegendaryTrickshot(LegendaryTrickshotModel shot) {
    activeLegendaryTrickshot = shot;
    activeBotStage = null;
    activeDailyPuzzle = null;
    activeTournamentStage = null;
    isLocalMultiplayer.value = false;
    isOnlineMultiplayer.value = false;
    isBotMode.value = false;
    restartMatch();
  }

  void startLocalMultiplayer() {
    activeBotStage = null;
    activeDailyPuzzle = null;
    activeLegendaryTrickshot = null;
    activeTournamentStage = null;
    isLocalMultiplayer.value = true;
    isOnlineMultiplayer.value = false;
    isBotMode.value = false;
    restartMatch();
  }

  void startTournamentStage(TournamentBracketStage stage) {
    activeTournamentStage = stage;
    activeBotStage = null;
    activeDailyPuzzle = null;
    activeLegendaryTrickshot = null;
    isLocalMultiplayer.value = false;
    isOnlineMultiplayer.value = false;
    isBotMode.value = true;
    botDifficulty.value = stage.bracketNumber <= 3 ? 1 : 2;
    restartMatch();
  }

  void startOnlineMultiplayer({
    required String roomId,
    required bool isHost,
    TournamentBracketStage? tournamentStage,
  }) {
    if (tournamentStage != null) {
      activeTournamentStage = tournamentStage;
    } else if (OnlineMultiplayerService.instance.isTournamentMatch) {
      final bNum = OnlineMultiplayerService.instance.tournamentBracket;
      activeTournamentStage = TournamentCatalog.brackets.firstWhere(
        (b) => b.bracketNumber == bNum,
        orElse: () => TournamentCatalog.brackets.first,
      );
    } else {
      activeTournamentStage = null;
    }
    activeBotStage = null;
    activeDailyPuzzle = null;
    activeLegendaryTrickshot = null;
    isLocalMultiplayer.value = false;
    isOnlineMultiplayer.value = true;
    isBotMode.value = false;
    restartMatch();

    if (isHost) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (_hasGameLoaded && isOnlineMultiplayer.value && OnlineMultiplayerService.instance.isHost) {
          final balls = _collectBallsState();
          OnlineMultiplayerService.instance.sendSyncBalls(balls);
        }
      });
    }
  }

  void resumeOnlineMultiplayer({
    required String roomId,
    required bool isHost,
    TournamentBracketStage? tournamentStage,
    Map<String, dynamic>? state,
  }) {
    if (tournamentStage != null) {
      activeTournamentStage = tournamentStage;
    } else if (OnlineMultiplayerService.instance.isTournamentMatch) {
      final bNum = OnlineMultiplayerService.instance.tournamentBracket;
      activeTournamentStage = TournamentCatalog.brackets.firstWhere(
        (b) => b.bracketNumber == bNum,
        orElse: () => TournamentCatalog.brackets.first,
      );
    } else {
      activeTournamentStage = null;
    }
    activeBotStage = null;
    activeDailyPuzzle = null;
    activeLegendaryTrickshot = null;
    isLocalMultiplayer.value = false;
    isOnlineMultiplayer.value = true;
    isBotMode.value = false;

    // QUAN TRỌNG: KHÔNG GỌI restartMatch() - Giữ nguyên trận đấu đang chạy theo thời gian thực!
    if (state != null) {
      _applyFullMatchState(state);
    }

    // Đảm bảo sync tọa độ khi layout hoàn tất nếu vừa mở lại màn hình
    Future.delayed(const Duration(milliseconds: 250), () {
      if (isOnlineMultiplayer.value && state != null && _hasGameLoaded) {
        try {
          if (size.x > 0) {
            _applyFullMatchState(state);
          }
        } catch (_) {}
      }
    });

    // Yêu cầu đối thủ/server gửi lại trạng thái bi mới nhất
    OnlineMultiplayerService.instance.sendJson({'type': 'request_sync_state'});
  }

  void setBotMode(bool enabled) {
    if (isBotMode.value == enabled) {
      return;
    }
    isBotMode.value = enabled;
    restartMatch();
  }

  void setBotDifficulty(int difficulty) {
    if (difficulty != 1 && difficulty != 2) {
      return;
    }
    botDifficulty.value = difficulty;
    if (isBotMode.value) {
      restartMatch();
    }
  }

  void declareLoss(int loser) {
    if (rackOver || (loser != 1 && loser != 2)) {
      return;
    }
    shotInProgress = false;
    winningPlayer = loser == 1 ? 2 : 1;
    playerScores[winningPlayer!] = (playerScores[winningPlayer!] ?? 0) + 1;
    ruleMessage.value = 'Player $loser bị xử thua';
    rackOver = true;
    ballInHand = false;
    _processMatchRewards();
    matchVersion.value++;
  }

  void restartMatch() {
    vfx.clearAll();
    currentTurn.value = 1;
    shotPower.value = 0.05;
    playerGroups.clear();
    groupVersion.value++;
    shotInProgress = false;
    breakShot = activeDailyPuzzle == null && activeLegendaryTrickshot == null;
    rackOver = false;
    winningPlayer = null;
    ballInHand = false;
    movingCueBall = false;
    settledTime = 0;
    botWaitTime = 0;
    botState = 0;
    aimAngle = 0;
    physicsReady = false;
    _lastMatchReward = null;

    if (activeDailyPuzzle != null) {
      ruleMessage.value = 'Thế bi: ${activeDailyPuzzle!.title}';
      dailyPuzzleShotsTaken = 0;
    } else if (activeLegendaryTrickshot != null) {
      final shot = activeLegendaryTrickshot!;
      final avoidText = shot.obstacleBallNumbers.isNotEmpty
          ? ' (Tránh rơi bi #${shot.obstacleBallNumbers.join(', #')})'
          : '';
      ruleMessage.value = '🎯 ${shot.playerName}: Ăn bi ${shot.targetBallNumber} vào ${shot.targetPocketName}$avoidText';
    } else if (activeTournamentStage != null) {
      ruleMessage.value = 'Bracket ${activeTournamentStage!.bracketNumber}: ${activeTournamentStage!.title} vs ${activeTournamentStage!.opponentName}';
    } else if (activeBotStage != null) {
      ruleMessage.value = '${activeBotStage!.title} - Bắt đầu!';
    } else if (isOnlineMultiplayer.value) {
      final oppName = OnlineMultiplayerService.instance.opponentName;
      ruleMessage.value = OnlineMultiplayerService.instance.isHost
          ? 'Đấu Online: Lượt của bạn (P1 break shot)'
          : 'Đấu Online: Lượt của $oppName (P1 break shot)';
    } else if (isLocalMultiplayer.value) {
      final oppName = LocalMultiplayerService.instance.opponentName.isNotEmpty
          ? LocalMultiplayerService.instance.opponentName
          : (LocalMultiplayerService.instance.isHost ? 'guest_p2'.tr : 'host_p1'.tr);
      ruleMessage.value = LocalMultiplayerService.instance.isHost
          ? 'Đấu mạng: Lượt của bạn (P1 break shot)'
          : 'Đấu mạng: Lượt của $oppName (P1 break shot)';
    } else {
      ruleMessage.value = 'Player 1: break shot';
    }

    if (activeDailyPuzzle != null || activeLegendaryTrickshot != null) {
      if (previousShotAimVector != null) {
        showPreviousShotGhost = true;
      }
    } else {
      showPreviousShotGhost = false;
    }

    resetCueSpin();

    if (!_hasGameLoaded) {
      matchVersion.value++;
      return;
    }

    if (activeDailyPuzzle != null) {
      _setupDailyPuzzle(activeDailyPuzzle!);
    } else if (activeLegendaryTrickshot != null) {
      _setupLegendaryTrickshot(activeLegendaryTrickshot!);
    } else {
      spawnTriangleBalls();
      _resetCueBall();
    }

    matchVersion.value++;
  }

  void setShotPower(double value) {
    if (ballInHand) {
      ballInHand = false;
      movingCueBall = false;
    }
    shotPower.value = value.clamp(0.05, 1.0);
    if (_hasGameLoaded) {
      cueBall.isAiming = true;
      cueBall.strokeDistance = maxDragDistance * shotPower.value;
    }
    if ((isLocalMultiplayer.value || isOnlineMultiplayer.value) && isMyTurn) {
      syncAim(
        angle: aimAngle,
        power: shotPower.value,
      );
    }
  }

  void setCueSpin(Offset value) {
    if (!canUserControl) {
      return;
    }
    final dist = value.distance;
    final clamped = dist > 1.0 ? value / dist : value;
    cueSpin.value = clamped;
    if (dist > 0.08) {
      ProgressionService.instance.unlockAchievement('spin_trick');
      ProgressionService.instance.unlockMedal('english_spin_master');
    }
    if (_hasGameLoaded) {
      cueBall.spinInfluence = clamped;
      if (cueBall.isAiming && cueBall.aimVector != null) {
        _updateAimVector(cueBall.aimVector!.length);
      }
    }
    if ((isLocalMultiplayer.value || isOnlineMultiplayer.value) && isMyTurn) {
      syncSpin(dx: clamped.dx, dy: clamped.dy);
    }
  }

  void commitCueSpin() {
    if (!_hasGameLoaded) return;
    cueBall.spinInfluence = cueSpin.value;
    if (cueBall.isAiming && cueBall.aimVector != null) {
      _updateAimVector(cueBall.aimVector!.length);
    }
  }

  void adjustShotPower(double delta) {
    if (!canUserControl) {
      return;
    }
    shotPower.value = (shotPower.value + delta).clamp(0.05, 1.0);
    if (_hasGameLoaded) {
      cueBall.isAiming = true;
      cueBall.strokeDistance = maxDragDistance * shotPower.value;
    }
    if ((isLocalMultiplayer.value || isOnlineMultiplayer.value) && isMyTurn) {
      syncAim(
        angle: aimAngle,
        power: shotPower.value,
      );
    }
  }

  void beginPowerDrag(double startY) {
    if (!canUserControl) {
      powerDragStartY = null;
      return;
    }
    if (ballInHand) {
      ballInHand = false;
      movingCueBall = false;
    }
    powerDragStartY = startY;
  }

  void updatePowerDrag(double currentY) {
    final startY = powerDragStartY;
    if (startY == null || !canUserControl) {
      return;
    }
    final pullDistance = math.max(0.0, currentY - startY);
    final power = (0.05 + pullDistance / maxDragDistance * 0.95).clamp(
      0.05,
      1.0,
    );
    setShotPower(power);
    if (_hasGameLoaded) {
      cueBall.isAiming = true;
      cueBall.strokeDistance = maxDragDistance * power;
    }
    if ((isLocalMultiplayer.value || isOnlineMultiplayer.value) && isMyTurn) {
      syncAim(angle: aimAngle, power: power);
    }
  }

  void endPowerDrag() {
    powerDragStartY = null;
  }

  void shootWithPower({
    bool fromBot = false,
    bool fromNetwork = false,
    double? networkAngle,
    double? networkPower,
    Offset? networkSpin,
    double? networkForceMult,
    double? networkSpinMult,
  }) {
    if (!_hasGameLoaded ||
        !physicsReady ||
        shotInProgress ||
        rackOver ||
        (!fromBot && !fromNetwork && !canUserControl) ||
        (networkPower == null && shotPower.value <= 0.05)) {
      return;
    }

    if (ballInHand) {
      ballInHand = false;
      movingCueBall = false;
    }

    if (networkAngle != null) {
      aimAngle = networkAngle;
    }
    if (networkPower != null) {
      shotPower.value = networkPower.clamp(0.05, 1.0);
    }
    if (networkSpin != null) {
      cueSpin.value = networkSpin;
      cueBall.spinInfluence = networkSpin;
    }

    final direction = Vector2(math.cos(aimAngle), math.sin(aimAngle));
    final normalizedPower = ((shotPower.value - 0.05) / 0.95).clamp(0.0, 1.0);
    final curvedPower = math
        .pow(normalizedPower, powerCurveExponent)
        .toDouble();

    // Áp dụng chỉ số Lực (Force) và Xoáy (Spin) từ cây gậy cơ của người chơi trong lượt đánh
    final (cue, level) = getActivePlayerCue();
    
    double forceMult = 1.0;
    double spinMult = 1.0;
    if (fromNetwork) {
      forceMult = networkForceMult ?? cue.getForceMultiplier(level);
      spinMult = networkSpinMult ?? cue.getSpinMultiplier(level);
    } else {
      forceMult = cue.getForceMultiplier(level);
      spinMult = cue.getSpinMultiplier(level);
    }

    if ((isLocalMultiplayer.value || isOnlineMultiplayer.value) && !fromBot && !fromNetwork) {
      syncShoot(
        power: shotPower.value,
        angle: aimAngle,
        spinX: cueSpin.value.dx,
        spinY: cueSpin.value.dy,
        forceMult: forceMult,
        spinMult: spinMult,
        cueId: cue.id,
        cueLevel: level,
      );
    }

    final targetSpeed =
        (minimumShotSpeed +
            (maximumShotSpeed - minimumShotSpeed) * curvedPower) *
        rollingVelocityMultiplier *
        forceMult;

    // Ghi nhận Vết bóng mờ lần bắn trước cho Daily Puzzle & Trickshots
    if (activeLegendaryTrickshot != null || activeDailyPuzzle != null) {
      previousShotAimAngle = aimAngle;
      previousShotAimVector = cueBall.aimVector?.clone();
      previousShotPower = shotPower.value;
      previousShotSpin = cueSpin.value;
      showPreviousShotGhost = false;
    }

    // Xử lý trục Z giả lập cho Jump Shot: Khi là thế bi nhảy hoặc nâng cơ
    final isJumpTrickshot = activeLegendaryTrickshot?.id.contains('jump') == true ||
        activeLegendaryTrickshot?.techniqueNotes.toLowerCase().contains('jump') == true;
    if (isJumpTrickshot) {
      final jumpPower = (shotPower.value * 340.0).clamp(140.0, 380.0);
      cueBall.zVelocity = jumpPower;
      cueBall.zHeight = 1.0;
    }

    cueBall.body.setAwake(true);
    // Vận tốc góc xoáy áp-phê quanh trục Z (áp-phê phải dx > 0 thì quay thuận chiều kim đồng hồ)
    cueBall.body.angularVelocity = -cueSpin.value.dx * 18.0 * spinMult;
    cueBall.body.linearVelocity.setFrom(direction * targetSpeed);

    // Hiệu ứng bụi lơ gậy (Chalk Dust Puff) tán xạ chân thực khi đầu gậy phát lực
    final tipPos = cueBall.body.position - direction * cueBall.radius;
    vfx.addCueChalkPuff(
      tipPos: tipPos,
      shotDirection: direction,
      shotSpeed: targetSpeed,
      ballRadius: ballRadius,
    );
    // Hiệu ứng tiếp xúc gậy cơ độc quyền theo Anime Concept
    vfx.addCueContactEffect(
      cue: cue,
      tipPos: tipPos,
      shotDirection: direction,
      shotSpeed: targetSpeed,
      ballRadius: ballRadius,
    );

    // Khởi tạo các trạng thái động lực học xoáy
    cueBall.activeSpin = cueSpin.value * spinMult;
    cueBall.shotDirection = direction.clone();
    cueBall.hasCollidedBall = false;
    cueBall.drawFollowTimer = 0.0;
    cueBall.drawFollowForce.setZero();

    // Reset số bi ăn trong lượt này
    currentShotPocketedBalls.clear();
    comboNotifier.value = null;

    shotInProgress = true;
    _shotElapsedTime = 0.0;
    objectBallHitRailThisShot = false;
    objectBallsHitRails = 0;

    for (final ball in poolBalls) {
      ball.pocketedThisShot = false;
    }
    cueBall.pocketedThisShot = false;
    cueBall.hitObjectThisShot = false;
    cueBall.firstObjectBallHit = null;
    settledTime = 0;
    shotPower.value = 0.05;
    cueBall.spinInfluence = cueSpin.value;
    cueBall.strokeDistance = 0;
    cueBall.isAiming = false;
  }

  void _maybeTakeBotTurn(double dt) {
    if (!isBotMode.value || currentTurn.value != 2 || rackOver) {
      botWaitTime = 0;
      botState = 0;
      return;
    }

    botWaitTime += dt;

    // Giai đoạn 0: Bot "suy nghĩ" tính toán thế bi và chọn mục tiêu (0.35s)
    if (botState == 0) {
      if (botWaitTime > 0.35 && physicsReady) {
        if (ballInHand) {
          _placeBotCueBall();
          ballInHand = false;
        }

        final shot = _chooseBotShot();
        if (shot != null && shot.direction.length2 > 1) {
          double angle = math.atan2(shot.direction.y, shot.direction.x);
          double pwr = shot.power;
          Offset spin = shot.spin;

          if (activeBotStage != null) {
            final stage = activeBotStage!;
            final angleErr = (math.Random().nextDouble() * 2 - 1) * stage.aimErrorRad;
            angle += angleErr;
            final pwrErr = (math.Random().nextDouble() * 2 - 1) * (1.0 - stage.powerAccuracy) * 0.20;
            pwr = (pwr + pwrErr).clamp(0.15, 0.95);
            if (!stage.useSpin) {
              spin = Offset.zero;
            }
          }

          targetBotAngle = angle;
          targetBotPower = pwr;
          cueSpin.value = spin;
          cueBall.spinInfluence = spin;
          cueBall.isAiming = true;

          botState = 1; // Chuyển sang giai đoạn xoay cơ ngắm mượt mà
          botWaitTime = 0;
        } else {
          final aliveBalls = poolBalls.where((b) => !b.isSunk && !b.isRemoved).toList();
          if (aliveBalls.isNotEmpty) {
            final targetBall = aliveBalls.firstWhere(
              (b) => b.number == 8,
              orElse: () => aliveBalls.first,
            );
            final aimDir = targetBall.body.position - cueBall.body.position;
            targetBotAngle = math.atan2(aimDir.y, aimDir.x);
            targetBotPower = 0.42;
            cueSpin.value = Offset.zero;
            cueBall.spinInfluence = Offset.zero;
            cueBall.isAiming = true;

            botState = 1;
            botWaitTime = 0;
          }
        }
      }
    }
    // Giai đoạn 1: Hiệu ứng xoay cây cơ từ từ và kéo lực mượt mà (0.65s)
    else if (botState == 1) {
      // Nội suy góc ngắm ngắn nhất (shortest angle interpolation)
      var diff = (targetBotAngle - aimAngle) % (2 * math.pi);
      if (diff > math.pi) diff -= 2 * math.pi;
      if (diff < -math.pi) diff += 2 * math.pi;
      aimAngle += diff * (dt * 7.5).clamp(0.0, 1.0);

      // Kéo nhẹ thanh lực mượt mà
      shotPower.value = (shotPower.value + (targetBotPower - shotPower.value) * (dt * 6.0)).clamp(0.05, 1.0);
      cueBall.strokeDistance = maxDragDistance * shotPower.value;
      _updateAimVector(ballRadius * 2);

      if (botWaitTime >= 0.65) {
        aimAngle = targetBotAngle;
        shotPower.value = targetBotPower;
        cueBall.strokeDistance = maxDragDistance * targetBotPower;
        _updateAimVector(ballRadius * 2);
        botState = 2; // Chuyển sang giai đoạn ngắm tĩnh định vị
        botWaitTime = 0;
      }
    }
    // Giai đoạn 2: Bot đứng ngắm chắc chắn trong 0.35s rồi ra cơ dứt khoát
    else if (botState == 2) {
      if (botWaitTime > 0.35) {
        shootWithPower(fromBot: true);
        botState = 0;
        botWaitTime = 0;
      }
    }
  }

  bool _isBallLegalTarget(PoolBall ball, int player) {
    if (ball.isRemoved || ball.isSunk) return false;
    final group = getPlayerGroup(player);
    if (ball.number == 8) {
      if (group == null) return false;
      return allGroupBallsPocketed(group);
    }
    if (group == null) {
      return true; // Bàn mở (Open table): mọi bi trừ bi 8
    }
    return ballGroup(ball.number) == group;
  }

  bool _isPocketEntryFeasible(Vector2 ballPos, Vector2 pocket, int pocketIndex) {
    final fromPocket = (ballPos - pocket).normalized();
    Vector2 pocketInward;
    switch (pocketIndex) {
      case 0:
        pocketInward = Vector2(0.707, 0.707);
        break;
      case 1:
        pocketInward = Vector2(0.0, 1.0);
        break;
      case 2:
        pocketInward = Vector2(-0.707, 0.707);
        break;
      case 3:
        pocketInward = Vector2(0.707, -0.707);
        break;
      case 4:
        pocketInward = Vector2(0.0, -1.0);
        break;
      case 5:
      default:
        pocketInward = Vector2(-0.707, -0.707);
        break;
    }
    final entryCosine = fromPocket.dot(pocketInward);
    // Lỗ giữa yêu cầu góc vào thoáng hơn
    if (pocketIndex == 1 || pocketIndex == 4) {
      return entryCosine >= 0.40;
    } else {
      return entryCosine >= 0.25;
    }
  }

  bool _checkCueBallScratchRisk(
    Vector2 ghostPos,
    Vector2 cueDeflection,
    List<Vector2> pockets,
    double maxTravel,
  ) {
    for (final pocket in pockets) {
      final toPocket = pocket - ghostPos;
      final proj = toPocket.dot(cueDeflection);
      if (proj > 0 && proj < maxTravel) {
        final dist = (toPocket - cueDeflection * proj).length;
        if (dist < ballRadius * 2.2) {
          return true; // Nguy cơ bi cái rơi thẳng vào lỗ
        }
      }
    }
    return false;
  }

  void _placeBotCueBall() {
    _prepareCueBallForPlacement();
    final minX = playAreaTopLeft.x + ballRadius * 1.5;
    final maxX = playAreaBottomRight.x - ballRadius * 1.5;
    final minY = playAreaTopLeft.y + ballRadius * 1.5;
    final maxY = playAreaBottomRight.y - ballRadius * 1.5;

    final legalBalls = poolBalls.where((b) => _isBallLegalTarget(b, 2)).toList();
    final pockets = _botPocketPositions();

    Vector2? bestPosition;
    double bestScore = double.infinity;

    // Ưu tiên cực cao của Bot Khó: Đặt bi cái thẳng tắp sau lưng bi mục tiêu dễ vào lỗ nhất
    if (botDifficulty.value == 2) {
      for (final ball in legalBalls) {
        for (int i = 0; i < pockets.length; i++) {
          final pocket = pockets[i];
          if (!_isPocketEntryFeasible(ball.body.position, pocket, i) ||
              !_isBotPathClear(ball.body.position, pocket, excluded: ball)) {
            continue;
          }
          final toPocket = (pocket - ball.body.position).normalized();
          // Đặt bi cái cách bi mục tiêu 3.8 lần bán kính
          final candidate = ball.body.position - toPocket * (ballRadius * 3.8);

          if (candidate.x >= minX &&
              candidate.x <= maxX &&
              candidate.y >= minY &&
              candidate.y <= maxY) {
            final overlaps = poolBalls.any((b) =>
                !b.isRemoved &&
                !b.isSunk &&
                (b.body.position - candidate).length < ballRadius * 2.3);
            if (!overlaps) {
              final distToPocket = (pocket - ball.body.position).length;
              if (distToPocket < bestScore) {
                bestScore = distToPocket;
                bestPosition = candidate;
              }
            }
          }
        }
      }
    }

    // Nếu không có vị trí thẳng hoàn hảo hoặc độ khó 1: quét lưới tìm vị trí có góc bắn an toàn nhất
    if (bestPosition == null) {
      for (var column = 1; column <= 8; column++) {
        for (var row = 1; row <= 5; row++) {
          final candidate = Vector2(
            minX + (maxX - minX) * column / 9,
            minY + (maxY - minY) * row / 6,
          );
          final overlaps = poolBalls.any((b) =>
              !b.isRemoved &&
              !b.isSunk &&
              (b.body.position - candidate).length < ballRadius * 2.2);
          if (overlaps) continue;

          cueBall.body.setTransform(candidate, 0);
          cueBall.body.linearVelocity.setZero();
          cueBall.body.angularVelocity = 0;
          final shot = _chooseBotShot();
          if (shot != null && shot.totalDistance < bestScore) {
            bestScore = shot.totalDistance;
            bestPosition = candidate.clone();
          }
        }
      }
    }

    final position = bestPosition ?? initialCueBallPosition;
    cueBall.body.setTransform(position, 0);
    cueBall.body.linearVelocity.setZero();
    cueBall.body.angularVelocity = 0;
    cueBall.isSunk = false;
    cueBall.isAiming = true;
    _updateAimVector(ballRadius * 2);
  }

  BotShot? _chooseBotShot() {
    // 1. Pha phá bóng (Break Shot): Đánh chuẩn xác vào đỉnh tam giác
    if (breakShot) {
      final apexPos = Vector2(size.x * 0.70, size.y / 2);
      final aimDir = apexPos - cueBall.body.position;
      final useSpin = activeBotStage != null
          ? activeBotStage!.useSpin
          : (botDifficulty.value == 2);
      final pwr = activeBotStage != null
          ? (0.70 + activeBotStage!.powerAccuracy * 0.25).clamp(0.65, 0.95)
          : (botDifficulty.value == 2 ? 0.90 : 0.75);
      return BotShot(
        direction: aimDir,
        totalDistance: aimDir.length,
        spin: useSpin ? const Offset(0.0, 0.22) : Offset.zero,
        power: pwr,
      );
    }

    // 2. Lọc danh sách các bi hợp lệ (tuyệt đối không nhắm bi đối thủ hay bi 8 khi chưa đến lượt)
    var legalBalls = poolBalls.where((b) => _isBallLegalTarget(b, 2)).toList();
    if (legalBalls.isEmpty) {
      final botGroup = getPlayerGroup(2);
      final allPotted = botGroup != null && allGroupBallsPocketed(botGroup);
      final eightBall = poolBalls.firstWhere(
        (b) => b.number == 8 && !b.isSunk && !b.isRemoved,
        orElse: () => poolBalls.firstWhere(
          (b) => !b.isSunk && !b.isRemoved,
          orElse: () => poolBalls.first,
        ),
      );
      if (allPotted && !eightBall.isSunk && !eightBall.isRemoved) {
        legalBalls = [eightBall];
      } else {
        return null;
      }
    }

    final pockets = _botPocketPositions();
    BotShot? bestShot;
    var bestScore = double.infinity;

    final isSimplePocketSearch = (activeBotStage != null && activeBotStage!.stageNumber <= 2) ||
        (activeBotStage == null && botDifficulty.value == 1);
    final isAdvanced = (activeBotStage != null && activeBotStage!.stageNumber >= 4) ||
        (activeBotStage == null && botDifficulty.value == 2);
    final enableSpin = activeBotStage != null ? activeBotStage!.useSpin : (botDifficulty.value == 2);
    final enableScratchPrevention = activeBotStage != null
        ? activeBotStage!.useScratchPrevention
        : (botDifficulty.value == 2);

    for (final ball in legalBalls) {
      final candidatePockets = isSimplePocketSearch
          ? [_nearestPocket(ball.body.position, pockets)]
          : pockets;

      for (int pIdx = 0; pIdx < candidatePockets.length; pIdx++) {
        final pocket = candidatePockets[pIdx];

        // Kiểm tra góc vào lỗ có khả thi không
        if (!_isPocketEntryFeasible(ball.body.position, pocket, pIdx)) {
          continue;
        }

        final objectDirection = (pocket - ball.body.position).normalized();
        final aimPoint = ball.body.position - objectDirection * (cueBall.hitboxRadius + ball.hitboxRadius);
        final cueDistance = (aimPoint - cueBall.body.position).length;
        final objectDistance = (pocket - ball.body.position).length;

        // Kiểm tra đường đi của bi cái tới Ghost Ball và bi mục tiêu tới lỗ có bị chắn không
        if (!_isInsidePlayableArea(aimPoint) ||
            !_isBotPathClear(cueBall.body.position, aimPoint, excluded: ball) ||
            !_isBotPathClear(ball.body.position, pocket, excluded: ball)) {
          continue;
        }

        final cueDirection = (aimPoint - cueBall.body.position).normalized();
        final cutCosine = cueDirection.dot(objectDirection);

        // Góc cắt quá lớn (> 74 độ) không thể ăn bi trực tiếp
        final minCutCosine = isAdvanced ? 0.28 : 0.20;
        if (cutCosine < minCutCosine) {
          continue;
        }

        // Tính toán hướng rẽ bi cái và xoáy an toàn chống rơi lỗ (Scratch Prevention)
        final normal = objectDirection;
        final dot = cueDirection.dot(normal);
        Vector2 tangent = cueDirection - normal * dot;
        if (tangent.length2 > 0.0001) {
          tangent.normalize();
        } else {
          tangent = Vector2(-normal.y, normal.x);
        }

        Offset chosenSpin = Offset.zero;
        if (enableSpin) {
          if (cutCosine >= 0.82) {
            chosenSpin = const Offset(0.0, 0.65);
          } else {
            final cutAngle =
                cueDirection.x * objectDirection.y -
                cueDirection.y * objectDirection.x;
            double spinDx = cutAngle.clamp(-1.0, 1.0) * 0.45;
            double spinDy = (cueDistance > size.x * 0.38) ? -0.35 : 0.35;
            chosenSpin = Offset(spinDx, spinDy);
          }

          if (enableScratchPrevention) {
            Vector2 cueDeflection = tangent;
            if (chosenSpin.dy > 0.05) {
              cueDeflection = (tangent * (1.0 - chosenSpin.dy * 0.45) - normal * (chosenSpin.dy * 0.75)).normalized();
            } else if (chosenSpin.dy < -0.05) {
              final f = -chosenSpin.dy;
              cueDeflection = (tangent * (1.0 - f * 0.45) + cueDirection * (f * 0.75)).normalized();
            }

            final maxCueTravel = cueDistance * 0.8 + 120.0;
            final hasScratchRisk = _checkCueBallScratchRisk(aimPoint, cueDeflection, pockets, maxCueTravel);
            if (hasScratchRisk) {
              final alternateSpin = chosenSpin.dy > 0 ? const Offset(0.0, -0.6) : const Offset(0.0, 0.7);
              Vector2 altDeflection = alternateSpin.dy > 0
                  ? (tangent * 0.6 - normal * 0.6).normalized()
                  : (tangent * 0.6 + cueDirection * 0.6).normalized();
              if (_checkCueBallScratchRisk(aimPoint, altDeflection, pockets, maxCueTravel)) {
                continue;
              } else {
                chosenSpin = alternateSpin;
              }
            }
          }
        }

        // Tính lực đánh chuẩn xác tối ưu theo cự ly và góc cắt
        final tableLength = size.x * 0.70;
        final effectiveDistance = cueDistance + objectDistance / math.max(0.25, cutCosine);
        final calculatedPower = (0.24 + 0.46 * (effectiveDistance / tableLength)).clamp(0.28, 0.75);

        // Tính điểm ưu tiên (Score càng nhỏ càng tốt)
        final cutPenalty = (1.0 - cutCosine) * (isAdvanced ? cueDistance * 0.8 : cueDistance * 0.3);
        final score = cueDistance + objectDistance * 1.15 + cutPenalty;

        if (score < bestScore) {
          bestScore = score;
          bestShot = BotShot(
            direction: aimPoint - cueBall.body.position,
            totalDistance: cueDistance + objectDistance,
            spin: chosenSpin,
            power: calculatedPower,
          );
        }
      }
    }

    if (bestShot != null) {
      return bestShot;
    }

    // 3. Nếu không có cơ hội ăn bi trực tiếp:
    final enableSafety = activeBotStage != null
        ? activeBotStage!.useSafetyShot
        : (botDifficulty.value == 2);
    if (enableSafety) {
      return _findSafeLegalContactShot(legalBalls, pockets);
    }

    // Bot chưa biết đánh safety: đánh bi mục tiêu đầu tiên
    final firstBall = legalBalls.first;
    final aimDir = firstBall.body.position - cueBall.body.position;
    return BotShot(
      direction: aimDir,
      totalDistance: aimDir.length,
      spin: Offset.zero,
      power: 0.32,
    );
  }

  BotShot _findSafeLegalContactShot(List<PoolBall> legalBalls, List<Vector2> pockets) {
    // 1. Tìm bi hợp lệ có đường ngắm trực tiếp thông thoáng nhất
    PoolBall? bestDirectBall;
    double bestDirectDist = double.infinity;
    Vector2? bestDirectAim;

    for (final ball in legalBalls) {
      if (_isBotPathClear(cueBall.body.position, ball.body.position, excluded: ball)) {
        final dist = (ball.body.position - cueBall.body.position).length;
        if (dist < bestDirectDist) {
          bestDirectDist = dist;
          bestDirectBall = ball;
          bestDirectAim = ball.body.position - cueBall.body.position;
        }
      }
    }

    if (bestDirectBall != null && bestDirectAim != null) {
      return BotShot(
        direction: bestDirectAim,
        totalDistance: bestDirectDist,
        spin: Offset.zero,
        power: 0.34, // Đánh lực vừa phải chạm bi hợp lệ và đưa bi chạm băng
      );
    }

    // 2. Nếu tất cả bi hợp lệ bị che khuất (Snookered): Thử cú A-băng dội thành chạm bi hợp lệ
    final walls = [
      playAreaTopLeft.y + ballRadius,
      playAreaBottomRight.x - ballRadius,
      playAreaBottomRight.y - ballRadius,
      playAreaTopLeft.x + ballRadius,
    ];

    for (final ball in legalBalls) {
      // Dội băng trên
      final mirrorTop = Vector2(ball.body.position.x, 2 * walls[0] - ball.body.position.y);
      final rayTop = mirrorTop - cueBall.body.position;
      if (rayTop.y < 0) {
        final t = (walls[0] - cueBall.body.position.y) / rayTop.y;
        final railPoint = cueBall.body.position + rayTop * t;
        if (railPoint.x >= playAreaTopLeft.x + ballRadius &&
            railPoint.x <= playAreaBottomRight.x - ballRadius) {
          if (_isBotPathClear(cueBall.body.position, railPoint) &&
              _isBotPathClear(railPoint, ball.body.position, excluded: ball)) {
            final aimDir = railPoint - cueBall.body.position;
            return BotShot(
              direction: aimDir,
              totalDistance: aimDir.length + (ball.body.position - railPoint).length,
              spin: Offset.zero,
              power: 0.48,
            );
          }
        }
      }

      // Dội băng dưới
      final mirrorBottom = Vector2(ball.body.position.x, 2 * walls[2] - ball.body.position.y);
      final rayBottom = mirrorBottom - cueBall.body.position;
      if (rayBottom.y > 0) {
        final t = (walls[2] - cueBall.body.position.y) / rayBottom.y;
        final railPoint = cueBall.body.position + rayBottom * t;
        if (railPoint.x >= playAreaTopLeft.x + ballRadius &&
            railPoint.x <= playAreaBottomRight.x - ballRadius) {
          if (_isBotPathClear(cueBall.body.position, railPoint) &&
              _isBotPathClear(railPoint, ball.body.position, excluded: ball)) {
            final aimDir = railPoint - cueBall.body.position;
            return BotShot(
              direction: aimDir,
              totalDistance: aimDir.length + (ball.body.position - railPoint).length,
              spin: Offset.zero,
              power: 0.48,
            );
          }
        }
      }

      // Dội băng phải (Right Cushion Kick Shot)
      final mirrorRight = Vector2(2 * walls[1] - ball.body.position.x, ball.body.position.y);
      final rayRight = mirrorRight - cueBall.body.position;
      if (rayRight.x > 0) {
        final t = (walls[1] - cueBall.body.position.x) / rayRight.x;
        final railPoint = cueBall.body.position + rayRight * t;
        if (railPoint.y >= playAreaTopLeft.y + ballRadius &&
            railPoint.y <= playAreaBottomRight.y - ballRadius) {
          if (_isBotPathClear(cueBall.body.position, railPoint) &&
              _isBotPathClear(railPoint, ball.body.position, excluded: ball)) {
            final aimDir = railPoint - cueBall.body.position;
            return BotShot(
              direction: aimDir,
              totalDistance: aimDir.length + (ball.body.position - railPoint).length,
              spin: Offset.zero,
              power: 0.48,
            );
          }
        }
      }

      // Dội băng trái (Left Cushion Kick Shot)
      final mirrorLeft = Vector2(2 * walls[3] - ball.body.position.x, ball.body.position.y);
      final rayLeft = mirrorLeft - cueBall.body.position;
      if (rayLeft.x < 0) {
        final t = (walls[3] - cueBall.body.position.x) / rayLeft.x;
        final railPoint = cueBall.body.position + rayLeft * t;
        if (railPoint.y >= playAreaTopLeft.y + ballRadius &&
            railPoint.y <= playAreaBottomRight.y - ballRadius) {
          if (_isBotPathClear(cueBall.body.position, railPoint) &&
              _isBotPathClear(railPoint, ball.body.position, excluded: ball)) {
            final aimDir = railPoint - cueBall.body.position;
            return BotShot(
              direction: aimDir,
              totalDistance: aimDir.length + (ball.body.position - railPoint).length,
              spin: Offset.zero,
              power: 0.48,
            );
          }
        }
      }
    }

    // 3. Phương án cuối cùng: Nhắm thẳng vào bi hợp lệ gần nhất
    legalBalls.sort((a, b) =>
      (a.body.position - cueBall.body.position).length2.compareTo(
        (b.body.position - cueBall.body.position).length2,
      ),
    );
    final fallbackTarget = legalBalls.first;
    final fallbackDir = fallbackTarget.body.position - cueBall.body.position;
    return BotShot(
      direction: fallbackDir,
      totalDistance: fallbackDir.length,
      spin: Offset.zero,
      power: 0.35,
    );
  }

  BallGroup? _inferBotGroup() {
    final opponentGroup = playerGroups[1];
    if (opponentGroup == null) {
      return null;
    }
    return opponentGroup == BallGroup.solids
        ? BallGroup.stripes
        : BallGroup.solids;
  }

  BallGroup? getPlayerGroup(int player) {
    if (playerGroups.containsKey(player)) {
      return playerGroups[player];
    }
    if (player == 2 && playerGroups.containsKey(1)) {
      return _inferBotGroup();
    }
    if (player == 1 && playerGroups.containsKey(2)) {
      return playerGroups[2] == BallGroup.solids
          ? BallGroup.stripes
          : BallGroup.solids;
    }
    return null;
  }

  Vector2 _nearestPocket(Vector2 ballPosition, List<Vector2> pockets) {
    return pockets.reduce(
      (a, b) => (a - ballPosition).length2 < (b - ballPosition).length2 ? a : b,
    );
  }

  bool _isBotPathClear(Vector2 start, Vector2 end, {PoolBall? excluded}) {
    final path = end - start;
    final pathLength2 = path.length2;
    if (pathLength2 <= 1) {
      return false;
    }
    for (final ball in poolBalls) {
      if (ball == excluded || ball.isRemoved || ball.isSunk) {
        continue;
      }
      final toBall = ball.body.position - start;
      final projection = (toBall.dot(path) / pathLength2).clamp(0.0, 1.0);
      final closestPoint = start + path * projection;
      if ((ball.body.position - closestPoint).length < ballRadius * 2.06) {
        return false;
      }
    }
    return true;
  }

  bool _isInsidePlayableArea(Vector2 position) {
    return position.x >= playAreaTopLeft.x + ballRadius &&
        position.x <= playAreaBottomRight.x - ballRadius &&
        position.y >= playAreaTopLeft.y + ballRadius &&
        position.y <= playAreaBottomRight.y - ballRadius;
  }

  List<Vector2> _botPocketPositions() {
    return [
      Vector2(size.x * 0.0520, size.y * 0.0915), // Top-Left
      Vector2(size.x * 0.4985, size.y * 0.0756), // Top-Middle
      Vector2(size.x * 0.9480, size.y * 0.0915), // Top-Right
      Vector2(size.x * 0.0520, size.y * 0.9085), // Bottom-Left
      Vector2(size.x * 0.4988, size.y * 0.9159), // Bottom-Middle
      Vector2(size.x * 0.9480, size.y * 0.9085), // Bottom-Right
    ];
  }

  void rotateAimToPoint(Vector2 touchPosition) {
    if (!canUserControl || !physicsReady || !_hasGameLoaded) {
      return;
    }
    if (ballInHand) {
      ballInHand = false;
      movingCueBall = false;
    }
    final offset = touchPosition - cueBall.body.position;
    if (offset.length2 > 4) {
      aimAngle = math.atan2(offset.y, offset.x);
      cueBall.isAiming = true;
      _updateAimVector(ballRadius * 2);
      if ((isLocalMultiplayer.value || isOnlineMultiplayer.value) && isMyTurn) {
        syncAim(
          angle: aimAngle,
          power: shotPower.value,
        );
      }
    }
  }

  void rotateAim(double delta) {
    if (!canUserControl) {
      return;
    }
    if (ballInHand) {
      ballInHand = false;
      movingCueBall = false;
    }
    aimAngle += delta;
    if (_hasGameLoaded && physicsReady) {
      cueBall.isAiming = true;
      _updateAimVector(ballRadius * 2);
    }
    if ((isLocalMultiplayer.value || isOnlineMultiplayer.value) && isMyTurn) {
      syncAim(
        angle: aimAngle,
        power: shotPower.value,
      );
    }
  }

  void _updateAimVector(double length) {
    if (!_hasGameLoaded) return;
    cueBall.aimVector =
        Vector2(math.cos(aimAngle), math.sin(aimAngle)) * length;
  }

  @override
  void onPanStart(DragStartInfo info) {
    if (!canUserControl || !_hasGameLoaded || !physicsReady) {
      return;
    }
    dragStart = info.eventPosition.widget;
    dragCurrent = dragStart;
    if (ballInHand) {
      final distToCueBall = (dragStart! - cueBall.body.position).length;
      if (distToCueBall <= ballRadius * 4.0) {
        movingCueBall = true;
        cueBall.isAiming = false;
      } else {
        // Chạm vị trí khác trên bàn: di chuyển bi cái đến vị trí chạm hợp lệ
        moveCueBallTo(dragStart!);
        movingCueBall = true;
        cueBall.isAiming = false;
      }
      return;
    }
    rotateAimToPoint(dragStart!);
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (!canUserControl || !_hasGameLoaded || !physicsReady) return;
    dragCurrent = info.eventPosition.widget;
    if (dragStart != null) {
      if (movingCueBall) {
        moveCueBallTo(dragCurrent!);
        return;
      }
      rotateAimToPoint(dragCurrent!);
    }
  }

  @override
  void onPanEnd(DragEndInfo info) {
    if (!canUserControl || !_hasGameLoaded || !physicsReady) return;
    if (movingCueBall || ballInHand) {
      // Đặt bi cái xuống bàn: nhấc ngón tay lên là mở khoá ngay lập tức!
      movingCueBall = false;
      ballInHand = false;
      cueBall.isAiming = true;
      _updateAimVector(ballRadius * 2);
      if ((isLocalMultiplayer.value || isOnlineMultiplayer.value) && isMyTurn) {
        syncBallInHand(
          x: cueBall.body.position.x,
          y: cueBall.body.position.y,
          placed: true,
        );
      }
    }
    dragStart = null;
    dragCurrent = null;
  }

  @override
  void onPanCancel() {
    if (movingCueBall || ballInHand) {
      movingCueBall = false;
      ballInHand = false;
      if (_hasGameLoaded && physicsReady) {
        cueBall.isAiming = true;
        _updateAimVector(ballRadius * 2);
      }
    }
    dragStart = null;
    dragCurrent = null;
  }

  void _prepareCueBallForPlacement() {
    resetCueSpin();
    var position = initialCueBallPosition;
    final r = ballRadius * 2.1;
    var shift = 0.0;
    while (poolBalls.any((b) => !b.isSunk && (b.body.position - position).length < r) && shift < size.x * 0.3) {
      shift += ballRadius * 1.5;
      position = Vector2(
        (size.x * 0.25 - shift).clamp(playAreaTopLeft.x + ballRadius * 2, size.x * 0.5),
        size.y / 2,
      );
    }
    cueBall.isSunk = false;
    cueBall.body.setTransform(position, 0);
    cueBall.body.linearVelocity.setZero();
    cueBall.body.angularVelocity = 0;
    cueBall.body.clearForces();
    cueBall.body.setAwake(true);
    cueBall.isAiming = false;
    cueBall.strokeDistance = 0;
  }

  Vector2 get initialCueBallPosition => Vector2(size.x * 0.25, size.y / 2);

  void moveCueBallTo(Vector2 requestedPosition) {
    final position = Vector2(
      requestedPosition.x.clamp(
        playAreaTopLeft.x + ballRadius,
        playAreaBottomRight.x - ballRadius,
      ),
      requestedPosition.y.clamp(
        playAreaTopLeft.y + ballRadius,
        playAreaBottomRight.y - ballRadius,
      ),
    );
    final overlapsBall = poolBalls.any(
      (ball) =>
          !ball.isSunk &&
          (ball.body.position - position).length < ballRadius * 2.05,
    );
    if (!overlapsBall) {
      cueBall.isSunk = false;
      cueBall.body.setTransform(position, 0);
      cueBall.body.linearVelocity.setZero();
      cueBall.body.angularVelocity = 0;
      cueBall.body.clearForces();
      cueBall.body.setAwake(true);
      if ((isLocalMultiplayer.value || isOnlineMultiplayer.value) && isMyTurn) {
        syncBallInHand(
          x: position.x,
          y: position.y,
        );
      }
    }
  }

  void finishShot() {
    resetCueSpin();
    _shotElapsedTime = 0.0;
    shotInProgress = false;
    cueBall.isAiming = true;
    _updateAimVector(ballRadius * 2);

    // Xử lý riêng cho chế độ Thế Bi Hàng Ngày (Daily Puzzle)
    if (activeDailyPuzzle != null) {
      dailyPuzzleShotsTaken++;
      final targetBalls = activeDailyPuzzle!.balls
          .where((b) => !b.isObstacle)
          .map((b) => b.ballNumber)
          .toSet();
      final obstacleBalls = activeDailyPuzzle!.balls
          .where((b) => b.isObstacle)
          .map((b) => b.ballNumber)
          .toSet();

      final cueScratched = cueBall.pocketedThisShot;
      final obstacleSunk = poolBalls.any(
        (b) => b.isSunk && obstacleBalls.contains(b.number),
      );
      final allTargetsSunk = poolBalls
          .where((b) => targetBalls.contains(b.number))
          .every((b) => b.isSunk);

      if (cueScratched || obstacleSunk) {
        ruleMessage.value = cueScratched
            ? 'Thất bại: Bi cái rơi lỗ!'
            : 'Thất bại: Bi chướng ngại rơi lỗ!';
        winningPlayer = 2; // Thất bại
        rackOver = true;
      } else if (allTargetsSunk) {
        ruleMessage.value = 'Chúc mừng! Phá giải thế bi thành công!';
        winningPlayer = 1; // Thắng cuộc
        rackOver = true;
      } else if (dailyPuzzleShotsTaken >= activeDailyPuzzle!.maxShotsAllowed) {
        ruleMessage.value =
            'Thất bại: Hết số cơ cho phép (${activeDailyPuzzle!.maxShotsAllowed})!';
        winningPlayer = 2;
        rackOver = true;
      } else {
        ruleMessage.value =
            'Lượt $dailyPuzzleShotsTaken/${activeDailyPuzzle!.maxShotsAllowed} - Đánh tiếp!';
      }
      groupVersion.value++;
      matchVersion.value++;
      return;
    }

    // Xử lý riêng cho chế độ Thế Đánh Huyền Thoại (Legendary Trickshot)
    if (activeLegendaryTrickshot != null) {
      final shot = activeLegendaryTrickshot!;
      final cueScratched = cueBall.pocketedThisShot;
      final obstacleBalls = shot.balls.where((b) => b.isObstacle).map((b) => b.ballNumber).toSet();
      final obstacleSunk = poolBalls.any((b) => b.isSunk && obstacleBalls.contains(b.number));

      final targetBall = poolBalls.firstWhere(
        (b) => b.number == shot.targetBallNumber,
        orElse: () => poolBalls.first,
      );
      final targetSunk = targetBall.isSunk;

      if (cueScratched) {
        ruleMessage.value = 'Thất bại: Bi cái rơi lỗ!';
        winningPlayer = 2;
        rackOver = true;
      } else if (obstacleSunk) {
        ruleMessage.value = 'Thất bại: Bi chướng ngại rơi lỗ!';
        winningPlayer = 2;
        rackOver = true;
      } else if (targetSunk) {
        ruleMessage.value = '🏆 Xuất sắc! Bạn đã tái hiện đường cơ đỉnh cao của ${shot.playerName}!';
        winningPlayer = 1;
        rackOver = true;
      } else {
        ruleMessage.value = 'Chưa vào lỗ! Hãy bấm "ĐẶT LẠI" để luyện tập lại!';
        winningPlayer = 2;
        rackOver = true;
      }
      groupVersion.value++;
      matchVersion.value++;
      if (rackOver) {
        _processMatchRewards();
      }
      return;
    }

    final currentPlayer = currentTurn.value;
    final pocketedThisShot = poolBalls
        .where((ball) => ball.pocketedThisShot)
        .toList();
    final eightPocketed = pocketedThisShot.any((ball) => ball.number == 8);
    final group = getPlayerGroup(currentPlayer);
    final firstHit = cueBall.firstObjectBallHit;
    final legalTargetHit =
        firstHit == null ||
        (firstHit != 8 && (group == null || ballGroup(firstHit) == group)) ||
        (firstHit == 8 && group != null && allGroupBallsPocketed(group));
    final foul =
        cueBall.pocketedThisShot ||
        !cueBall.hitObjectThisShot ||
        !legalTargetHit ||
        (breakShot && pocketedThisShot.isEmpty && objectBallsHitRails < 4);

    if (foul) {
      if (eightPocketed) {
        ruleMessage.value = 'Foul: 8-ball on an illegal shot';
        winningPlayer = currentPlayer == 1 ? 2 : 1;
        playerScores[winningPlayer!] = (playerScores[winningPlayer!] ?? 0) + 1;
        rackOver = true;
      } else {
        ruleMessage.value = 'Foul - ball in hand';
        switchTurn();
        ballInHand = true;
        _prepareCueBallForPlacement();
      }
    } else if (eightPocketed) {
      final canWin = group != null && allGroupBallsPocketed(group);
      if (canWin) {
        ruleMessage.value = 'Player $currentPlayer wins the rack!';
        winningPlayer = currentPlayer;
        playerScores[currentPlayer] = (playerScores[currentPlayer] ?? 0) + 1;
      } else {
        ruleMessage.value = 'Player $currentPlayer loses: 8-ball early';
        winningPlayer = currentPlayer == 1 ? 2 : 1;
        playerScores[winningPlayer!] = (playerScores[winningPlayer!] ?? 0) + 1;
      }
      rackOver = true;
    } else if (breakShot) {
      breakShot = false;
      if (pocketedThisShot.isNotEmpty) {
        ruleMessage.value = 'Player $currentPlayer tiếp tục';
      } else {
        switchTurn();
      }
    } else if (group == null &&
        pocketedThisShot.any((ball) => ball.number != 8)) {
      assignGroupAfterBreak(pocketedThisShot);
      ruleMessage.value = 'Player $currentPlayer tiếp tục';
    } else if (pocketedThisShot.any(
      (ball) => ballGroup(ball.number) == group,
    )) {
      ruleMessage.value = 'Player $currentPlayer tiếp tục';
    } else {
      switchTurn();
    }
    if ((isLocalMultiplayer.value || isOnlineMultiplayer.value) && !rackOver) {
      final oppName = isOnlineMultiplayer.value
          ? OnlineMultiplayerService.instance.opponentName
          : (LocalMultiplayerService.instance.opponentName.isNotEmpty
              ? LocalMultiplayerService.instance.opponentName
              : (LocalMultiplayerService.instance.isHost ? 'guest_p2'.tr : 'host_p1'.tr));
      ruleMessage.value = isMyTurn
          ? (ballInHand ? 'Đấu mạng: Lượt của bạn (Đặt bi tuỳ ý!)' : 'Đấu mạng: Lượt của bạn!')
          : 'Đấu mạng: Lượt của $oppName...';
    }
    if (isOnlineMultiplayer.value) {
      final ballStates = _collectBallsState();
      final shotResultData = {
        'type': 'shot_result',
        'balls': ballStates,
        'nextTurn': currentTurn.value,
        'ballInHand': ballInHand,
        'cueBall': {
          'nx': size.x > 0 ? (cueBall.body.position.x / size.x) : 0.25,
          'ny': size.y > 0 ? (cueBall.body.position.y / size.y) : 0.5,
          'sunk': cueBall.isSunk,
        },
        'p1Group': playerGroups[1]?.name,
        'p2Group': playerGroups[2]?.name,
        'breakShot': breakShot,
        'foul': foul,
        'rackOver': rackOver,
        'winningPlayer': winningPlayer,
        'ruleMessage': ruleMessage.value,
      };
      OnlineMultiplayerService.instance.sendShotResult(shotResultData);
    }
    if (rackOver) {
      _processMatchRewards();
    }
    groupVersion.value++;
    matchVersion.value++;
  }

  BallGroup? ballGroup(int number) {
    if (number < 8) return BallGroup.solids;
    if (number > 8) return BallGroup.stripes;
    return null; // Bi 8 là bi đen trung lập, không thuộc nhóm bi trơn hay bi sọc
  }

  void assignGroupAfterBreak(List<PoolBall> pocketed) {
    final candidates = pocketed.where((ball) => ball.number != 8).toList();
    final firstObject = candidates.isEmpty ? null : candidates.first;
    if (firstObject != null) {
      final grp = ballGroup(firstObject.number);
      if (grp != null) {
        playerGroups[currentTurn.value] = grp;
        playerGroups[currentTurn.value == 1 ? 2 : 1] =
            grp == BallGroup.solids ? BallGroup.stripes : BallGroup.solids;
        groupVersion.value++;
      }
    }
  }

  String groupLabel(int player) {
    final group = getPlayerGroup(player);
    if (group == BallGroup.solids) {
      return 'solids'.tr;
    }
    if (group == BallGroup.stripes) {
      return 'stripes'.tr;
    }
    return '';
  }

  List<int> groupBalls(int player) {
    final group = getPlayerGroup(player);
    if (group == null) {
      return const [];
    }
    return group == BallGroup.solids
        ? List<int>.generate(7, (index) => index + 1)
        : List<int>.generate(7, (index) => index + 9);
  }

  bool isBallPocketed(int number) => poolBalls.any(
    (ball) => ball.number == number && (ball.isSunk || ball.isRemoved),
  );

  bool allGroupBallsPocketed(BallGroup group) => poolBalls
      .where((ball) => ball.number != 8 && ballGroup(ball.number) == group)
      .every((ball) => ball.isRemoved || ball.isSunk);

  void _processMatchRewards() {
    final bool isWinner;
    if (isOnlineMultiplayer.value) {
      final isHost = OnlineMultiplayerService.instance.isHost;
      isWinner = isHost ? (winningPlayer == 1) : (winningPlayer == 2);
    } else if (isLocalMultiplayer.value) {
      final isHost = LocalMultiplayerService.instance.isHost;
      isWinner = isHost ? (winningPlayer == 1) : (winningPlayer == 2);
    } else {
      isWinner = winningPlayer == 1;
    }

    final p1Balls = groupBalls(1);
    final pocketed = p1Balls.isEmpty
        ? 0
        : p1Balls.where((bNum) => isBallPocketed(bNum)).length;

    if (isOnlineMultiplayer.value) {
      if (activeTournamentStage != null && isWinner) {
        _lastMatchReward = ProgressionService.instance.completeTournamentBracket(
          activeTournamentStage!,
        );
      } else {
        _lastMatchReward = ProgressionService.instance.handleMultiplayerMatchRewards(
          isWinner: isWinner,
          betAmount: activeTournamentStage != null ? activeTournamentStage!.coinReward : 500,
        );
      }
      OnlineMultiplayerService.instance.sendProfile();
      OnlineMultiplayerService.instance.clearActiveMatch();
    } else if (isLocalMultiplayer.value) {
      _lastMatchReward = ProgressionService.instance.handleMultiplayerMatchRewards(
        isWinner: isWinner,
        betAmount: 500,
      );
      LocalMultiplayerService.instance.sendPlayerInfo();
    } else if (activeTournamentStage != null) {
      if (isWinner) {
        _lastMatchReward = ProgressionService.instance.completeTournamentBracket(
          activeTournamentStage!,
        );
      } else {
        _lastMatchReward = ProgressionService.instance.handleMatchRewards(
          isWinner: false,
          pottedBallsCount: pocketed,
        );
      }
    } else if (activeDailyPuzzle != null) {
      if (isWinner) {
        _lastMatchReward = ProgressionService.instance.claimDailyPuzzleReward(
          activeDailyPuzzle!,
        );
        ProgressionService.instance.recordWin();
      } else {
        _lastMatchReward = null;
      }
    } else if (activeLegendaryTrickshot != null) {
      if (isWinner) {
        _lastMatchReward = ProgressionService.instance.completeLegendaryTrickshot(
          activeLegendaryTrickshot!,
        );
        ProgressionService.instance.recordWin();
      } else {
        _lastMatchReward = null;
      }
    } else if (activeBotStage != null) {
      if (isWinner) {
        _lastMatchReward = ProgressionService.instance.completeBotStage(
          activeBotStage!,
        );
        ProgressionService.instance.recordWin();
      } else {
        _lastMatchReward = ProgressionService.instance.handleMatchRewards(
          isWinner: false,
          pottedBallsCount: pocketed,
        );
      }
    } else {
      _lastMatchReward = ProgressionService.instance.handleMatchRewards(
        isWinner: isWinner,
        pottedBallsCount: pocketed,
      );
      if (isWinner) {
        ProgressionService.instance.recordWin();
      }
    }

    ProgressionService.instance.checkAchievementsAndMedals();
    AuthService.instance.syncCurrentPlayerStats();
  }

  void registerRailHit(Object bodyOwner) {
    if (bodyOwner is PoolBall && !bodyOwner.isSunk) {
      objectBallHitRailThisShot = true;
      objectBallsHitRails++;
    }
  }

  PoolBall? targetForAim(Vector2 direction) {
    if (!_hasGameLoaded) return null;
    PoolBall? target;
    var nearestDistance = double.infinity;
    for (final ball in poolBalls) {
      if (ball.isRemoved || ball.isSunk) {
        continue;
      }
      final offset = ball.body.position - cueBall.body.position;
      final forwardDistance = offset.dot(direction);
      if (forwardDistance <= 0) {
        continue;
      }
      final sideDistance = (offset - direction * forwardDistance).length;
      if (sideDistance <= ballRadius * 1.25 &&
          forwardDistance < nearestDistance) {
        nearestDistance = forwardDistance;
        target = ball;
      }
    }
    return target;
  }

  AimGuide? guideForAim(Vector2 direction) {
    if (!_hasGameLoaded) return null;
    final normalizedDirection = direction.normalized();
    AimGuide? guide;
    var nearestDistance = double.infinity;
    final collisionDistance = (cueBall.hitboxRadius * 2.0);

    for (final ball in poolBalls) {
      if (ball.isRemoved || ball.isSunk) {
        continue;
      }
      final offset = ball.body.position - cueBall.body.position;
      final projectedDistance = offset.dot(normalizedDirection);
      if (projectedDistance <= 0) {
        continue;
      }
      final perpendicular = offset - normalizedDirection * projectedDistance;
      final perpendicularDistance = perpendicular.length;
      if (perpendicularDistance > collisionDistance) {
        continue;
      }
      final alongCircle = math.sqrt(
        math.max(
          0,
          collisionDistance * collisionDistance -
              perpendicularDistance * perpendicularDistance,
        ),
      );
      final impactDistance = projectedDistance - alongCircle;
      if (impactDistance <= 0 || impactDistance >= nearestDistance) {
        continue;
      }
      final impactPoint =
          cueBall.body.position + normalizedDirection * impactDistance;
      final objectDirection = (ball.body.position - impactPoint).normalized();
      final ghostCenter =
          ball.body.position - objectDirection * collisionDistance;

      // Tính toán hướng rẽ của bi cái (định luật 90 độ tiếp tuyến + tác động xoáy)
      final normal = objectDirection;
      final dot = normalizedDirection.dot(normal);
      Vector2 tangent = normalizedDirection - normal * dot;
      if (tangent.length2 > 0.0001) {
        tangent.normalize();
      } else {
        tangent = Vector2(-normal.y, normal.x);
      }

      final spin = cueSpin.value;
      Vector2 predictedCueDir = tangent;
      if (spin.dy > 0.05) {
        // Trô bóng (Lùi): kéo lệch hướng lùi về phía sau (-normal)
        predictedCueDir = (tangent * (1.0 - spin.dy * 0.45) - normal * (spin.dy * 0.75)).normalized();
      } else if (spin.dy < -0.05) {
        // Cu-lê (Tiến): đẩy lệch hướng tiến theo hướng ngắm ban đầu
        final follow = -spin.dy;
        predictedCueDir = (tangent * (1.0 - follow * 0.45) + normalizedDirection * (follow * 0.75)).normalized();
      }
      if (spin.dx.abs() > 0.05) {
        predictedCueDir = (predictedCueDir + tangent * (spin.dx * 0.18)).normalized();
      }

      guide = AimGuide(ball, impactPoint, objectDirection, ghostCenter, predictedCueDir);
      nearestDistance = impactDistance;
    }
    return guide;
  }

  Vector2 lineToTableEdge(Vector2 start, Vector2 direction) {
    final ray = direction.normalized();
    var distance = double.infinity;
    if (ray.x > 0) {
      distance = math.min(
        distance,
        (playAreaBottomRight.x - ballRadius - start.x) / ray.x,
      );
    } else if (ray.x < 0) {
      distance = math.min(
        distance,
        (playAreaTopLeft.x + ballRadius - start.x) / ray.x,
      );
    }
    if (ray.y > 0) {
      distance = math.min(
        distance,
        (playAreaBottomRight.y - ballRadius - start.y) / ray.y,
      );
    } else if (ray.y < 0) {
      distance = math.min(
        distance,
        (playAreaTopLeft.y + ballRadius - start.y) / ray.y,
      );
    }
    return start + ray * math.max(0.0, distance);
  }
}

class BotShot {
  final Vector2 direction;
  final double totalDistance;
  final Offset spin;
  final double power;

  BotShot({
    required this.direction,
    required this.totalDistance,
    required this.spin,
    this.power = 0.5,
  });
}

class AimGuide {
  final PoolBall target;
  final Vector2 impactPoint;
  final Vector2 objectDirection;
  final Vector2 ghostCenter;
  final Vector2 cueDeflection;

  AimGuide(
    this.target,
    this.impactPoint,
    this.objectDirection,
    this.ghostCenter,
    this.cueDeflection,
  );
}

// ================= LỚP VẬT LÝ =================

class Wall extends BodyComponent {
  final Vector2 start;
  final Vector2 end;
  final double restitution;
  final double friction;
  final bool isFacing;

  Wall(
    this.start,
    this.end, {
    this.restitution = 0.82,
    this.friction = 0.10,
    this.isFacing = false,
  }) : super(renderBody: false);

  @override
  Body createBody() {
    final shape = EdgeShape()..set(start, end);
    final fixtureDef = FixtureDef(
      shape,
      friction: friction,
      restitution: restitution,
    );
    final createdBody = world.createBody(BodyDef(type: BodyType.static))
      ..createFixture(fixtureDef);
    createdBody.userData = this;
    return createdBody;
  }
}

// Lớp quản lý va chạm chung cho toàn bộ bàn bida
class BilliardContactListener extends ContactListener {
  static BilliardGame? activeGame;

  @override
  void beginContact(Contact contact) {
    final fixtureA = contact.fixtureA;
    final fixtureB = contact.fixtureB;

    final bodyA = fixtureA.body;
    final bodyB = fixtureB.body;

    // Kiểm tra nếu một bên là Lỗ (Pocket) và bên còn lại là Bi (Ball)
    _checkPocketCollision(bodyA, bodyB);
    _checkPocketCollision(bodyB, bodyA);
    _checkBallCollision(bodyA, bodyB);
    _checkRailCollision(bodyA, bodyB);
    _checkRailCollision(bodyB, bodyA);
  }

  void _checkRailCollision(Body first, Body second) {
    final equippedTable = ProgressionService.instance.equippedTable;
    if (first.userData is Wall && (second.userData is CueBall || second.userData is PoolBall)) {
      final wall = first.userData as Wall;
      final speed = second.linearVelocity.length;
      if (!speed.isNaN && speed > 40.0) {
        activeGame?.vfx.addRailImpact(
          ballPos: second.position,
          wallStart: wall.start,
          wallEnd: wall.end,
          speed: speed,
          ballRadius: activeGame?.ballRadius ?? 12.0,
          tableConcept: equippedTable.animeConcept,
          railAccentColor: equippedTable.railAccentColor,
        );
      }
      if (second.userData is CueBall) {
        if (!wall.isFacing) {
          _applyCushionSpin(second.userData as CueBall, wall);
        } else {
          activeGame?.registerRailHit(second.userData!);
        }
      } else {
        activeGame?.registerRailHit(second.userData!);
      }
    } else if (second.userData is Wall && (first.userData is CueBall || first.userData is PoolBall)) {
      final wall = second.userData as Wall;
      final speed = first.linearVelocity.length;
      if (!speed.isNaN && speed > 40.0) {
        activeGame?.vfx.addRailImpact(
          ballPos: first.position,
          wallStart: wall.start,
          wallEnd: wall.end,
          speed: speed,
          ballRadius: activeGame?.ballRadius ?? 12.0,
          tableConcept: equippedTable.animeConcept,
          railAccentColor: equippedTable.railAccentColor,
        );
      }
      if (first.userData is CueBall) {
        if (!wall.isFacing) {
          _applyCushionSpin(first.userData as CueBall, wall);
        } else {
          activeGame?.registerRailHit(first.userData!);
        }
      } else {
        activeGame?.registerRailHit(first.userData!);
      }
    }
  }

  void _applyCushionSpin(CueBall cue, Wall wall) {
    activeGame?.registerRailHit(cue);

    final spin = cue.activeSpin;
    if (spin.dx.abs() < 0.05) {
      return;
    }

    final wallVec = (wall.end - wall.start).normalized();
    final tableCenter = activeGame != null
        ? Vector2(activeGame!.size.x / 2, activeGame!.size.y / 2)
        : Vector2(500, 250);
    final wallMid = (wall.start + wall.end) * 0.5;
    final toCenter = (tableCenter - wallMid).normalized();

    Vector2 normal = Vector2(-wallVec.y, wallVec.x);
    if (normal.dot(toCenter) < 0) {
      normal = -normal;
    }
    // Tiếp tuyến sao cho quay ngược chiều kim đồng hồ 90 độ từ pháp tuyến
    final tangent = Vector2(-normal.y, normal.x);

    final speed = cue.body.linearVelocity.length;
    if (speed.isNaN || speed.isInfinite) {
      cue.body.linearVelocity.setZero();
      return;
    }
    // Áp-phê tác động lực dọc theo mép băng (running english nảy choãi, reverse english nảy gắt)
    final spinKick = tangent * (spin.dx * math.min(speed * 0.45, 340.0));
    cue.body.linearVelocity.add(spinKick);

    // Băng tiêu hao bớt một phần áp-phê
    cue.activeSpin = Offset(cue.activeSpin.dx * 0.60, cue.activeSpin.dy * 0.65);
  }

  void _checkBallCollision(Body first, Body second) {
    final isFirstBall = first.userData is CueBall || first.userData is PoolBall;
    final isSecondBall = second.userData is CueBall || second.userData is PoolBall;
    if (isFirstBall && isSecondBall) {
      // Giảm animation xoay bi quá mức mỗi lần va chạm bi
      first.angularVelocity *= 0.25;
      second.angularVelocity *= 0.25;

      final velA = first.linearVelocity;
      final velB = second.linearVelocity;
      if (!velA.x.isNaN && !velA.y.isNaN && !velB.x.isNaN && !velB.y.isNaN) {
        final relVel = (velA - velB).length;
        if (!relVel.isNaN && !relVel.isInfinite) {
          if (activeGame?.isCatchingUp != true) {
            AudioManager.instance.playBallHit(relativeSpeed: relVel);
          }
          // Hiệu ứng sóng kích phát quang va chạm nảy bi chân thực
          final contactPos = (first.position + second.position) * 0.5;
          activeGame?.vfx.addBallCollision(
            contactPos,
            relVel,
            ballRadius: activeGame?.ballRadius ?? 12.0,
          );
        }
      }
    }

    final cue = first.userData is CueBall
        ? first.userData as CueBall
        : (second.userData is CueBall ? second.userData as CueBall : null);
    if (cue != null && cue.isAirborne) {
      // Bi cái đang bay trên không (Jump Shot): Tạm thời bỏ qua va chạm với bi cản phía dưới!
      return;
    }
    final target = first.userData is PoolBall
        ? first.userData as PoolBall
        : second.userData is PoolBall
        ? second.userData as PoolBall
        : null;
    if (cue != null && target != null) {
      cue.hitObjectThisShot = true;
      cue.firstObjectBallHit ??= target.number;
      if (!cue.hasCollidedBall) {
        cue.hasCollidedBall = true;
        final normal = (target.body.position - cue.body.position).normalized();
        final cueVel = cue.body.linearVelocity;
        final shotSpeed = cueVel.length;
        final dir = cue.shotDirection ?? (shotSpeed > 10.0 ? cueVel.normalized() : normal);
        final dot = dir.dot(normal);

        Vector2 tangent = dir - normal * dot;
        if (tangent.length2 > 0.0001) {
          tangent.normalize();
        } else {
          tangent = Vector2(-normal.y, normal.x);
        }

        // 1. Trô bóng (draw shot / backspin: dy > 0.05)
        if (cue.activeSpin.dy > 0.05) {
          final spinDy = cue.activeSpin.dy;
          // Truyền trọn vẹn động lượng cho bi mục tiêu theo đúng thực tế va chạm đàn hồi
          final targetForwardSpeed = (shotSpeed * math.max(0.35, dot) * 0.94);
          target.body.linearVelocity = normal * targetForwardSpeed;

          if (dot >= 0.72) {
            // Đánh trực diện: Bi mục tiêu lao đi mạnh mẽ, bi cái triệt tiêu vận tốc tiến và giật lùi dọc trục -normal
            cue.body.linearVelocity.scale(0.08);
            final drawStrength = (460.0 + shotSpeed * 0.38) * spinDy;
            cue.drawFollowForce = -normal * drawStrength;
            cue.drawFollowTimer = 0.48;
          } else {
            // Đánh góc chéo (Cut shot): Bi mục tiêu vẫn lao đi với lực thực tế, bi cái giật về phía sau
            final drawStrength = (400.0 + shotSpeed * 0.32) * spinDy;
            cue.drawFollowForce = (-normal * (dot * 0.85) - dir * (1.0 - dot * 0.5)).normalized() * drawStrength;
            cue.drawFollowTimer = 0.42;
          }
        }
        // 2. Cu-lê (follow shot / topspin: dy < -0.05)
        else if (cue.activeSpin.dy < -0.05) {
          final spinDy = -cue.activeSpin.dy;
          if (dot >= 0.72) {
            // Đánh trực diện: Lăn bám nỉ tiến tới theo normal
            final followStrength = (400.0 + shotSpeed * 0.32) * spinDy;
            cue.drawFollowForce = normal * followStrength;
            cue.drawFollowTimer = 0.42;
          } else {
            // Đánh góc chéo (Cut shot): Lực cu-lê kéo bi uốn cong vút tới theo hướng bắn ban đầu
            final followStrength = (360.0 + shotSpeed * 0.28) * spinDy;
            cue.drawFollowForce = dir * followStrength;
            cue.drawFollowTimer = 0.40;
          }
        }

        // 3. Hiệu ứng va chạm xoáy ngang (English throw):
        if (cue.activeSpin.dx.abs() > 0.05) {
          cue.body.linearVelocity.add(tangent * (cue.activeSpin.dx * 35.0));
          target.body.linearVelocity.add(-tangent * (cue.activeSpin.dx * 20.0));
        }
      }
    }
  }

  void _checkPocketCollision(Body pocketBody, Body ballBody) {
    if (pocketBody.userData is Pocket) {
      final pocket = pocketBody.userData as Pocket;
      final game = activeGame;
      if (game != null && !game.canBallEnterPocket(ballBody, pocket)) {
        return;
      }
      if (ballBody.userData is PoolBall) {
        final ball = ballBody.userData as PoolBall;
        if (!ball.isSunk) {
          game?.vfx.clearBallTrail(ball.number);
          ball.sinkIntoPocket(pocket.position);
          ball.pocketedThisShot = true;
          game?.handleBallPocketed(ball);
          game?.vfx.addPocketDrop(pocket.position, pocket.dropDistance);
        }
      } else if (ballBody.userData is CueBall) {
        final cueBall = ballBody.userData as CueBall;
        if (!cueBall.isSunk) {
          game?.vfx.clearBallTrail(0);
          cueBall.sinkIntoPocket(pocket.position);
          cueBall.pocketedThisShot = true;
          if (game?.isCatchingUp != true) {
            AudioManager.instance.playPocket();
          }
          game?.comboNotifier.value = null;
          game?.vfx.addPocketDrop(pocket.position, pocket.dropDistance);
        }
      }
    }
  }

  @override
  void endContact(Contact contact) {}

  @override
  void preSolve(Contact contact, Manifold oldManifold) {}

  @override
  void postSolve(Contact contact, ContactImpulse impulse) {}
}

// Cảm biến Lỗ Bida
class Pocket extends BodyComponent {
  @override
  final Vector2 position;
  final double radius;
  final bool isMiddle;
  final double dropDistance;

  Pocket(
    this.position,
    this.radius, {
    this.isMiddle = false,
    double? dropDistance,
  })  : dropDistance = dropDistance ?? radius,
        super(renderBody: false) {
    priority = 0;
  }

  @override
  Body createBody() {
    final shape = CircleShape()..radius = radius;
    // isSensor: true giúp bi lọt qua thay vì dội lại như đập tường
    final fixtureDef = FixtureDef(shape, isSensor: true);
    final createdBody = world.createBody(
      BodyDef(type: BodyType.static, position: position),
    )..createFixture(fixtureDef);
    createdBody.userData = this;
    return createdBody;
  }
}

// Lớp hỗ trợ tia ngắm A-Băng
class AimRayCastCallback extends RayCastCallback {
  final Body ignoreBody;
  Vector2? hitPoint, hitNormal;
  Fixture? hitFixture;

  AimRayCastCallback(this.ignoreBody);

  @override
  double reportFixture(
    Fixture fixture,
    Vector2 point,
    Vector2 normal,
    double fraction,
  ) {
    if (fixture.body == ignoreBody || fixture.isSensor) {
      return -1.0; // Xuyên qua Lỗ Bida
    }
    hitPoint = point.clone();
    hitNormal = normal.clone();
    hitFixture = fixture;
    return fraction;
  }
}

class CueBall extends BodyComponent {
  Vector2 initialPosition;
  double radius;
  double hitboxRadius;

  Vector2? aimVector, rayHitPoint, reflectionVector;
  Sprite? cueSprite;
  Sprite? cueStickSprite;
  double strokeDistance = 0;
  Offset spinInfluence = Offset.zero;
  Offset activeSpin = Offset.zero;
  Vector2? shotDirection;
  bool hasCollidedBall = false;
  double drawFollowTimer = 0.0;
  Vector2 drawFollowForce = Vector2.zero();
  bool isAiming = true;
  bool isSunk = false;
  bool hitObjectThisShot = false;
  int? firstObjectBallHit;
  bool pocketedThisShot = false;

  // Trục Z giả lập cho các cú Jump Shot và nhảy bi qua bi cản
  double zHeight = 0.0;
  double zVelocity = 0.0;
  bool get isAirborne => zHeight > (hitboxRadius * 0.60);

  Vector2? _sunkStartPos;
  Vector2? _sunkCurrentPos;
  Vector2? _sunkTargetPocket;
  Vector2? _sunkVelocity;
  double _sunkProgress = 0.0;
  bool _sunkAnimComplete = false;
  bool get isSunkAnimComplete => !isSunk || _sunkAnimComplete;

  void sinkIntoPocket(Vector2 pocketPos) {
    if (isSunk) return;
    isSunk = true;
    try {
      gameInstance.vfx.clearBallTrail(0);
    } catch (_) {}
    _sunkStartPos = body.position.clone();
    _sunkCurrentPos = body.position.clone();
    _sunkTargetPocket = pocketPos.clone();
    _sunkVelocity = body.linearVelocity.clone();
    _sunkProgress = 0.0;
    _sunkAnimComplete = false;
    isAiming = false;

    body.linearVelocity.setZero();
    body.angularVelocity = 0;
    body.setTransform(Vector2(-1000, -1000), 0);
  }

  void resetSunkState() {
    isSunk = false;
    _sunkStartPos = null;
    _sunkCurrentPos = null;
    _sunkTargetPocket = null;
    _sunkVelocity = null;
    _sunkProgress = 0.0;
    _sunkAnimComplete = false;
  }

  void completeSunkAnim() {
    _sunkProgress = 1.0;
    _sunkAnimComplete = true;
  }

  // Quản lý trạng thái lăn và xoay 3D thực tế của bi cái
  final Ball3DOrientation orientation = Ball3DOrientation();

  CueBall(
    this.initialPosition,
    this.radius, {
    double? hitboxRadius,
  }) : hitboxRadius = hitboxRadius ?? (radius * 0.88) {
    priority = 2;
  }

  void updateRadius(double newRadius) {
    radius = newRadius;
    hitboxRadius = newRadius * 0.88;
    try {
      for (final f in body.fixtures) {
        if (f.shape is CircleShape) {
          f.shape.radius = hitboxRadius;
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    cueSprite = await Sprite.load('cue_ball.png');
    cueStickSprite = await Sprite.load('cue_stick.png');
  }

  @override
  Body createBody() {
    final shape = CircleShape()..radius = hitboxRadius;
    final fixtureDef = FixtureDef(
      shape,
      restitution: 0.90,
      density: 0.8,
      friction: 0.16,
    );
    final createdBody = world.createBody(
      BodyDef(
        type: BodyType.dynamic,
        position: initialPosition,
        bullet: true,
        fixedRotation: false,
        linearDamping: 0.0,
        angularDamping: 1.6,
      ),
    )..createFixture(fixtureDef);
    createdBody.userData = this;
    return createdBody;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Cập nhật độ cao trục Z giả lập cho Jump Shot
    if (zHeight > 0.0 || zVelocity > 0.0) {
      zVelocity -= 980.0 * dt;
      zHeight += zVelocity * dt;
      if (zHeight <= 0.0) {
        zHeight = 0.0;
        zVelocity = 0.0;
      }
    }

    if (!isMounted) return;
    try {
      final _ = body;
    } catch (_) {
      return;
    }

    if (isSunk) {
      body.linearVelocity.setZero();
      body.angularVelocity = 0;
      isAiming = false;
      if (body.position.x > -500) {
        body.setTransform(Vector2(-1000, -1000), 0);
      }
      if (_sunkStartPos == null) {
        _sunkStartPos = body.position.clone();
        _sunkCurrentPos = body.position.clone();
        _sunkVelocity = body.linearVelocity.clone();
        Pocket? nearest;
        double minD = double.infinity;
        for (final p in gameInstance.pockets) {
          final d = (p.position - _sunkStartPos!).length;
          if (d < minD) {
            minD = d;
            nearest = p;
          }
        }
        _sunkTargetPocket = nearest?.position.clone() ?? _sunkStartPos!.clone();
      }

      if (!_sunkAnimComplete) {
        // Tốc độ lăn chìm vào lỗ tự nhiên (~0.74 giây)
        _sunkProgress += dt * 1.35;
        if (_sunkProgress >= 1.0) {
          _sunkProgress = 1.0;
          _sunkAnimComplete = true;
        }

        final t = _sunkProgress.clamp(0.0, 1.0);
        final start = _sunkStartPos!;
        final target = _sunkTargetPocket!;
        final toTarget = target - start;
        final dist = toTarget.length;

        final inVel = _sunkVelocity ?? Vector2.zero();
        final inSpeed = inVel.length;
        final inDir = inSpeed > 0.5
            ? inVel.normalized()
            : (dist > 0.001 ? toTarget.normalized() : Vector2(0, 1));

        final p0 = start;
        final p3 = target;
        final p1 = p0 + inDir * (dist * 0.45);
        final toPocketNorm = dist > 0.001 ? toTarget.normalized() : inDir;
        final p2 = p3 - toPocketNorm * (dist * 0.25);

        final u = math.pow(t, 1.25).toDouble();
        final oneMinusU = 1.0 - u;
        final nextX = oneMinusU * oneMinusU * oneMinusU * p0.x +
            3.0 * oneMinusU * oneMinusU * u * p1.x +
            3.0 * oneMinusU * u * u * p2.x +
            u * u * u * p3.x;
        final nextY = oneMinusU * oneMinusU * oneMinusU * p0.y +
            3.0 * oneMinusU * oneMinusU * u * p1.y +
            3.0 * oneMinusU * u * u * p2.y +
            u * u * u * p3.y;

        if (nextX.isNaN || nextY.isNaN || nextX.isInfinite || nextY.isInfinite) {
          _sunkProgress = 1.0;
          _sunkAnimComplete = true;
          return;
        }

        if (_sunkCurrentPos != null) {
          final dx = nextX - _sunkCurrentPos!.x;
          final dy = nextY - _sunkCurrentPos!.y;
          final stepDist = math.sqrt(dx * dx + dy * dy);
          if (stepDist > 0.0001 && !stepDist.isNaN && !stepDist.isInfinite) {
            final rollMultiplier = 1.8 + 1.2 * t;
            orientation.roll(dx * rollMultiplier, dy * rollMultiplier, radius);

            final crossZ = inDir.x * toTarget.y - inDir.y * toTarget.x;
            final swirlDir = crossZ >= 0 ? 1.0 : -1.0;
            final spinZRate = swirlDir * math.sin(t * math.pi) * 4.5 * dt;
            if (!spinZRate.isNaN && !spinZRate.isInfinite) {
              orientation.spinZ(spinZRate);
            }
          }
        }
        _sunkCurrentPos = Vector2(nextX, nextY);
      }
      return;
    } else {
      _sunkStartPos = null;
      _sunkCurrentPos = null;
      _sunkTargetPocket = null;
      _sunkVelocity = null;
      _sunkProgress = 0.0;
      _sunkAnimComplete = false;
    }

    // Cập nhật góc lăn 3D theo vận tốc di chuyển thực tế trên mặt bàn
    final vel = body.linearVelocity;
    if (vel.x.isNaN || vel.y.isNaN || vel.x.isInfinite || vel.y.isInfinite) {
      vel.setZero();
      body.angularVelocity = 0;
      return;
    }
    if (body.position.x.isNaN || body.position.y.isNaN || body.position.x.isInfinite || body.position.y.isInfinite) {
      body.setTransform(Vector2(gameInstance.size.x * 0.3, gameInstance.size.y * 0.5), 0);
      vel.setZero();
      body.angularVelocity = 0;
      return;
    }
    final speed = vel.length;
    if (speed > 0.5) {
      orientation.roll(vel.x * dt, vel.y * dt, radius);
    }
    if (body.angularVelocity.abs() > 0.01 && !body.angularVelocity.isNaN) {
      orientation.spinZ(body.angularVelocity * dt * 0.25);
    }

    if (aimVector != null &&
        !aimVector!.x.isNaN &&
        !aimVector!.y.isNaN &&
        aimVector!.length > 0.0) {
      final callback = AimRayCastCallback(body);
      final p1 = body.position;
      final direction = aimVector!.normalized();
      final p2 = p1 + (direction * 2000.0);
      world.raycast(callback, p1, p2);

      if (callback.hitPoint != null &&
          callback.hitNormal != null &&
          callback.hitFixture != null) {
        rayHitPoint = callback.hitPoint;
        final v = direction;
        final n = callback.hitNormal!;
        final dotProduct = v.dot(n);

        if (callback.hitFixture!.shape.shapeType == ShapeType.circle) {
          Vector2 tangentVector = v - (n * dotProduct);
          reflectionVector = tangentVector.length2 > 0.001
              ? tangentVector.normalized()
              : Vector2.zero();
        } else {
          reflectionVector = (v - (n * 2.0 * dotProduct))..normalize();
        }
      } else {
        rayHitPoint = null;
        reflectionVector = null;
      }
    } else {
      rayHitPoint = null;
      reflectionVector = null;
    }
  }

  @override
  void render(Canvas canvas) {
    if (isSunk) {
      if (_sunkAnimComplete || _sunkCurrentPos == null) {
        return;
      }
      if (_sunkCurrentPos!.x.isNaN ||
          _sunkCurrentPos!.y.isNaN ||
          body.position.x.isNaN ||
          body.position.y.isNaN) {
        return;
      }
      canvas.save();
      // Bù lại tọa độ thế giới khi bi đang rơi
      canvas.translate(-body.position.x + _sunkCurrentPos!.x, -body.position.y + _sunkCurrentPos!.y);
      if (!body.angle.isNaN && !body.angle.isInfinite) {
        canvas.rotate(-body.angle);
      }

      final t = _sunkProgress.clamp(0.0, 1.0);
      final dropT = t <= 0.30 ? 0.0 : ((t - 0.30) / 0.70).clamp(0.0, 1.0);
      final scale = (1.0 - math.pow(dropT, 1.25) * 0.74).clamp(0.26, 1.0);

      final cupDepthY = math.pow(dropT, 1.3) * (radius * 0.28);
      canvas.translate(0, cupDepthY);

      // Bi cái cũng là bi đặc nguyên khối, không tan biến dần
      Ball3DRenderer.renderBall(
        canvas: canvas,
        radius: radius,
        orientation: orientation,
        ballNumber: null,
        scale: scale,
        opacity: 1.0,
        pocketDropProgress: t,
      );
      canvas.restore();
      return;
    }
    // The physics body can spin, but aiming is defined in world space.
    canvas.save();
    canvas.rotate(-body.angle);
    if (isAiming &&
        aimVector != null &&
        aimVector!.length > 0.0) {
      final direction = aimVector!.normalized();

      // Cây cơ hiển thị theo gậy người chơi đang trong lượt đánh (đồng bộ trên mọi máy)
      final (activeCue, activeLevel) = gameInstance.getActivePlayerCue();

      _renderEquippedCueStick(
        canvas,
        direction,
        strokeDistance,
        activeCue,
        activeLevel,
      );
    }

    // Khi Ball In Hand: vẽ vòng định vị kèm 4 mũi tên hướng dẫn
    if (gameInstance.ballInHand) {
      final ringPaint = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      canvas.drawCircle(Offset.zero, radius * 1.55, ringPaint);

      final crossPaint = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.85)
        ..strokeWidth = 1.5;
      final d = radius * 1.55;
      canvas.drawLine(Offset(0, -d - 4), Offset(0, -d + 4), crossPaint);
      canvas.drawLine(Offset(0, d - 4), Offset(0, d + 4), crossPaint);
      canvas.drawLine(Offset(-d - 4, 0), Offset(-d + 4, 0), crossPaint);
      canvas.drawLine(Offset(d - 4, 0), Offset(d + 4, 0), crossPaint);
    }

    // Vết bóng mờ lần bắn trước (Ghost Trail Replay) cho Trickshots & Daily Puzzle
    if (gameInstance.showPreviousShotGhost &&
        gameInstance.previousShotAimVector != null &&
        (gameInstance.activeLegendaryTrickshot != null || gameInstance.activeDailyPuzzle != null)) {
      final prevDir = gameInstance.previousShotAimVector!.normalized();
      final ghostLength = gameInstance.ballRadius * 16.0;

      final ghostPaint = Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.40)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      const dashWidth = 5.0;
      const dashSpace = 4.0;
      double currentDist = 0.0;
      while (currentDist < ghostLength) {
        final start = prevDir * currentDist;
        final end = prevDir * math.min(currentDist + dashWidth, ghostLength);
        canvas.drawLine(start.toOffset(), end.toOffset(), ghostPaint);
        currentDist += dashWidth + dashSpace;
      }

      final ghostEnd = prevDir * ghostLength;
      canvas.drawCircle(
        ghostEnd.toOffset(),
        radius * 0.90,
        Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: 0.18)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        ghostEnd.toOffset(),
        radius * 0.90,
        Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    // Dựng hình Bi cái 2.5D lăn 3D với 6 chấm đỏ giải đấu Aramith TV và độ cao Jump Shot
    Ball3DRenderer.renderBall(
      canvas: canvas,
      radius: radius,
      orientation: orientation,
      ballNumber: null,
      scale: 1.0,
      opacity: 1.0,
      cueSpinOffset: spinInfluence,
      zHeight: zHeight,
    );

    if (isAiming && aimVector != null) {
      canvas.save();
      final aimPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = 0.4;
      final direction = aimVector!.normalized();
      final guide = (game as BilliardGame).guideForAim(direction);

      final (cueForAim, levelForAim) = gameInstance.getActivePlayerCue();
      final aimMult = cueForAim.getAimMultiplier(levelForAim);

      if (guide != null) {
        final targetOffset = guide.impactPoint - body.position;
        final targetCenterOffset = guide.target.body.position - body.position;
        final ghostOffset = guide.ghostCenter - body.position;
        final targetLineEnd =
            (game as BilliardGame).lineToTableEdge(
              guide.target.body.position,
              guide.objectDirection,
            ) -
            body.position;

        // Vệt hào quang ma pháp nếu gậy đạt Lv >= 7 (Epic/Legendary)
        if (levelForAim >= 7) {
          canvas.drawCircle(
            ghostOffset.toOffset(),
            radius * 1.35,
            Paint()
              ..color = cueForAim.auraColor.withValues(alpha: 0.4)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
        }

        // 1. Đường ngắm bi cái tới điểm tiếp xúc (Ghost Ball)
        canvas.drawLine(
          Offset.zero,
          ghostOffset.toOffset(),
          Paint()
            ..color = (levelForAim >= 8 ? cueForAim.ballTrailColor : Colors.cyanAccent).withValues(alpha: 0.9)
            ..strokeWidth = 1.1 + (levelForAim >= 8 ? 0.3 : 0.0),
        );

        // 2. Đường lăn dự kiến của bi mục tiêu (kéo dài theo aimMult)
        final extendedEnd = targetOffset + (targetLineEnd - targetOffset) * aimMult.clamp(0.8, 1.4);
        canvas.drawLine(
          targetOffset.toOffset(),
          extendedEnd.toOffset(),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.75)
            ..strokeWidth = 0.7,
        );

        // 3. Vòng tròn bi mục tiêu và điểm tiếp xúc
        canvas.drawCircle(
          targetCenterOffset.toOffset(),
          radius,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );
        canvas.drawCircle(
          ghostOffset.toOffset(),
          radius,
          Paint()
            ..color = (levelForAim >= 8 ? cueForAim.ballTrailColor : Colors.cyanAccent).withValues(alpha: 0.85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );
        canvas.drawLine(
          ghostOffset.toOffset(),
          targetOffset.toOffset(),
          Paint()
            ..color = Colors.orangeAccent.withValues(alpha: 0.9)
            ..strokeWidth = 0.9,
        );
        canvas.drawCircle(
          targetOffset.toOffset(),
          radius * 0.22,
          Paint()..color = Colors.orangeAccent.withValues(alpha: 0.95),
        );

        // 4. Đường rẽ của bi cái sau va chạm (hiển thị tác động xoáy Cu-lê, Trô bóng, Áp-phê có nhân aimMult)
        final deflectionLength = (50.0 + gameInstance.shotPower.value * 120.0).clamp(40.0, 160.0) * aimMult;
        final cueDeflectionEnd = ghostOffset + guide.cueDeflection * deflectionLength;
        canvas.drawLine(
          ghostOffset.toOffset(),
          cueDeflectionEnd.toOffset(),
          Paint()
            ..color = Colors.amberAccent.withValues(alpha: 0.88)
            ..strokeWidth = 0.9,
        );
        canvas.drawCircle(
          cueDeflectionEnd.toOffset(),
          radius * 0.22,
          Paint()..color = Colors.amberAccent.withValues(alpha: 0.95),
        );
      } else if (rayHitPoint != null && reflectionVector != null) {
        // Ngắm A-băng (đập băng trực tiếp): phản ánh góc nảy có xoáy áp-phê
        final localHitPoint = rayHitPoint! - body.position;
        canvas.drawLine(Offset.zero, localHitPoint.toOffset(), aimPaint);
        canvas.drawCircle(
          localHitPoint.toOffset(),
          0.6,
          Paint()..color = Colors.red.withValues(alpha: 0.8),
        );

        // Điều chỉnh góc phản xạ của tia A-băng theo áp-phê
        final spin = (game as BilliardGame).cueSpin.value;
        Vector2 adjustedReflection = reflectionVector!;
        if (spin.dx.abs() > 0.05) {
          final normal = (adjustedReflection - direction).normalized();
          final tangent = Vector2(-normal.y, normal.x);
          adjustedReflection = (adjustedReflection + tangent * (spin.dx * 0.35)).normalized();
        }

        canvas.drawLine(
          localHitPoint.toOffset(),
          (localHitPoint + (adjustedReflection * 45.0 * aimMult)).toOffset(),
          Paint()
            ..color = Colors.yellow.withValues(alpha: 0.7)
            ..strokeWidth = 0.6,
        );
      } else {
        canvas.drawLine(Offset.zero, (aimVector! * 2.5 * aimMult).toOffset(), aimPaint);
      }
      canvas.restore();
    }

    canvas.restore();
  }

  void _renderEquippedCueStick(
    Canvas canvas,
    Vector2 direction,
    double strokeDistance,
    CueModel cue,
    int level,
  ) {
    final stickLength = radius * 19.5;
    final angle = math.atan2(direction.y, direction.x);

    canvas.save();
    // Dịch chuyển đến vị trí đầu cơ cách mép bi cái một khoảng strokeDistance
    canvas.translate(
      -direction.x * (radius * 1.05 + strokeDistance),
      -direction.y * (radius * 1.05 + strokeDistance),
    );
    canvas.rotate(angle);

    // Tip nằm tại x = 0, gậy kéo dài về phía âm trục X (từ 0 đến -stickLength)
    final tipR = radius * 0.22;
    final ferruleR = radius * 0.24;
    final jointR = radius * 0.33;
    final buttR = radius * 0.44;

    // 0a. Bóng đổ 2.5D chân thực của gậy cơ xuống mặt bàn nỉ
    canvas.save();
    canvas.translate(-radius * 0.15, radius * 0.38);
    final cueShadowPath = Path()
      ..moveTo(0, -tipR * 1.2)
      ..lineTo(-stickLength, -buttR * 1.35)
      ..lineTo(-stickLength, buttR * 1.35)
      ..lineTo(0, tipR * 1.2)
      ..close();
    canvas.drawPath(
      cueShadowPath,
      Paint()
        ..color = const Color(0x38000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
    canvas.restore();

    // 0b. HÀO QUANG NĂNG LƯỢNG (Aura Corona) - CÀNG CAO CÀNG RỰC RỠ & LỘNG LẪY
    // Lv 3-5: Quầng sáng dịu; Lv 6-8: Hào quang sắc nét; Lv 9-10 (MAX): Thiên quang Thần Thoại
    if (level >= 3 || cue.rarity == CueRarity.epic || cue.rarity == CueRarity.legendary) {
      final auraColor = cue.auraColor;
      final isMaxTier = level >= 9;
      final isHighTier = level >= 6;

      // Pass 1: Quầng sáng nở rộng tỏa lan (Soft ambient aura)
      final ambientAlpha = isMaxTier ? 0.55 : (isHighTier ? 0.40 : 0.26);
      canvas.drawLine(
        const Offset(-2, 0),
        Offset(-stickLength + 2, 0),
        Paint()
          ..color = auraColor.withValues(alpha: ambientAlpha)
          ..strokeWidth = radius * (isMaxTier ? 2.2 : (isHighTier ? 1.6 : 1.1))
          ..style = PaintingStyle.stroke
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, isMaxTier ? 6.0 : 3.5),
      );

      // Pass 2: Lõi năng lượng phát quang cường độ cao cho gậy Lv >= 6
      if (isHighTier) {
        canvas.drawLine(
          const Offset(-4, 0),
          Offset(-stickLength + 4, 0),
          Paint()
            ..color = Colors.white.withValues(alpha: isMaxTier ? 0.65 : 0.45)
            ..strokeWidth = radius * 0.35
            ..style = PaintingStyle.stroke
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8),
        );
      }
    }

    void drawSegment({
      required double xStart,
      required double xEnd,
      required double rStart,
      required double rEnd,
      required List<Color> colors,
    }) {
      final path = Path()
        ..moveTo(xStart, -rStart)
        ..lineTo(xEnd, -rEnd)
        ..lineTo(xEnd, rEnd)
        ..lineTo(xStart, rStart)
        ..close();

      final maxR = math.max(rStart, rEnd);
      final c0 = colors[0];
      final cMid = colors.length > 2 ? colors[1] : colors[0];
      final cLast = colors.last;

      // Chiếu sáng hình trụ 3D siêu thực với dải phản quang ánh kim (High-specular cylinder)
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            c0,
            cMid,
            Colors.white.withValues(alpha: 0.72), // Vệt bóng sáng trắng phản chiếu ánh đèn bàn
            cMid,
            cLast.withValues(alpha: 0.90),
          ],
          stops: const [0.0, 0.24, 0.46, 0.74, 1.0],
        ).createShader(Rect.fromLTRB(xEnd, -maxR, xStart, maxR));

      canvas.drawPath(path, paint);
    }

    // 1. Đầu lơ (Chalk Tip) bo cong hình bán nguyệt ở đỉnh x = 0
    final tipLen = radius * 0.36;
    final tipPath = Path()
      ..moveTo(0, 0)
      ..arcToPoint(
        Offset(-tipLen, -tipR),
        radius: Radius.circular(tipR),
        clockwise: false,
      )
      ..lineTo(-tipLen, tipR)
      ..arcToPoint(
        const Offset(0, 0),
        radius: Radius.circular(tipR),
        clockwise: false,
      )
      ..close();
    canvas.drawPath(tipPath, Paint()..color = cue.tipColor);

    // 2. Phíp cơ trắng ngà (White Ferrule) bọc viền vàng kim
    final ferruleLen = radius * 0.72;
    drawSegment(
      xStart: -tipLen,
      xEnd: -(tipLen + ferruleLen),
      rStart: tipR,
      rEnd: ferruleR,
      colors: const [Color(0xFFE8E8E8), Color(0xFFFFFFFF), Color(0xFFC0C0C0)],
    );

    // Chỉ vàng / titanium nẹp chân phíp
    final ferruleTrimColor = level >= 5 ? const Color(0xFFFFD54F) : const Color(0xFF222222);
    canvas.drawLine(
      Offset(-(tipLen + ferruleLen), -ferruleR),
      Offset(-(tipLen + ferruleLen), ferruleR),
      Paint()
        ..color = ferruleTrimColor
        ..strokeWidth = level >= 8 ? 1.0 : 0.6,
    );

    // 3. Ngọn cơ (Shaft) - thể hiện màu sắc đặc trưng của cây gậy
    final jointX = -stickLength * 0.52;
    drawSegment(
      xStart: -(tipLen + ferruleLen),
      xEnd: jointX,
      rStart: ferruleR,
      rEnd: jointR,
      colors: cue.shaftColors,
    );

    // HỌA TIẾT CONCEPT ANIME TRÊN THÂN NGỌN CƠ - PHÂN CẤP THEO LEVEL
    final shaftXStart = -(tipLen + ferruleLen);
    switch (cue.animeConcept) {
      case CueAnimeConcept.katanaSamurai:
        // Vân tôi kiếm Hamon đỏ/trắng uốn lượn sắc bén
        final hamonPaint = Paint()
          ..color = const Color(0xFFFF1744).withValues(alpha: level >= 6 ? 0.95 : 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = level >= 7 ? 1.2 : 0.8;
        final hamonPath = Path()..moveTo(shaftXStart - 2, 0);
        for (double hx = shaftXStart - 2; hx > jointX + 2; hx -= radius * 0.8) {
          hamonPath.quadraticBezierTo(hx - radius * 0.2, -jointR * 0.45, hx - radius * 0.4, 0);
          hamonPath.quadraticBezierTo(hx - radius * 0.6, jointR * 0.45, hx - radius * 0.8, 0);
        }
        canvas.drawPath(hamonPath, hamonPaint);

        // Lv >= 5: Thêm đai cổ kiếm Habaki dát vàng 24K ở gốc ngọn
        if (level >= 5) {
          canvas.drawRect(
            Rect.fromLTWH(jointX + radius * 0.2, -jointR * 0.8, radius * 0.5, jointR * 1.6),
            Paint()..color = const Color(0xFFFFD54F),
          );
        }
        // Lv >= 8: Khắc chìm cổ tự Diệt Quỷ dát vàng dọc sống kiếm
        if (level >= 8) {
          final runePaint = Paint()
            ..color = Colors.white.withValues(alpha: 0.85)
            ..strokeWidth = 0.6;
          for (double rx = shaftXStart - radius * 2.0; rx > jointX + radius * 1.5; rx -= radius * 1.8) {
            canvas.drawLine(Offset(rx, -1.0), Offset(rx - radius * 0.5, 1.0), runePaint);
          }
        }
        break;

      case CueAnimeConcept.cyberNeo:
        // Tia laser năng lượng Cyan & Magenta chạy dọc ngọn cơ
        final beamPaint = Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: level >= 6 ? 0.95 : 0.75)
          ..strokeWidth = level >= 6 ? 1.2 : 0.8;
        canvas.drawLine(Offset(shaftXStart - 4, 0), Offset(jointX + 4, 0), beamPaint);

        // Lv >= 4: Các vi mạch bán dẫn và tụ điện Nano phát quang
        if (level >= 4) {
          final microPaint = Paint()..color = const Color(0xFFE040FB);
          for (double cx = shaftXStart - radius * 1.5; cx > jointX + radius * 1.5; cx -= radius * 2.2) {
            canvas.drawRect(Rect.fromCenter(center: Offset(cx, 0), width: 2.2, height: jointR * 0.7), microPaint);
            canvas.drawCircle(Offset(cx, 0), 1.0, Paint()..color = Colors.white);
          }
        }
        break;

      case CueAnimeConcept.dragonFlame:
        // Vệt lửa Hỏa Long rực cháy
        final flamePaint = Paint()
          ..color = const Color(0xFFFF6D00).withValues(alpha: level >= 6 ? 0.95 : 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = level >= 6 ? 1.4 : 0.9;
        canvas.drawLine(Offset(shaftXStart - 4, 0), Offset(jointX + 4, 0), flamePaint);

        // Lv >= 4: Vảy rồng mạ vàng khắc nổi dọc thân
        if (level >= 4) {
          final scalePaint = Paint()
            ..color = const Color(0xFFFFD54F).withValues(alpha: 0.80)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.9;
          for (double dx = shaftXStart - radius * 1.2; dx > jointX + radius * 1.2; dx -= radius * 1.4) {
            final p = Path()
              ..moveTo(dx, -jointR * 0.4)
              ..lineTo(dx - radius * 0.35, 0)
              ..lineTo(dx, jointR * 0.4);
            canvas.drawPath(p, scalePaint);
          }
        }
        break;

      case CueAnimeConcept.arcaneMagic:
        // Vòng khuyên Mana xoay quanh thân ngọn
        final manaPaint = Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: level >= 6 ? 0.90 : 0.70)
          ..strokeWidth = level >= 6 ? 1.3 : 0.9;
        for (double mx = shaftXStart - radius * 1.0; mx > jointX + radius * 0.8; mx -= radius * 1.4) {
          canvas.drawLine(Offset(mx, -jointR * 0.6), Offset(mx - radius * 0.4, jointR * 0.6), manaPaint);
          if (level >= 6) {
            canvas.drawCircle(Offset(mx - radius * 0.2, 0), 1.2, Paint()..color = const Color(0xFFB388FF));
          }
        }
        break;

      case CueAnimeConcept.mechaGundam:
        // Rãnh ghép giáp Titanium Mecha và sọc phản quang
        final mechaLine = Paint()
          ..color = const Color(0xFF76FF03).withValues(alpha: level >= 6 ? 0.90 : 0.70)
          ..strokeWidth = 1.0;
        canvas.drawLine(Offset(shaftXStart - 4, 0), Offset(jointX + 4, 0), mechaLine);
        if (level >= 5) {
          for (double gx = shaftXStart - radius * 1.8; gx > jointX + radius * 1.2; gx -= radius * 2.0) {
            canvas.drawLine(Offset(gx, -jointR * 0.5), Offset(gx, jointR * 0.5), mechaLine);
          }
        }
        break;

      case CueAnimeConcept.sakuraZen:
        // Cánh hoa anh đào dát vàng bay trên thân ngọn
        final sakuraPaint = Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.80);
        for (double sx = shaftXStart - radius * 1.5; sx > jointX + radius * 1.2; sx -= radius * 2.0) {
          canvas.drawOval(
            Rect.fromCenter(center: Offset(sx, (sx.toInt() % 2 == 0 ? 1 : -1) * jointR * 0.3), width: 3.5, height: 1.8),
            sakuraPaint,
          );
        }
        break;

      case CueAnimeConcept.shadowVoid:
        final shadowLine = Paint()
          ..color = const Color(0xFFBA68C8).withValues(alpha: 0.85)
          ..strokeWidth = 1.0;
        canvas.drawLine(Offset(shaftXStart - 4, 0), Offset(jointX + 4, 0), shadowLine);
        break;

      case CueAnimeConcept.frostCryo:
        final iceLine = Paint()
          ..color = const Color(0xFF80D8FF).withValues(alpha: 0.90)
          ..strokeWidth = 1.0;
        canvas.drawLine(Offset(shaftXStart - 4, 0), Offset(jointX + 4, 0), iceLine);
        break;

      case CueAnimeConcept.classic:
        break;
    }

    // 4. Khớp ren kim loại trang trí hoặc Vành Tsuba hộ kiếm (Joint Rings / Tsuba)
    final jointLen = radius * 0.55;
    if (cue.animeConcept == CueAnimeConcept.katanaSamurai) {
      // Vành Tsuba hộ kiếm Nhật Bản dát vàng chạm khắc
      final tsubaH = jointR * (level >= 7 ? 4.8 : 4.4);
      final tsubaPath = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(jointX - radius * 0.42, -tsubaH * 0.5, radius * 0.42, tsubaH),
            Radius.circular(radius * 0.6),
          ),
        );
      canvas.drawPath(tsubaPath, Paint()..color = const Color(0xFFFFD54F));
      canvas.drawPath(
        tsubaPath,
        Paint()
          ..color = Colors.black87
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
      // Lv >= 6: Khắc rãnh hoa văn Tsuba
      if (level >= 6) {
        canvas.drawCircle(Offset(jointX - radius * 0.21, -tsubaH * 0.28), 1.2, Paint()..color = const Color(0xFFB8860B));
        canvas.drawCircle(Offset(jointX - radius * 0.21, tsubaH * 0.28), 1.2, Paint()..color = const Color(0xFFB8860B));
      }
    } else {
      // Vòng ren kim loại đa tầng có vân chỉ khắc sắc sảo
      drawSegment(
        xStart: jointX,
        xEnd: jointX - jointLen,
        rStart: jointR,
        rEnd: jointR + 0.05,
        colors: level >= 5
            ? const [Color(0xFFFFD54F), Color(0xFFFFF9C4), Color(0xFFB8860B)]
            : const [Color(0xFFB8860B), Color(0xFFFFD700), Color(0xFF5A440D)],
      );
      if (level >= 6) {
        // Viền khảm ngọc quý ở khớp nối
        canvas.drawCircle(Offset(jointX - jointLen * 0.5, 0), jointR * 0.35, Paint()..color = cue.auraColor);
      }
    }

    // 5. Chuôi gậy (Handle / Butt) - hoa văn tay cầm của skin
    final buttCapX = -stickLength + radius * 0.50;
    drawSegment(
      xStart: jointX - jointLen,
      xEnd: buttCapX,
      rStart: jointR + 0.05,
      rEnd: buttR,
      colors: cue.handleColors,
    );

    // Họa tiết Concept Anime trên chuôi tay cầm - PHÂN CẤP THEO LEVEL
    final handleXStart = jointX - jointLen;
    switch (cue.animeConcept) {
      case CueAnimeConcept.katanaSamurai:
        // Đan dây quấn Tsuka hình quả trám (Diamond laces)
        final tsukaLace = Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: level >= 6 ? 0.90 : 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = level >= 6 ? 1.4 : 1.1;
        for (double tx = handleXStart - radius * 0.6; tx > buttCapX + radius * 0.6; tx -= radius * 1.2) {
          final diamond = Path()
            ..moveTo(tx, 0)
            ..lineTo(tx - radius * 0.3, -buttR * 0.6)
            ..lineTo(tx - radius * 0.6, 0)
            ..lineTo(tx - radius * 0.3, buttR * 0.6)
            ..close();
          canvas.drawPath(diamond, tsukaLace);

          // Lv >= 5: Hạt ngọc Menuki dát vàng cài giữa tâm đan dây
          if (level >= 5) {
            canvas.drawCircle(Offset(tx - radius * 0.3, 0), 1.0, Paint()..color = const Color(0xFFFF1744));
          }
        }
        break;

      case CueAnimeConcept.cyberNeo:
        final circuitP = Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.85)
          ..strokeWidth = 1.2;
        canvas.drawLine(Offset(handleXStart - radius * 0.5, -buttR * 0.3), Offset(buttCapX + radius * 0.5, -buttR * 0.3), circuitP);
        canvas.drawLine(Offset(handleXStart - radius * 0.5, buttR * 0.3), Offset(buttCapX + radius * 0.5, buttR * 0.3), circuitP..color = const Color(0xFFE040FB));
        break;

      case CueAnimeConcept.mechaGundam:
        // Sọc cảnh báo nguy hiểm EVA Cam/Đen
        final hazardPaint = Paint()
          ..color = const Color(0xFFFF6D00).withValues(alpha: 0.85)
          ..strokeWidth = 2.2;
        for (double hx = handleXStart - radius * 0.6; hx > buttCapX + radius * 0.6; hx -= radius * 1.5) {
          canvas.drawLine(Offset(hx, -buttR * 0.65), Offset(hx - radius * 0.5, buttR * 0.65), hazardPaint);
        }
        break;

      case CueAnimeConcept.dragonFlame:
        final scalePaint = Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        for (double sx = handleXStart - radius * 0.6; sx > buttCapX + radius * 0.6; sx -= radius * 1.1) {
          canvas.drawLine(Offset(sx, -buttR * 0.5), Offset(sx + radius * 0.3, 0), scalePaint);
          canvas.drawLine(Offset(sx + radius * 0.3, 0), Offset(sx, buttR * 0.5), scalePaint);
        }
        break;

      case CueAnimeConcept.arcaneMagic:
      case CueAnimeConcept.shadowVoid:
      case CueAnimeConcept.sakuraZen:
      case CueAnimeConcept.frostCryo:
      case CueAnimeConcept.classic:
        break;
    }

    // 6. Đệm cao su chống va đập & VIÊN NGỌC KHẢM ĐUÔI GẬY (Butt Bumper & Gemstone)
    final bumperPath = Path()
      ..moveTo(buttCapX, -buttR)
      ..arcToPoint(
        Offset(-stickLength, 0),
        radius: Radius.circular(buttR),
        clockwise: false,
      )
      ..arcToPoint(
        Offset(buttCapX, buttR),
        radius: Radius.circular(buttR),
        clockwise: false,
      )
      ..close();
    canvas.drawPath(bumperPath, Paint()..color = const Color(0xFF141414));

    // Lv >= 5: Viên ngọc linh hồn khảm đáy chuôi cơ (Butt Gemstone Bezel)
    if (level >= 5) {
      final gemColor = switch (cue.animeConcept) {
        CueAnimeConcept.katanaSamurai => const Color(0xFFFF1744), // Hồng ngọc Ruby
        CueAnimeConcept.cyberNeo => const Color(0xFF00E5FF),      // Pha lê Cyan
        CueAnimeConcept.dragonFlame => const Color(0xFFFF6D00),   // Hỏa ngọc
        CueAnimeConcept.arcaneMagic => const Color(0xFFB388FF),   // Thạch anh tím
        CueAnimeConcept.shadowVoid => const Color(0xFF6A1B9A),    // Ngọc hắc ám
        CueAnimeConcept.mechaGundam => const Color(0xFF76FF03),   // Hạt nhân xanh
        CueAnimeConcept.sakuraZen => const Color(0xFFFF80AB),     // Thạch anh hồng
        CueAnimeConcept.frostCryo => const Color(0xFF80D8FF),     // Lam ngọc
        CueAnimeConcept.classic => const Color(0xFFFFD54F),
      };

      // Đĩa kim loại đỡ ngọc
      canvas.drawCircle(Offset(buttCapX + radius * 0.15, 0), buttR * 0.6, Paint()..color = const Color(0xFFFFD54F));
      // Viên đá quý phát quang
      canvas.drawCircle(Offset(buttCapX + radius * 0.15, 0), buttR * 0.42, Paint()..color = gemColor);
      canvas.drawCircle(Offset(buttCapX + radius * 0.10, -buttR * 0.12), buttR * 0.15, Paint()..color = Colors.white.withValues(alpha: 0.90));
    }

    canvas.restore();
  }
}

class PoolBall extends BodyComponent {
  Vector2 initialPosition;
  double radius;
  double hitboxRadius;
  final String imageName;
  final int number;
  Sprite? ballSprite;
  bool isSunk = false;
  bool pocketedThisShot = false;

  Vector2? _sunkStartPos;
  Vector2? _sunkCurrentPos;
  Vector2? _sunkTargetPocket;
  Vector2? _sunkVelocity;
  double _sunkProgress = 0.0;
  bool _sunkAnimComplete = false;
  bool get isSunkAnimComplete => !isSunk || _sunkAnimComplete;

  void sinkIntoPocket(Vector2 pocketPos) {
    if (isSunk) return;
    isSunk = true;
    try {
      gameInstance.vfx.clearBallTrail(number);
    } catch (_) {}
    _sunkStartPos = body.position.clone();
    _sunkCurrentPos = body.position.clone();
    _sunkTargetPocket = pocketPos.clone();
    _sunkVelocity = body.linearVelocity.clone();
    _sunkProgress = 0.0;
    _sunkAnimComplete = false;

    body.linearVelocity.setZero();
    body.angularVelocity = 0;
    body.setTransform(Vector2(-1000, -1000), 0);
  }

  void resetSunkState() {
    isSunk = false;
    _sunkStartPos = null;
    _sunkCurrentPos = null;
    _sunkTargetPocket = null;
    _sunkVelocity = null;
    _sunkProgress = 0.0;
    _sunkAnimComplete = false;
  }

  void completeSunkAnim() {
    _sunkProgress = 1.0;
    _sunkAnimComplete = true;
  }

  void instantSunk() {
    isSunk = true;
    _sunkAnimComplete = true;
    _sunkProgress = 1.0;
    _sunkStartPos = null;
    _sunkCurrentPos = null;
    _sunkTargetPocket = null;
    _sunkVelocity = null;
    try {
      gameInstance.vfx.clearBallTrail(number);
    } catch (_) {}
  }

  // Quản lý góc lăn và xoay 3D thực tế của quả bi
  late final Ball3DOrientation orientation;

  PoolBall(
    this.initialPosition,
    this.imageName,
    this.radius,
    this.number, {
    double? hitboxRadius,
  }) : hitboxRadius = hitboxRadius ?? (radius * 0.88) {
    priority = 2;
    orientation = Ball3DOrientation(initialAngle: number * 1.35);
  }

  void updateRadius(double newRadius) {
    radius = newRadius;
    hitboxRadius = newRadius * 0.88;
    try {
      for (final f in body.fixtures) {
        if (f.shape is CircleShape) {
          f.shape.radius = hitboxRadius;
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    ballSprite = await Sprite.load(imageName);
  }

  @override
  Body createBody() {
    final shape = CircleShape()..radius = hitboxRadius;
    final fixtureDef = FixtureDef(
      shape,
      restitution: 0.90,
      density: 0.8,
      friction: 0.16,
    );
    final createdBody = world.createBody(
      BodyDef(
        type: BodyType.dynamic,
        position: initialPosition,
        bullet: true,
        fixedRotation: false,
        linearDamping: 0.0,
        angularDamping: 1.6,
      ),
    )..createFixture(fixtureDef);
    createdBody.userData = this;
    return createdBody;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isMounted) return;
    try {
      final _ = body;
    } catch (_) {
      return;
    }
    if (isSunk) {
      if (_sunkStartPos == null) {
        _sunkStartPos = body.position.clone();
        _sunkCurrentPos = body.position.clone();
        _sunkVelocity = body.linearVelocity.clone();
        body.linearVelocity.setZero();
        body.angularVelocity = 0;
        if (body.position.x > -500) {
          body.setTransform(Vector2(-1000, -1000), 0);
        }
        Pocket? nearest;
        double minD = double.infinity;
        for (final p in gameInstance.pockets) {
          final d = (p.position - _sunkStartPos!).length;
          if (d < minD) {
            minD = d;
            nearest = p;
          }
        }
        _sunkTargetPocket = nearest?.position.clone() ?? _sunkStartPos!.clone();
      }

      if (!_sunkAnimComplete) {
        // Tốc độ lăn chìm vào lỗ tự nhiên (~0.74 giây)
        _sunkProgress += dt * 1.35;
        if (_sunkProgress >= 1.0) {
          _sunkProgress = 1.0;
          _sunkAnimComplete = true;
        }

        final t = _sunkProgress.clamp(0.0, 1.0);
        final start = _sunkStartPos!;
        final target = _sunkTargetPocket!;
        final toTarget = target - start;
        final dist = toTarget.length;

        final inVel = _sunkVelocity ?? Vector2.zero();
        final inSpeed = inVel.length;
        final inDir = inSpeed > 0.5
            ? inVel.normalized()
            : (dist > 0.001 ? toTarget.normalized() : Vector2(0, 1));

        final p0 = start;
        final p3 = target;
        final p1 = p0 + inDir * (dist * 0.45);
        final toPocketNorm = dist > 0.001 ? toTarget.normalized() : inDir;
        final p2 = p3 - toPocketNorm * (dist * 0.25);

        final u = math.pow(t, 1.25).toDouble();
        final oneMinusU = 1.0 - u;
        final nextX = oneMinusU * oneMinusU * oneMinusU * p0.x +
            3.0 * oneMinusU * oneMinusU * u * p1.x +
            3.0 * oneMinusU * u * u * p2.x +
            u * u * u * p3.x;
        final nextY = oneMinusU * oneMinusU * oneMinusU * p0.y +
            3.0 * oneMinusU * oneMinusU * u * p1.y +
            3.0 * oneMinusU * u * u * p2.y +
            u * u * u * p3.y;

        if (nextX.isNaN || nextY.isNaN || nextX.isInfinite || nextY.isInfinite) {
          _sunkProgress = 1.0;
          _sunkAnimComplete = true;
          return;
        }

        if (_sunkCurrentPos != null) {
          final dx = nextX - _sunkCurrentPos!.x;
          final dy = nextY - _sunkCurrentPos!.y;
          final stepDist = math.sqrt(dx * dx + dy * dy);
          if (stepDist > 0.0001 && !stepDist.isNaN && !stepDist.isInfinite) {
            final rollMultiplier = 1.8 + 1.2 * t;
            orientation.roll(dx * rollMultiplier, dy * rollMultiplier, radius);

            final crossZ = inDir.x * toTarget.y - inDir.y * toTarget.x;
            final swirlDir = crossZ >= 0 ? 1.0 : -1.0;
            final spinZRate = swirlDir * math.sin(t * math.pi) * 4.5 * dt;
            if (!spinZRate.isNaN && !spinZRate.isInfinite) {
              orientation.spinZ(spinZRate);
            }
          }
        }
        _sunkCurrentPos = Vector2(nextX, nextY);
      }
      return;
    } else {
      _sunkStartPos = null;
      _sunkCurrentPos = null;
      _sunkTargetPocket = null;
      _sunkVelocity = null;
      _sunkProgress = 0.0;
      _sunkAnimComplete = false;
    }

    // Cập nhật góc lăn 3D theo vận tốc di chuyển thực tế trên mặt bàn
    final vel = body.linearVelocity;
    if (vel.x.isNaN || vel.y.isNaN || vel.x.isInfinite || vel.y.isInfinite) {
      vel.setZero();
      body.angularVelocity = 0;
      return;
    }
    if (body.position.x.isNaN || body.position.y.isNaN || body.position.x.isInfinite || body.position.y.isInfinite) {
      body.setTransform(Vector2(gameInstance.size.x * 0.7, gameInstance.size.y * 0.5), 0);
      vel.setZero();
      body.angularVelocity = 0;
      return;
    }
    final speed = vel.length;
    if (speed > 0.5) {
      orientation.roll(vel.x * dt, vel.y * dt, radius);
    }
    if (body.angularVelocity.abs() > 0.01 && !body.angularVelocity.isNaN) {
      orientation.spinZ(body.angularVelocity * dt * 0.25);
    }
  }

  @override
  void render(Canvas canvas) {
    if (isRemoved || isRemoving) {
      return;
    }
    if (isSunk) {
      if (_sunkAnimComplete || _sunkCurrentPos == null) {
        return;
      }
      if (_sunkCurrentPos!.x.isNaN ||
          _sunkCurrentPos!.y.isNaN ||
          body.position.x.isNaN ||
          body.position.y.isNaN) {
        return;
      }
      canvas.save();
      // Bù lại tọa độ thế giới khi body đã chuyển sang (-1000, -1000)
      canvas.translate(-body.position.x + _sunkCurrentPos!.x, -body.position.y + _sunkCurrentPos!.y);

      final t = _sunkProgress.clamp(0.0, 1.0);
      final dropT = t <= 0.30 ? 0.0 : ((t - 0.30) / 0.70).clamp(0.0, 1.0);
      final scale = (1.0 - math.pow(dropT, 1.25) * 0.74).clamp(0.26, 1.0);

      final cupDepthY = math.pow(dropT, 1.3) * (radius * 0.28);
      canvas.translate(0, cupDepthY);

      // TUYỆT ĐỐI KHÔNG BIẾN MẤT DẦN (Opacity luôn 1.0). Quả bi đặc hoàn toàn, chìm sâu vào lòng tối của lỗ
      Ball3DRenderer.renderBall(
        canvas: canvas,
        radius: radius,
        orientation: orientation,
        ballNumber: number,
        scale: scale,
        opacity: 1.0,
        pocketDropProgress: t,
      );
      canvas.restore();
      return;
    }

    // Dựng hình Quả bi 2.5D lăn 3D chân thực
    canvas.save();
    if (!body.angle.isNaN && !body.angle.isInfinite) {
      canvas.rotate(-body.angle);
    }

    Ball3DRenderer.renderBall(
      canvas: canvas,
      radius: radius,
      orientation: orientation,
      ballNumber: number,
      scale: 1.0,
      opacity: 1.0,
    );

    canvas.restore();
  }
}

@visibleForTesting
Widget buildControlBarForTesting(
  BuildContext context, {
  bool compact = false,
  bool ultraCompact = false,
  double upscaleFactor = 1.0,
  required VoidCallback onHome,
}) => _buildControlBar(context, compact: compact, ultraCompact: ultraCompact, upscaleFactor: upscaleFactor, onHome: onHome);

@visibleForTesting
Widget buildPlayerCardForTesting(
  String name,
  Color color,
  bool isTurn,
  int score,
  String groupLabel,
  List<int> groupBalls,
  bool alignRight, {
  int level = 1,
  int coins = 1200,
  CueModel? cue,
  int cueLevel = 1,
  bool compact = false,
  bool ultraCompact = false,
  double upscaleFactor = 1.0,
  VoidCallback? onTapCue,
}) => _buildPlayerCard(name, color, isTurn, score, groupLabel, groupBalls, alignRight,
    level: level, coins: coins, cue: cue, cueLevel: cueLevel, compact: compact,
    ultraCompact: ultraCompact, upscaleFactor: upscaleFactor, onTapCue: onTapCue);
