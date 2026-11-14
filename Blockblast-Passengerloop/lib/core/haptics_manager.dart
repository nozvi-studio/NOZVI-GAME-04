import 'dart:async';
import 'package:flutter/services.dart';
import '../models/enums.dart';
import 'game_event_bus.dart';

/// Quản lý phản hồi xúc giác (Haptic Feedback) đa tầng cho toàn bộ trận đấu
class HapticsManager {
  static final HapticsManager _instance = HapticsManager._internal();
  static HapticsManager get instance => _instance;

  HapticsManager._internal();

  bool isEnabled = true;
  StreamSubscription<GameEvent>? _busSubscription;
  int? _lastHoverRow;
  int? _lastHoverCol;

  /// Khởi tạo và đăng ký lắng nghe GameEventBus
  void init() {
    _busSubscription?.cancel();
    _busSubscription = GameEventBus.instance.stream.listen(_handleGameEvent);
  }

  void _handleGameEvent(GameEvent event) {
    if (!isEnabled) return;

    if (event is BlockPlacedEvent) {
      // Rung vừa khi đặt khối xuống bàn cờ thành công
      triggerBlockPlaced();
    } else if (event is LinesClearedEvent) {
      // Rung mạnh khi phá nổ hàng/cột (Combo)
      triggerLineClear();
    } else if (event is RelicUsedEvent) {
      if (event.relic == RelicType.hammer) {
        // Rung mạnh khi dùng Búa Rèn Lửa phá nổ 3x3
        triggerHammerSmash();
      } else {
        // Rung nhẹ/vừa khi dùng La Bàn Gió
        triggerCompassRotate();
      }
    } else if (event is PassengerBoardBusEvent || event is DockPetBoardedEvent) {
      // Rung nhẹ mỗi khi một bé thú cưng nhảy vào cửa sổ xe buýt
      triggerPetBoarded();
    }
  }

  /// Gọi mỗi khi khối gạch đang kéo lướt qua một tọa độ ô (row, col) trên lưới 8x8.
  /// Chỉ rung khi tọa độ ô thực sự thay đổi, không rung lặp lại trên cùng một ô.
  void onHoverCell(int row, int col) {
    if (!isEnabled) return;
    if (row != _lastHoverRow || col != _lastHoverCol) {
      _lastHoverRow = row;
      _lastHoverCol = col;
      HapticFeedback.selectionClick();
    }
  }

  /// Đặt lại tọa độ ô hover khi kết thúc kéo hoặc thả khối
  void resetHover() {
    _lastHoverRow = null;
    _lastHoverCol = null;
  }

  void triggerBlockPlaced() {
    if (!isEnabled) return;
    HapticFeedback.mediumImpact();
  }

  void triggerLineClear() {
    if (!isEnabled) return;
    HapticFeedback.heavyImpact();
  }

  void triggerHammerSmash() {
    if (!isEnabled) return;
    HapticFeedback.heavyImpact();
  }

  void triggerCompassRotate() {
    if (!isEnabled) return;
    HapticFeedback.mediumImpact();
  }

  void triggerPetBoarded() {
    if (!isEnabled) return;
    HapticFeedback.lightImpact();
  }

  void dispose() {
    _busSubscription?.cancel();
    _busSubscription = null;
  }
}

