import 'dart:math' as math;
import '../models/enums.dart';
import '../models/bus_data.dart';
import 'grid_engine.dart';
import '../core/game_event_bus.dart';

const int kMaxDockSlots = 5;

class PassengerExtractionResult {
  final List<PassengerExtractionItem> items;
  final List<BusData> dispatchedBuses;
  final bool dockOverflow;

  const PassengerExtractionResult({
    required this.items,
    required this.dispatchedBuses,
    required this.dockOverflow,
  });
}

class BusStationManager {
  BusData? activeBus;
  final List<BusData> queuedBuses = [];
  int dockCapacity = kMaxDockSlots;
  late List<HoldingDockSlot> holdingDock;
  int totalDispatchedCount = 0;
  int initialBusCount = 0;

  BusStationManager({int initialDockCapacity = kMaxDockSlots}) {
    dockCapacity = initialDockCapacity;
    holdingDock = List.generate(
      dockCapacity,
      (index) => HoldingDockSlot(
        slotIndex: index,
        isVip: index >= kMaxDockSlots,
      ),
    );
  }

  void setDockCapacity(int capacity) {
    dockCapacity = capacity;
    final oldPets = <int, PetColor?>{
      for (int i = 0; i < holdingDock.length; i++) i: holdingDock[i].petColor
    };
    holdingDock = List.generate(
      dockCapacity,
      (index) => HoldingDockSlot(
        slotIndex: index,
        petColor: oldPets[index],
        isVip: index >= kMaxDockSlots,
      ),
    );
  }

  void expandDockByOne() {
    setDockCapacity(dockCapacity + 1);
  }

  List<PetColor> rescuePetsFromDock(int count) {
    final List<PetColor> rescued = [];
    for (final slot in holdingDock) {
      if (slot.petColor != null) {
        rescued.add(slot.petColor!);
        slot.petColor = null;
        if (rescued.length >= count) break;
      }
    }
    return rescued;
  }

  void reset() {
    activeBus = null;
    queuedBuses.clear();
    totalDispatchedCount = 0;
    initialBusCount = 0;
    for (final slot in holdingDock) {
      slot.petColor = null;
      slot.isLocked = false;
    }
  }

  void initializeBuses(List<BusData> buses) {
    reset();
    initialBusCount = buses.length;
    if (buses.isNotEmpty) {
      activeBus = buses.first;
      if (buses.length > 1) {
        queuedBuses.addAll(buses.sublist(1));
      }
    }
  }

  BusData? get nextBus => queuedBuses.isNotEmpty ? queuedBuses.first : null;

  int get dockedPetCount => holdingDock.where((s) => s.petColor != null).length;

  bool get isDockFull => holdingDock.every((s) => s.petColor != null || s.isLocked);

  bool get allBusesCleared => activeBus == null && queuedBuses.isEmpty;

  int get totalBusesInLevel => initialBusCount > 0
      ? initialBusCount
      : (totalDispatchedCount + (activeBus != null ? 1 : 0) + queuedBuses.length);

  int get currentBusNumber => (totalDispatchedCount + (activeBus != null ? 1 : 0))
      .clamp(1, math.max(1, totalBusesInLevel));

  List<BusData> get queuedBusesList => List.unmodifiable(queuedBuses);

  /// Thuật toán EXTRACT_PASSENGERS chuẩn Bus Solver:
  /// Khách trùng màu với activeBus (hoặc bất kỳ màu nào nếu là Rainbow Bus) sẽ lên xe ngay.
  /// Nếu xe đầy và xuất bến -> xe tiếp theo cập bến và tiếp tục đón khách trùng màu từ danh sách vừa giải phóng.
  /// Chỉ những khách thực sự không có xe đón tại thời điểm đó mới chuyển vào ghế chờ Holding Dock.
  PassengerExtractionResult extractAndSortPassengers(List<FreedPetInfo> freedPets) {
    final List<PassengerExtractionItem> items = [];
    final List<BusData> dispatched = [];
    bool dockOverflow = false;

    if (freedPets.isEmpty) {
      return PassengerExtractionResult(
        items: items,
        dispatchedBuses: dispatched,
        dockOverflow: false,
      );
    }

    final List<FreedPetInfo> pendingPets = List.from(freedPets);
    int idCounter = 0;

    // 1. Phân phối khách trực tiếp lên các xe buýt đang đỗ và xe kế tiếp nếu xe đầy
    while (pendingPets.isNotEmpty && activeBus != null && !activeBus!.isFull) {
      final isRainbow = activeBus!.isRainbow;
      final activeColor = activeBus!.color;
      final matchIdx = pendingPets.indexWhere((p) => isRainbow || p.color == activeColor);

      if (matchIdx == -1) break; // Không còn thú cưng nào trùng màu với xe đang đỗ

      final pet = pendingPets.removeAt(matchIdx);
      final String itemId = 'pass_${DateTime.now().millisecondsSinceEpoch}_${idCounter++}';

      activeBus!.currentPassengers++;
      activeBus!.passengerPets.add(pet.color);

      final item = PassengerExtractionItem(
        id: itemId,
        color: pet.color,
        fromRow: pet.row,
        fromCol: pet.col,
        destination: PassengerDestination.bus,
      );
      items.add(item);
      GameEventBus.instance.fire(PassengerBoardBusEvent(passenger: item, bus: activeBus!));

      // Kiểm tra xe đã đón đủ khách chưa
      if (activeBus!.isFull) {
        final bus = dispatchActiveBus();
        if (bus != null) {
          dispatched.add(bus);
          // Tự động gọi khách phù hợp từ ghế chờ lên xe mới vừa tiến vào trạm!
          final pulled = pullMatchingPetsFromDock();
          dispatched.addAll(pulled);
        }
      }
    }

    // 2. Những thú cưng còn lại không có xe đón sẽ chuyển vào ghế chờ Holding Dock
    for (final pet in pendingPets) {
      final String itemId = 'pass_${DateTime.now().millisecondsSinceEpoch}_${idCounter++}';
      final emptySlot = holdingDock.cast<HoldingDockSlot?>().firstWhere(
            (s) => s != null && s.isEmpty,
            orElse: () => null,
          );

      if (emptySlot != null) {
        emptySlot.petColor = pet.color;
        final item = PassengerExtractionItem(
          id: itemId,
          color: pet.color,
          fromRow: pet.row,
          fromCol: pet.col,
          destination: PassengerDestination.dock,
          dockSlotIndex: emptySlot.slotIndex,
        );
        items.add(item);
        GameEventBus.instance.fire(PassengerEnterDockEvent(
          passenger: item,
          slotIndex: emptySlot.slotIndex,
        ));
      } else {
        // Các ghế chờ đều đã kín chỗ! Tràn ghế chờ -> Game Over!
        dockOverflow = true;
        final item = PassengerExtractionItem(
          id: itemId,
          color: pet.color,
          fromRow: pet.row,
          fromCol: pet.col,
          destination: PassengerDestination.dock,
        );
        items.add(item);
        break; // Dừng lại để xử lý Game Over
      }
    }

    return PassengerExtractionResult(
      items: items,
      dispatchedBuses: dispatched,
      dockOverflow: dockOverflow,
    );
  }

  /// Cho xe buýt xuất bến và đưa xe tiếp theo vào trạm
  BusData? dispatchActiveBus() {
    if (activeBus == null) return null;

    final departing = activeBus!;
    departing.isDeparting = true;
    totalDispatchedCount++;
    GameEventBus.instance.fire(BusDispatchedEvent(bus: departing));

    if (queuedBuses.isNotEmpty) {
      activeBus = queuedBuses.removeAt(0);
      activeBus!.isArriving = true;
      GameEventBus.instance.fire(NextBusArrivedEvent(bus: activeBus!));
    } else {
      activeBus = null;
    }

    return departing;
  }

  /// Tự động chuyển khách từ Holding Dock lên xe buýt mới ngay khi xe phù hợp cập bến
  List<BusData> pullMatchingPetsFromDock() {
    final List<BusData> dispatched = [];

    while (activeBus != null && !activeBus!.isFull) {
      final matchSlot = holdingDock.cast<HoldingDockSlot?>().firstWhere(
            (s) => s != null && s.petColor != null && activeBus!.accepts(s.petColor!),
            orElse: () => null,
          );

      if (matchSlot == null) break;

      final color = matchSlot.petColor!;
      matchSlot.petColor = null; // Trả lại ghế trống
      activeBus!.currentPassengers++;
      activeBus!.passengerPets.add(color);

      GameEventBus.instance.fire(DockPetBoardedEvent(
        petColor: color,
        slotIndex: matchSlot.slotIndex,
        bus: activeBus!,
      ));

      if (activeBus!.isFull) {
        final d = dispatchActiveBus();
        if (d != null) {
          dispatched.add(d);
        }
      }
    }

    return dispatched;
  }
}
