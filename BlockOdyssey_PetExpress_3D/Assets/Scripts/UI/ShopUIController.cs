using BlockOdyssey.Core;
using BlockOdyssey.Data;
using UnityEngine;
using UnityEngine.UI;

namespace BlockOdyssey.UI
{
    /// <summary>
    /// Điều khiển giao diện Kho Skin & Cổ vật (Screen 4 - Skins & Relics)
    /// Có đài trưng bày xoay tròn 3D và đèn rọi Spotlight vào Boss Corgi
    /// </summary>
    public class ShopUIController : MonoBehaviour
    {
        [Header("Đài trưng bày 3D có đèn rọi")]
        [SerializeField] private Transform revolvingPedestal;
        [SerializeField] private float rotationSpeed = 30f;
        [SerializeField] private Light spotlight;

        [Header("Danh mục Skin")]
        [SerializeField] private Button jellyPuddingSkinButton;
        [SerializeField] private Button rgbKeycapSkinButton;
        [SerializeField] private Button jadeMahjongSkinButton;

        [Header("Thẻ nâng cấp Cổ vật")]
        [SerializeField] private Button upgradeHammerButton;
        [SerializeField] private Button upgradeCompassButton;
        [SerializeField] private Button upgradePrismButton;

        private void Update()
        {
            if (revolvingPedestal != null)
            {
                revolvingPedestal.Rotate(Vector3.up, rotationSpeed * Time.deltaTime);
            }
        }

        public void EquipSkin(GameSkinTheme theme)
        {
            Debug.Log($"Trang bị Skin: {theme}");
        }
    }
}
