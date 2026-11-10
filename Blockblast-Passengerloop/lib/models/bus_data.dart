import 'enums.dart';

/// Dữ liệu của một chiếc xe buýt đón thú cưng
class BusData {
  final String id;
  final PetColor color;
  final String name;
  final int capacity;
  int currentPassengers;
  final List<PetColor> passengerPets;
  bool isDeparting;
  bool isArriving;
  final bool isRainbow;

  BusData({
    required this.id,
    required this.color,
    required this.name,
    required this.capacity,
    this.currentPassengers = 0,
    List<PetColor>? passengerPets,
    this.isDeparting = false,
    this.isArriving = false,
    this.isRainbow = false,
  }) : passengerPets = passengerPets ?? [];

  bool get isFull => currentPassengers >= capacity;

  bool accepts(PetColor petColor) => isRainbow || color == petColor;

  String get capacityDisplay => '$currentPassengers/$capacity';

  BusData clone() {
    return BusData(
      id: id,
      color: color,
      name: name,
      capacity: capacity,
      currentPassengers: currentPassengers,
      passengerPets: List<PetColor>.from(passengerPets),
      isDeparting: isDeparting,
      isArriving: isArriving,
      isRainbow: isRainbow,
    );
  }
}

/// Dữ liệu của một vị trí ghế chờ trên chiếc ghế dài Holding Dock (5 chỗ)
class HoldingDockSlot {
  final int slotIndex;
  PetColor? petColor;
  bool isLocked;
  final bool isVip;

  HoldingDockSlot({
    required this.slotIndex,
    this.petColor,
    this.isLocked = false,
    this.isVip = false,
  });

  bool get isEmpty => petColor == null && !isLocked;

  HoldingDockSlot clone() {
    return HoldingDockSlot(
      slotIndex: slotIndex,
      petColor: petColor,
      isLocked: isLocked,
      isVip: isVip,
    );
  }
}

/// Dữ liệu một bé thú cưng được giải phóng và chuẩn bị bay đến đích
enum PassengerDestination {
  bus,
  dock,
}

class PassengerExtractionItem {
  final String id;
  final PetColor color;
  final int fromRow;
  final int fromCol;
  final PassengerDestination destination;
  final int? dockSlotIndex;

  const PassengerExtractionItem({
    required this.id,
    required this.color,
    required this.fromRow,
    required this.fromCol,
    required this.destination,
    this.dockSlotIndex,
  });
}

