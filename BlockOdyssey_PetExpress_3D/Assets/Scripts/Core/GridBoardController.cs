using System;
using System.Collections.Generic;
using BlockOdyssey.Data;
using BlockOdyssey.Events;
using UnityEngine;

namespace BlockOdyssey.Core
{
    [Serializable]
    public class GridCell
    {
        public int row;
        public int col;
        public bool isOccupied;
        public PetColor petColor;
        public HazardType hazard = HazardType.None;
        public int iceHp = 0;       // 1 hoặc 2 lượt nổ
        public int bombTurns = 0;    // Đếm lùi về 0 nổ thua
        public bool isLocked = false;
        public GameObject visualObject;

        public bool CanAcceptBlock()
        {
            return !isOccupied && !isLocked && hazard != HazardType.Stone;
        }
    }

    /// <summary>
    /// Quản lý Bàn cờ 8x8, logic va chạm, kiểm tra hoàn thành hàng/cột và giải phóng hành khách
    /// </summary>
    public class GridBoardController : MonoBehaviour
    {
        public const int GridSize = 8;

        [Header("Cấu hình Bàn cờ 3D")]
        [SerializeField] private Transform boardOrigin;
        [SerializeField] private float cellSize = 0.95f;
        [SerializeField] private GameObject defaultBlockPrefab;
        [SerializeField] private GameObject iceOverlayPrefab;
        [SerializeField] private GameObject bombPrefab;
        [SerializeField] private GameObject stonePrefab;

        [Header("Events")]
        [SerializeField] private GameEventSO onLineClearedEvent;
        [SerializeField] private GameEventSO onBombExplodedEvent;

        private GridCell[,] _grid = new GridCell[GridSize, GridSize];

        public GridCell[,] Grid => _grid;
        public float CellSize => cellSize;

        private void Awake()
        {
            InitializeEmptyGrid();
        }

        public void InitializeEmptyGrid()
        {
            for (int r = 0; r < GridSize; r++)
            {
                for (int c = 0; c < GridSize; c++)
                {
                    _grid[r, c] = new GridCell
                    {
                        row = r,
                        col = c,
                        isOccupied = false,
                        hazard = HazardType.None
                    };
                }
            }
        }

        public void LoadLevelLayout(LevelDataSO levelData)
        {
            InitializeEmptyGrid();

            if (levelData == null) return;

            foreach (var initCell in levelData.initialGrid)
            {
                if (initCell.row >= 0 && initCell.row < GridSize && initCell.col >= 0 && initCell.col < GridSize)
                {
                    var cell = _grid[initCell.row, initCell.col];
                    cell.isOccupied = initCell.hasPet;
                    cell.petColor = initCell.petColor;
                    cell.hazard = initCell.hazard;
                    cell.iceHp = initCell.iceHp;
                    cell.bombTurns = initCell.bombTurns;
                    cell.isLocked = initCell.isLocked;
                }
            }
        }

        /// <summary>
        /// Chuyển đổi tọa độ ô (row, col) sang tọa độ thế giới 3D
        /// </summary>
        public Vector3 GetCellWorldPosition(int row, int col)
        {
            Vector3 origin = boardOrigin != null ? boardOrigin.position : Vector3.zero;
            // Bàn cờ 8x8 căn giữa: col dịch theo trục X, row dịch theo trục Z (hoặc Y tùy Camera 2.5D/3D)
            float xOffset = (col - (GridSize - 1) * 0.5f) * cellSize;
            float zOffset = ((GridSize - 1) * 0.5f - row) * cellSize;
            return origin + new Vector3(xOffset, 0f, zOffset);
        }

        /// <summary>
        /// Kiểm tra xem khối gạch có thể đặt tại vị trí (startRow, startCol) hay không
        /// </summary>
        public bool CanPlaceShapeAt(PolyominoShapeSO shape, int startRow, int startCol)
        {
            if (shape == null) return false;

            foreach (var tile in shape.localTiles)
            {
                int r = startRow + tile.r;
                int c = startCol + tile.c;

                // Vượt biên bàn cờ
                if (r < 0 || r >= GridSize || c < 0 || c >= GridSize)
                {
                    return false;
                }

                // Ô đã có vật hoặc bị khóa
                if (!_grid[r, c].CanAcceptBlock())
                {
                    return false;
                }
            }

            return true;
        }

        /// <summary>
        /// Kiểm tra xem bàn cờ hiện tại còn chỗ đặt cho khối gạch này không
        /// </summary>
        public bool HasValidMoveForShape(PolyominoShapeSO shape)
        {
            if (shape == null) return false;

            for (int r = 0; r <= GridSize - shape.height; r++)
            {
                for (int c = 0; c <= GridSize - shape.width; c++)
                {
                    if (CanPlaceShapeAt(shape, r, c))
                    {
                        return true;
                    }
                }
            }
            return false;
        }

        /// <summary>
        /// Đặt khối gạch vào bàn cờ và trả về danh sách ô bị lấp đầy
        /// </summary>
        public List<GridCell> PlaceShape(PolyominoShapeSO shape, int startRow, int startCol, PetColor assignedColor)
        {
            var affectedCells = new List<GridCell>();

            foreach (var tile in shape.localTiles)
            {
                int r = startRow + tile.r;
                int c = startCol + tile.c;

                var cell = _grid[r, c];
                cell.isOccupied = true;
                cell.petColor = assignedColor;
                affectedCells.Add(cell);
            }

            // Đếm lùi bom hẹn giờ nếu có
            TickBombsCountdown();

            return affectedCells;
        }

        private void TickBombsCountdown()
        {
            for (int r = 0; r < GridSize; r++)
            {
                for (int c = 0; c < GridSize; c++)
                {
                    var cell = _grid[r, c];
                    if (cell.hazard == HazardType.Bomb && cell.bombTurns > 0)
                    {
                        cell.bombTurns--;
                        if (cell.bombTurns <= 0)
                        {
                            onBombExplodedEvent?.Raise();
                        }
                    }
                }
            }
        }

        /// <summary>
        /// Quét toàn bộ bàn cờ để phát hiện và nổ các hàng & cột hoàn chỉnh
        /// Trả về danh sách tất cả thú cưng được giải cứu
        /// </summary>
        public List<PassengerExtractionInfo> ResolveCompletedLines(out int rowsCleared, out int colsCleared)
        {
            var fullRows = new List<int>();
            var fullCols = new List<int>();

            // 1. Kiểm tra các hàng đầy
            for (int r = 0; r < GridSize; r++)
            {
                bool isRowFull = true;
                for (int c = 0; c < GridSize; c++)
                {
                    if (!_grid[r, c].isOccupied && !_grid[r, c].isLocked)
                    {
                        isRowFull = false;
                        break;
                    }
                }
                if (isRowFull) fullRows.Add(r);
            }

            // 2. Kiểm tra các cột đầy
            for (int c = 0; c < GridSize; c++)
            {
                bool isColFull = true;
                for (int r = 0; r < GridSize; r++)
                {
                    if (!_grid[r, c].isOccupied && !_grid[r, c].isLocked)
                    {
                        isColFull = false;
                        break;
                    }
                }
                if (isColFull) fullCols.Add(c);
            }

            rowsCleared = fullRows.Count;
            colsCleared = fullCols.Count;

            var freedPassengers = new List<PassengerExtractionInfo>();
            if (rowsCleared == 0 && colsCleared == 0)
            {
                return freedPassengers;
            }

            var clearedCellsSet = new HashSet<(int, int)>();
            foreach (int r in fullRows)
            {
                for (int c = 0; c < GridSize; c++) clearedCellsSet.Add((r, c));
            }
            foreach (int c in fullCols)
            {
                for (int r = 0; r < GridSize; r++) clearedCellsSet.Add((r, c));
            }

            // 3. Xử lý nổ ô và thu thập hành khách
            int idCounter = 0;
            foreach (var (r, c) in clearedCellsSet)
            {
                var cell = _grid[r, c];

                // Nếu là băng: giảm 1 HP, nếu còn HP thì chưa giải phóng
                if (cell.hazard == HazardType.Ice && cell.iceHp > 1)
                {
                    cell.iceHp--;
                    continue; // Vẫn còn lớp băng bảo vệ
                }

                // Nếu là đá: không nổ bởi hàng/cột thường
                if (cell.hazard == HazardType.Stone)
                {
                    continue;
                }

                if (cell.isOccupied)
                {
                    freedPassengers.Add(new PassengerExtractionInfo
                    {
                        passengerId = $"p_{DateTime.UtcNow.Ticks}_{idCounter++}",
                        color = cell.petColor,
                        sourceRow = r,
                        sourceCol = c,
                        worldStartPosition = GetCellWorldPosition(r, c)
                    });

                    // Dọn dẹp ô cờ
                    cell.isOccupied = false;
                    cell.hazard = HazardType.None;
                    cell.iceHp = 0;
                }
            }

            onLineClearedEvent?.Raise();
            return freedPassengers;
        }

        /// <summary>
        /// Kích hoạt Búa Rèn Lửa phá tan vùng 3x3 quanh tâm (centerRow, centerCol)
        /// </summary>
        public List<PassengerExtractionInfo> SmashHammer3x3(int centerRow, int centerCol)
        {
            var freedPassengers = new List<PassengerExtractionInfo>();
            int idCounter = 0;

            for (int r = centerRow - 1; r <= centerRow + 1; r++)
            {
                for (int c = centerCol - 1; c <= centerCol + 1; c++)
                {
                    if (r >= 0 && r < GridSize && c >= 0 && c < GridSize)
                    {
                        var cell = _grid[r, c];
                        if (cell.isOccupied)
                        {
                            freedPassengers.Add(new PassengerExtractionInfo
                            {
                                passengerId = $"hammer_{DateTime.UtcNow.Ticks}_{idCounter++}",
                                color = cell.petColor,
                                sourceRow = r,
                                sourceCol = c,
                                worldStartPosition = GetCellWorldPosition(r, c)
                            });
                        }
                        cell.isOccupied = false;
                        cell.hazard = HazardType.None;
                        cell.iceHp = 0;
                        cell.bombTurns = 0;
                    }
                }
            }

            return freedPassengers;
        }
    }
}
