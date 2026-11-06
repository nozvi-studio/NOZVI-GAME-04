import 'package:flutter/material.dart';
import '../services/progression_service.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import 'cue_shop_dialog.dart';
import 'table_shop_dialog.dart';
import 'auth_dialog.dart';
import 'leaderboard_dialog.dart';
import 'player_profile_dialog.dart';
import 'achievements_dialog.dart';
import '../models/medal_model.dart';

class PlayerProfileBar extends StatelessWidget {
  final bool compact;
  final bool showShopButton;

  const PlayerProfileBar({
    super.key,
    this.compact = false,
    this.showShopButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ProgressionService.instance,
        AuthService.instance,
        LanguageService.instance,
      ]),
      builder: (context, _) {
        final auth = AuthService.instance;
        final service = ProgressionService.instance;
        final level = service.playerLevel;
        final xp = service.currentXP;
        final nextXp = service.xpRequiredForNextLevel;
        final progress = service.xpProgress;
        final coins = service.coins;
        final diamonds = service.diamonds;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 16,
            vertical: compact ? 4 : 7,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1E18).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: const Color(0xFF26A69A).withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
            children: [
              // 1 & 2. Level Badge & XP Progress Bar (Chạm vào mở Hồ Sơ Profile)
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => const PlayerProfileDialog(),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 8 : 10,
                        vertical: compact ? 4 : 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        'Lv.$level',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w900,
                          fontSize: compact ? 11 : 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: compact ? 70 : 110),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'XP',
                                style: TextStyle(
                                  color: Colors.tealAccent,
                                  fontSize: compact ? 9 : 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '$xp/$nextXp',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: compact ? 8 : 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: compact ? 4 : 7,
                              backgroundColor: Colors.white12,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF00E676),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: compact ? 8 : 12),

              // 3. Vàng (Coins)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 7 : 10,
                  vertical: compact ? 3 : 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.monetization_on,
                      color: const Color(0xFFFFD54F),
                      size: compact ? 16 : 19,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _formatNumber(coins),
                      style: TextStyle(
                        color: const Color(0xFFFFD54F),
                        fontWeight: FontWeight.w900,
                        fontSize: compact ? 11 : 14,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: compact ? 6 : 8),

              // 4. Kim Cương (Diamonds)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 7 : 10,
                  vertical: compact ? 3 : 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF29B6F6).withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.diamond,
                      color: const Color(0xFF29B6F6),
                      size: compact ? 15 : 18,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _formatNumber(diamonds),
                      style: TextStyle(
                        color: const Color(0xFF81D4FA),
                        fontWeight: FontWeight.w900,
                        fontSize: compact ? 11 : 14,
                      ),
                    ),
                  ],
                ),
              ),

              // 4.1. Mini Showcased Medals (Tối đa 5 Huy chương hiển thị trên Profile)
              if (service.showcasedMedals.isNotEmpty) ...[
                SizedBox(width: compact ? 6 : 8),
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => const PlayerProfileDialog(),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 6 : 8,
                      vertical: compact ? 3 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: service.showcasedMedals.take(5).map((mId) {
                        final medal = MedalCatalog.getById(mId);
                        if (medal == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.5),
                          child: Icon(
                            medal.icon,
                            color: medal.rarity.glowColor,
                            size: compact ? 13 : 16,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],

              // 5. Nút mở Cửa hàng (Shop)
              if (showShopButton) ...[
                SizedBox(width: compact ? 6 : 8),
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => const CueShopDialog(),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 8 : 13,
                      vertical: compact ? 4 : 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pinkAccent.withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shopping_bag,
                          color: Colors.white,
                          size: compact ? 13 : 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'shop'.tr.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            fontSize: compact ? 10 : 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: compact ? 4 : 6),
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => const TableShopDialog(),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 7 : 11,
                      vertical: compact ? 4 : 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00897B), Color(0xFF004D40)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.tealAccent.withValues(alpha: 0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.table_restaurant,
                          color: Colors.white,
                          size: compact ? 13 : 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'table_shop'.tr.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            fontSize: compact ? 9.5 : 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // 6. Nút mở Bảng Xếp Hạng (BXH)
              SizedBox(width: compact ? 6 : 8),
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => const LeaderboardDialog(),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 8 : 13,
                    vertical: compact ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: Colors.black87,
                        size: compact ? 13 : 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'rank'.tr.toUpperCase(),
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          fontSize: compact ? 10 : 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 6.5. Nút mở Thành Tựu & Huy Chương
              SizedBox(width: compact ? 6 : 8),
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => const AchievementsDialog(),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 8 : 13,
                    vertical: compact ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C4DFF), Color(0xFF536DFE)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurpleAccent.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.military_tech,
                        color: Colors.white,
                        size: compact ? 13 : 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'medals'.tr.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          fontSize: compact ? 10 : 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 7. Nút Tài khoản / Đăng nhập
              SizedBox(width: compact ? 6 : 8),
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => const AuthDialog(),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 8 : 13,
                    vertical: compact ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: auth.isLoggedIn
                          ? (auth.isAdmin
                              ? [const Color(0xFFFFD54F), const Color(0xFFFFA000)]
                              : [const Color(0xFF00B0FF), const Color(0xFF0288D1)])
                          : [const Color(0xFF26A69A), const Color(0xFF00796B)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: (auth.isLoggedIn && auth.isAdmin ? Colors.amber : Colors.cyan)
                            .withValues(alpha: 0.35),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        auth.isLoggedIn
                            ? (auth.isAdmin ? Icons.shield : Icons.person)
                            : Icons.login,
                        color: auth.isLoggedIn && auth.isAdmin ? Colors.black87 : Colors.white,
                        size: compact ? 13 : 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        auth.isLoggedIn
                            ? (auth.isAdmin
                                ? 'ADMIN'
                                : (auth.isGuest ? 'guest_offline'.tr : auth.displayName))
                            : 'login'.tr,
                        style: TextStyle(
                          color: auth.isLoggedIn && auth.isAdmin ? Colors.black87 : Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          fontSize: compact ? 10 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      },
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
