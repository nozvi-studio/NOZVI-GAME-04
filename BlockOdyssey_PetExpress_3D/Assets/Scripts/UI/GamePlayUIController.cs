using BlockOdyssey.Core;
using UnityEngine;
using UnityEngine.UI;

namespace BlockOdyssey.UI
{
    /// <summary>
    /// Điều khiển giao diện màn hình Chơi chính (Screen 1 - GamePlay HUD)
    /// Tương thích hoàn hảo với màn hình dọc điện thoại chuẩn 9:16 (1080 x 1920)
    /// </summary>
    public class GamePlayUIController : MonoBehaviour
    {
        [Header("Thanh HUD đỉnh (Top Bar)")]
        [SerializeField] private Text levelLabel;        // "Level 48"
        [SerializeField] private Text streakLabel;       // "Streak x3"
        [SerializeField] private Text coinsLabel;        // "2,450"
        [SerializeField] private Text scoreLabel;        // "12,500"

        [Header("Trạng thái Xe buýt")]
        [SerializeField] private Text activeBusBadge;    // "Corgi Bus 3/4"
        [SerializeField] private Text queuedBusBadge;    // "Cat Bus 0/4"

        [Header("Kỹ năng Cổ vật (Zone D)")]
        [SerializeField] private Button hammerButton;
        [SerializeField] private Button compassButton;
        [SerializeField] private Button prismButton;
        [SerializeField] private Text hammerCountText;
        [SerializeField] private Text compassCountText;

        [Header("Tham chiếu Logic")]
        [SerializeField] private ActionQueue actionQueue;
        [SerializeField] private BusStationController busStation;
        [SerializeField] private RelicManager relicManager;

        private void Start()
        {
            UpdateHUDDisplay();
            SetupButtonCallbacks();
        }

        private void SetupButtonCallbacks()
        {
            if (hammerButton != null && relicManager != null)
                hammerButton.onClick.AddListener(relicManager.ToggleHammerTargetMode);

            if (compassButton != null && relicManager != null)
                compassButton.onClick.AddListener(relicManager.UseWindCompass);

            if (prismButton != null && relicManager != null)
                prismButton.onClick.AddListener(relicManager.UseMagneticPrism);
        }

        public void UpdateHUDDisplay()
        {
            var economy = PlayerEconomyManager.Instance;
            if (economy != null)
            {
                if (coinsLabel != null) coinsLabel.text = economy.Coins.ToString("N0");
                if (streakLabel != null) streakLabel.text = $"Streak x{economy.WinStreak}";
            }

            if (actionQueue != null && scoreLabel != null)
            {
                scoreLabel.text = actionQueue.CurrentScore.ToString("N0");
            }

            if (busStation != null)
            {
                if (activeBusBadge != null && busStation.ActiveBus != null)
                {
                    activeBusBadge.text = $"{busStation.ActiveBus.busName} {busStation.ActiveBus.currentPassengers}/{busStation.ActiveBus.capacity}";
                }
            }

            if (relicManager != null)
            {
                if (hammerCountText != null) hammerCountText.text = relicManager.hammerCount.ToString();
                if (compassCountText != null) compassCountText.text = relicManager.compassCount.ToString();
            }
        }
    }
}
