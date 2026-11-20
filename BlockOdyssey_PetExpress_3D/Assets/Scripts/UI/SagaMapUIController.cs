using BlockOdyssey.Core;
using UnityEngine;
using UnityEngine.UI;

namespace BlockOdyssey.UI
{
    /// <summary>
    /// Điều khiển giao diện Bản Đồ Hành Trình 3D (Screen 2 - Saga Map)
    /// Hiển thị các đảo bay Diorama và Nút vàng 3D khổng lồ 'PLAY'
    /// </summary>
    public class SagaMapUIController : MonoBehaviour
    {
        [Header("Nút Play 3D Cực Đại")]
        [SerializeField] private Button playButton;
        [SerializeField] private Text unlockedLevelText;

        [Header("Các đảo bay Diorama")]
        [SerializeField] private Transform[] islandDioramaRoots;
        [SerializeField] private Button[] milestoneChestButtons;

        private void Start()
        {
            if (playButton != null)
            {
                playButton.onClick.AddListener(OnPlayButtonClicked);
            }
        }

        private void OnPlayButtonClicked()
        {
            Debug.Log("Vào trận màn chơi tiếp theo!");
        }

        public void RefreshMilestones(int maxClearedLevel)
        {
            if (unlockedLevelText != null)
            {
                unlockedLevelText.text = $"Lv.{maxClearedLevel + 1}";
            }
        }
    }
}
