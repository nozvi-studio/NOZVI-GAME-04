using UnityEngine;
using BlockOdyssey.Events;

namespace BlockOdyssey.Core
{
    /// <summary>
    /// Quản lý 3 bảo bối Cổ vật: Búa Rèn Lửa, La Bàn Gió, Lăng Kính Từ
    /// </summary>
    public class RelicManager : MonoBehaviour
    {
        [Header("Tham chiếu hệ thống")]
        [SerializeField] private GridBoardController gridBoard;
        [SerializeField] private BusStationController busStation;
        [SerializeField] private SmartSpawner smartSpawner;

        [Header("Events")]
        [SerializeField] private GameEventSO onRelicActivatedEvent;

        [Header("Điểm tích lũy / Số lượt sử dụng")]
        public int hammerCount = 2;
        public int compassCount = 3;
        public int prismCount = 1;

        private bool _isHammerActive = false;
        public bool IsHammerActive => _isHammerActive;

        /// <summary>
        /// 🔨 Kích hoạt Búa Rèn Lửa (Chọn 1 ô để phá tan vùng 3x3)
        /// </summary>
        public void ToggleHammerTargetMode()
        {
            if (hammerCount <= 0) return;
            _isHammerActive = !_isHammerActive;
            onRelicActivatedEvent?.Raise();
        }

        public void ExecuteHammerSmash(int centerRow, int centerCol)
        {
            if (!_isHammerActive || hammerCount <= 0) return;

            hammerCount--;
            _isHammerActive = false;

            var freedPassengers = gridBoard.SmashHammer3x3(centerRow, centerCol);
            busStation.ProcessExtractedPassengers(freedPassengers, null);
        }

        /// <summary>
        /// 🧭 Kích hoạt La Bàn Gió (Xoay 90 độ toàn bộ 3 khối trong khay Next)
        /// </summary>
        public void UseWindCompass()
        {
            if (compassCount <= 0) return;
            compassCount--;

            smartSpawner.RotateAllShapesInTray();
            onRelicActivatedEvent?.Raise();
        }

        /// <summary>
        /// 💎 Kích hoạt Lăng Kính Từ (Đổi màu chuyến xe buýt kế tiếp sang màu đông nhất ở Ghế Chờ)
        /// </summary>
        public void UseMagneticPrism()
        {
            if (prismCount <= 0) return;

            bool success = busStation.SwapQueuedBusColorToDockDominantColor();
            if (success)
            {
                prismCount--;
                onRelicActivatedEvent?.Raise();
            }
        }
    }
}
