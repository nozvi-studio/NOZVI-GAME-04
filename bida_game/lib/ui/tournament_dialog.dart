import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/tournament_model.dart';
// import '../services/online_multiplayer_service.dart';
import '../services/language_service.dart';
import '../services/progression_service.dart';

class TournamentDialog extends StatefulWidget {
  final void Function(TournamentBracketStage stage) onStartBracketMatch;
  // final void Function(TournamentBracketStage stage, String roomId, bool isHost)? onStartBracketOnlineMatch;

  const TournamentDialog({
    super.key,
    required this.onStartBracketMatch,
    // this.onStartBracketOnlineMatch,
  });

  @override
  State<TournamentDialog> createState() => _TournamentDialogState();
}

class _TournamentDialogState extends State<TournamentDialog> {
  // TournamentBracketStage? _selectedStage;

  @override
  void initState() {
    super.initState();
    // // Chế độ Online đã được ẩn bằng // để ưu tiên offline thuần túy
    // final service = OnlineMultiplayerService.instance;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 750;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 28,
        vertical: isMobile ? 8 : 18,
      ),
      child: ListenableBuilder(
        listenable: Listenable.merge([
          ProgressionService.instance,
          LanguageService.instance,
        ]),
        builder: (context, _) {
          return Container(
            width: math.min(screenSize.width * 0.95, 880.0),
            height: screenSize.height * 0.92,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1D17),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFFFD54F), width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.85),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header Giải Đấu Offline Vô Địch 5 Brackets
                _buildHeader(context),

                // Grand Champion Reward Banner
                _buildChampionBanner(),

                // 5 Brackets Ladder
                Expanded(
                  child: _buildBracketLadder(context, isMobile),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    // final serverUrl = service.lastConnectedUrl ?? OnlineMultiplayerService.realPhoneDefaultUrl;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B3D30), Color(0xFF10261E)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(bottom: BorderSide(color: Color(0xFFFFD54F), width: 1.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
              ),
            ),
            child: const Icon(Icons.emoji_events, color: Colors.black87, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'tournament_title'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'tournament_subtitle'.tr,
                  style: const TextStyle(
                    color: Color(0xFFFFD54F),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Row(
                //   children: [
                //     Container(
                //       width: 7,
                //       height: 7,
                //       decoration: BoxDecoration(
                //         shape: BoxShape.circle,
                //         color: service.isConnected ? const Color(0xFF00E676) : Colors.orangeAccent,
                //       ),
                //     ),
                //     const SizedBox(width: 5),
                //     Expanded(
                //       child: Text(
                //         service.isConnected
                //             ? 'Cổng ĐT thật kết nối sẵn: $serverUrl'
                //             : 'Đang kết nối cổng điện thoại thật ($serverUrl)...',
                //         style: TextStyle(
                //           color: service.isConnected ? const Color(0xFF00E676) : Colors.orangeAccent,
                //           fontSize: 10,
                //           fontWeight: FontWeight.bold,
                //         ),
                //         overflow: TextOverflow.ellipsis,
                //       ),
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
          ListenableBuilder(
            listenable: ProgressionService.instance,
            builder: (context, _) {
              if (ProgressionService.instance.currentTournamentBracket <= 1) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed: () {
                    ProgressionService.instance.resetTournament();
                    final langCode = LanguageService.instance.currentCode;
                    final snackText = switch (langCode) {
                      'zh' => '🔄 锦标赛已重置为第1轮!',
                      'ja' => '🔄 トーナメントを第1ラウンドにリセットしました!',
                      'ko' => '🔄 토너먼트를 1라운드로 초기화했습니다!',
                      'en' => '🔄 Tournament reset to Round 1!',
                      _ => '🔄 Đã làm mới giải đấu về Vòng 1!',
                    };
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(snackText),
                        backgroundColor: const Color(0xFFC77700),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.restart_alt, size: 14, color: Color(0xFFFFD54F)),
                  label: Text(
                    'reset'.tr,
                    style: const TextStyle(
                      color: Color(0xFFFFD54F),
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white10,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              );
            },
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white70, size: 20),
            tooltip: 'close'.tr,
          ),
        ],
      ),
    );
  }

  Widget _buildChampionBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5D4037), Color(0xFF2E1C14)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium, color: Color(0xFFFFD54F), size: 26),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'champion_reward_banner'.tr,
                  style: const TextStyle(
                    color: Color(0xFFFFD54F),
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'champion_reward_desc'.tr,
                  style: const TextStyle(color: Colors.white, fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBracketLadder(BuildContext context, bool isMobile) {
    final currentBracket = ProgressionService.instance.currentTournamentBracket;
    final brackets = TournamentCatalog.brackets;

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: brackets.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final stage = brackets[index];
        final isPassed = stage.bracketNumber < currentBracket;
        final isCurrent = stage.bracketNumber == currentBracket;
        final isLocked = stage.bracketNumber > currentBracket;
        final isFinal = stage.bracketNumber == 5;

        return Container(
          decoration: BoxDecoration(
            color: isCurrent
                ? const Color(0xFF1B4332)
                : (isPassed ? const Color(0xFF132B22) : Colors.black38),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrent
                  ? const Color(0xFFFFD54F)
                  : (isPassed ? const Color(0xFF00E676) : Colors.white12),
              width: isCurrent ? 2.0 : 1.0,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // Bracket Badge Number
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: isPassed
                        ? const LinearGradient(colors: [Color(0xFF00E676), Color(0xFF00B0FF)])
                        : (isCurrent
                            ? const LinearGradient(colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)])
                            : null),
                    color: isLocked ? Colors.white12 : null,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isPassed
                        ? const Icon(Icons.check, color: Colors.black, size: 24)
                        : (isLocked
                            ? const Icon(Icons.lock, color: Colors.white38, size: 20)
                            : (isFinal
                                ? const Icon(Icons.emoji_events, color: Colors.black87, size: 24)
                                : Text(
                                    '${stage.bracketNumber}',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                    ),
                                  ))),
                  ),
                ),
                const SizedBox(width: 12),

                // Info: Title, Round Name, Opponent, Rewards
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isFinal
                                  ? Colors.amber.withValues(alpha: 0.25)
                                  : const Color(0xFF26A69A).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'BRACKET ${stage.bracketNumber} • ${LanguageService.instance.localizeStageTitle(stage.roundName)}',
                              style: TextStyle(
                                color: isFinal ? const Color(0xFFFFD54F) : Colors.tealAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (isFinal) ...[
                            Text(
                              'championship_match'.tr,
                              style: const TextStyle(
                                color: Color(0xFFFFD54F),
                                fontWeight: FontWeight.w900,
                                fontSize: 9.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        LanguageService.instance.localizeStageTitle(stage.title),
                        style: TextStyle(
                          color: isLocked ? Colors.white54 : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.sports_esports, color: Colors.white60, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            '${'opponent'.tr}: ${LanguageService.instance.localizeOpponentName(stage.opponentName)} (Lv.${stage.opponentLevel}) • ${stage.opponentCue.localizedName}',
                            style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      // Rewards Row
                      Wrap(
                        spacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.monetization_on, color: Color(0xFFFFD54F), size: 12),
                              const SizedBox(width: 3),
                              Text(
                                '+${stage.coinReward} ${'coins'.tr}',
                                style: const TextStyle(
                                  color: Color(0xFFFFD54F),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.tealAccent, size: 12),
                              const SizedBox(width: 3),
                              Text(
                                '+${stage.xpReward} EXP',
                                style: const TextStyle(
                                  color: Colors.tealAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          if (stage.bonusMedalId != null) ...[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.workspace_premium, color: Color(0xFFFF4081), size: 12),
                                const SizedBox(width: 3),
                                Text(
                                  isFinal ? '🏆 ${'trophy_cup'.tr}' : '🎖️ ${'medals'.tr}',
                                  style: const TextStyle(
                                    color: Color(0xFFFF4081),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Action Buttons for Current Bracket
                if (isCurrent) ...[
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nút Vào trận Offline (Đấu Bot)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onStartBracketMatch(stage);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB300),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 3,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isFinal ? Icons.emoji_events : Icons.smart_toy, size: 13),
                            const SizedBox(width: 3),
                            Text(
                              isFinal ? 'compete_cup'.tr : 'play_bot'.tr,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else if (isPassed) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF00E676)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, color: Color(0xFF00E676), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'won'.tr,
                              style: const TextStyle(
                                color: Color(0xFF00E676),
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onStartBracketMatch(stage);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white12,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 1,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.replay, size: 12),
                            const SizedBox(width: 3),
                            Text(
                              'replay'.tr,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'locked'.tr,
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget _buildMatchmakingView(OnlineMultiplayerService service) {
  //   final bracket = service.tournamentBracket;
  //   final serverUrl = service.lastConnectedUrl ?? OnlineMultiplayerService.realPhoneDefaultUrl;
  //
  //   return Center(
  //     child: Container(
  //       padding: const EdgeInsets.all(24),
  //       margin: const EdgeInsets.all(24),
  //       decoration: BoxDecoration(
  //         color: Colors.black54,
  //         borderRadius: BorderRadius.circular(20),
  //         border: Border.all(color: const Color(0xFFFFD54F), width: 1.6),
  //       ),
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           const SizedBox(
  //             width: 46,
  //             height: 46,
  //             child: CircularProgressIndicator(color: Color(0xFFFFD54F), strokeWidth: 3.5),
  //           ),
  //           const SizedBox(height: 16),
  //           Text(
  //             'ĐANG TÌM ĐỐI THỦ ONLINE CHO BRACKET $bracket...',
  //             style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
  //             textAlign: TextAlign.center,
  //           ),
  //           const SizedBox(height: 6),
  //           Text(
  //             'Cổng kết nối điện thoại thật: $serverUrl\nSẵn sàng thi đấu và giành quà Bracket $bracket!',
  //             style: const TextStyle(color: Colors.white70, fontSize: 11),
  //             textAlign: TextAlign.center,
  //           ),
  //           const SizedBox(height: 20),
  //           ElevatedButton(
  //             onPressed: () {
  //               service.cancelQuickMatch();
  //             },
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: const Color(0xFFC62828),
  //               foregroundColor: Colors.white,
  //               padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
  //               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  //             ),
  //             child: const Text('HỦY TÌM TRẬN', style: TextStyle(fontWeight: FontWeight.bold)),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  //
  // Widget _buildWaitingInRoomView(OnlineMultiplayerService service) {
  //   final roomId = service.currentRoomId ?? '------';
  //   final bracket = service.tournamentBracket;
  //
  //   return Center(
  //     child: Container(
  //       padding: const EdgeInsets.all(24),
  //       margin: const EdgeInsets.all(24),
  //       decoration: BoxDecoration(
  //         color: const Color(0xFF261810),
  //         borderRadius: BorderRadius.circular(20),
  //         border: Border.all(color: const Color(0xFFFFD54F), width: 1.8),
  //       ),
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           const Icon(Icons.emoji_events, color: Color(0xFFFFD54F), size: 36),
  //           const SizedBox(height: 8),
  //           Text(
  //             'PHÒNG TOURNAMENT BRACKET $bracket SẴN SÀNG!',
  //             style: const TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.w900, fontSize: 16),
  //           ),
  //           const SizedBox(height: 6),
  //           const Text(
  //             'Chia sẻ mã PIN dưới đây cho đối thủ để cùng vào thi đấu:',
  //             style: TextStyle(color: Colors.white70, fontSize: 11),
  //           ),
  //           const SizedBox(height: 14),
  //           Container(
  //             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
  //             decoration: BoxDecoration(
  //               color: Colors.black54,
  //               borderRadius: BorderRadius.circular(14),
  //               border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
  //             ),
  //             child: Text(
  //               roomId,
  //               style: const TextStyle(
  //                 color: Color(0xFFFFD54F),
  //                 fontWeight: FontWeight.w900,
  //                 fontSize: 28,
  //                 letterSpacing: 4.0,
  //               ),
  //             ),
  //           ),
  //           const SizedBox(height: 16),
  //           const Row(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               SizedBox(
  //                 width: 14,
  //                 height: 14,
  //                 child: CircularProgressIndicator(color: Colors.amber, strokeWidth: 2),
  //               ),
  //               SizedBox(width: 8),
  //               Text(
  //                 'Đang chờ đối thủ nhập mã...',
  //                 style: TextStyle(color: Colors.amber, fontSize: 11),
  //               ),
  //             ],
  //           ),
  //           const SizedBox(height: 16),
  //           TextButton(
  //             onPressed: () {
  //               service.disconnect();
  //             },
  //             child: const Text('Hủy & Rời Phòng', style: TextStyle(color: Colors.redAccent)),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}
