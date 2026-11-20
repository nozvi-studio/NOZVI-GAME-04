using System.Collections.Generic;
using BlockOdyssey.Core;
using BlockOdyssey.Data;
using BlockOdyssey.Events;
using NUnit.Framework;
using UnityEngine;

namespace BlockOdyssey.Tests
{
    [TestFixture]
    public class BlockOdysseyCoreTests
    {
        private GameObject _testRunnerGo;
        private GridBoardController _gridBoard;
        private BusStationController _busStation;

        [SetUp]
        public void SetUp()
        {
            _testRunnerGo = new GameObject("TestRunnerContext");
            _gridBoard = _testRunnerGo.AddComponent<GridBoardController>();
            _busStation = _testRunnerGo.AddComponent<BusStationController>();

            _gridBoard.InitializeEmptyGrid();
            _busStation.InitializeDock();
        }

        [TearDown]
        public void TearDown()
        {
            if (_testRunnerGo != null)
            {
                Object.DestroyImmediate(_testRunnerGo);
            }
        }

        [Test]
        public void Test_PolyominoRotation_RotatesClockwiseAndNormalizes()
        {
            // Tạo khối 2x1 nằm ngang: (0,0) và (0,1)
            var shape = ScriptableObject.CreateInstance<PolyominoShapeSO>();
            shape.shapeId = "domino_h";
            shape.shapeName = "Domino Horizontal";
            shape.width = 2;
            shape.height = 1;
            shape.localTiles = new[]
            {
                new Vector2IntCoord(0, 0),
                new Vector2IntCoord(0, 1)
            };

            // Xoay 90 độ -> khối 1x2 đứng
            var rotated = shape.CreateRotatedClockwise();
            Assert.AreEqual(1, rotated.width, "Width sau xoay phải là 1");
            Assert.AreEqual(2, rotated.height, "Height sau xoay phải là 2");

            // Kiểm tra tọa độ đã được chuẩn hóa về (0,0) và (1,0)
            Assert.AreEqual(2, rotated.localTiles.Length);
            Assert.IsTrue((rotated.localTiles[0].r == 0 && rotated.localTiles[0].c == 0) ||
                          (rotated.localTiles[1].r == 0 && rotated.localTiles[1].c == 0));
        }

        [Test]
        public void Test_GridBoard_CanPlaceShapeAt_DetectsCollisionAndBoundary()
        {
            var dot = ScriptableObject.CreateInstance<PolyominoShapeSO>();
            dot.width = 1;
            dot.height = 1;
            dot.localTiles = new[] { new Vector2IntCoord(0, 0) };

            // Ô hợp lệ
            Assert.IsTrue(_gridBoard.CanPlaceShapeAt(dot, 0, 0));
            Assert.IsTrue(_gridBoard.CanPlaceShapeAt(dot, 7, 7));

            // Vượt biên
            Assert.IsFalse(_gridBoard.CanPlaceShapeAt(dot, -1, 0));
            Assert.IsFalse(_gridBoard.CanPlaceShapeAt(dot, 8, 0));

            // Đặt 1 khối
            _gridBoard.PlaceShape(dot, 3, 3, PetColor.Red);
            Assert.IsTrue(_gridBoard.Grid[3, 3].isOccupied);

            // Thử đặt đè lên ô đã có khối -> phải từ chối
            Assert.IsFalse(_gridBoard.CanPlaceShapeAt(dot, 3, 3));
        }

        [Test]
        public void Test_GridBoard_LineClearAndSimultaneousRowColClear()
        {
            var dot = ScriptableObject.CreateInstance<PolyominoShapeSO>();
            dot.width = 1;
            dot.height = 1;
            dot.localTiles = new[] { new Vector2IntCoord(0, 0) };

            // Lấp đầy hàng 2 (7 ô đầu)
            for (int c = 0; c < 7; c++)
            {
                _gridBoard.PlaceShape(dot, 2, c, PetColor.Red);
            }
            int rCleared, cCleared;
            var freed = _gridBoard.ResolveCompletedLines(out rCleared, out cCleared);
            Assert.AreEqual(0, rCleared, "Hàng chưa đầy 8 ô thì không được nổ");

            // Lấp ô cuối cùng của hàng 2
            _gridBoard.PlaceShape(dot, 2, 7, PetColor.Yellow);
            freed = _gridBoard.ResolveCompletedLines(out rCleared, out cCleared);

            Assert.AreEqual(1, rCleared, "Hàng 2 phải nổ");
            Assert.AreEqual(8, freed.Count, "Phải giải cứu 8 bé thú cưng");
            Assert.IsFalse(_gridBoard.Grid[2, 0].isOccupied, "Ô sau khi nổ phải được dọn sạch");
        }

        [Test]
        public void Test_BusStation_PriorityBoarding_MatchingGoesToBus_NonMatchingGoesToDock()
        {
            var levelData = ScriptableObject.CreateInstance<LevelDataSO>();
            levelData.buses = new List<BusRequirement>
            {
                new BusRequirement { busId = "b1", color = PetColor.Red, busName = "Corgi Bus", capacity = 2 },
                new BusRequirement { busId = "b2", color = PetColor.Yellow, busName = "Cat Bus", capacity = 3 }
            };

            _busStation.SetupBusesFromLevel(levelData);

            Assert.IsNotNull(_busStation.ActiveBus);
            Assert.AreEqual(PetColor.Red, _busStation.ActiveBus.color);

            var passengers = new List<PassengerExtractionInfo>
            {
                new PassengerExtractionInfo { passengerId = "p1", color = PetColor.Red, sourceRow = 0, sourceCol = 0 },
                new PassengerExtractionInfo { passengerId = "p2", color = PetColor.Yellow, sourceRow = 0, sourceCol = 1 }
            };

            _busStation.ProcessExtractedPassengers(passengers, null);

            // Bé Corgi Đỏ phải nhảy lên xe Corgi Đỏ
            Assert.AreEqual(1, _busStation.ActiveBus.currentPassengers);

            // Bé Mèo Vàng phải vào ghế chờ Holding Dock đầu tiên
            Assert.IsTrue(_busStation.DockSeats[0].isOccupied);
            Assert.AreEqual(PetColor.Yellow, _busStation.DockSeats[0].petColor);
        }

        [Test]
        public void Test_BusStation_AutoPullMatchingPetsFromDock_WhenNewBusArrives()
        {
            var levelData = ScriptableObject.CreateInstance<LevelDataSO>();
            levelData.buses = new List<BusRequirement>
            {
                new BusRequirement { busId = "b1", color = PetColor.Red, busName = "Corgi Bus", capacity = 1 },
                new BusRequirement { busId = "b2", color = PetColor.Yellow, busName = "Cat Bus", capacity = 3 }
            };

            _busStation.SetupBusesFromLevel(levelData);

            // Đặt sẵn 2 bé Mèo Vàng ở ghế chờ (Holding Dock)
            _busStation.DockSeats[0].isOccupied = true;
            _busStation.DockSeats[0].petColor = PetColor.Yellow;

            _busStation.DockSeats[1].isOccupied = true;
            _busStation.DockSeats[1].petColor = PetColor.Yellow;

            // Đưa 1 bé Corgi Đỏ lên xe b1 để xe b1 đủ 1/1 khách và xuất bến
            var passengers = new List<PassengerExtractionInfo>
            {
                new PassengerExtractionInfo { passengerId = "p_corgi", color = PetColor.Red, sourceRow = 0, sourceCol = 0 }
            };
            _busStation.ProcessExtractedPassengers(passengers, null);

            // Xe b1 đã đầy -> Xuất bến -> Xe b2 (Mèo Vàng) lập tức tiến vào trạm
            Assert.AreEqual(1, _busStation.TotalDispatchedCount, "Xe b1 phải đã xuất bến");
            Assert.IsNotNull(_busStation.ActiveBus);
            Assert.AreEqual(PetColor.Yellow, _busStation.ActiveBus.color, "Xe mới phải là Cat Bus");

            // QUY TẮC CỐT LÕI: Tự động hút 2 bé Mèo Vàng từ ghế chờ lên xe mới!
            Assert.AreEqual(2, _busStation.ActiveBus.currentPassengers, "Cat Bus phải tự động nhận 2 bé từ ghế chờ");
            Assert.IsFalse(_busStation.DockSeats[0].isOccupied, "Ghế 0 phải được giải phóng trống");
            Assert.IsFalse(_busStation.DockSeats[1].isOccupied, "Ghế 1 phải được giải phóng trống");
        }
    }
}
