using UnityEngine;

namespace BlockOdyssey.Data
{
    /// <summary>
    /// ScriptableObject chứa toàn bộ thông tin nhận diện, thẩm mỹ và âm thanh của từng bé thú cưng
    /// </summary>
    [CreateAssetMenu(fileName = "PetColorData", menuName = "BlockOdyssey/Data/PetColorData")]
    public class PetColorDataSO : ScriptableObject
    {
        [Header("Thông tin cơ bản")]
        public PetColor petColor;
        public string displayName;
        public Color primaryColor = Color.white;
        public Color secondaryColor = Color.white;

        [Header("Đồ họa 3D Stylized Toy")]
        public GameObject blockModelPrefab;
        public Sprite uiIcon;
        public Material toyMaterial;

        [Header("Hiệu ứng & Âm thanh")]
        public Color particleGlowColor = Color.yellow;
        public AudioClip voiceSoundClip;
        [Range(0.8f, 1.4f)] public float voicePitch = 1.0f;
    }
}
