import 'package:flutter/material.dart';
import '../../logic/bus_rush_race_service.dart';
import '../../logic/daily_quest_service.dart';
import '../../logic/player_economy_service.dart';
import '../../core/pentatonic_audio_synth.dart';

/// Tab 4 - Đua Top Giờ Cao Điểm (15 Chuyến Xe vs 4 AI) & 3 Nhiệm Vụ Hàng Ngày
class BusRushQuestsScreen extends StatelessWidget {
  const BusRushQuestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        BusRushRaceService.instance,
        DailyQuestService.instance,
      ]),
      builder: (context, _) {
        final race = BusRushRaceService.instance;
        final racers = race.sortedRacers;
        final isWinner = race.isPlayerWinner;
        final claimed = race.isChestClaimed;
        final quests = DailyQuestService.instance.quests;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Banner Cuộc Đua Giờ Cao Điểm
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFE86F17), Color(0xFFFF9D42)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: const Row(
                  children: [
                    Text('🏁', style: TextStyle(fontSize: 32)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ĐUA TOP GIỜ CAO ĐIỂM',
                            style: TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w900),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Đón đủ 15 chuyến xe trước 4 đối thủ AI để giành Rương Cổ Vật!',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Danh sách 5 tay đua
              for (int i = 0; i < racers.length; i++) ...[
                _buildRacerRow(racers[i], i + 1, race.targetBuses),
                const SizedBox(height: 7),
              ],

              const SizedBox(height: 8),
              if (isWinner && !claimed)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD84D),
                    foregroundColor: const Color(0xFF3B2314),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Text('🎁', style: TextStyle(fontSize: 20)),
                  label: const Text(
                    'NHẬN RƯƠNG GIỜ CAO ĐIỂM (+500 Xu, +25 Ngọc)',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                  onPressed: () async {
                    final ok = await race.claimRewardChest();
                    if (ok) {
                      await PlayerEconomyService.instance.addRewards(coinsDelta: 500, gemsDelta: 25);
                      PentatonicAudioSynth.instance.playFanfare();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🎉 Đã nhận +500 Xu & +25 Ngọc từ Rương Cổ Vật!'),
                            backgroundColor: Color(0xFF2D8512),
                          ),
                        );
                      }
                    }
                  },
                )
              else if (race.isFinished)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF4FC3F7)),
                    foregroundColor: const Color(0xFF4FC3F7),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('BẮT ĐẦU MÙA ĐUA MỚI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: () => race.resetNewSeason(),
                ),

              const SizedBox(height: 18),

              // 2. 3 Nhiệm Vụ Hàng Ngày (Daily Quests)
              const Text(
                '📋 3 NHIỆM VỤ HÀNG NGÀY (DAILY QUESTS)',
                style: TextStyle(
                  color: Color(0xFFFFD84D),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),

              for (final quest in quests) ...[
                _buildQuestCard(context, quest),
                const SizedBox(height: 9),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildRacerRow(RacerInfo racer, int rank, int target) {
    final double progress = (racer.busesDispatched / target).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: racer.isPlayer ? const Color(0xFF2D8512).withValues(alpha: 0.35) : const Color(0xFF263238),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: racer.isPlayer ? const Color(0xFF81E659) : (rank == 1 ? const Color(0xFFFFD84D) : Colors.white12),
          width: racer.isPlayer ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Text(
            '#$rank',
            style: TextStyle(
              color: rank == 1 ? const Color(0xFFFFD84D) : Colors.white54,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Text(racer.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  racer.name,
                  style: TextStyle(
                    color: racer.isPlayer ? const Color(0xFF81E659) : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.black38,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      racer.isPlayer ? const Color(0xFF81E659) : const Color(0xFFFF9D42),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${racer.busesDispatched}/$target',
            style: const TextStyle(color: Color(0xFFFFD84D), fontWeight: FontWeight.w900, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestCard(BuildContext context, DailyQuestItem quest) {
    final double ratio = (quest.progress / quest.target).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF263238),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: quest.isCompleted && !quest.isClaimed ? const Color(0xFFFFD84D) : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF3B2314),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(quest.emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 6,
                          backgroundColor: Colors.black38,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4FC3F7)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${quest.progress}/${quest.target}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Thưởng: 🪙 ${quest.rewardCoins}  •  💎 ${quest.rewardGems}',
                  style: const TextStyle(color: Color(0xFFFFD84D), fontSize: 10.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (quest.isClaimed)
            const Icon(Icons.check_circle_rounded, color: Color(0xFF81E659), size: 24)
          else if (quest.isCompleted)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD84D),
                foregroundColor: const Color(0xFF3B2314),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              onPressed: () async {
                final claimed = await DailyQuestService.instance.claimQuest(quest.id);
                if (claimed && context.mounted) {
                  PentatonicAudioSynth.instance.playFanfare();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎉 Nhận thưởng: +${quest.rewardCoins} Xu & +${quest.rewardGems} Ngọc!'),
                      backgroundColor: const Color(0xFF2D8512),
                    ),
                  );
                }
              },
              child: const Text('NHẬN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
              child: const Text('Đang làm', style: TextStyle(color: Colors.white38, fontSize: 10)),
            ),
        ],
      ),
    );
  }
}

