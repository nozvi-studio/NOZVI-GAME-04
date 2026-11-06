import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';

class LeaderboardDialog extends StatefulWidget {
  const LeaderboardDialog({super.key});

  @override
  State<LeaderboardDialog> createState() => _LeaderboardDialogState();
}

class _LeaderboardDialogState extends State<LeaderboardDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _levelRankings = [];
  List<Map<String, dynamic>> _coinsRankings = [];
  List<Map<String, dynamic>> _winsRankings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllRankings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllRankings() async {
    setState(() => _isLoading = true);
    final auth = AuthService.instance;

    // Luôn đồng bộ chỉ số mới nhất của người chơi trước khi tải BXH
    await auth.syncCurrentPlayerStats();

    final levels = await auth.getRanking(category: 'level');
    final coins = await auth.getRanking(category: 'coins');
    final wins = await auth.getRanking(category: 'wins');

    if (mounted) {
      setState(() {
        _levelRankings = levels;
        _coinsRankings = coins;
        _winsRankings = wins;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: math.min(MediaQuery.of(context).size.width * 0.94, 680.0),
          maxHeight: math.min(screenHeight * 0.94, 600.0),
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F1E19), Color(0xFF132A22), Color(0xFF0B1713)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFFB300).withValues(alpha: 0.6),
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black87, blurRadius: 30, offset: Offset(0, 8)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF081410),
                  border: Border(bottom: BorderSide(color: Colors.white12)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Color(0xFFFFD54F), size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'leaderboard_header'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'refresh'.tr,
                      icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                      onPressed: _isLoading ? null : _loadAllRankings,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // TabBar
              Container(
                color: Colors.black26,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFFFFD54F),
                  labelColor: const Color(0xFFFFD54F),
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  tabs: [
                    Tab(icon: const Icon(Icons.military_tech, size: 18), text: 'level'.tr.toUpperCase()),
                    Tab(icon: const Icon(Icons.monetization_on, size: 18), text: 'coins'.tr.toUpperCase()),
                    Tab(icon: const Icon(Icons.workspace_premium, size: 18), text: 'wins'.tr.toUpperCase()),
                  ],
                ),
              ),

              // TabView Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFFFFD54F)),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildRankingList(_levelRankings, 'level', 'level'.tr),
                          _buildRankingList(_coinsRankings, 'coins', 'coins'.tr),
                          _buildRankingList(_winsRankings, 'wins', 'wins'.tr),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildRankingList(
    List<Map<String, dynamic>> items,
    String keyField,
    String unit,
  ) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.white30),
            const SizedBox(height: 10),
            Text(
              'no_leaderboard_data'.tr,
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'leaderboard_empty_hint'.tr,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
            ),
          ],
        ),
      );
    }

    final currentUid = AuthService.instance.currentUser?.uid;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount: items.length,
      separatorBuilder: (_, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final rank = index + 1;
        final name = (item['displayName'] as String?) ?? 'player_default'.tr;
        final role = (item['role'] as String?) ?? 'player';
        final val = (item[keyField] as num?)?.toInt() ?? 0;
        final isMe = (item['uid'] != null && item['uid'] == currentUid) ||
            (item['id'] != null && item['id'] == currentUid);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMe
                ? const Color(0xFF00E676).withValues(alpha: 0.15)
                : Colors.black26,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isMe
                  ? const Color(0xFF00E676)
                  : rank == 1
                      ? const Color(0xFFFFD54F)
                      : Colors.white12,
              width: isMe || rank == 1 ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              // Thứ hạng (Rank Badge)
              _buildRankBadge(rank),
              const SizedBox(width: 12),

              // Avatar & Tên
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: role == 'admin' ? const Color(0xFFFFB300) : Colors.teal.shade800,
                      child: Icon(
                        role == 'admin' ? Icons.shield : Icons.person,
                        size: 18,
                        color: role == 'admin' ? Colors.black87 : Colors.white,
                      ),
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
                                  name,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (role == 'admin') ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFB300),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'ADMIN',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ],
                              if (isMe) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00E676),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'you'.tr.toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Giá trị (Cấp độ / Tiền / Trận thắng)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  keyField == 'coins'
                      ? '${_formatNumber(val)} ${'coins_unit'.tr}'
                      : keyField == 'level'
                          ? '${'level_short'.tr} $val'
                          : '$val ${'wins_unit'.tr}',
                  style: TextStyle(
                    color: keyField == 'coins'
                        ? const Color(0xFFFFD54F)
                        : keyField == 'level'
                            ? const Color(0xFF00B0FF)
                            : const Color(0xFF00E676),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRankBadge(int rank) {
    if (rank == 1) {
      return const CircleAvatar(
        radius: 13,
        backgroundColor: Color(0xFFFFD700),
        child: Text('1', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 13)),
      );
    } else if (rank == 2) {
      return const CircleAvatar(
        radius: 13,
        backgroundColor: Color(0xFFE0E0E0),
        child: Text('2', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 13)),
      );
    } else if (rank == 3) {
      return const CircleAvatar(
        radius: 13,
        backgroundColor: Color(0xFFCD7F32),
        child: Text('3', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 13)),
      );
    } else {
      return SizedBox(
        width: 26,
        child: Text(
          '#$rank',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      );
    }
  }

  static String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}
