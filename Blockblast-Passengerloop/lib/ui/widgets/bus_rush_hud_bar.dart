import 'package:flutter/material.dart';
import '../../logic/bus_rush_race_service.dart';
import '../../core/pentatonic_audio_synth.dart';

/// Thanh tiến độ thu gọn của "Cuộc Đua Giờ Cao Điểm" (Bus Rush Race)
class BusRushHudBar extends StatelessWidget {
  const BusRushHudBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BusRushRaceService.instance,
      builder: (context, _) {
        final race = BusRushRaceService.instance;
        final rank = race.getPlayerRank();
        final playerBuses = race.playerBuses;
        final target = race.targetBuses;
        final progress = (playerBuses / target).clamp(0.0, 1.0);

        Color rankColor;
        switch (rank) {
          case 1:
            rankColor = const Color(0xFFFFD54F); // Vàng
            break;
          case 2:
            rankColor = const Color(0xFFCFD8DC); // Bạc
            break;
          case 3:
            rankColor = const Color(0xFFFFB74D); // Đồng
            break;
          default:
            rankColor = Colors.white70;
        }

        return InkWell(
          onTap: () => _showRaceLeaderboard(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF263238), Color(0xFF1E282D)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: rankColor.withValues(alpha: 0.6), width: 1.2),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                // 1. Huy hiệu Hạng của người chơi
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: rankColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: rankColor, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(rank == 1 ? '🥇' : (rank == 2 ? '🥈' : '🥉'), style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        'Hạng $rank/5',
                        style: TextStyle(
                          color: rankColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // 2. Thanh tiến độ chạy đua đến 15 xe
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              '🏁 ĐUA GIỜ CAO ĐIỂM',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$playerBuses/$target Xe',
                            style: const TextStyle(
                              color: Color(0xFFFFD54F),
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 7,
                          backgroundColor: Colors.black45,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // 3. Biểu tượng Rương Cổ Vật ở đích
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: race.isPlayerWinner && !race.isChestClaimed
                        ? Colors.amber.withValues(alpha: 0.3)
                        : Colors.transparent,
                  ),
                  child: const Text('🎁', style: TextStyle(fontSize: 20)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRaceLeaderboard(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return ListenableBuilder(
          listenable: BusRushRaceService.instance,
          builder: (context, _) {
            final race = BusRushRaceService.instance;
            final racers = race.sortedRacers;

            return Dialog(
              backgroundColor: const Color(0xFF1E252B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tiêu đề
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('🏁', style: TextStyle(fontSize: 22)),
                        SizedBox(width: 8),
                        Text(
                          'BẢNG XẾP HẠNG ĐUA XE BUÝT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ai xuất bến đủ 15 xe buýt trước sẽ giành Rương Cổ Vật!',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Danh sách 5 tay đua
                    ...List.generate(racers.length, (index) {
                      final r = racers[index];
                      final progress = (r.busesDispatched / race.targetBuses).clamp(0.0, 1.0);
                      final isTop1 = index == 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: r.isPlayer
                              ? const Color(0xFF1B3B38)
                              : (isTop1 ? const Color(0xFF2A281E) : Colors.black26),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: r.isPlayer
                                ? const Color(0xFF00E676)
                                : (isTop1 ? Colors.amber : Colors.white12),
                            width: r.isPlayer ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '#${index + 1}',
                              style: TextStyle(
                                color: isTop1 ? Colors.amber : Colors.white54,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(r.emoji, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.name,
                                    style: TextStyle(
                                      color: r.isPlayer ? const Color(0xFF00E676) : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 5,
                                      backgroundColor: Colors.black38,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        r.isPlayer ? const Color(0xFF00E676) : Colors.amberAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${r.busesDispatched}/${race.targetBuses}',
                              style: const TextStyle(
                                color: Color(0xFFFFD54F),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),

                    // Phần thưởng hoặc Nút nhận thưởng
                    if (race.isPlayerWinner && !race.isChestClaimed)
                      ElevatedButton.icon(
                        onPressed: () async {
                          await race.claimRewardChest();
                          PentatonicAudioSynth.instance.playFanfare();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🎉 Chúc mừng bạn về Nhất! Đã nhận Rương Cổ Vật (+500 Xu, +3 Búa, +3 La Bàn)!'),
                                backgroundColor: Color(0xFF2E7D32),
                              ),
                            );
                            Navigator.of(context).pop();
                          }
                        },
                        icon: const Icon(Icons.card_giftcard),
                        label: const Text('NHẬN RƯƠNG CỔ VẬT VỀ NHẤT'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB300),
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          textStyle: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      )
                    else if (race.isFinished)
                      TextButton(
                        onPressed: () async {
                          await race.resetNewSeason();
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        child: const Text('Bắt đầu mùa giải đua mới', style: TextStyle(color: Color(0xFF00E676))),
                      )
                    else
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Đóng', style: TextStyle(color: Colors.white60)),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

