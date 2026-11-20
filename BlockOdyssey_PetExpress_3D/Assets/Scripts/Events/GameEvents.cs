using System;
using BlockOdyssey.Data;
using UnityEngine;

namespace BlockOdyssey.Events
{
    public struct PassengerExtractionInfo
    {
        public string passengerId;
        public PetColor color;
        public int sourceRow;
        public int sourceCol;
        public Vector3 worldStartPosition;
    }

    public struct LineClearEventData
    {
        public int clearedRowsCount;
        public int clearedColsCount;
        public int comboMultiplier;
        public int scoreEarned;
    }

    public struct BusBoardedEventData
    {
        public PetColor petColor;
        public string busId;
        public int currentPassengers;
        public int busCapacity;
    }

    public struct DockBoardedEventData
    {
        public PetColor petColor;
        public int slotIndex;
    }
}
