import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/progression_service.dart';
import '../services/language_service.dart';
import '../models/medal_model.dart';
import 'achievements_dialog.dart';
import 'auth_dialog.dart';

class PlayerProfileDialog extends StatelessWidget {
  const PlayerProfileDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 650;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 36,
        vertical: isMobile ? 12 : 24,
      ),
      child: Container(
        width: math.min(screenSize.width * 0.94, 700.0),
        constraints: BoxConstraints(maxHeight: screenSize.height * 0.94),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1F1A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF26A69A), width: 1.8),
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
            ProgressionService.instance,
            AuthService.instance,
            LanguageService.instance,
          ]),
          builder: (context, _) {
            final auth = AuthService.instance;
            final progress = ProgressionService.instance;

            final inGameName = auth.displayName;
            final level = progress.playerLevel;
            final currentXp = progress.currentXP;
            final nextXp = progress.xpRequiredForNextLevel;
            final xpPercent = progress.xpProgress;
            final coins = progress.coins;
            final diamonds = progress.diamonds;
            final wins = progress.totalWins;
            final tourWins = progress.tournamentWins;
            final showcased = progress.showcasedMedals;

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Header with Close Button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: const BoxDecoration(
                      color: Color(0xFF142B24),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      border: Border(bottom: BorderSide(color: Color(0xFF26A69A), width: 1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.badge, color: Color(0xFFFFD54F), size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'profile_title'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white70),
                          tooltip: 'close'.tr,
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 2. Avatar & Player In-Game Info Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1A382F), Color(0xFF11251F)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF26A69A).withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Avatar Frame
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    width: isMobile ? 64 : 76,
                                    height: isMobile ? 64 : 76,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.amber.withValues(alpha: 0.5),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black,
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Image.asset(
                                        'assets/images/ball_8.png',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  // Level Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF6F00),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white, width: 1.2),
                                    ),
                                    child: Text(
                                      'Lv.$level',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),

                              // Name & Level Progress
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            inGameName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (auth.isAdmin) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.amber,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'ADMIN',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),

                                    // XP Progress Bar
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'level_progress'.tr,
                                          style: const TextStyle(color: Colors.tealAccent, fontSize: 11),
                                        ),
                                        Text(
                                          '$currentXp / $nextXp XP',
                                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: xpPercent,
                                        minHeight: 8,
                                        backgroundColor: Colors.white12,
                                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 3. Currency & Match Stats (Tiền, Kim Cương, Thắng trận)
                        Row(
                          children: [
                            // Vàng (Coins)
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.monetization_on,
                                iconColor: const Color(0xFFFFD54F),
                                title: 'coins'.tr.toUpperCase(),
                                value: _formatNumber(coins),
                                valueColor: const Color(0xFFFFD54F),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Kim Cương (Diamonds)
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.diamond,
                                iconColor: const Color(0xFF29B6F6),
                                title: 'diamonds'.tr.toUpperCase(),
                                value: _formatNumber(diamonds),
                                valueColor: const Color(0xFF81D4FA),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Tổng Trận Thắng
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.military_tech,
                                iconColor: const Color(0xFF00E676),
                                title: 'wins'.tr.toUpperCase(),
                                value: '$wins',
                                valueColor: const Color(0xFF00E676),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Cúp Tournament
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.emoji_events,
                                iconColor: const Color(0xFFFF4081),
                                title: 'champion_cups'.tr,
                                value: '$tourWins',
                                valueColor: const Color(0xFFFF4081),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 4. 5 Ô HUY CHƯƠNG GHIM TRÊN PROFILE (MEDAL SHOWCASE - MAX 5)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1B3B30), Color(0xFF12241E)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha: 0.15),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.workspace_premium, color: Color(0xFFFFD54F), size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'medals_showcase_title'.tr,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                  InkWell(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      showDialog(
                                        context: context,
                                        builder: (_) => const AchievementsDialog(initialTab: 1),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        Text(
                                          'manage'.tr,
                                          style: const TextStyle(
                                            color: Color(0xFFFFD54F),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios, color: Color(0xFFFFD54F), size: 12),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // 5 Medal Slots Display
                              Row(
                                children: List.generate(5, (index) {
                                  final hasMedal = index < showcased.length;
                                  final medalId = hasMedal ? showcased[index] : null;
                                  final medal = medalId != null ? MedalCatalog.getById(medalId) : null;

                                  return Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      height: 90,
                                      decoration: BoxDecoration(
                                        color: hasMedal ? Colors.black54 : Colors.black26,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: hasMedal
                                              ? (medal?.rarity.glowColor ?? Colors.amber)
                                              : Colors.white12,
                                          width: hasMedal ? 1.8 : 1,
                                        ),
                                        boxShadow: hasMedal
                                            ? [
                                                BoxShadow(
                                                  color: (medal?.rarity.glowColor ?? Colors.amber)
                                                      .withValues(alpha: 0.25),
                                                  blurRadius: 8,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: hasMedal && medal != null
                                          ? InkWell(
                                              onTap: () {
                                                _showMedalDetail(context, medal);
                                              },
                                              borderRadius: BorderRadius.circular(14),
                                              child: Padding(
                                                padding: const EdgeInsets.all(4),
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(5),
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        gradient: LinearGradient(
                                                          colors: medal.rarity.gradientColors,
                                                        ),
                                                      ),
                                                      child: Icon(
                                                        medal.icon,
                                                        color: Colors.black87,
                                                        size: 20,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      medal.localizedName,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      textAlign: TextAlign.center,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                          : InkWell(
                                              onTap: () {
                                                Navigator.of(context).pop();
                                                showDialog(
                                                  context: context,
                                                  builder: (_) => const AchievementsDialog(initialTab: 1),
                                                );
                                              },
                                              borderRadius: BorderRadius.circular(14),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(Icons.add_circle_outline, color: Colors.white30, size: 24),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'add'.tr,
                                                    style: const TextStyle(color: Colors.white30, fontSize: 10),
                                                  ),
                                                ],
                                              ),
                                            ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 5. Action Buttons (Thành Tựu, Đổi Tài Khoản)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  showDialog(
                                    context: context,
                                    builder: (_) => const AchievementsDialog(initialTab: 0),
                                  );
                                },
                                icon: const Icon(Icons.emoji_events),
                                label: Text('achievements_list'.tr),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00897B),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                showDialog(
                                  context: context,
                                  builder: (_) => const AuthDialog(),
                                );
                              },
                              icon: const Icon(Icons.switch_account),
                              label: Text('account'.tr),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF263238),
                                foregroundColor: Colors.white70,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showMedalDetail(BuildContext context, MedalModel medal) {
    showDialog(
      context: context,
      builder: (_) => ListenableBuilder(
        listenable: LanguageService.instance,
        builder: (context, _) => AlertDialog(
          backgroundColor: const Color(0xFF132B23),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Icon(medal.icon, color: medal.rarity.glowColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  medal.localizedName,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                medal.localizedDescription,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                '${'rarity'.tr}: ${medal.rarity.label}',
                style: TextStyle(color: medal.rarity.glowColor, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${'requirement'.tr}: ${medal.localizedRequirement}',
                style: const TextStyle(color: Color(0xFF00E676), fontSize: 11),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('close'.tr, style: const TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }


  static String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}
