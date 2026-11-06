import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/cue_model.dart';
import '../services/language_service.dart';
import '../services/progression_service.dart';

class CueShopDialog extends StatefulWidget {
  const CueShopDialog({super.key});

  @override
  State<CueShopDialog> createState() => _CueShopDialogState();
}

class _CueShopDialogState extends State<CueShopDialog> {
  late String _selectedCueId;
  String? _toastMessage;
  bool _toastIsError = false;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    _selectedCueId = ProgressionService.instance.equippedCueId;
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
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
          final selectedCue = CueCatalog.getById(_selectedCueId);
          final isOwned = service.isCueOwned(selectedCue.id);
          final isEquipped = service.isCueEquipped(selectedCue.id);
          final isUnlocked = service.canUnlockCue(selectedCue);
          final currentLevel = service.getCueLevel(selectedCue.id);
          final screenHeight = MediaQuery.of(context).size.height;
          final screenWidth = MediaQuery.of(context).size.width;

          return Container(
            constraints: BoxConstraints(
              maxWidth: math.min(screenWidth * 0.95, 920.0),
              maxHeight: math.min(screenHeight * 0.94, 620.0),
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F1B16), Color(0xFF162B23), Color(0xFF0B1411)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF26A69A).withValues(alpha: 0.6),
                width: 2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black87,
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  Column(
                    children: [
                      // --- TOP BAR ---
                      _buildHeader(service),

                      // --- MAIN BODY (SPLIT VIEW) ---
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // CỘT TRÁI: DANH SÁCH GẬY CƠ
                            Expanded(
                              flex: 5,
                              child: _buildCueList(service),
                            ),

                            // PHÂN TÁCH DỌC
                            Container(
                              width: 1.5,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),

                            // CỘT PHẢI: CHI TIẾT GẬY & NÂNG CẤP
                            Expanded(
                              flex: 6,
                              child: _buildCueDetailPanel(
                                service,
                                selectedCue,
                                isOwned: isOwned,
                                isEquipped: isEquipped,
                                isUnlocked: isUnlocked,
                                currentLevel: currentLevel,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // In-Shop Floating Notification Banner
                  if (_toastMessage != null)
                    Positioned(
                      top: 54,
                      left: 16,
                      right: 16,
                      child: Center(
                        child: _buildInShopToast(),
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

  Widget _buildHeader(ProgressionService service) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF081410),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront, color: Color(0xFFFFD54F), size: 24),
          const SizedBox(width: 8),
          Text(
            'shop_title'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),

          // Level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${'level'.tr} ${service.playerLevel}',
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Vàng
          Row(
            children: [
              const Icon(Icons.monetization_on, color: Color(0xFFFFD54F), size: 18),
              const SizedBox(width: 4),
              Text(
                '${service.coins}',
                style: const TextStyle(
                  color: Color(0xFFFFD54F),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Kim Cương
          Row(
            children: [
              const Icon(Icons.diamond, color: Color(0xFF29B6F6), size: 17),
              const SizedBox(width: 4),
              Text(
                '${service.diamonds}',
                style: const TextStyle(
                  color: Color(0xFF81D4FA),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Nút Đóng
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white70),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'close'.tr,
          ),
        ],
      ),
    );
  }

  Widget _buildCueList(ProgressionService service) {
    final cues = CueCatalog.allCues;
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: cues.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final cue = cues[index];
        final isSelected = cue.id == _selectedCueId;
        final isOwned = service.isCueOwned(cue.id);
        final isEquipped = service.isCueEquipped(cue.id);
        final isUnlocked = service.canUnlockCue(cue);
        final cueLevel = service.getCueLevel(cue.id);

        return InkWell(
          onTap: () => setState(() => _selectedCueId = cue.id),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? cue.rarity.color.withValues(alpha: 0.22)
                  : (isOwned
                      ? const Color(0xFF142E25)
                      : const Color(0xFF0F1B17)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? cue.rarity.color
                    : (isEquipped
                        ? const Color(0xFF00E676)
                        : Colors.white.withValues(alpha: 0.1)),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: cue.rarity.glowColor,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Khối màu nhận diện phẩm cấp
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [cue.shaftColors.first, cue.handleColors.first],
                    ),
                    border: Border.all(color: cue.rarity.color, width: 1.5),
                  ),
                  child: Icon(
                    !isUnlocked
                        ? Icons.lock
                        : (isEquipped ? Icons.check : Icons.sports_volleyball),
                    color: !isUnlocked ? Colors.white70 : Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),

                // Tên và thông tin gậy
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              cue.localizedName,
                              style: TextStyle(
                                color: isUnlocked ? Colors.white : Colors.white54,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: cue.rarity.color.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              cue.rarity.displayName,
                              style: TextStyle(
                                color: cue.rarity.color,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (!isUnlocked) ...[
                            Text(
                              '${'need_level'.tr} ${cue.requiredLevel}',
                              style: const TextStyle(
                                color: Color(0xFFFF5252),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ] else if (isOwned) ...[
                            Text(
                              '${'cue_level'.tr}: $cueLevel/10',
                              style: const TextStyle(
                                color: Color(0xFF69F0AE),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isEquipped) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00E676).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: const Color(0xFF00E676),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'equipped'.tr.toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFF00E676),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ] else ...[
                            _buildPriceTag(cue),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriceTag(CueModel cue) {
    if (cue.isFree) {
      return Text(
        'free'.tr,
        style: const TextStyle(
          color: Color(0xFF69F0AE),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    if (cue.priceDiamonds != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.diamond, color: Color(0xFF29B6F6), size: 13),
          const SizedBox(width: 3),
          Text(
            '${cue.priceDiamonds}',
            style: const TextStyle(
              color: Color(0xFF81D4FA),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.monetization_on, color: Color(0xFFFFD54F), size: 13),
        const SizedBox(width: 3),
        Text(
          '${cue.priceCoins}',
          style: const TextStyle(
            color: Color(0xFFFFD54F),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCueDetailPanel(
    ProgressionService service,
    CueModel cue, {
    required bool isOwned,
    required bool isEquipped,
    required bool isUnlocked,
    required int currentLevel,
  }) {
    final effectiveLevel = isOwned ? currentLevel : 1;
    final currentStats = cue.getStatsForLevel(effectiveLevel);
    final nextStats = isOwned && effectiveLevel < 10
        ? cue.getStatsForLevel(effectiveLevel + 1)
        : null;
    final upgradeCost = isOwned ? cue.getUpgradeCostCoins(effectiveLevel) : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề & Độ hiếm
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cue.localizedName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cue.localizedDescription,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                      softWrap: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cue.rarity.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cue.rarity.color, width: 1.5),
                ),
                child: Text(
                  cue.rarity.displayName.toUpperCase(),
                  style: TextStyle(
                    color: cue.rarity.color,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cue.animeConcept.icon, size: 13, color: Colors.amberAccent),
                    const SizedBox(width: 4),
                    Text(
                      cue.animeConcept.localizedLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // XEM TRƯỚC CÂY GẬY VECTOR NẰM NGANG
          Container(
            height: 52,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cue.rarity.color.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: CustomPaint(
              painter: _HorizontalCuePreviewPainter(
                cue: cue,
                level: effectiveLevel,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // CẤP ĐỘ GẬY (SEGMENTS)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isOwned
                    ? '${'level'.tr.toUpperCase()}: $effectiveLevel / 10'
                    : '${'level'.tr.toUpperCase()}: Lv.1',
                style: TextStyle(
                  color: cue.rarity.color,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
              if (isOwned && effectiveLevel == 10)
                Text(
                  'max_level'.tr,
                  style: const TextStyle(
                    color: Color(0xFFFFD54F),
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(10, (idx) {
              final isFilled = idx < effectiveLevel;
              return Expanded(
                child: Container(
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: isFilled
                        ? cue.rarity.color
                        : Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 5),

          // CHỈ DẪN NÂNG CẤP NGOẠI HÌNH THEO CẤP ĐỘ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: (effectiveLevel == 10
                        ? const Color(0xFFFFD54F)
                        : (effectiveLevel >= 5 ? const Color(0xFF69F0AE) : Colors.white24))
                    .withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  effectiveLevel == 10
                      ? Icons.workspace_premium
                      : (effectiveLevel >= 5 ? Icons.auto_awesome : Icons.info_outline),
                  size: 13,
                  color: effectiveLevel == 10
                      ? const Color(0xFFFFD54F)
                      : (effectiveLevel >= 5 ? const Color(0xFF69F0AE) : Colors.white70),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    effectiveLevel == 10
                        ? 'cue_perk_max_state'.tr
                        : (effectiveLevel >= 5
                            ? 'cue_perk_unlocked_state'.tr
                            : 'cue_perk_level5_req'.tr),
                    style: TextStyle(
                      color: effectiveLevel == 10
                          ? const Color(0xFFFFD54F)
                          : (effectiveLevel >= 5 ? const Color(0xFF69F0AE) : Colors.white70),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 4 THANH CHỈ SỐ STATS
          _buildStatRow(
            label: '${'force'.tr} (Force)',
            current: currentStats.force,
            next: nextStats?.force,
            color: const Color(0xFFFF7043),
            icon: Icons.flash_on,
          ),
          const SizedBox(height: 6),
          _buildStatRow(
            label: '${'aim'.tr} (Aim Guide)',
            current: currentStats.aim,
            next: nextStats?.aim,
            color: const Color(0xFF29B6F6),
            icon: Icons.track_changes,
          ),
          const SizedBox(height: 6),
          _buildStatRow(
            label: '${'spin'.tr} (Spin)',
            current: currentStats.spin,
            next: nextStats?.spin,
            color: const Color(0xFFAB47BC),
            icon: Icons.rotate_right,
          ),
          const SizedBox(height: 6),
          _buildStatRow(
            label: 'time'.tr,
            current: currentStats.time,
            next: nextStats?.time,
            color: const Color(0xFFFFCA28),
            icon: Icons.timer,
          ),
          const SizedBox(height: 12),

          // HỘP NỘI TẠI KỸ NĂNG ĐẶC BIỆT
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A2F),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF26A69A).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFFFFD54F),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cue.localizedPerk,
                    style: const TextStyle(
                      color: Color(0xFFE0F2F1),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // CÁC NÚT THAO TÁC (MUA, NÂNG CẤP, TRANG BỊ)
          _buildActionButtons(
            service,
            cue,
            isOwned: isOwned,
            isEquipped: isEquipped,
            isUnlocked: isUnlocked,
            currentLevel: effectiveLevel,
            upgradeCost: upgradeCost,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required String label,
    required double current,
    double? next,
    required Color color,
    required IconData icon,
  }) {
    const double maxStat = 16.0;
    final currentRatio = (current / maxStat).clamp(0.0, 1.0);
    final nextDiff = (next != null && next > current) ? next - current : 0.0;
    final nextRatio = ((current + nextDiff) / maxStat).clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 13),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  current.toStringAsFixed(1),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                if (nextDiff > 0) ...[
                  Text(
                    ' (+${nextDiff.toStringAsFixed(1)})',
                    style: const TextStyle(
                      color: Color(0xFF69F0AE),
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 3),
        Stack(
          children: [
            // Background bar
            Container(
              height: 7,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Next stat preview
            if (nextDiff > 0)
              FractionallySizedBox(
                widthFactor: nextRatio,
                child: Container(
                  height: 7,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            // Current stat
            FractionallySizedBox(
              widthFactor: currentRatio,
              child: Container(
                height: 7,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 4,
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

  Widget _buildActionButtons(
    ProgressionService service,
    CueModel cue, {
    required bool isOwned,
    required bool isEquipped,
    required bool isUnlocked,
    required int currentLevel,
    required int upgradeCost,
  }) {
    // 1. Chưa đủ cấp độ để mở khóa
    if (!isUnlocked) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () {
            _showToast(
              context,
              'locked_requires_level_toast'.tr.replaceAll('{level}', '${cue.requiredLevel}'),
              isError: true,
            );
          },
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white12,
            foregroundColor: Colors.white54,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.lock, size: 18),
          label: Text(
            'locked_requires_level'.tr.replaceAll('{level}', '${cue.requiredLevel}'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
      );
    }

    // 2. Đã mở khóa nhưng CHƯA MUA
    if (!isOwned) {
      final isDiamond = cue.priceDiamonds != null;
      final price = isDiamond ? cue.priceDiamonds! : (cue.priceCoins ?? 0);
      final canAfford = isDiamond
          ? service.diamonds >= price
          : service.coins >= price;

      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () {
            if (!canAfford) {
              final missing = price - (isDiamond ? service.diamonds : service.coins);
              _showToast(
                context,
                isDiamond
                    ? 'not_enough_diamonds'.tr.replaceAll('{missing}', '$missing')
                    : 'not_enough_coins_cue'.tr.replaceAll('{missing}', '$missing'),
                isError: true,
              );
              return;
            }
            final success = service.buyCue(cue);
            if (success) {
              _showToast(context, 'cue_purchased_equipped'.tr.replaceAll('{name}', cue.localizedName));
            } else {
              _showToast(
                context,
                'cue_buy_failed'.tr,
                isError: true,
              );
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: canAfford ? const Color(0xFF00E676) : Colors.grey.shade700,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: Icon(isDiamond ? Icons.diamond : Icons.monetization_on, size: 20),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${'buy_now'.tr} • $price ${isDiamond ? 'diamonds'.tr.toUpperCase() : 'coins'.tr.toUpperCase()}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      );
    }

    // 3. ĐÃ SỞ HỮU: CUNG CẤP NÚT TRANG BỊ & NÂNG CẤP
    return Row(
      children: [
        // Nút Trang Bị / Đang dùng
        Expanded(
          flex: 4,
          child: isEquipped
              ? Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF00E676),
                      width: 1.8,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF00E676), size: 18),
                      const SizedBox(width: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'equipped'.tr.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF00E676),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : FilledButton.icon(
                  onPressed: () {
                    service.equipCue(cue.id);
                    _showToast(context, 'cue_equipped_success'.tr.replaceAll('{name}', cue.localizedName));
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00B0FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.colorize, size: 18, color: Colors.white),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'equip'.tr.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.8,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 10),

        // Nút Nâng Cấp Gậy
        Expanded(
          flex: 6,
          child: FilledButton.icon(
            onPressed: currentLevel >= 10
                ? null
                : () {
                    final canUpgrade = service.coins >= upgradeCost;
                    if (!canUpgrade) {
                      final missing = upgradeCost - service.coins;
                      _showToast(
                        context,
                        'cue_upgrade_need_coins'.tr.replaceAll('{missing}', '$missing').replaceAll('{total}', '$upgradeCost'),
                        isError: true,
                      );
                      return;
                    }
                    final ok = service.upgradeCue(cue.id);
                    if (ok) {
                      _showToast(
                        context,
                        'cue_upgraded_success'.tr.replaceAll('{name}', cue.localizedName).replaceAll('{level}', '${currentLevel + 1}'),
                      );
                    }
                  },
            style: FilledButton.styleFrom(
              backgroundColor: currentLevel >= 10
                  ? Colors.white12
                  : const Color(0xFFFFB300),
              foregroundColor: currentLevel >= 10
                  ? Colors.white38
                  : Colors.black87,
              disabledBackgroundColor: Colors.white12,
              disabledForegroundColor: Colors.white38,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: Icon(
              currentLevel >= 10 ? Icons.star : Icons.arrow_upward,
              size: 18,
            ),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                currentLevel >= 10
                    ? 'max_level'.tr
                    : '${'upgrade'.tr.toUpperCase()} LV.${currentLevel + 1} • $upgradeCost ${'coins'.tr.toUpperCase()}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showToast(BuildContext context, String message, {bool isError = false}) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
      _toastIsError = isError;
    });
    _toastTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _toastMessage = null;
        });
      }
    });
  }

  Widget _buildInShopToast() {
    return TweenAnimationBuilder<double>(
      key: ValueKey(_toastMessage),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, anim, child) {
        return Transform.translate(
          offset: Offset(0, (1 - anim) * -16),
          child: Opacity(
            opacity: anim.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _toastIsError
                ? [const Color(0xFFD32F2F), const Color(0xFF8B0000)]
                : [const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _toastIsError ? const Color(0xFFFF8A80) : const Color(0xFF69F0AE),
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: (_toastIsError ? Colors.redAccent : Colors.greenAccent)
                  .withValues(alpha: 0.4),
              blurRadius: 18,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
            const BoxShadow(
              color: Colors.black54,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _toastIsError ? Icons.error_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                _toastMessage ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () {
                _toastTimer?.cancel();
                setState(() => _toastMessage = null);
              },
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.close, color: Colors.white70, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bộ vẽ cây gậy cơ Vector nằm ngang chuẩn High-Definition, phân cấp chi tiết theo Cấp Độ (Lv.1 - Lv.10)
class _HorizontalCuePreviewPainter extends CustomPainter {
  final CueModel cue;
  final int level;

  _HorizontalCuePreviewPainter({required this.cue, required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centerY = h / 2;

    // Chiều rộng và kích thước các đoạn gậy
    final tipRadius = 2.4;
    final ferruleRadius = 2.6;
    final jointRadius = 4.2;
    final handleRadius = 5.6;

    final xButtEnd = 16.0;
    final xHandleJoint = w * 0.38;
    final xShaftTip = w - 24.0;
    final xFerruleStart = xShaftTip - 8.0;

    // 0. BÓNG ĐỔ CHIỀU SÂU 2.5D CỦA CÂY GẬY XUỐNG KHUNG CHỨA
    final shadowPath = Path()
      ..moveTo(xButtEnd, centerY + handleRadius + 2.5)
      ..lineTo(xShaftTip, centerY + tipRadius + 2.0)
      ..lineTo(xShaftTip, centerY + tipRadius + 4.5)
      ..lineTo(xButtEnd, centerY + handleRadius + 5.5)
      ..close();
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black45
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );

    // 1. HÀO QUANG NĂNG LƯỢNG (Aura Corona) - CÀNG CAO CÀNG RỰC RỠ & HUYỀN ẢO
    // Lv 3-5: Quầng sáng dịu; Lv 6-8: Hào quang sắc nét; Lv 9-10 (MAX): Thiên quang Thần Thoại
    if (level >= 3 || cue.rarity == CueRarity.epic || cue.rarity == CueRarity.legendary) {
      final isMaxTier = level >= 9;
      final isHighTier = level >= 6;

      // Pass 1: Quầng sáng nở rộng tỏa lan (Soft ambient aura)
      final ambientAlpha = isMaxTier ? 0.60 : (isHighTier ? 0.42 : 0.28);
      canvas.drawLine(
        Offset(xButtEnd, centerY),
        Offset(xShaftTip, centerY),
        Paint()
          ..color = cue.auraColor.withValues(alpha: ambientAlpha)
          ..strokeWidth = isMaxTier ? 18.0 : (isHighTier ? 14.0 : 10.0)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, isMaxTier ? 8.0 : 4.5),
      );

      // Pass 2: Lõi năng lượng phát quang cường độ cao cho gậy Lv >= 6
      if (isHighTier) {
        canvas.drawLine(
          Offset(xButtEnd + 4, centerY),
          Offset(xShaftTip - 4, centerY),
          Paint()
            ..color = Colors.white.withValues(alpha: isMaxTier ? 0.70 : 0.45)
            ..strokeWidth = 2.4
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8),
        );
      }
    }

    void drawCylinderSegment({
      required double x1,
      required double x2,
      required double r1,
      required double r2,
      required List<Color> colors,
    }) {
      final path = Path()
        ..moveTo(x1, centerY - r1)
        ..lineTo(x2, centerY - r2)
        ..lineTo(x2, centerY + r2)
        ..lineTo(x1, centerY + r1)
        ..close();

      final maxR = math.max(r1, r2);
      final c0 = colors[0];
      final cMid = colors.length > 2 ? colors[1] : colors[0];
      final cLast = colors.last;

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            c0,
            cMid,
            Colors.white.withValues(alpha: 0.65), // Vệt bóng sáng trắng phản chiếu ánh sáng
            cMid,
            cLast.withValues(alpha: 0.90),
          ],
          stops: const [0.0, 0.26, 0.46, 0.72, 1.0],
        ).createShader(Rect.fromLTRB(x1, centerY - maxR, x2, centerY + maxR));

      canvas.drawPath(path, paint);
    }

    // 2. PHẦN CHUÔI CƠ (Handle / Butt)
    final buttCapWidth = 4.0;
    final xHandleStart = xButtEnd + buttCapWidth;

    drawCylinderSegment(
      x1: xHandleStart,
      x2: xHandleJoint,
      r1: handleRadius,
      r2: jointRadius,
      colors: cue.handleColors,
    );

    // HỌA TIẾT CONCEPT ANIME TRÊN TAY CẦM - PHÂN CẤP THEO LEVEL
    switch (cue.animeConcept) {
      case CueAnimeConcept.katanaSamurai:
        // Đan dây quấn kiếm Tsuka hình quả trám (Diamond laces)
        final lacePaint = Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: level >= 6 ? 0.90 : 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = level >= 6 ? 1.4 : 1.0;
        for (double lx = xHandleStart + 6; lx < xHandleJoint - 6; lx += 10) {
          final diamond = Path()
            ..moveTo(lx, centerY)
            ..lineTo(lx + 4, centerY - handleRadius * 0.58)
            ..lineTo(lx + 8, centerY)
            ..lineTo(lx + 4, centerY + handleRadius * 0.58)
            ..close();
          canvas.drawPath(diamond, lacePaint);

          // Lv >= 5: Hạt ngọc Menuki dát vàng cài giữa tâm đan dây
          if (level >= 5) {
            canvas.drawCircle(Offset(lx + 4, centerY), 1.0, Paint()..color = const Color(0xFFFF1744));
          }
        }
        break;

      case CueAnimeConcept.cyberNeo:
        // Vi mạch neon chớp nháy trên tay cầm
        final chipPaint = Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.85)
          ..strokeWidth = 1.2;
        canvas.drawLine(Offset(xHandleStart + 8, centerY - 2), Offset(xHandleJoint - 8, centerY - 2), chipPaint);
        canvas.drawLine(Offset(xHandleStart + 8, centerY + 2), Offset(xHandleJoint - 8, centerY + 2), chipPaint..color = const Color(0xFFE040FB));
        canvas.drawCircle(Offset(xHandleStart + 14, centerY - 2), 1.4, Paint()..color = Colors.white);
        canvas.drawCircle(Offset(xHandleJoint - 14, centerY + 2), 1.4, Paint()..color = const Color(0xFF00E5FF));
        break;

      case CueAnimeConcept.dragonFlame:
        // Vảy rồng lửa hình chữ V mạ vàng
        final scalePaint = Paint()
          ..color = const Color(0xFFFFD600).withValues(alpha: level >= 6 ? 0.85 : 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1;
        for (double sx = xHandleStart + 8; sx < xHandleJoint - 6; sx += 8) {
          canvas.drawLine(Offset(sx, centerY - 3), Offset(sx + 3, centerY), scalePaint);
          canvas.drawLine(Offset(sx + 3, centerY), Offset(sx, centerY + 3), scalePaint);
        }
        break;

      case CueAnimeConcept.mechaGundam:
        // Vạch sọc cảnh báo nguy hiểm EVA Cam/Đen
        final hazardPaint = Paint()
          ..color = const Color(0xFFFF6D00).withValues(alpha: 0.85)
          ..strokeWidth = 2.0;
        for (double hx = xHandleStart + 8; hx < xHandleJoint - 8; hx += 10) {
          canvas.drawLine(Offset(hx, centerY - 3.8), Offset(hx + 4, centerY + 3.8), hazardPaint);
        }
        break;

      case CueAnimeConcept.arcaneMagic:
      case CueAnimeConcept.shadowVoid:
      case CueAnimeConcept.sakuraZen:
      case CueAnimeConcept.frostCryo:
      case CueAnimeConcept.classic:
        // Vòng chỉ viền ánh kim trang trí
        if (level >= 5) {
          final trimPaint = Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.75)..strokeWidth = 1.0;
          canvas.drawLine(Offset(xHandleStart + 12, centerY - 4), Offset(xHandleStart + 12, centerY + 4), trimPaint);
          canvas.drawLine(Offset(xHandleJoint - 12, centerY - 3.5), Offset(xHandleJoint - 12, centerY + 3.5), trimPaint);
        }
        break;
    }

    // 3. KHỚP REN KIM LOẠI TRANG TRÍ HOẶC VÀNH TSUBA HỘ KIẾM (Joint)
    if (cue.animeConcept == CueAnimeConcept.katanaSamurai) {
      // Tsuba hình oval dát vàng
      final tsubaH = jointRadius * (level >= 7 ? 4.2 : 3.8);
      final tsubaRect = Rect.fromLTWH(xHandleJoint - 2, centerY - tsubaH * 0.5, 4.5, tsubaH);
      final tsubaRRect = RRect.fromRectAndRadius(tsubaRect, const Radius.circular(2.2));
      canvas.drawRRect(tsubaRRect, Paint()..color = const Color(0xFFFFD54F));
      canvas.drawRRect(tsubaRRect, Paint()..color = Colors.black87..style = PaintingStyle.stroke..strokeWidth = 0.8);
      if (level >= 6) {
        canvas.drawCircle(Offset(xHandleJoint + 0.2, centerY - tsubaH * 0.28), 1.0, Paint()..color = const Color(0xFFB8860B));
        canvas.drawCircle(Offset(xHandleJoint + 0.2, centerY + tsubaH * 0.28), 1.0, Paint()..color = const Color(0xFFB8860B));
      }
    } else {
      // Vòng ren kim loại đa tầng dát vàng
      final ringPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: level >= 5
              ? const [Color(0xFFFFD54F), Color(0xFFFFF9C4), Color(0xFFB8860B)]
              : const [Color(0xFFB8860B), Color(0xFFFFD700), Color(0xFF5A440D)],
        ).createShader(Rect.fromLTWH(xHandleJoint - 2.5, centerY - jointRadius, 5, jointRadius * 2));
      canvas.drawRect(Rect.fromLTWH(xHandleJoint - 2.5, centerY - jointRadius * 0.95, 5, jointRadius * 1.9), ringPaint);
      if (level >= 6) {
        // Viền khảm ngọc quý ở khớp nối
        canvas.drawCircle(Offset(xHandleJoint, centerY), jointRadius * 0.35, Paint()..color = cue.auraColor);
      }
    }

    // 4. PHẦN NGỌN CƠ (Shaft)
    drawCylinderSegment(
      x1: xHandleJoint + 2.5,
      x2: xFerruleStart,
      r1: jointRadius * 0.95,
      r2: ferruleRadius,
      colors: cue.shaftColors,
    );

    // HỌA TIẾT CONCEPT ANIME TRÊN THÂN NGỌN - PHÂN CẤP THEO LEVEL
    final shaftXStart = xHandleJoint + 4;
    switch (cue.animeConcept) {
      case CueAnimeConcept.katanaSamurai:
        // Đường sống kiếm gợn sóng Hamon rực đỏ
        final hamonPaint = Paint()
          ..color = const Color(0xFFFF1744).withValues(alpha: level >= 6 ? 0.95 : 0.80)
          ..style = PaintingStyle.stroke
          ..strokeWidth = level >= 7 ? 1.2 : 0.9;
        final hamonPath = Path()..moveTo(shaftXStart, centerY);
        for (double hx = shaftXStart; hx < xFerruleStart - 4; hx += 12) {
          hamonPath.quadraticBezierTo(hx + 3, centerY - 1.5, hx + 6, centerY);
          hamonPath.quadraticBezierTo(hx + 9, centerY + 1.5, hx + 12, centerY);
        }
        canvas.drawPath(hamonPath, hamonPaint);

        // Lv >= 5: Đai cổ kiếm Habaki dát vàng 24K ở gốc ngọn
        if (level >= 5) {
          canvas.drawRect(
            Rect.fromLTWH(shaftXStart, centerY - jointRadius * 0.8, 6.0, jointRadius * 1.6),
            Paint()..color = const Color(0xFFFFD54F),
          );
        }
        // Lv >= 8: Cổ tự phát quang dọc sống kiếm
        if (level >= 8) {
          final runePaint = Paint()..color = Colors.white.withValues(alpha: 0.85)..strokeWidth = 0.6;
          for (double rx = shaftXStart + 14; rx < xFerruleStart - 10; rx += 14) {
            canvas.drawLine(Offset(rx, centerY - 1), Offset(rx + 4, centerY + 1), runePaint);
          }
        }
        break;

      case CueAnimeConcept.cyberNeo:
        // Kênh phát sáng laser neon chạy dọc ngọn
        final beamPaint = Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: level >= 6 ? 0.95 : 0.75)
          ..strokeWidth = level >= 6 ? 1.2 : 0.8;
        canvas.drawLine(Offset(shaftXStart, centerY), Offset(xFerruleStart, centerY), beamPaint);
        // Lv >= 4: Các vi mạch nano phát quang
        if (level >= 4) {
          final microPaint = Paint()..color = const Color(0xFFE040FB);
          for (double cx = shaftXStart + 16; cx < xFerruleStart - 10; cx += 18) {
            canvas.drawRect(Rect.fromCenter(center: Offset(cx, centerY), width: 3.0, height: jointRadius * 0.7), microPaint);
            canvas.drawCircle(Offset(cx, centerY), 0.9, Paint()..color = Colors.white);
          }
        }
        break;

      case CueAnimeConcept.dragonFlame:
        // Vệt lửa Hỏa Long rực cháy
        final flamePaint = Paint()
          ..color = const Color(0xFFFF6D00).withValues(alpha: level >= 6 ? 0.95 : 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = level >= 6 ? 1.3 : 0.9;
        canvas.drawLine(Offset(shaftXStart, centerY), Offset(xFerruleStart, centerY), flamePaint);
        // Lv >= 4: Vảy rồng mạ vàng khắc nổi
        if (level >= 4) {
          final scalePaint = Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.80)..style = PaintingStyle.stroke..strokeWidth = 0.9;
          for (double dx = shaftXStart + 12; dx < xFerruleStart - 10; dx += 14) {
            final p = Path()..moveTo(dx, centerY - 1.5)..lineTo(dx + 3, centerY)..lineTo(dx, centerY + 1.5);
            canvas.drawPath(p, scalePaint);
          }
        }
        break;

      case CueAnimeConcept.arcaneMagic:
        // Vòng xoắn mana vàng ánh kim & tinh vân
        final manaPaint = Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: level >= 6 ? 0.90 : 0.70)
          ..strokeWidth = level >= 6 ? 1.3 : 0.9;
        for (double mx = shaftXStart + 10; mx < xFerruleStart - 10; mx += 14) {
          canvas.drawLine(Offset(mx, centerY - 2), Offset(mx + 4, centerY + 2), manaPaint);
          if (level >= 6) {
            canvas.drawCircle(Offset(mx + 2, centerY), 1.1, Paint()..color = const Color(0xFFB388FF));
          }
        }
        break;

      case CueAnimeConcept.mechaGundam:
        // Rãnh Titanium Mecha
        final mechaLine = Paint()..color = const Color(0xFF76FF03).withValues(alpha: level >= 6 ? 0.90 : 0.70)..strokeWidth = 1.0;
        canvas.drawLine(Offset(shaftXStart, centerY), Offset(xFerruleStart, centerY), mechaLine);
        if (level >= 5) {
          for (double gx = shaftXStart + 14; gx < xFerruleStart - 8; gx += 16) {
            canvas.drawLine(Offset(gx, centerY - 2), Offset(gx, centerY + 2), mechaLine);
          }
        }
        break;

      case CueAnimeConcept.sakuraZen:
        // Cánh hoa anh đào vàng kim bay trên ngọn
        final sakuraPaint = Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.85);
        for (double sx = shaftXStart + 12; sx < xFerruleStart - 8; sx += 18) {
          canvas.drawOval(
            Rect.fromCenter(center: Offset(sx, centerY + (sx.toInt() % 2 == 0 ? 0.8 : -0.8)), width: 3.5, height: 1.8),
            sakuraPaint,
          );
        }
        break;

      case CueAnimeConcept.shadowVoid:
        final shadowLine = Paint()..color = const Color(0xFFBA68C8).withValues(alpha: 0.85)..strokeWidth = 1.0;
        canvas.drawLine(Offset(shaftXStart, centerY), Offset(xFerruleStart, centerY), shadowLine);
        break;

      case CueAnimeConcept.frostCryo:
        final iceLine = Paint()..color = const Color(0xFF80D8FF).withValues(alpha: 0.90)..strokeWidth = 1.0;
        canvas.drawLine(Offset(shaftXStart, centerY), Offset(xFerruleStart, centerY), iceLine);
        break;

      case CueAnimeConcept.classic:
        break;
    }

    // 5. PHÍP CƠ TRẮNG NGÀ (White Ferrule) & VÒNG KIM LOẠI
    drawCylinderSegment(
      x1: xFerruleStart,
      x2: xShaftTip,
      r1: ferruleRadius,
      r2: tipRadius,
      colors: const [Color(0xFFE8E8E8), Color(0xFFFFFFFF), Color(0xFFC0C0C0)],
    );

    // Chỉ vàng nẹp chân phíp nếu Lv >= 5
    if (level >= 5) {
      canvas.drawLine(
        Offset(xFerruleStart, centerY - ferruleRadius),
        Offset(xFerruleStart, centerY + ferruleRadius),
        Paint()..color = const Color(0xFFFFD54F)..strokeWidth = 1.0,
      );
    }

    // 6. ĐẦU CƠ (Tip)
    final tipPaint = Paint()..color = cue.tipColor;
    if (cue.animeConcept == CueAnimeConcept.arcaneMagic) {
      // Đầu pha lê tinh tú hình thoi
      final crystal = Path()
        ..moveTo(xShaftTip, centerY - tipRadius)
        ..lineTo(xShaftTip + 5.5, centerY)
        ..lineTo(xShaftTip, centerY + tipRadius)
        ..close();
      canvas.drawPath(crystal, tipPaint);
      canvas.drawPath(crystal, Paint()..color = Colors.white.withValues(alpha: 0.8)..style = PaintingStyle.stroke..strokeWidth = 0.6);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(xShaftTip, centerY - tipRadius, 4.0, tipRadius * 2),
          const Radius.circular(1.5),
        ),
        tipPaint,
      );
    }

    // Điểm nhấn sao/lửa nếu là gậy cấp cao (Lv. 8 - 10)
    if (level >= 8) {
      final sparkPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.95)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(xShaftTip + 2.5, centerY), 2.0, sparkPaint);
    }

    // 7. ĐỆM CAO SU CHỐNG VA ĐẬP & VIÊN ĐÁ QUÝ KHẢM ĐUÔI CHUÔI CƠ (Butt Gemstone Bezel)
    final bumperPath = Path()
      ..moveTo(xHandleStart, centerY - handleRadius)
      ..arcToPoint(
        Offset(xButtEnd, centerY),
        radius: Radius.circular(handleRadius),
        clockwise: false,
      )
      ..arcToPoint(
        Offset(xHandleStart, centerY + handleRadius),
        radius: Radius.circular(handleRadius),
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
        CueAnimeConcept.shadowVoid => const Color(0xFF7C4DFF),    // Ngọc hắc ám
        CueAnimeConcept.mechaGundam => const Color(0xFF76FF03),   // Hạt nhân xanh
        CueAnimeConcept.sakuraZen => const Color(0xFFFF80AB),     // Thạch anh hồng
        CueAnimeConcept.frostCryo => const Color(0xFF80D8FF),     // Lam ngọc
        CueAnimeConcept.classic => const Color(0xFFFFD54F),
      };

      // Đĩa kim loại đỡ ngọc dát vàng
      canvas.drawCircle(Offset(xButtEnd + 3.0, centerY), handleRadius * 0.65, Paint()..color = const Color(0xFFFFD54F));
      // Viên đá quý phát quang
      canvas.drawCircle(Offset(xButtEnd + 3.0, centerY), handleRadius * 0.45, Paint()..color = gemColor);
      canvas.drawCircle(Offset(xButtEnd + 2.2, centerY - 1.0), handleRadius * 0.16, Paint()..color = Colors.white.withValues(alpha: 0.90));

      // Lv == 10: Tinh thể kim cương lấp lánh (Max God-Tier Star Glint)
      if (level == 10) {
        final starPaint = Paint()..color = Colors.white..strokeWidth = 0.8;
        canvas.drawLine(Offset(xButtEnd + 3.0 - 3.5, centerY), Offset(xButtEnd + 3.0 + 3.5, centerY), starPaint);
        canvas.drawLine(Offset(xButtEnd + 3.0, centerY - 3.5), Offset(xButtEnd + 3.0, centerY + 3.5), starPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HorizontalCuePreviewPainter oldDelegate) {
    return oldDelegate.cue.id != cue.id || oldDelegate.level != level;
  }
}
