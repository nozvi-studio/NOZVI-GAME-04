import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/table_skin_model.dart';
import '../services/language_service.dart';
import '../services/progression_service.dart';
import 'table_skin_component.dart';

/// Hộp thoại Cửa Hàng Bàn Bida với 20 mẫu bàn đa dạng phẩm cấp, chuẩn Mobile
class TableShopDialog extends StatefulWidget {
  const TableShopDialog({super.key});

  @override
  State<TableShopDialog> createState() => _TableShopDialogState();
}

class _TableShopDialogState extends State<TableShopDialog> {
  late String _selectedTableId;
  TableRarity? _filterRarity;
  String? _toastMessage;
  bool _toastIsError = false;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    _selectedTableId = ProgressionService.instance.equippedTableId;
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  void _showToast(String message, {bool isError = false}) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
      _toastIsError = isError;
    });
    _toastTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) {
        setState(() {
          _toastMessage = null;
        });
      }
    });
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
          final selectedTable = TableSkinCatalog.getById(_selectedTableId);
          final isOwned = service.isTableOwned(selectedTable.id);
          final isEquipped = service.isTableEquipped(selectedTable.id);
          final isUnlocked = service.canUnlockTable(selectedTable);
          final screenHeight = MediaQuery.of(context).size.height;
          final screenWidth = MediaQuery.of(context).size.width;
          final isLandscape = screenWidth > screenHeight;

          return Container(
            constraints: BoxConstraints(
              maxWidth: math.min(screenWidth * 0.95, 920.0),
              maxHeight: math.min(screenHeight * 0.94, 620.0),
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF13171D), Color(0xFF1A222B), Color(0xFF11171E)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF26A69A), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black87,
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(context, service),
                    _buildRarityFilter(),
                    Expanded(
                      child: isLandscape
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Danh sách chọn 20 bàn bida
                                Expanded(
                                  flex: 5,
                                  child: _buildTableGrid(service),
                                ),
                                Container(
                                  width: 1,
                                  color: Colors.white12,
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                // Bảng chi tiết & Xem trước bàn đấu
                                Expanded(
                                  flex: 6,
                                  child: _buildTableDetail(
                                    selectedTable,
                                    isOwned,
                                    isEquipped,
                                    isUnlocked,
                                    service,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: _buildTableDetail(
                                    selectedTable,
                                    isOwned,
                                    isEquipped,
                                    isUnlocked,
                                    service,
                                    compact: true,
                                  ),
                                ),
                                Container(
                                  height: 1,
                                  color: Colors.white12,
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                Expanded(
                                  flex: 5,
                                  child: _buildTableGrid(service),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
                // Toast Thông báo
                if (_toastMessage != null)
                  Positioned(
                    top: 60,
                    left: 20,
                    right: 20,
                    child: Center(
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _toastIsError
                                ? const Color(0xFFD32F2F).withValues(alpha: 0.95)
                                : const Color(0xFF2E7D32).withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _toastIsError ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _toastMessage!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Tiêu đề + Vàng & Kim Cương
  Widget _buildHeader(BuildContext context, ProgressionService service) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF142028),
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF26A69A), Color(0xFF00796B)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.table_restaurant, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'table_shop_title'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  'table_shop_subtitle'.tr,
                  style: TextStyle(
                    color: Colors.tealAccent.shade100,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Tiền tệ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, color: Color(0xFFFFD54F), size: 16),
                const SizedBox(width: 4),
                Text(
                  '${service.coins}',
                  style: const TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.diamond, color: Color(0xFF00E5FF), size: 16),
                const SizedBox(width: 4),
                Text(
                  '${service.diamonds}',
                  style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// Bộ lọc Phẩm cấp
  Widget _buildRarityFilter() {
    final rarities = [null, ...TableRarity.values];
    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: rarities.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final rarity = rarities[index];
          final isSelected = _filterRarity == rarity;
          final label = rarity == null ? 'all_tables_filter'.tr : rarity.label;
          final color = rarity?.glowColor ?? Colors.tealAccent;

          return ChoiceChip(
            label: Text(label, style: TextStyle(fontSize: 11.5, color: isSelected ? Colors.black87 : Colors.white70, fontWeight: FontWeight.bold)),
            selected: isSelected,
            selectedColor: color,
            backgroundColor: const Color(0xFF1E2833),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onSelected: (_) => setState(() => _filterRarity = rarity),
          );
        },
      ),
    );
  }

  /// Lưới danh sách 20 bàn bida
  Widget _buildTableGrid(ProgressionService service) {
    final filtered = TableSkinCatalog.allTables.where((t) {
      if (_filterRarity == null) return true;
      return t.rarity == _filterRarity;
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final table = filtered[index];
        final isSelected = table.id == _selectedTableId;
        final isOwned = service.isTableOwned(table.id);
        final isEquipped = service.isTableEquipped(table.id);

        return GestureDetector(
          onTap: () => setState(() => _selectedTableId = table.id),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isSelected
                    ? [const Color(0xFF1B3B38), const Color(0xFF142B28)]
                    : [const Color(0xFF182029), const Color(0xFF131A21)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF26A69A)
                    : isEquipped
                        ? Colors.amber.withValues(alpha: 0.6)
                        : Colors.white10,
                width: isSelected ? 1.8 : 1.0,
              ),
            ),
            child: Row(
              children: [
                // Swatch Màu Vải Nỉ & Thành Băng
                Container(
                  width: 48,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: table.railColor, width: 3),
                    gradient: LinearGradient(
                      colors: [table.clothPrimary, table.clothSecondary],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: table.railAccentColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              table.localizedName,
                              style: TextStyle(
                                color: isSelected ? Colors.tealAccent : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: table.rarity.glowColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: table.rarity.glowColor.withValues(alpha: 0.6), width: 0.8),
                            ),
                            child: Text(
                              table.rarity.label,
                              style: TextStyle(color: table.rarity.glowColor, fontSize: 9.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isEquipped
                            ? 'table_in_use'.tr
                            : isOwned
                                ? 'table_owned'.tr
                                : table.priceCoins == 0 && table.priceDiamonds == 0
                                    ? 'free'.tr
                                    : table.priceDiamonds > 0
                                        ? '${table.priceDiamonds} KC'
                                        : '${table.priceCoins} ${'coins_unit'.tr}',
                        style: TextStyle(
                          color: isEquipped
                              ? Colors.amberAccent
                              : isOwned
                                  ? Colors.greenAccent
                                  : Colors.white54,
                          fontSize: 11,
                          fontWeight: isEquipped ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isEquipped)
                  const Icon(Icons.check_circle, color: Colors.amberAccent, size: 20)
                else if (isOwned)
                  const Icon(Icons.inventory_2_outlined, color: Colors.white38, size: 18)
                else
                  const Icon(Icons.lock_outline, color: Colors.white24, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Chi tiết & Mô hình xem trước bàn đấu
  Widget _buildTableDetail(
    TableSkinModel table,
    bool isOwned,
    bool isEquipped,
    bool isUnlocked,
    ProgressionService service, {
    bool compact = false,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: compact ? 6 : 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mô hình xem trước Bàn Bida 2.5D
          _buildMiniTablePreview(table, compact),
          SizedBox(height: compact ? 6 : 10),

          // Tên bàn & Phẩm cấp
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  table.localizedName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 15 : 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: table.rarity.gradientColors),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  table.rarity.label,
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Mô tả chủ đề
          Text(
            table.localizedDescription,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          SizedBox(height: compact ? 6 : 10),

          // Bảng thông số bàn
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF141A20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: _buildTableStat('table_cushion_bounce'.tr, 'tour_standard'.tr, Icons.sports_tennis)),
                Expanded(child: _buildTableStat('table_cloth_felt'.tr, 'ultra_smooth'.tr, Icons.texture)),
                Expanded(child: _buildTableStat('concept_label'.tr, table.animeConcept.localizedLabel, table.animeConcept.icon)),
                Expanded(child: _buildTableStat('level'.tr, 'Lv.${table.unlockLevel}', Icons.military_tech)),
              ],
            ),
          ),
          SizedBox(height: compact ? 8 : 14),

          // Nút Hành Động (Trang Bị / Đang Dùng / Mua)
          _buildActionButton(table, isOwned, isEquipped, isUnlocked, service),
        ],
      ),
    );
  }

  Widget _buildTableStat(String title, String val, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF26A69A), size: 16),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        Text(
          val,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Mô hình Thu Nhỏ Trực Quan Bàn Bida với thành băng, vải nỉ và 6 lỗ
  Widget _buildMiniTablePreview(TableSkinModel table, bool compact) {
    final height = compact ? 110.0 : 140.0;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: table.railColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: table.railAccentColor.withValues(alpha: 0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: table.clothPrimary.withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Lòng bàn (Vải Nỉ có hoa văn Anime)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [table.clothPrimary, table.clothSecondary],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: table.cushionShadowColor,
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: CustomPaint(
              size: Size.infinite,
              painter: _MiniTableMarksPainter(table: table),
            ),
          ),
          // 4 Lỗ Góc và 2 Lỗ Giữa
          ..._buildCornerPockets(table.pocketColor),
          // Bi số 8 trang trí giữa bàn
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black87,
              boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 4)],
            ),
            child: const Center(
              child: Text(
                '8',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerPockets(Color pocketColor) {
    const size = 16.0;
    return [
      Positioned(top: 8, left: 10, child: _pocketCircle(pocketColor, size)),
      Positioned(top: 8, right: 10, child: _pocketCircle(pocketColor, size)),
      Positioned(bottom: 8, left: 10, child: _pocketCircle(pocketColor, size)),
      Positioned(bottom: 8, right: 10, child: _pocketCircle(pocketColor, size)),
      Positioned(top: 8, child: _pocketCircle(pocketColor, size * 0.9)),
      Positioned(bottom: 8, child: _pocketCircle(pocketColor, size * 0.9)),
    ];
  }

  Widget _pocketCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black45, width: 1.0),
      ),
    );
  }

  /// Nút bấm mua hoặc trang bị
  Widget _buildActionButton(
    TableSkinModel table,
    bool isOwned,
    bool isEquipped,
    bool isUnlocked,
    ProgressionService service,
  ) {
    if (isEquipped) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2F23),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amberAccent),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.amberAccent, size: 18),
              SizedBox(width: 6),
              Text(
                'table_equipped_banner'.tr,
                style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (isOwned) {
      return ElevatedButton.icon(
        onPressed: () {
          service.equipTable(table.id);
          _showToast('table_applied_toast'.tr.replaceAll('{name}', table.localizedName));
        },
        icon: const Icon(Icons.check, size: 18),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('equip_table_btn'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00897B),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    if (!isUnlocked) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'unlock_table_level'.tr.replaceAll('{level}', '${table.unlockLevel}'),
              style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
      );
    }

    // Nút Mua bằng Vàng hoặc Kim Cương
    final isDiamond = table.priceDiamonds > 0;
    final price = isDiamond ? table.priceDiamonds : table.priceCoins;
    final canAfford = isDiamond ? service.diamonds >= price : service.coins >= price;

    return ElevatedButton.icon(
      onPressed: () {
        if (!canAfford) {
          _showToast(isDiamond ? 'not_enough_diamonds'.tr : 'not_enough_coins'.tr, isError: true);
          return;
        }
        final ok = service.buyTable(table);
        if (ok) {
          _showToast('table_bought_toast'.tr.replaceAll('{name}', table.localizedName));
        } else {
          _showToast('table_buy_error_toast'.tr, isError: true);
        }
      },
      icon: Icon(isDiamond ? Icons.diamond : Icons.monetization_on, size: 18),
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          isDiamond
              ? 'buy_with_diamonds'.tr.replaceAll('{price}', '$price')
              : 'buy_with_coins'.tr.replaceAll('{price}', '$price'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: canAfford
            ? (isDiamond ? const Color(0xFF00B0FF) : const Color(0xFFFF8F00))
            : Colors.grey.shade800,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
/// Vẽ họa tiết Concept Anime và vạch phát bóng cho mô hình thu nhỏ
class _MiniTableMarksPainter extends CustomPainter {
  final TableSkinModel table;
  _MiniTableMarksPainter({required this.table});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Vẽ họa tiết Concept Anime thu nhỏ
    AnimeTablePatternRenderer.renderAnimePattern(
      canvas: canvas,
      playRect: Rect.fromLTWH(0, 0, size.width, size.height),
      table: table,
      scale: (size.height / 140.0).clamp(0.4, 1.2),
    );

    final linePaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.0;

    // Vạch phát bóng (baulk line 25% từ bên trái)
    final lineX = size.width * 0.25;
    canvas.drawLine(Offset(lineX, 0), Offset(lineX, size.height), linePaint);

    // Điểm đặt bi cái
    final dotPaint = Paint()..color = Colors.white54;
    canvas.drawCircle(Offset(lineX, size.height / 2), 2.5, dotPaint);

    // Điểm đặt tam giác bi (75% từ bên trái)
    canvas.drawCircle(Offset(size.width * 0.75, size.height / 2), 2.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _MiniTableMarksPainter oldDelegate) =>
      oldDelegate.table.id != table.id;
}
