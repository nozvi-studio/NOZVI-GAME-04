import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/daily_puzzle_model.dart';
import '../services/language_service.dart';
import '../services/progression_service.dart';

class DailyPuzzleDialog extends StatelessWidget {
  final void Function(DailyPuzzleModel puzzle) onStartPuzzle;

  const DailyPuzzleDialog({super.key, required this.onStartPuzzle});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final puzzle = DailyPuzzleModel.generateForDate(now);
    final isCompleted = ProgressionService.instance.isDailyPuzzleCompletedToday();
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final isLandscape = screenWidth > screenHeight || screenWidth > 580;
    final compact = screenHeight < 420;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 16,
        vertical: compact ? 6 : 12,
      ),
      child: ListenableBuilder(
        listenable: Listenable.merge([
          ProgressionService.instance,
          LanguageService.instance,
        ]),
        builder: (context, _) {
          return Container(
        constraints: BoxConstraints(
          maxWidth: isLandscape
              ? math.min(MediaQuery.of(context).size.width * 0.95, 780.0)
              : 440,
          maxHeight: math.min(screenHeight * 0.94, 620.0),
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A122E), Color(0xFF2E1C4D), Color(0xFF140D24)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFAB47BC).withValues(alpha: 0.7),
            width: 1.8,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black87,
              blurRadius: 25,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // --- 1. HEADER (CỐ ĐỊNH PHÍA TRÊN) ---
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 16,
                  vertical: compact ? 8 : 10,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF100921),
                  border: Border(
                    bottom: BorderSide(color: Colors.white12, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_note,
                      color: Color(0xFFFFD54F),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'daily_puzzle_header'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${now.day}/${now.month}/${now.year}',
                        style: const TextStyle(
                          color: Color(0xFFE1BEE7),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'close'.tr,
                    ),
                  ],
                ),
              ),

              // --- 2. NỘI DUNG CUỘN ĐƯỢC (TỰ CO GIÃN THEO MOBILE) ---
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(compact ? 12 : 16),
                  child: isLandscape
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cột trái: Thông tin thế bi, mục tiêu & mẹo
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildPuzzleTitle(puzzle),
                                  const SizedBox(height: 8),
                                  _buildDescription(puzzle),
                                  const SizedBox(height: 8),
                                  _buildShotLimit(puzzle),
                                  const SizedBox(height: 8),
                                  _buildHintBox(puzzle),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Cột phải: Phần thưởng & thông tin bổ sung
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'completion_reward'.tr,
                                    style: const TextStyle(
                                      color: Color(0xFFFFD54F),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  _buildRewardCard(puzzle),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle_outline,
                                          color: Color(0xFF69F0AE),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'daily_reset_note'.tr,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPuzzleTitle(puzzle),
                            const SizedBox(height: 8),
                            _buildDescription(puzzle),
                            const SizedBox(height: 8),
                            _buildShotLimit(puzzle),
                            const SizedBox(height: 8),
                            _buildHintBox(puzzle),
                            const SizedBox(height: 12),
                            Text(
                              'completion_reward'.tr,
                              style: const TextStyle(
                                color: Color(0xFFFFD54F),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildRewardCard(puzzle),
                          ],
                        ),
                ),
              ),

              // --- 3. BOTTOM ACTION BAR (LUÔN CỐ ĐỊNH, KHÔNG BAO GIỜ BỊ MẤT NÚT) ---
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 16,
                  vertical: compact ? 8 : 10,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F091E),
                  border: Border(
                    top: BorderSide(color: Colors.white12, width: 1),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: compact ? 42 : 46,
                  child: isCompleted
                      ? Row(
                          children: [
                            Expanded(
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFF00E676).withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF00E676),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'completed_today'.tr,
                                        style: const TextStyle(
                                          color: Color(0xFF00E676),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11,
                                          letterSpacing: 0.4,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                onStartPuzzle(puzzle);
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF00E676),
                                foregroundColor: const Color(0xFF071F14),
                                elevation: 2,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.replay, size: 18),
                              label: Text(
                                'practice_again'.tr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        )
                      : FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onStartPuzzle(puzzle);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF00E676),
                            foregroundColor: const Color(0xFF071F14),
                            elevation: 3,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 22),
                          label: Text(
                            'start_daily_puzzle'.tr,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
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

  Widget _buildPuzzleTitle(DailyPuzzleModel puzzle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFAB47BC).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFAB47BC)),
          ),
          child: Text(
            'daily_puzzle_badge'.tr,
            style: const TextStyle(
              color: Color(0xFFE1BEE7),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            LanguageService.instance.localizeStageTitle(puzzle.title),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(DailyPuzzleModel puzzle) {
    return Text(
      LanguageService.instance.localizeDailyPuzzleDescription(puzzle.title, puzzle.description),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        height: 1.35,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildShotLimit(DailyPuzzleModel puzzle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.touch_app, color: Color(0xFFFFD54F), size: 14),
          const SizedBox(width: 5),
          Text(
            'puzzle_shot_limit'.tr.replaceAll('{max}', '${puzzle.maxShotsAllowed}'),
            style: const TextStyle(
              color: Color(0xFFFFD54F),
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintBox(DailyPuzzleModel puzzle) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF381E57).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFAB47BC).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb, color: Colors.amber, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              LanguageService.instance.localizeDailyPuzzleHint(puzzle.title, puzzle.hint),
              style: const TextStyle(
                color: Color(0xFFE1BEE7),
                fontSize: 10.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard(DailyPuzzleModel puzzle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF120B22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on, color: Color(0xFFFFD54F), size: 17),
              const SizedBox(width: 4),
              Text(
                '+${puzzle.rewardCoins}',
                style: const TextStyle(
                  color: Color(0xFFFFD54F),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt, color: Color(0xFF69F0AE), size: 17),
              const SizedBox(width: 4),
              Text(
                '+${puzzle.rewardXP} XP',
                style: const TextStyle(
                  color: Color(0xFF69F0AE),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.diamond, color: Color(0xFF81D4FA), size: 15),
              const SizedBox(width: 4),
              Text(
                '+${puzzle.rewardDiamonds}',
                style: const TextStyle(
                  color: Color(0xFF81D4FA),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
