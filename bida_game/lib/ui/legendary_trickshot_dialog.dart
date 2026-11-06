import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/legendary_trickshot_model.dart';
import '../services/language_service.dart';
import '../services/progression_service.dart';

class LegendaryTrickshotDialog extends StatefulWidget {
  final void Function(LegendaryTrickshotModel shot) onSelectTrickshot;

  const LegendaryTrickshotDialog({super.key, required this.onSelectTrickshot});

  @override
  State<LegendaryTrickshotDialog> createState() => _LegendaryTrickshotDialogState();
}

class _LegendaryTrickshotDialogState extends State<LegendaryTrickshotDialog> {
  String _selectedMaster = 'all';
  int _selectedDifficulty = 0; // 0 = Tất cả, 1..5 = số sao
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: ListenableBuilder(
        listenable: Listenable.merge([
          ProgressionService.instance,
          LanguageService.instance,
        ]),
        builder: (context, _) {
          final service = ProgressionService.instance;
          final allShots = LegendaryTrickshotCatalog.trickshots;
          final filteredShots = LegendaryTrickshotCatalog.getFiltered(
            master: _selectedMaster,
            difficultyStars: _selectedDifficulty,
            query: _searchCtrl.text,
          );

          final screenHeight = MediaQuery.of(context).size.height;
          final screenWidth = MediaQuery.of(context).size.width;
          final isCompact = screenHeight < 500 || screenWidth < 720;

          // Đếm số thế hoàn thành trong danh sách hiện tại
          final completedInFiltered = filteredShots
              .where((s) => service.isTrickshotCompleted(s.id))
              .length;

          return Container(
            constraints: BoxConstraints(
              maxWidth: 880,
              maxHeight: math.min(screenHeight * 0.95, 620.0),
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D281E), Color(0xFF163E30), Color(0xFF091F17)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.6),
                width: 2,
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black87, blurRadius: 24),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Column(
                children: [
                  // --- HEADER ---
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 12 : 18,
                      vertical: isCompact ? 8 : 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF081812),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                            ),
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.black87, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'legendary_trickshot_header'.tr,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isCompact ? 13.5 : 15,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.0,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFD54F),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${allShots.length} ${'trickshots_unit'.tr}',
                                      style: const TextStyle(
                                        color: Color(0xFF261810),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 9.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'legendary_trickshot_sub'.tr,
                                style: const TextStyle(
                                  color: Color(0xFFFFD54F),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            '$completedInFiltered / ${filteredShots.length} ${'completed_unit'.tr}',
                            style: const TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white70, size: 22),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'close'.tr,
                        ),
                      ],
                    ),
                  ),

                  // --- THANH LỌC (FILTERS) ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1F17),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. THANH LỌC THEO CƠ THỦ HUYỀN THOẠI
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildMasterChip(
                                label: '${'all_masters'.tr} (${allShots.length})',
                                avatar: '🎱',
                                isSelected: _selectedMaster == 'all',
                                onSelected: () => setState(() => _selectedMaster = 'all'),
                              ),
                              const SizedBox(width: 6),
                              ...LegendaryTrickshotCatalog.allMasters.map((master) {
                                final count = allShots
                                    .where((s) => s.masterName == master)
                                    .length;
                                final avatar = _getAvatarForMaster(master);
                                final shortName = LanguageService.instance.localizeMasterName(master, short: true);
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: _buildMasterChip(
                                    label: '$shortName ($count)',
                                    avatar: avatar,
                                    isSelected: _selectedMaster.toLowerCase() == master.toLowerCase(),
                                    onSelected: () => setState(() => _selectedMaster = master),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),

                        const SizedBox(height: 5),

                        // 2. THANH LỌC THEO ĐỘ KHÓ (1-5 SAO)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildDifficultyChip(
                                label: 'all_difficulties'.tr,
                                starCount: 0,
                                count: allShots
                                    .where((s) => _selectedMaster == 'all' || s.masterName == _selectedMaster)
                                    .length,
                                isSelected: _selectedDifficulty == 0,
                                onSelected: () => setState(() => _selectedDifficulty = 0),
                              ),
                              const SizedBox(width: 6),
                              ...List.generate(5, (idx) {
                                final stars = idx + 1;
                                final count = allShots.where((s) {
                                  final matchMaster = _selectedMaster == 'all' || s.masterName == _selectedMaster;
                                  return matchMaster && s.difficultyStars == stars;
                                }).length;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: _buildDifficultyChip(
                                    label: 'stars_count'.tr.replaceAll('{stars}', '$stars'),
                                    starCount: stars,
                                    count: count,
                                    isSelected: _selectedDifficulty == stars,
                                    onSelected: () => setState(() => _selectedDifficulty = stars),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- LIST OF LEGENDARY TRICKSHOTS ---
                  Expanded(
                    child: filteredShots.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.filter_list_off, color: Colors.white38, size: 40),
                                  const SizedBox(height: 10),
                                  Text(
                                    'no_trickshot_match'.tr,
                                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _selectedMaster = 'all';
                                        _selectedDifficulty = 0;
                                        _searchCtrl.clear();
                                      });
                                    },
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: Text('reset_filter'.tr),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFFFD54F),
                                      side: const BorderSide(color: Color(0xFFFFD54F)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(10),
                            itemCount: filteredShots.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final shot = filteredShots[index];
                              final isCompleted = service.isTrickshotCompleted(shot.id);
                              final originalIndex = allShots.indexWhere((s) => s.id == shot.id);

                              return Container(
                                padding: const EdgeInsets.all(11),
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? const Color(0xFF133629)
                                      : const Color(0xFF0E271D),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isCompleted
                                        ? const Color(0xFF00E676)
                                        : const Color(0xFFFFD54F).withValues(alpha: 0.35),
                                    width: isCompleted ? 1.8 : 1.2,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Avatar Bi / Số thứ tự
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: isCompleted
                                                  ? [const Color(0xFF00E676), const Color(0xFF00897B)]
                                                  : [const Color(0xFFFFD54F), const Color(0xFFE65100)],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: isCompleted
                                                  ? const Color(0xFF00E676).withValues(alpha: 0.35)
                                                  : const Color(0xFFFFD54F).withValues(alpha: 0.25),
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: isCompleted
                                                ? const Icon(Icons.emoji_events, color: Colors.black87, size: 20)
                                                : Text(
                                                    '#${originalIndex >= 0 ? originalIndex + 1 : index + 1}',
                                                    style: const TextStyle(
                                                      color: Colors.black87,
                                                      fontWeight: FontWeight.w900,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),

                                        // Nội dung thế đánh
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      LanguageService.instance.localizeTrickshotTitle(shot.id, shot.title),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w900,
                                                        fontSize: 13.5,
                                                      ),
                                                    ),
                                                  ),
                                                  // Độ khó sao
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: List.generate(5, (starIdx) {
                                                      return Icon(
                                                        starIdx < shot.difficultyStars
                                                            ? Icons.star
                                                            : Icons.star_border,
                                                        size: 12.5,
                                                        color: const Color(0xFFFFD54F),
                                                      );
                                                    }),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Text(
                                                    '${shot.playerAvatar} ${LanguageService.instance.localizeMasterName(shot.masterName)}',
                                                    style: const TextStyle(
                                                      color: Color(0xFFFFD54F),
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      '• ${LanguageService.instance.localizeTrickshotNickname(shot.id, shot.masterNickname)}',
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 10,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                LanguageService.instance.localizeTrickshotTournament(shot.id, shot.yearAndTournament),
                                                style: const TextStyle(
                                                  color: Color(0xFF80CBC4),
                                                  fontSize: 9.5,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                LanguageService.instance.localizeTrickshotDescription(shot.id, shot.description),
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 11,
                                                  height: 1.25,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Wrap(
                                                spacing: 6,
                                                runSpacing: 4,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF00E676).withValues(alpha: 0.18),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(color: const Color(0xFF00E676), width: 1),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(Icons.track_changes, color: Color(0xFF00E676), size: 12),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          '${'pot_ball'.tr} #${shot.targetBallNumber} ➜ ${LanguageService.instance.localizePocketName(shot.targetPocketName)}',
                                                          style: const TextStyle(
                                                            color: Color(0xFFB9F6CA),
                                                            fontSize: 9.5,
                                                            fontWeight: FontWeight.w800,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (shot.obstacleBallNumbers.isNotEmpty)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFFF5252).withValues(alpha: 0.18),
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(color: const Color(0xFFFF5252), width: 1),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          const Icon(Icons.block, color: Color(0xFFFF5252), size: 12),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            'avoid_balls_label'.tr.replaceAll(
                                                              '{balls}',
                                                              shot.obstacleBallNumbers.join(', #'),
                                                            ),
                                                            style: const TextStyle(
                                                              color: Color(0xFFFF8A80),
                                                              fontSize: 9.5,
                                                              fontWeight: FontWeight.w800,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 7),

                                    // Bottom bar: Gợi ý kỹ thuật & Tặng thưởng vàng, kim cương, exp & Nút Tập
                                    Row(
                                      children: [
                                        // Badge Gợi ý kỹ thuật
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                                            decoration: BoxDecoration(
                                              color: Colors.black38,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.amber.withValues(alpha: 0.25),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.lightbulb, color: Color(0xFFFFD54F), size: 12),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    LanguageService.instance.localizeTrickshotHint(shot.id, shot.techniqueHint),
                                                    style: const TextStyle(
                                                      color: Color(0xFFFFECB3),
                                                      fontSize: 9.5,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // --- CÁC PHẦN THƯỞNG: VÀNG, KIM CƯƠNG, KINH NGHIỆM ---
                                        // 1. VÀNG
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.black45,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.3)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.monetization_on, color: Color(0xFFFFD54F), size: 12),
                                              const SizedBox(width: 2),
                                              Text(
                                                '+${shot.rewardCoins}',
                                                style: const TextStyle(
                                                  color: Color(0xFFFFD54F),
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 4),

                                        // 2. KIM CƯƠNG
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.black45,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.diamond, color: Color(0xFF00E5FF), size: 12),
                                              const SizedBox(width: 2),
                                              Text(
                                                '+${shot.rewardDiamonds}',
                                                style: const TextStyle(
                                                  color: Color(0xFF00E5FF),
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 4),

                                        // 3. EXP
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.black45,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFFCE93D8).withValues(alpha: 0.4)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.bolt, color: Color(0xFFCE93D8), size: 12),
                                              const SizedBox(width: 2),
                                              Text(
                                                '+${shot.rewardXP}',
                                                style: const TextStyle(
                                                  color: Color(0xFFE1BEE7),
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Nút Vào Luyện Tập
                                        FilledButton.icon(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            widget.onSelectTrickshot(shot);
                                          },
                                          style: FilledButton.styleFrom(
                                            backgroundColor: isCompleted
                                                ? const Color(0xFF00E676)
                                                : const Color(0xFFFFB300),
                                            foregroundColor: Colors.black87,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          icon: Icon(
                                            isCompleted ? Icons.replay : Icons.play_arrow_rounded,
                                            size: 14,
                                          ),
                                          label: Text(
                                            isCompleted ? 'practice_again'.tr : 'practice_shot'.tr,
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ],
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
          );
        },
      ),
    );
  }

  Widget _buildMasterChip({
    required String label,
    required String avatar,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFD54F) : const Color(0xFF132F24),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD54F) : Colors.white24,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(avatar, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF1E1400) : Colors.white,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyChip({
    required String label,
    required int starCount,
    required int count,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00E676) : const Color(0xFF12241C),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF00E676) : Colors.white12,
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (starCount > 0) ...[
              const Icon(Icons.star, color: Color(0xFFFFD54F), size: 11),
              const SizedBox(width: 2),
            ],
            Text(
              '$label ($count)',
              style: TextStyle(
                color: isSelected ? const Color(0xFF052110) : Colors.white70,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                fontSize: 9.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAvatarForMaster(String name) {
    if (name.contains('Efren')) return '🧙‍♂️';
    if (name.contains('Ronnie')) return '🚀';
    if (name.contains('Shane')) return '⚡';
    if (name.contains('Florian') || name.contains('Venom')) return '🐍';
    if (name.contains('Hoàng')) return '⭐';
    if (name.contains('Earl')) return '👑';
    if (name.contains('Bustamante')) return '🛡️';
    if (name.contains('Shaw')) return '🦅';
    if (name.contains('Gorst')) return '👻';
    if (name.contains('Blomdahl')) return '🎯';
    if (name.contains('Saygıner')) return '🎩';
    if (name.contains('Ceulemans')) return '💎';
    if (name.contains('Massey')) return '🎪';
    if (name.contains('Jeanette') || name.contains('Widow')) return '🕷️';
    return '🎱';
  }
}
