import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/achievement_model.dart';
import '../models/medal_model.dart';
import '../services/progression_service.dart';
import '../services/language_service.dart';

class AchievementsDialog extends StatefulWidget {
  final int initialTab; // 0: Achievements, 1: Medals

  const AchievementsDialog({super.key, this.initialTab = 0});

  @override
  State<AchievementsDialog> createState() => _AchievementsDialogState();
}

class _AchievementsDialogState extends State<AchievementsDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        final screenSize = MediaQuery.of(context).size;
        final isMobile = screenSize.width < 700;

        return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 32,
        vertical: isMobile ? 12 : 24,
      ),
      child: Container(
        width: math.min(screenSize.width * 0.95, 860.0),
        height: screenSize.height * 0.90,
        decoration: BoxDecoration(
          color: const Color(0xFF0F1E19),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF26A69A), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF26A69A), Color(0xFF00897B)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(
                    icon: const Icon(Icons.military_tech, size: 20),
                    text: 'achievements_tab'.tr,
                  ),
                  Tab(
                    icon: const Icon(Icons.workspace_premium, size: 20),
                    text: 'medals_tab'.tr,
                  ),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: ListenableBuilder(
                listenable: ProgressionService.instance,
                builder: (context, _) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAchievementsTab(),
                      _buildMedalsTab(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF142B24),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: Color(0xFF26A69A), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events, color: Colors.black87, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'achievements_header'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'achievements_sub'.tr,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
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

  // --- TAB 1: THÀNH TỰU ---
  Widget _buildAchievementsTab() {
    final service = ProgressionService.instance;
    final allAch = AchievementCatalog.allAchievements;
    final completedCount = allAch.where((a) => service.isAchievementUnlocked(a.id)).length;

    return Column(
      children: [
        // Progress Banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF163229),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF26A69A).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${'achievements_progress'.tr}: $completedCount / ${allAch.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: allAch.isEmpty ? 0 : completedCount / allAch.length,
                        minHeight: 6,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: Text(
                  '+XP ${'by_difficulty'.tr}',
                  style: TextStyle(
                    color: Colors.amber.shade300,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // List View
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: allAch.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final ach = allAch[index];
              final isUnlocked = service.isAchievementUnlocked(ach.id);
              final isClaimed = service.isAchievementClaimed(ach.id);

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? (isClaimed ? const Color(0xFF142E25) : const Color(0xFF1B4332))
                      : Colors.black26,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isUnlocked
                        ? (isClaimed ? Colors.white24 : ach.difficulty.color)
                        : Colors.white10,
                    width: isUnlocked && !isClaimed ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? ach.difficulty.color.withValues(alpha: 0.2)
                            : Colors.white10,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isUnlocked ? ach.difficulty.color : Colors.white24,
                        ),
                      ),
                      child: Icon(
                        ach.icon,
                        color: isUnlocked ? ach.difficulty.color : Colors.white38,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title & Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  ach.localizedTitle,
                                  style: TextStyle(
                                    color: isUnlocked ? Colors.white : Colors.white60,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: ach.difficulty.color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: ach.difficulty.color, width: 0.8),
                                ),
                                child: Text(
                                  '${'difficulty'.tr}: ${ach.difficulty.label}',
                                  style: TextStyle(
                                    color: ach.difficulty.color,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            ach.localizedDescription,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Claim / Reward Button
                    if (isClaimed) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, color: Color(0xFF00E676), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'claimed'.tr,
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ] else if (isUnlocked) ...[
                      ElevatedButton(
                        onPressed: () {
                          final reward = service.claimAchievement(ach.id);
                          if (reward != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('achievement_claimed_toast'.tr.replaceAll('{xp}', '${ach.rewardXP}')),
                                backgroundColor: const Color(0xFF00897B),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB300),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.card_giftcard, size: 15),
                            const SizedBox(width: 4),
                            Text(
                              '+${ach.rewardXP} XP',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '+${ach.rewardXP} XP',
                          style: TextStyle(
                            color: ach.difficulty.color.withValues(alpha: 0.8),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- TAB 2: KHO HUY CHƯƠNG & SHOWCASE (TỐI ĐA 5) ---
  Widget _buildMedalsTab() {
    final service = ProgressionService.instance;
    final allMedals = MedalCatalog.allMedals;
    final showcased = service.showcasedMedals;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Khu vực 5 ô Huy Chương Showcase
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B3D32), Color(0xFF10261F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.2),
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
                        const Icon(Icons.stars, color: Color(0xFFFFD54F), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'medals_pinned_title'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${showcased.length}/5 ${'selected'.tr}',
                      style: const TextStyle(
                        color: Color(0xFFFFD54F),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 5 Slots
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (index) {
                    final hasMedal = index < showcased.length;
                    final medalId = hasMedal ? showcased[index] : null;
                    final medal = medalId != null ? MedalCatalog.getById(medalId) : null;

                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 78,
                        decoration: BoxDecoration(
                          color: hasMedal ? Colors.black45 : Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: hasMedal
                                ? (medal?.rarity.glowColor ?? Colors.amber)
                                : Colors.white24,
                            width: hasMedal ? 1.5 : 1,
                          ),
                        ),
                        child: hasMedal && medal != null
                            ? InkWell(
                                onTap: () {
                                  service.toggleShowcaseMedal(medal.id);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      medal.icon,
                                      color: medal.rarity.glowColor,
                                      size: 26,
                                    ),
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2),
                                      child: Text(
                                        medal.localizedName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(

                                      'tap_to_remove'.tr,
                                      style: const TextStyle(color: Colors.white54, fontSize: 7.5),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add, color: Colors.white38, size: 22),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${'slot'.tr} ${index + 1}',
                                    style: const TextStyle(color: Colors.white38, fontSize: 9),
                                  ),
                                ],
                              ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'all_medals_title'.tr,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),

          // Danh sách toàn bộ Huy Chương
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allMedals.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final medal = allMedals[index];
              final isUnlocked = service.isMedalUnlocked(medal.id);
              final isShowcased = service.isMedalShowcased(medal.id);

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUnlocked ? const Color(0xFF132B23) : Colors.black26,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isUnlocked ? medal.rarity.glowColor.withValues(alpha: 0.6) : Colors.white10,
                  ),
                ),
                child: Row(
                  children: [
                    // Medal Icon with Gradient
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: isUnlocked
                            ? LinearGradient(colors: medal.rarity.gradientColors)
                            : null,
                        color: isUnlocked ? null : Colors.white12,
                        shape: BoxShape.circle,
                        boxShadow: isUnlocked
                            ? [
                                BoxShadow(
                                  color: medal.rarity.glowColor.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        medal.icon,
                        color: isUnlocked ? Colors.black87 : Colors.white38,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  medal.localizedName,
                                  style: TextStyle(
                                    color: isUnlocked ? Colors.white : Colors.white60,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: medal.rarity.glowColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: medal.rarity.glowColor, width: 0.8),
                                ),
                                child: Text(
                                  medal.rarity.label,
                                  style: TextStyle(
                                    color: medal.rarity.glowColor,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            medal.localizedDescription,
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${'requirement'.tr}: ${medal.localizedRequirement}',
                            style: TextStyle(
                              color: isUnlocked ? const Color(0xFF00E676) : Colors.white38,
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Showcase Action
                    if (isUnlocked) ...[
                      ElevatedButton(
                        onPressed: () {
                          final success = service.toggleShowcaseMedal(medal.id);
                          if (!success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('medals_max_toast'.tr),
                                backgroundColor: const Color(0xFFC62828),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isShowcased
                              ? const Color(0xFFE91E63)
                              : const Color(0xFF00897B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          isShowcased ? 'unpin_from_profile'.tr : 'pin_to_profile'.tr,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock, color: Colors.white38, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              'locked'.tr,
                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
