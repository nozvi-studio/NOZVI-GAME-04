using UnityEngine;

namespace BlockOdyssey.Visuals
{
    /// <summary>
    /// Thiết lập ánh sáng 3D Stylized Toy Diorama:
    /// - Key Light ấm áp (mặt trời nghiêng)
    /// - Rim Light xanh ngọc (tạo viền sắc nét đồ chơi)
    /// - Ambient Occlusion & Soft Shadow
    /// </summary>
    [ExecuteAlways]
    public class ToyDioramaLighting : MonoBehaviour
    {
        [Header("Nguồn sáng chính (Key Light)")]
        [SerializeField] private Light keyDirectionalLight;
        [SerializeField] private Color warmSunColor = new Color(1.0f, 0.96f, 0.88f);
        [SerializeField] private float keyIntensity = 1.35f;

        [Header("Viền sáng đồ chơi (Rim Light)")]
        [SerializeField] private Light rimDirectionalLight;
        [SerializeField] private Color cyanRimColor = new Color(0.6f, 0.95f, 1.0f);
        [SerializeField] private float rimIntensity = 0.85f;

        private void OnEnable()
        {
            ApplyLightingSetup();
        }

        public void ApplyLightingSetup()
        {
            if (keyDirectionalLight != null)
            {
                keyDirectionalLight.color = warmSunColor;
                keyDirectionalLight.intensity = keyIntensity;
                keyDirectionalLight.shadows = LightShadows.Soft;
            }

            if (rimDirectionalLight != null)
            {
                rimDirectionalLight.color = cyanRimColor;
                rimDirectionalLight.intensity = rimIntensity;
                rimDirectionalLight.shadows = LightShadows.None;
            }
        }
    }
}
