import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/enums.dart';
import '../../logic/player_economy_service.dart';
import '../../core/pentatonic_audio_synth.dart';

/// Màn hình 4: SKIN & CỔ VẬT (Skins & Relics)
/// Tái tạo chuẩn xác 100% theo Mockup:
/// 1. Biển gỗ treo "4. SKIN & CỔ VẬT (Skins & Relics)"
/// 2. Đài trưng bày Boss Corgi & Pets 2.5D trên bục gỗ xoay tròn kèm đèn rọi Spotlight
/// 3. Khay thẻ Skin: "Jelly Pudding" (thạch núng nính) & "RGB Keycap" (bàn phím cơ phát sáng)
/// 4. Khay Cổ Vật "Relics" gồm 3 thẻ: Búa Rèn Lửa Lv.3, La Bàn Gió Lv.2, Lăng Kính Từ Lv.2
class ShopScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const ShopScreen({super.key, this.onBack});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlayerEconomyService.instance,
      builder: (context, _) {
        final economy = PlayerEconomyService.instance;

        return Scaffold(
          backgroundColor: const Color(0xFF78C058), // Nền xanh lá diorama mát mắt như mockup
          body: SafeArea(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                final double t = _animController.value;
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Column(
                    children: [
                      // 1. Header Biển gỗ treo & Nút Cài đặt
                      _buildHeaderBar(context, economy),
                      const SizedBox(height: 10),

                      // 2. Đài trưng bày 2.5D Boss Corgi & Pets trên bục gỗ có đèn rọi
                      _buildShowcaseStage(t, economy),
                      const SizedBox(height: 12),

                      // 3. Khay bộ sưu tập Skin: Jelly Pudding & RGB Keycap
                      _buildSkinCollectionTray(context, economy, t),
                      const SizedBox(height: 14),

                      // 4. Khay 3 Cổ Vật "Relics" (Búa, La Bàn, Lăng Kính)
                      _buildRelicsTray(context, economy),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // 1. HEADER BIỂN GỖ TREO
  // ==========================================
  Widget _buildHeaderBar(BuildContext context, PlayerEconomyService economy) {
    return Row(
      children: [
        // Nút Back mũi tên gỗ
        GestureDetector(
          onTap: widget.onBack ?? () => Navigator.maybePop(context),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE4A670), Color(0xFF9E633A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF5A3317), width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0x60000000), offset: Offset(0, 3), blurRadius: 4),
              ],
            ),
            child: const Center(
              child: Icon(Icons.arrow_back_rounded, color: Color(0xFFFFF9E6), size: 24),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Biển gỗ treo ở giữa: "4. SKIN & CỔ VẬT (Skins & Relics)"
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFDE9F67), Color(0xFFA66436)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF542E13), width: 2.2),
              boxShadow: const [
                BoxShadow(color: Color(0x60000000), offset: Offset(0, 4), blurRadius: 5),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Hai dây treo biển
                Positioned(
                  top: -8,
                  left: 24,
                  child: Container(width: 3.5, height: 10, color: const Color(0xFF542E13)),
                ),
                Positioned(
                  top: -8,
                  right: 24,
                  child: Container(width: 3.5, height: 10, color: const Color(0xFF542E13)),
                ),
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: '4. SKIN & CỔ VẬT\n',
                          style: TextStyle(
                            color: Color(0xFFFFF7D6),
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            height: 1.1,
                            shadows: [Shadow(color: Color(0xFF4A250B), offset: Offset(0, 1.5), blurRadius: 2)],
                          ),
                        ),
                        TextSpan(
                          text: '(Skins & Relics)',
                          style: TextStyle(
                            color: Color(0xFFFFD54F),
                            fontWeight: FontWeight.w800,
                            fontSize: 10.5,
                            shadows: [Shadow(color: Color(0xFF4A250B), offset: Offset(0, 1), blurRadius: 1)],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Nút Cúp Vàng Cài Đặt
        GestureDetector(
          onTap: () => _showSettingsDialog(context, economy),
          child: Container(
            width: 44,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF01579B), width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0x60000000), offset: Offset(0, 3), blurRadius: 4),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🏆', style: TextStyle(fontSize: 16)),
                Text(
                  'Cài đặt',
                  style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 2. ĐÀI TRƯNG BÀY BOSS CORGI & PETS
  // ==========================================
  Widget _buildShowcaseStage(double t, PlayerEconomyService economy) {
    return Container(
      width: double.infinity,
      height: 190,
      decoration: BoxDecoration(
        color: const Color(0xFF8D5531),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF542E13), width: 3.5),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), offset: Offset(0, 6), blurRadius: 8),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Nền hốc gỗ vòm lưng cong 2.5D
          Positioned.fill(
            child: CustomPaint(
              painter: _ShowcaseAlcovePainter(),
            ),
          ),

          // Đèn rọi Spotlight + Bục gỗ xoay tròn + Boss Corgi 2.5D
          Positioned.fill(
            child: CustomPaint(
              painter: _BossCorgiShowcasePainter(
                progress: t,
                activeSkin: economy.activeSkin,
              ),
            ),
          ),

          // Biển tên cong phía dưới: "Boss Corgi & Pets"
          Positioned(
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDE9F67), Color(0xFFA66436)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF542E13), width: 2),
                boxShadow: const [
                  BoxShadow(color: Color(0x60000000), offset: Offset(0, 3), blurRadius: 4),
                ],
              ),
              child: Text(
                economy.activeSkin == GameSkinTheme.kawaiiPets
                    ? 'Boss Corgi & Pets'
                    : economy.activeSkin.title,
                style: const TextStyle(
                  color: Color(0xFFFFF9E6),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.5,
                  shadows: [Shadow(color: Color(0xFF4A250B), offset: Offset(0, 1.5), blurRadius: 2)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. KHAY BỘ SƯU TẬP SKIN: JELLY & RGB KEYCAP
  // ==========================================
  Widget _buildSkinCollectionTray(BuildContext context, PlayerEconomyService economy, double t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF6B3E21), // Khung gỗ ấm sẫm màu
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4A2610), width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), offset: Offset(0, 5), blurRadius: 6),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Thẻ 1: Jelly Pudding
              Expanded(
                child: _buildSingleSkinCard(
                  context: context,
                  economy: economy,
                  skin: GameSkinTheme.jellyCandy,
                  displayTitle: 'Jelly Pudding',
                  hasPreviewIcon: true,
                  customPainter: _JellyPuddingPreviewPainter(animValue: t),
                  progressText: null,
                ),
              ),
              const SizedBox(width: 10),

              // Thẻ 2: RGB Keycap
              Expanded(
                child: _buildSingleSkinCard(
                  context: context,
                  economy: economy,
                  skin: GameSkinTheme.rgbMechanical,
                  displayTitle: 'RGB Keycap',
                  hasPreviewIcon: false,
                  customPainter: _RgbKeycapPreviewPainter(animValue: t),
                  progressText: '24/30 Vòng',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Dải nút chuyển đổi nhanh giữa các Skin khác (Mạt Chược & Kawaii Pets)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMiniSkinPill(economy, GameSkinTheme.kawaiiPets, '🐶 Corgi Cổ Điển'),
              const SizedBox(width: 8),
              _buildMiniSkinPill(economy, GameSkinTheme.jadeMahjong, '🀄 Mạt Chược Ngọc'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniSkinPill(PlayerEconomyService economy, GameSkinTheme skin, String label) {
    final bool isEquipped = economy.activeSkin == skin;
    return GestureDetector(
      onTap: () => economy.equipSkin(skin),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isEquipped ? const Color(0xFFFFD84D) : const Color(0xFF502D17),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isEquipped ? Colors.white : Colors.white24, width: 1.2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isEquipped ? const Color(0xFF3B2314) : Colors.white70,
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSingleSkinCard({
    required BuildContext context,
    required PlayerEconomyService economy,
    required GameSkinTheme skin,
    required String displayTitle,
    required bool hasPreviewIcon,
    required CustomPainter customPainter,
    required String? progressText,
  }) {
    final bool isEquipped = economy.activeSkin == skin;
    final bool isUnlocked = economy.unlockedSkins.contains(skin);

    return Container(
      height: 165,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0), // Nền thẻ kem tươi sáng chuẩn diorama
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEquipped ? const Color(0xFFFF9800) : const Color(0xFFDE9F67),
          width: isEquipped ? 2.8 : 1.8,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x30000000), offset: Offset(0, 3), blurRadius: 4),
        ],
      ),
      child: Column(
        children: [
          // Khu vực xem trước 2.5D
          Expanded(
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: 90,
                    height: 80,
                    child: CustomPaint(painter: customPainter),
                  ),
                ),
                if (hasPreviewIcon)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDE9F67),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF4A250B), size: 14),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Tên Skin
          Text(
            displayTitle,
            style: const TextStyle(
              color: Color(0xFF4E260E),
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 4),

          // Thanh tiến trình hoặc nút hành động
          if (progressText != null && !isUnlocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF29B6F6), Color(0xFF0288D1)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  progressText,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            )
          else if (isEquipped)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  '✓ ĐANG DÙNG',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10),
                ),
              ),
            )
          else if (isUnlocked)
            SizedBox(
              width: double.infinity,
              height: 24,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9800),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => economy.equipSkin(skin),
                child: const Text('TRANG BỊ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10.5)),
              ),
            )
          else
            GestureDetector(
              onTap: () async {
                final ok = await economy.buySkinWithCoins(skin);
                if (context.mounted && !ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chưa đủ Xu Vàng!'), backgroundColor: Color(0xFFA82419)),
                  );
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFFD54F), Color(0xFFFF9800)]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [BoxShadow(color: Color(0x30000000), offset: Offset(0, 1.5))],
                ),
                child: Center(
                  child: Text(
                    '🪙 ${skin.priceCoins}',
                    style: const TextStyle(color: Color(0xFF3B2314), fontWeight: FontWeight.w900, fontSize: 11),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. KHAY CỔ VẬT "RELICS" (3 THẺ CỔ VẬT)
  // ==========================================
  Widget _buildRelicsTray(BuildContext context, PlayerEconomyService economy) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF6B3E21),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4A2610), width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), offset: Offset(0, 5), blurRadius: 6),
        ],
      ),
      child: Column(
        children: [
          // Header thẻ bài cong: "Relics"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFDE9F67), Color(0xFFA66436)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: const Text(
              'Relics',
              style: TextStyle(
                color: Color(0xFFFFF9E6),
                fontWeight: FontWeight.w900,
                fontSize: 12,
                shadows: [Shadow(color: Color(0xFF4A250B), offset: Offset(0, 1), blurRadius: 1)],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 3 Thẻ bài cổ vật hình vuông cạnh bo tròn
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
            child: Row(
              children: [
                // Thẻ 1: Búa Rèn Lửa Lv.3 (Màu cam ấm)
                Expanded(
                  child: _buildRelicCard(
                    context: context,
                    iconEmoji: '🔨',
                    name: 'Búa Rèn Lửa',
                    level: economy.starterHammerLevel,
                    maxLevel: 3,
                    bgGradient: const [Color(0xFFFFB74D), Color(0xFFE65100)],
                    cost: economy.getHammerUpgradeCost(),
                    canAfford: economy.coins >= economy.getHammerUpgradeCost(),
                    onUpgrade: () async {
                      final ok = await economy.upgradeStarterHammer();
                      if (context.mounted && ok) {
                        PentatonicAudioSynth.instance.playPopSound(0.9);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Thẻ 2: La Bàn Gió Lv.2 (Màu xanh lá tươi)
                Expanded(
                  child: _buildRelicCard(
                    context: context,
                    iconEmoji: '🧭',
                    name: 'La Bàn Gió',
                    level: economy.starterCompassLevel,
                    maxLevel: 2,
                    bgGradient: const [Color(0xFF81C784), Color(0xFF2E7D32)],
                    cost: economy.getCompassUpgradeCost(),
                    canAfford: economy.coins >= economy.getCompassUpgradeCost(),
                    onUpgrade: () async {
                      final ok = await economy.upgradeStarterCompass();
                      if (context.mounted && ok) {
                        PentatonicAudioSynth.instance.playPopSound(1.0);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Thẻ 3: Lăng Kính Từ Lv.2 (Màu tím ruby ánh pha lê)
                Expanded(
                  child: _buildRelicCard(
                    context: context,
                    iconEmoji: '💎',
                    name: 'Lăng Kính Từ',
                    level: economy.starterMagnetLevel,
                    maxLevel: 2,
                    bgGradient: const [Color(0xFFF48FB1), Color(0xFF880E4F)],
                    cost: economy.getMagnetUpgradeCost(),
                    canAfford: economy.coins >= economy.getMagnetUpgradeCost(),
                    onUpgrade: () async {
                      final ok = await economy.upgradeStarterMagnet();
                      if (context.mounted && ok) {
                        PentatonicAudioSynth.instance.playPopSound(1.1);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelicCard({
    required BuildContext context,
    required String iconEmoji,
    required String name,
    required int level,
    required int maxLevel,
    required List<Color> bgGradient,
    required int cost,
    required bool canAfford,
    required VoidCallback onUpgrade,
  }) {
    final bool isMax = level >= maxLevel;

    return GestureDetector(
      onTap: isMax ? null : onUpgrade,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bgGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 1.8),
          boxShadow: const [
            BoxShadow(color: Color(0x35000000), offset: Offset(0, 3), blurRadius: 4),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Cổ vật 3D
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
              ),
              child: Center(
                child: Text(iconEmoji, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(height: 4),

            // Tên Cổ vật
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 10.5,
                shadows: [Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 2)],
              ),
            ),

            // Cấp độ: Lv.X
            Text(
              isMax ? 'Lv.$level (MAX)' : 'Lv.$level',
              style: const TextStyle(
                color: Color(0xFFFFF9C4),
                fontWeight: FontWeight.bold,
                fontSize: 9.5,
              ),
            ),
            const SizedBox(height: 2),

            // Chi phí nâng cấp
            if (!isMax)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '🪙 $cost',
                  style: TextStyle(
                    color: canAfford ? const Color(0xFFFFD54F) : Colors.white60,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, PlayerEconomyService economy) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF263238),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('CÀI ĐẶT TRÒ CHƠI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Âm nhạc nền (BGM)', style: TextStyle(color: Colors.white, fontSize: 13)),
              value: economy.bgmEnabled,
              activeColor: const Color(0xFFFFD84D),
              onChanged: (val) => economy.setBgmEnabled(val),
            ),
            SwitchListTile(
              title: const Text('Hiệu ứng âm thanh (SFX)', style: TextStyle(color: Colors.white, fontSize: 13)),
              value: economy.sfxEnabled,
              activeColor: const Color(0xFFFFD84D),
              onChanged: (val) => economy.setSfxEnabled(val),
            ),
            SwitchListTile(
              title: const Text('Rung phản hồi (Haptics)', style: TextStyle(color: Colors.white, fontSize: 13)),
              value: economy.hapticsEnabled,
              activeColor: const Color(0xFFFFD84D),
              onChanged: (val) => economy.setHapticsEnabled(val),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD84D), foregroundColor: Colors.black87),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ĐÓNG'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// PAINTERS 2.5D VECTOR CHO SHOP & STAGE
// ==========================================

/// Vẽ vòm lưng gỗ cong 2.5D của hốc trưng bày
class _ShowcaseAlcovePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Các thanh nan gỗ ghép cong
    final bgPaint = Paint()..color = const Color(0xFF6B3E21);
    final borderPaint = Paint()
      ..color = const Color(0xFF502D17)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final double plankW = size.width / 7;
    for (int i = 0; i < 7; i++) {
      final rect = Rect.fromLTWH(i * plankW, 0, plankW, size.height);
      canvas.drawRect(rect, bgPaint);
      canvas.drawRect(rect, borderPaint);
    }

    // Hiệu ứng đổ bóng vignette mềm trong hốc
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.35)],
        stops: const [0.65, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vignettePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Vẽ đài bục xoay 2.5D, luồng đèn rọi Spotlight & Boss Corgi 2.5D
class _BossCorgiShowcasePainter extends CustomPainter {
  final double progress;
  final GameSkinTheme activeSkin;

  _BossCorgiShowcasePainter({required this.progress, required this.activeSkin});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.58);

    // 1. Luồng sáng Spotlight hình nón rọi từ trên cao xuống bục
    final spotPath = Path()
      ..moveTo(size.width * 0.38, 0)
      ..lineTo(size.width * 0.62, 0)
      ..lineTo(center.dx + 80, center.dy + 15)
      ..lineTo(center.dx - 80, center.dy + 15)
      ..close();

    final spotPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFFF9C4).withValues(alpha: 0.45),
          const Color(0xFFFFF9C4).withValues(alpha: 0.08),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(spotPath, spotPaint);

    // 2. Bục gỗ tròn xoay 2.5D (Ellipse đĩa kép)
    final double ovalW = 140;
    final double ovalH = 50;

    // Bóng đĩa bục
    canvas.drawOval(
      Rect.fromCenter(center: center.translate(0, 14), width: ovalW + 10, height: ovalH),
      Paint()..color = const Color(0x55000000),
    );

    // Viền thành gỗ bục dưới (Extrusion)
    canvas.drawOval(
      Rect.fromCenter(center: center.translate(0, 8), width: ovalW, height: ovalH),
      Paint()..color = const Color(0xFF7A4422),
    );

    // Mặt đĩa bục gỗ trên (Caramel Oak)
    canvas.drawOval(
      Rect.fromCenter(center: center, width: ovalW, height: ovalH),
      Paint()..color = const Color(0xFFE4A670),
    );

    // Vòng chỉ viền vàng sáng trên mặt đĩa
    canvas.drawOval(
      Rect.fromCenter(center: center, width: ovalW - 14, height: ovalH - 8),
      Paint()
        ..color = const Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // 3. Nhân vật Boss Corgi 2.5D đáng yêu đứng giữa bục
    final double bobY = math.sin(progress * 2 * math.pi) * 3.5;
    final corgiCenter = center.translate(0, -22 + bobY);

    _drawIsometricBossCorgi(canvas, corgiCenter, progress);
  }

  void _drawIsometricBossCorgi(Canvas canvas, Offset pos, double t) {
    // Bóng dưới chân corgi
    canvas.drawOval(
      Rect.fromCenter(center: pos.translate(0, 26), width: 56, height: 20),
      Paint()..color = const Color(0x40000000),
    );

    // Thân khối gạch Corgi 2.5D vuông vắn
    final Rect bodyRect = Rect.fromCenter(center: pos, width: 48, height: 44);
    final RRect bodyRRect = RRect.fromRectAndRadius(bodyRect, const Radius.circular(14));

    // Thân cam Corgi
    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF8A65), Color(0xFFE64A19)],
        ).createShader(bodyRect),
    );

    // Bụng và ngực trắng
    final Rect chestRect = Rect.fromLTWH(pos.dx - 16, pos.dy - 6, 32, 28);
    canvas.drawRRect(
      RRect.fromRectAndRadius(chestRect, const Radius.circular(10)),
      Paint()..color = Colors.white,
    );

    // 2 Tai nhọn dựng thẳng đứng với lòng tai hồng
    _drawCorgiEar(canvas, pos.translate(-16, -22), isLeft: true);
    _drawCorgiEar(canvas, pos.translate(16, -22), isLeft: false);

    // Mõm trắng và mũi đen
    final Rect muzzleRect = Rect.fromCenter(center: pos.translate(0, 4), width: 22, height: 16);
    canvas.drawOval(muzzleRect, Paint()..color = Colors.white);
    canvas.drawCircle(pos.translate(0, 0), 3.5, Paint()..color = const Color(0xFF263238));

    // Lưỡi hồng thè ra cười
    canvas.drawOval(
      Rect.fromCenter(center: pos.translate(0, 7), width: 6, height: 8),
      Paint()..color = const Color(0xFFFF5252),
    );

    // 2 Mắt tròn lấp lánh (chớp mắt tự nhiên)
    final double blink = ((t * 4) % 1.0 > 0.88) ? 0.2 : 1.0;
    _drawAnimeEye(canvas, pos.translate(-10, -6), blink);
    _drawAnimeEye(canvas, pos.translate(10, -6), blink);

    // 2 Má hồng thắm
    canvas.drawCircle(pos.translate(-16, 2), 4, Paint()..color = const Color(0xFFFF8A80).withValues(alpha: 0.65));
    canvas.drawCircle(pos.translate(16, 2), 4, Paint()..color = const Color(0xFFFF8A80).withValues(alpha: 0.65));

    // 4 Chân ngắn ngủi bám bục gỗ
    _drawStubbyPaw(canvas, pos.translate(-14, 21));
    _drawStubbyPaw(canvas, pos.translate(14, 21));
  }

  void _drawCorgiEar(Canvas canvas, Offset tip, {required bool isLeft}) {
    final Path ear = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx + (isLeft ? -10 : 2), tip.dy + 18)
      ..lineTo(tip.dx + (isLeft ? -2 : 10), tip.dy + 18)
      ..close();
    canvas.drawPath(ear, Paint()..color = const Color(0xFFD84315));

    // Lòng tai hồng
    final Path inner = Path()
      ..moveTo(tip.dx, tip.dy + 4)
      ..lineTo(tip.dx + (isLeft ? -6 : 1), tip.dy + 16)
      ..lineTo(tip.dx + (isLeft ? -1 : 6), tip.dy + 16)
      ..close();
    canvas.drawPath(inner, Paint()..color = const Color(0xFFFFAB91));
  }

  void _drawAnimeEye(Canvas canvas, Offset p, double openScale) {
    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.scale(1.0, openScale);
    canvas.drawCircle(Offset.zero, 3.8, Paint()..color = const Color(0xFF263238));
    if (openScale > 0.5) {
      canvas.drawCircle(const Offset(-1.2, -1.2), 1.4, Paint()..color = Colors.white);
    }
    canvas.restore();
  }

  void _drawStubbyPaw(Canvas canvas, Offset p) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 14, height: 10), const Radius.circular(5)),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _BossCorgiShowcasePainter oldDelegate) => true;
}

/// Xem trước 2.5D cho Jelly Pudding (Thạch rau câu núng nính)
class _JellyPuddingPreviewPainter extends CustomPainter {
  final double animValue;
  _JellyPuddingPreviewPainter({required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double wobble = math.sin(animValue * 2 * math.pi) * 0.08;

    canvas.save();
    canvas.translate(center.dx, center.dy + 10);
    canvas.scale(1.0 + wobble, 1.0 - wobble);

    // Đế thạch hình nón cụt bo tròn
    final Path body = Path()
      ..moveTo(-32, 16)
      ..quadraticBezierTo(-34, 18, -30, 20)
      ..lineTo(30, 20)
      ..quadraticBezierTo(34, 18, 32, 16)
      ..lineTo(22, -16)
      ..quadraticBezierTo(20, -20, 16, -20)
      ..lineTo(-16, -20)
      ..quadraticBezierTo(-20, -20, -22, -16)
      ..close();

    // Nước thạch hổ phách trong suốt
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFCA28), Color(0xFFFF8F00)],
        ).createShader(Rect.fromLTWH(-35, -20, 70, 40)),
    );

    // Lớp sốt caramel nâu óng ả trên đỉnh
    final Rect topRect = Rect.fromCenter(center: const Offset(0, -18), width: 38, height: 14);
    canvas.drawOval(
      topRect,
      Paint()..color = const Color(0xFF6D4C41),
    );

    // Vệt sốt caramel chảy xuống cạnh
    final Path drip = Path()
      ..moveTo(-12, -18)
      ..quadraticBezierTo(-10, -8, -8, -6)
      ..quadraticBezierTo(-6, -8, -4, -18)
      ..close();
    canvas.drawPath(drip, Paint()..color = const Color(0xFF6D4C41));

    // Vệt sáng bóng loáng phản chiếu
    final Path shine = Path()
      ..moveTo(14, -12)
      ..lineTo(18, 8)
      ..lineTo(15, 8)
      ..lineTo(11, -12)
      ..close();
    canvas.drawPath(shine, Paint()..color = Colors.white.withValues(alpha: 0.65));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _JellyPuddingPreviewPainter oldDelegate) => true;
}

/// Xem trước 2.5D cho RGB Keycap (Bàn phím cơ chuyển sắc)
class _RgbKeycapPreviewPainter extends CustomPainter {
  final double animValue;
  _RgbKeycapPreviewPainter({required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    canvas.save();
    canvas.translate(center.dx, center.dy);

    // Cụm 4 Keycap isometric xếp cạnh nhau
    final offsets = [
      const Offset(-14, -12),
      const Offset(14, -12),
      const Offset(-14, 12),
      const Offset(14, 12),
    ];

    final colors = [
      HSVColor.fromAHSV(1.0, (animValue * 360) % 360, 0.85, 1.0).toColor(),
      HSVColor.fromAHSV(1.0, (animValue * 360 + 90) % 360, 0.85, 1.0).toColor(),
      HSVColor.fromAHSV(1.0, (animValue * 360 + 180) % 360, 0.85, 1.0).toColor(),
      HSVColor.fromAHSV(1.0, (animValue * 360 + 270) % 360, 0.85, 1.0).toColor(),
    ];

    for (int i = 0; i < 4; i++) {
      final p = offsets[i];
      final c = colors[i];

      // Đèn LED RGB hắt sáng dưới chân phím
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: p.translate(0, 4), width: 26, height: 22), const Radius.circular(6)),
        Paint()
          ..color = c.withValues(alpha: 0.75)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      // Thân phím PBT đen nhám
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: p.translate(0, 2), width: 24, height: 20), const Radius.circular(5)),
        Paint()..color = const Color(0xFF1E272E),
      );

      // Mặt trên Keycap dốc vát
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 20, height: 16), const Radius.circular(4)),
        Paint()..color = const Color(0xFF2F3542),
      );

      // Viền RGB sắc nét trên đỉnh phím
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 20, height: 16), const Radius.circular(4)),
        Paint()
          ..color = c
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RgbKeycapPreviewPainter oldDelegate) => true;
}
