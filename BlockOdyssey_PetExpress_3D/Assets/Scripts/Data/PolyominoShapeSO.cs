using System;
using UnityEngine;

namespace BlockOdyssey.Data
{
    [Serializable]
    public struct Vector2IntCoord
    {
        public int r;
        public int c;

        public Vector2IntCoord(int row, int col)
        {
            r = row;
            c = col;
        }
    }

    /// <summary>
    /// ScriptableObject định nghĩa khối gạch Polyomino (1x1, Domino, Triomino, Tetromino, Pentomino)
    /// </summary>
    [CreateAssetMenu(fileName = "PolyominoShape", menuName = "BlockOdyssey/Data/PolyominoShape")]
    public class PolyominoShapeSO : ScriptableObject
    {
        public string shapeId;
        public string shapeName;
        public int width;
        public int height;
        public Vector2IntCoord[] localTiles;
        public Sprite previewIcon;

        /// <summary>
        /// Xoay 90 độ theo chiều kim đồng hồ và chuẩn hóa tọa độ về (0,0)
        /// Dùng cho bảo bối La Bàn Gió (Wind Compass)
        /// </summary>
        public PolyominoShapeSO CreateRotatedClockwise()
        {
            var rotated = CreateInstance<PolyominoShapeSO>();
            rotated.shapeId = $"{shapeId}_rot";
            rotated.shapeName = $"{shapeName} (Rotated)";
            rotated.width = height;
            rotated.height = width;

            var newTiles = new Vector2IntCoord[localTiles.Length];
            int minR = int.MaxValue;
            int minC = int.MaxValue;

            for (int i = 0; i < localTiles.Length; i++)
            {
                // Công thức xoay 90 độ: new_r = c, new_c = (height - 1 - r)
                int nr = localTiles[i].c;
                int nc = height - 1 - localTiles[i].r;
                newTiles[i] = new Vector2IntCoord(nr, nc);

                if (nr < minR) minR = nr;
                if (nc < minC) minC = nc;
            }

            // Chuẩn hóa về gốc (0,0)
            for (int i = 0; i < newTiles.Length; i++)
            {
                newTiles[i] = new Vector2IntCoord(newTiles[i].r - minR, newTiles[i].c - minC);
            }

            rotated.localTiles = newTiles;
            rotated.previewIcon = previewIcon;
            return rotated;
        }
    }
}
