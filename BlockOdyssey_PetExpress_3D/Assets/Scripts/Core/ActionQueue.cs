using System.Collections;
using System.Collections.Generic;
using BlockOdyssey.Data;
using BlockOdyssey.Events;
using UnityEngine;

namespace BlockOdyssey.Core
{
    /// <summary>
    /// Bộ điều phối vòng lặp trò chơi 7 bước (Deterministic 7-Step Action Queue)
    /// Đảm bảo thứ tự thực thi rõ ràng, công bằng và hiệu ứng mượt mà.
    /// </summary>
    public class ActionQueue : MonoBehaviour
    {
        [Header("Tham chiếu Hệ Thống Cốt Lõi")]
        [SerializeField] private GridBoardController gridBoard;
        [SerializeField] private BusStationController busStation;
        [SerializeField] private SmartSpawner smartSpawner;
        [SerializeField] private RelicManager relicManager;

        [Header("Events")]
        [SerializeField] private GameEventSO onMoveCompletedEvent;
        [SerializeField] private GameEventSO onGridLockDefeatEvent;

        private bool _isActionInProgress = false;
        private int _currentScore = 12500;
        private int _currentCombo = 0;

        public bool IsActionInProgress => _isActionInProgress;
        public int CurrentScore => _currentScore;
        public int CurrentCombo => _currentCombo;

        /// <summary>
        /// Điểm vào chính: Khi người chơi thả một khối gạch vào bàn cờ
        /// </summary>
        public void ExecuteBlockDrop(PolyominoShapeSO shape, int traySlotIndex, int targetRow, int targetCol, PetColor color, List<PetColor> availableColors)
        {
            if (_isActionInProgress) return;

            if (gridBoard.CanPlaceShapeAt(shape, targetRow, targetCol))
            {
                StartCoroutine(Process7StepQueueCoroutine(shape, traySlotIndex, targetRow, targetCol, color, availableColors));
            }
        }

        private IEnumerator Process7StepQueueCoroutine(
            PolyominoShapeSO shape,
            int traySlotIndex,
            int targetRow,
            int targetCol,
            PetColor color,
            List<PetColor> availableColors)
        {
            _isActionInProgress = true;

            // BƯỚC 1: Đặt khối gạch vào bàn cờ (Place Block)
            gridBoard.PlaceShape(shape, targetRow, targetCol, color);
            smartSpawner.ConsumeTraySlot(traySlotIndex);
            yield return new WaitForSeconds(0.12f);

            // BƯỚC 2: Kiểm tra và nổ hàng/cột (Resolve Completed Lines)
            int rowsCleared, colsCleared;
            var freedPassengers = gridBoard.ResolveCompletedLines(out rowsCleared, out colsCleared);

            // BƯỚC 3: Tính toán Combo & Điểm số (Combo & Score Calculation)
            int totalLines = rowsCleared + colsCleared;
            if (totalLines > 0)
            {
                _currentCombo++;
                int baseScore = totalLines * 100;
                int comboBonus = _currentCombo * 50;
                _currentScore += (baseScore + comboBonus);
            }
            else
            {
                _currentCombo = 0; // Hết nhịp combo nếu không nổ dòng
            }

            // BƯỚC 4 & 5: Đón khách và nhảy Parabol vào Xe hoặc Ghế chờ (Parabolic Boarding Loop)
            if (freedPassengers.Count > 0)
            {
                busStation.ProcessExtractedPassengers(freedPassengers, (passenger, targetPosition, boardedBus) =>
                {
                    // Visual Jump Trigger (được kích hoạt bởi ParabolicJumper)
                });
                yield return new WaitForSeconds(0.45f);
            }

            // BƯỚC 6: Nạp lại Khay gạch nếu cả 3 ô đã dùng hết (Refill Next Tray)
            if (smartSpawner.IsTrayEmpty())
            {
                smartSpawner.RefillTray(availableColors);
                yield return new WaitForSeconds(0.2f);
            }

            // BƯỚC 7: Kiểm tra Khóa bàn cờ (Gridlock Defeat Check)
            CheckGridLockDefeat();

            _isActionInProgress = false;
            onMoveCompletedEvent?.Raise();
        }

        private void CheckGridLockDefeat()
        {
            bool anyMovePossible = false;
            foreach (var shape in smartSpawner.CurrentTrayShapes)
            {
                if (shape != null && gridBoard.HasValidMoveForShape(shape))
                {
                    anyMovePossible = true;
                    break;
                }
            }

            // Nếu còn gạch trong khay nhưng không một khối nào vừa bàn cờ -> THUA CUỘC
            if (!anyMovePossible && !smartSpawner.IsTrayEmpty())
            {
                onGridLockDefeatEvent?.Raise();
            }
        }
    }
}
