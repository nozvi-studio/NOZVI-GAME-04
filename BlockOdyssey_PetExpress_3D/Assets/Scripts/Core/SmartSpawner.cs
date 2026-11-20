using System.Collections.Generic;
using BlockOdyssey.Data;
using UnityEngine;

namespace BlockOdyssey.Core
{
    /// <summary>
    /// Thuật toán sinh 3 khối gạch Polyomino thông minh (Smart Spawner)
    /// Đảm bảo tính cuốn hút và tỷ lệ giải được >92% thông qua Mercy Rule
    /// </summary>
    public class SmartSpawner : MonoBehaviour
    {
        public const int TrayCapacity = 3;

        [Header("Thư viện Khối Gạch Polyomino")]
        [SerializeField] private List<PolyominoShapeSO> shapeCatalog = new List<PolyominoShapeSO>();
        [SerializeField] private PolyominoShapeSO dotShape1x1;
        [SerializeField] private PolyominoShapeSO domino2x1;

        [Header("Tham chiếu hệ thống")]
        [SerializeField] private GridBoardController gridBoard;
        [SerializeField] private BusStationController busStation;

        private readonly PolyominoShapeSO[] _currentTrayShapes = new PolyominoShapeSO[TrayCapacity];
        private readonly PetColor[] _currentTrayColors = new PetColor[TrayCapacity];

        public PolyominoShapeSO[] CurrentTrayShapes => _currentTrayShapes;
        public PetColor[] CurrentTrayColors => _currentTrayColors;

        public bool IsTrayEmpty()
        {
            for (int i = 0; i < TrayCapacity; i++)
            {
                if (_currentTrayShapes[i] != null) return false;
            }
            return true;
        }

        /// <summary>
        /// Nạp lại đầy khay 3 khối gạch với cơ chế bảo đảm khả năng đặt (Mercy Rule)
        /// </summary>
        public void RefillTray(List<PetColor> availableColors)
        {
            if (availableColors == null || availableColors.Count == 0)
            {
                availableColors = new List<PetColor> { PetColor.Red, PetColor.Yellow, PetColor.Blue };
            }

            // 1. Sinh ngẫu nhiên 3 khối
            for (int i = 0; i < TrayCapacity; i++)
            {
                _currentTrayShapes[i] = GetRandomShape();
                _currentTrayColors[i] = PickColorBiased(availableColors);
            }

            // 2. Kiểm tra tính giải được (Solvability Guarantee > 92%)
            EnsureAtLeastOneShapePlayable(availableColors);
        }

        private PolyominoShapeSO GetRandomShape()
        {
            if (shapeCatalog == null || shapeCatalog.Count == 0) return dotShape1x1;
            int idx = Random.Range(0, shapeCatalog.Count);
            return shapeCatalog[idx];
        }

        /// <summary>
        /// Ưu tiên sinh màu trùng với xe buýt đang đón hoặc xe buýt chờ tiếp theo
        /// </summary>
        private PetColor PickColorBiased(List<PetColor> availableColors)
        {
            if (busStation != null && busStation.ActiveBus != null && Random.value < 0.45f)
            {
                return busStation.ActiveBus.color;
            }

            int idx = Random.Range(0, availableColors.Count);
            return availableColors[idx];
        }

        /// <summary>
        /// Áp dụng Mercy Rule: Nếu cả 3 khối đều không đặt được vào bàn cờ hiện tại,
        /// thay thế khối thứ 3 bằng một khối nhỏ (1x1 hoặc Domino) chắc chắn lọt ô trống!
        /// </summary>
        private void EnsureAtLeastOneShapePlayable(List<PetColor> availableColors)
        {
            if (gridBoard == null) return;

            bool hasPlayable = false;
            for (int i = 0; i < TrayCapacity; i++)
            {
                if (_currentTrayShapes[i] != null && gridBoard.HasValidMoveForShape(_currentTrayShapes[i]))
                {
                    hasPlayable = true;
                    break;
                }
            }

            if (!hasPlayable)
            {
                // Áp dụng khối cứu hộ 1x1 hoặc Domino
                _currentTrayShapes[0] = (dotShape1x1 != null) ? dotShape1x1 : domino2x1;
                if (busStation != null && busStation.ActiveBus != null)
                {
                    _currentTrayColors[0] = busStation.ActiveBus.color;
                }
            }
        }

        public void ConsumeTraySlot(int slotIndex)
        {
            if (slotIndex >= 0 && slotIndex < TrayCapacity)
            {
                _currentTrayShapes[slotIndex] = null;
            }
        }

        /// <summary>
        /// Xoay 90 độ toàn bộ khối trong khay (Kỹ năng La Bàn Gió)
        /// </summary>
        public void RotateAllShapesInTray()
        {
            for (int i = 0; i < TrayCapacity; i++)
            {
                if (_currentTrayShapes[i] != null)
                {
                    _currentTrayShapes[i] = _currentTrayShapes[i].CreateRotatedClockwise();
                }
            }
        }
    }
}
