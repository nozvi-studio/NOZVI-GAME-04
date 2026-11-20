using UnityEngine;

namespace BlockOdyssey.Data
{
    /// <summary>
    /// ScriptableObject định nghĩa bộ giao diện (Skin Theme)
    /// </summary>
    [CreateAssetMenu(fileName = "GameSkin", menuName = "BlockOdyssey/Data/GameSkin")]
    public class GameSkinSO : ScriptableObject
    {
        public GameSkinTheme themeId;
        public string skinName;
        public string description;
        public Sprite previewBanner;
        public int unlockCostCoins = 300;

        [Header("Shader & Vật liệu tùy chỉnh")]
        public Material boardWoodMaterial;
        public Material blockBaseMaterial;
        public Material busBodyMaterial;
        public Material holdingBenchMaterial;

        [Header("Ghi đè hình thái khối (Mesh Overrides)")]
        public Mesh blockMeshOverride;
        public bool useJellyBouncePhysics = false;
        public bool useRgbLightingEmission = false;
    }
}
