using System;
using System.Collections.Generic;
using UnityEngine;

namespace BlockOdyssey.Data
{
    [Serializable]
    public class InitialCellData
    {
        public int row;
        public int col;
        public bool hasPet;
        public PetColor petColor;
        public HazardType hazard = HazardType.None;
        public int iceHp = 0;       // 1 hoặc 2
        public int bombTurns = 0;    // Số lượt đếm lùi
        public bool isLocked = false;
    }

    [Serializable]
    public class BusRequirement
    {
        public string busId;
        public PetColor color;
        public string busName;
        public int capacity = 4;
        public bool isRainbow = false;
    }

    /// <summary>
    /// ScriptableObject cấu hình màn chơi: kích thước 8x8, danh sách xe buýt, chướng ngại vật
    /// </summary>
    [CreateAssetMenu(fileName = "LevelData", menuName = "BlockOdyssey/Data/LevelData")]
    public class LevelDataSO : ScriptableObject
    {
        [Header("Thông tin chương & màn")]
        public int levelNumber;
        public int chapterNumber;
        public string chapterName;
        [TextArea(2, 4)] public string description;

        [Header("Độ khó & Màu sắc")]
        public List<PetColor> availableColors = new List<PetColor> { PetColor.Red, PetColor.Yellow };
        public int targetScore = 2000;

        [Header("Quy định Đội xe buýt (Bus Fleet)")]
        public List<BusRequirement> buses = new List<BusRequirement>();

        [Header("Khóa ghế chờ (Thắt cổ chai Holding Dock)")]
        public List<int> lockedDockSlots = new List<int>(); // Ví dụ: [3, 4] chỉ còn 3 ghế

        [Header("Bố cục khởi tạo bàn cờ 8x8")]
        public List<InitialCellData> initialGrid = new List<InitialCellData>();
    }
}
