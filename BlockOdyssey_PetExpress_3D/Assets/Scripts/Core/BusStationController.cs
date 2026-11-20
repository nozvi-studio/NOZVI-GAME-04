using System;
using System.Collections.Generic;
using BlockOdyssey.Data;
using BlockOdyssey.Events;
using UnityEngine;

namespace BlockOdyssey.Core
{
    [Serializable]
    public class RuntimeBusData
    {
        public string busId;
        public PetColor color;
        public string busName;
        public int capacity = 4;
        public int currentPassengers = 0;
        public bool isRainbow = false;
        public GameObject busGameObject;

        public bool IsFull => currentPassengers >= capacity;

        public bool Accepts(PetColor petColor)
        {
            return isRainbow || color == petColor;
        }
    }

    [Serializable]
    public class DockSeat
    {
        public int seatIndex;
        public bool isOccupied;
        public PetColor petColor;
        public bool isLocked;
        public Transform seatAnchor;
        public GameObject petVisualObject;

        public bool IsAvailable => !isOccupied && !isLocked;
    }

    /// <summary>
    /// Điều phối Trạm xe buýt và Băng ghế chờ Holding Dock (5 chỗ)
    /// </summary>
    public class BusStationController : MonoBehaviour
    {
        public const int MaxDockSeats = 5;

        [Header("Tọa độ trạm & Làn đường")]
        [SerializeField] private Transform activeBusStopPoint;
        [SerializeField] private Transform queuedBusWaitPoint;
        [SerializeField] private Transform busDepartureTarget;
        [SerializeField] private Transform[] dockSeatTransforms = new Transform[MaxDockSeats];

        [Header("Events")]
        [SerializeField] private GameEventSO onBusBoardedEvent;
        [SerializeField] private GameEventSO onBusDispatchedEvent;
        [SerializeField] private GameEventSO onDockOverflowEvent;
        [SerializeField] private GameEventSO onLevelVictoryEvent;

        // Trạng thái trạm
        private RuntimeBusData _activeBus;
        private readonly Queue<RuntimeBusData> _queuedBuses = new Queue<RuntimeBusData>();
        private readonly DockSeat[] _dockSeats = new DockSeat[MaxDockSeats];
        private int _totalDispatchedCount = 0;
        private int _totalBusesRequired = 0;

        public RuntimeBusData ActiveBus => _activeBus;
        public int QueuedBusCount => _queuedBuses.Count;
        public DockSeat[] DockSeats => _dockSeats;
        public int TotalDispatchedCount => _totalDispatchedCount;
        public int TotalBusesRequired => _totalBusesRequired;

        public Transform ActiveBusStopPoint => activeBusStopPoint;
        public Transform[] DockSeatTransforms => dockSeatTransforms;

        private void Awake()
        {
            InitializeDock();
        }

        public void InitializeDock()
        {
            for (int i = 0; i < MaxDockSeats; i++)
            {
                _dockSeats[i] = new DockSeat
                {
                    seatIndex = i,
                    isOccupied = false,
                    isLocked = false,
                    seatAnchor = (dockSeatTransforms != null && i < dockSeatTransforms.Length) ? dockSeatTransforms[i] : null
                };
            }
        }

        public void SetupBusesFromLevel(LevelDataSO levelData)
        {
            InitializeDock();
            _queuedBuses.Clear();
            _totalDispatchedCount = 0;
            _totalBusesRequired = levelData.buses.Count;

            // Áp dụng khóa ghế chờ nếu có
            if (levelData.lockedDockSlots != null)
            {
                foreach (int lockedIndex in levelData.lockedDockSlots)
                {
                    if (lockedIndex >= 0 && lockedIndex < MaxDockSeats)
                    {
                        _dockSeats[lockedIndex].isLocked = true;
                    }
                }
            }

            // Nạp danh sách xe buýt
            foreach (var req in levelData.buses)
            {
                var bus = new RuntimeBusData
                {
                    busId = req.busId,
                    color = req.color,
                    busName = req.busName,
                    capacity = req.capacity,
                    currentPassengers = 0,
                    isRainbow = req.isRainbow
                };
                _queuedBuses.Enqueue(bus);
            }

            // Xe đầu tiên tiến vào làn đón khách
            AdvanceNextBusToDock();
        }

        /// <summary>
        /// Cho xe tiếp theo tiến vào làn đón khách (Active Lane)
        /// và TỰ ĐỘNG quét đón khách hợp lệ từ Ghế chờ Holding Dock!
        /// </summary>
        public void AdvanceNextBusToDock()
        {
            if (_queuedBuses.Count > 0)
            {
                _activeBus = _queuedBuses.Dequeue();

                // TỰ ĐỘNG QUÉT & ĐÓN KHÁCH TỪ GHẾ CHỜ
                PullMatchingPetsFromDock();
            }
            else
            {
                _activeBus = null;
                // Kiểm tra điều kiện thắng
                if (_totalDispatchedCount >= _totalBusesRequired)
                {
                    onLevelVictoryEvent?.Raise();
                }
            }
        }

        /// <summary>
        /// Thuật toán phân luồng hành khách sau khi nổ hàng (Passenger Extraction Loop):
        /// - Khách trùng màu với ActiveBus nhảy thẳng lên xe.
        /// - Khách khác màu chuyển vào ghế chờ Holding Dock.
        /// - Tràn ghế chờ -> Game Over!
        /// </summary>
        public void ProcessExtractedPassengers(
            List<PassengerExtractionInfo> passengers,
            Action<PassengerExtractionInfo, Vector3, bool> onPassengerDispatchCallback)
        {
            if (passengers == null || passengers.Count == 0) return;

            // Ưu tiên: Xếp các bé trùng màu với ActiveBus lên trước
            passengers.Sort((a, b) =>
            {
                bool aMatches = _activeBus != null && _activeBus.Accepts(a.color);
                bool bMatches = _activeBus != null && _activeBus.Accepts(b.color);
                return bMatches.CompareTo(aMatches);
            });

            foreach (var passenger in passengers)
            {
                // Trường hợp 1: Trùng màu với xe đang đón và xe chưa đầy
                if (_activeBus != null && _activeBus.Accepts(passenger.color) && !_activeBus.IsFull)
                {
                    _activeBus.currentPassengers++;
                    Vector3 busTargetPos = activeBusStopPoint != null ? activeBusStopPoint.position : Vector3.zero;

                    onPassengerDispatchCallback?.Invoke(passenger, busTargetPos, true);
                    onBusBoardedEvent?.Raise();

                    // Nếu xe đã đầy khách -> Cho xe xuất bến
                    if (_activeBus.IsFull)
                    {
                        DispatchActiveBus();
                    }
                }
                else
                {
                    // Trường hợp 2: Khác màu hoặc xe đã đầy -> Tìm ghế trống đầu tiên trên Holding Dock
                    int emptySeatIndex = FindFirstEmptyDockSeat();

                    if (emptySeatIndex != -1)
                    {
                        var seat = _dockSeats[emptySeatIndex];
                        seat.isOccupied = true;
                        seat.petColor = passenger.color;

                        Vector3 seatPos = seat.seatAnchor != null
                            ? seat.seatAnchor.position
                            : (dockSeatTransforms != null && emptySeatIndex < dockSeatTransforms.Length ? dockSeatTransforms[emptySeatIndex].position : Vector3.zero);

                        onPassengerDispatchCallback?.Invoke(passenger, seatPos, false);
                    }
                    else
                    {
                        // Toàn bộ ghế chờ đã kín -> THUA CUỘC (Dock Overflow)!
                        onDockOverflowEvent?.Raise();
                        return;
                    }
                }
            }
        }

        private int FindFirstEmptyDockSeat()
        {
            for (int i = 0; i < MaxDockSeats; i++)
            {
                if (_dockSeats[i].IsAvailable)
                {
                    return i;
                }
            }
            return -1;
        }

        /// <summary>
        /// Tự động chuyển khách từ Holding Dock lên xe buýt mới ngay khi xe phù hợp cập bến
        /// </summary>
        public void PullMatchingPetsFromDock()
        {
            if (_activeBus == null) return;

            while (!_activeBus.IsFull)
            {
                int matchSeatIndex = -1;
                for (int i = 0; i < MaxDockSeats; i++)
                {
                    if (_dockSeats[i].isOccupied && _activeBus.Accepts(_dockSeats[i].petColor))
                    {
                        matchSeatIndex = i;
                        break;
                    }
                }

                if (matchSeatIndex == -1) break; // Không còn khách phù hợp trên ghế chờ

                var seat = _dockSeats[matchSeatIndex];
                seat.isOccupied = false; // Trả lại ghế trống!
                _activeBus.currentPassengers++;

                onBusBoardedEvent?.Raise();

                if (_activeBus.IsFull)
                {
                    DispatchActiveBus();
                    break;
                }
            }
        }

        /// <summary>
        /// Cho xe đầy khách xuất bến và đưa xe mới vào trạm
        /// </summary>
        public void DispatchActiveBus()
        {
            if (_activeBus == null) return;

            _totalDispatchedCount++;
            onBusDispatchedEvent?.Raise();

            // Đưa xe tiếp theo vào trạm
            AdvanceNextBusToDock();
        }

        /// <summary>
        /// Đổi màu xe buýt đang chờ kế tiếp sang màu có số lượng đông nhất đang kẹt ở Ghế Chờ
        /// Dùng cho bảo bối Lăng Kính Từ (Magnetic Prism)
        /// </summary>
        public bool SwapQueuedBusColorToDockDominantColor()
        {
            // Đếm màu đông nhất trên ghế chờ
            var colorCounts = new Dictionary<PetColor, int>();
            foreach (var seat in _dockSeats)
            {
                if (seat.isOccupied)
                {
                    colorCounts[seat.petColor] = colorCounts.GetValueOrDefault(seat.petColor, 0) + 1;
                }
            }

            if (colorCounts.Count == 0 || _queuedBuses.Count == 0) return false;

            PetColor dominantColor = PetColor.Red;
            int maxCount = -1;
            foreach (var kvp in colorCounts)
            {
                if (kvp.Value > maxCount)
                {
                    maxCount = kvp.Value;
                    dominantColor = kvp.Key;
                }
            }

            // Đổi màu xe kế tiếp
            var nextBus = _queuedBuses.Peek();
            nextBus.color = dominantColor;
            nextBus.busName = $"{dominantColor} Bus (Prism)";
            return true;
        }
    }
}
