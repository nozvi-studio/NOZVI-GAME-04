import 'package:flutter/material.dart';
import '../../models/enums.dart';
import '../../logic/player_economy_service.dart';
import '../painters/kawaii_25d_renderer.dart';

/// Tab 1 - Cửa Hàng & Kho Skin (4 Bộ Skin + Nâng cấp Búa & La Bàn khởi đầu)
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlayerEconomyService.instance,
      builder: (context, _) {
        final economy = PlayerEconomyService.instance;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner Cửa Hàng
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9E633A), Color(0xFF6D4226)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFD84D), width: 1.5),
                ),
                child: Row(
                  children: [
                    const Text('🛍️', style: TextStyle(fontSize: 30)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CỬA HÀNG & KHO SKIN',
                            style: TextStyle(color: Color(0xFFFFD84D), fontWeight: FontWeight.w900, fontSize: 15),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Mở khóa 4 bộ Skin 2.5D và nâng cấp Cổ Vật đầu trận!',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Phần 1: Kho 4 Bộ Skin
              const Text(
                'BỘ SƯU TẬP SKIN KHỐI GẠCH (4 CHỦ ĐỀ)',
                style: TextStyle(color: Color(0xFFFFD84D), fontWeight: FontWeight.bold, fontSize: 12.5, letterSpacing: 0.6),
              ),
              const SizedBox(height: 10),

              for (final skin in GameSkinTheme.values) ...[
                _buildSkinCard(context, economy, skin),
                const SizedBox(height: 10),
              ],

              const SizedBox(height: 12),

              // Phần 2: Nâng cấp Cổ Vật Khởi Đầu
              const Text(
                'NÂNG CẤP CỔ VẬT KHỞI ĐẦU TRẬN',
                style: TextStyle(color: Color(0xFF4FC3F7), fontWeight: FontWeight.bold, fontSize: 12.5, letterSpacing: 0.6),
              ),
              const SizedBox(height: 10),

              _buildUpgradeCard(
                context: context,
                emoji: '🔨',
                title: 'Búa Rèn Lửa Khởi Đầu',
                subtitle: 'Vào trận có sẵn +${economy.starterHammerCharges} vạch sạc Búa 3x3',
                level: economy.starterHammerLevel,
                maxLevel: 3,
                cost: economy.getHammerUpgradeCost(),
                canAfford: economy.coins >= economy.getHammerUpgradeCost(),
                onUpgrade: () async {
                  final ok = await economy.upgradeStarterHammer();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok ? '🔨 Đã nâng cấp Búa Rèn Lửa lên Cấp ${economy.starterHammerLevel}!' : 'Không đủ Xu Vàng!'),
                        backgroundColor: ok ? const Color(0xFF2D8512) : const Color(0xFFA82419),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 10),
              _buildUpgradeCard(
                context: context,
                emoji: '🧭',
                title: 'La Bàn Gió Khởi Đầu',
                subtitle: 'Vào trận có sẵn +${economy.starterCompassCharges} vạch sạc La Bàn xoay khối',
                level: economy.starterCompassLevel,
                maxLevel: 2,
                cost: economy.getCompassUpgradeCost(),
                canAfford: economy.coins >= economy.getCompassUpgradeCost(),
                onUpgrade: () async {
                  final ok = await economy.upgradeStarterCompass();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok ? '🧭 Đã nâng cấp La Bàn Gió lên Cấp ${economy.starterCompassLevel}!' : 'Không đủ Xu Vàng!'),
                        backgroundColor: ok ? const Color(0xFF2D8512) : const Color(0xFFA82419),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkinCard(BuildContext context, PlayerEconomyService economy, GameSkinTheme skin) {
    final bool isUnlocked = economy.unlockedSkins.contains(skin);
    final bool isEquipped = economy.activeSkin == skin;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEquipped ? const Color(0xFF2D8512).withValues(alpha: 0.25) : const Color(0xFF263238),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEquipped ? const Color(0xFF81E659) : Colors.white12,
          width: isEquipped ? 2.0 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Xem trước 2x2 trực tiếp bằng Kawaii25DRenderer
          Container(
            width: 68,
            height: 68,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFF4A2E1B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF9E633A)),
            ),
            child: CustomPaint(
              painter: _SkinPreview2x2Painter(skin: skin),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(skin.badgeEmoji, style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        skin.title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  skin.description,
                  style: const TextStyle(color: Colors.white60, fontSize: 10.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                if (isEquipped)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4BC226),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '✓ ĐANG TRANG BỊ',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10.5),
                    ),
                  )
                else if (isUnlocked)
                  SizedBox(
                    height: 30,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FC3F7),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      onPressed: () => economy.equipSkin(skin),
                      child: const Text('TRANG BỊ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      SizedBox(
                        height: 30,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD84D),
                            foregroundColor: const Color(0xFF3B2314),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onPressed: () async {
                            final ok = await economy.buySkinWithCoins(skin);
                            if (context.mounted && !ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Chưa đủ Xu Vàng!'), backgroundColor: Color(0xFFA82419)),
                              );
                            }
                          },
                          child: Text('🪙 ${skin.priceCoins}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                        ),
                      ),
                      SizedBox(
                        height: 30,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4FC3F7),
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onPressed: () async {
                            final ok = await economy.buySkinWithGems(skin);
                            if (context.mounted && !ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Chưa đủ Ngọc!'), backgroundColor: Color(0xFFA82419)),
                              );
                            }
                          },
                          child: Text('💎 ${skin.priceGems}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
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
  }

  Widget _buildUpgradeCard({
    required BuildContext context,
    required String emoji,
    required String title,
    required String subtitle,
    required int level,
    required int maxLevel,
    required int cost,
    required bool canAfford,
    required VoidCallback onUpgrade,
  }) {
    final bool isMax = level >= maxLevel;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF263238),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF3B2314),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF9E633A)),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$title (Lv.$level/$maxLevel)',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          isMax
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF2D8512), borderRadius: BorderRadius.circular(10)),
                  child: const Text('TỐI ĐA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                )
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canAfford ? const Color(0xFFFFD84D) : Colors.white12,
                    foregroundColor: canAfford ? const Color(0xFF3B2314) : Colors.white38,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onPressed: onUpgrade,
                  child: Text('🪙 $cost', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                ),
        ],
      ),
    );
  }
}

class _SkinPreview2x2Painter extends CustomPainter {
  final GameSkinTheme skin;
  const _SkinPreview2x2Painter({required this.skin});

  @override
  void paint(Canvas canvas, Size size) {
    final double cell = size.width / 2;
    const colors = [PetColor.red, PetColor.yellow, PetColor.blue, PetColor.green];
    for (int i = 0; i < 4; i++) {
      final int r = i ~/ 2;
      final int c = i % 2;
      final rect = Rect.fromLTWH(c * cell + 1, r * cell + 1, cell - 2, cell - 2);
      Kawaii25DRenderer.drawBlock(canvas, rect, colors[i], skin: skin, animateIdle: false);
    }
  }

  @override
  bool shouldRepaint(covariant _SkinPreview2x2Painter oldDelegate) => oldDelegate.skin != skin;
}

