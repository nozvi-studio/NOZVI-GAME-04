using System;
using BlockOdyssey.Core;
using UnityEngine;
using UnityEngine.UI;

namespace BlockOdyssey.UI
{
    /// <summary>
    /// Điều khiển giao diện Đảo Thú Cưng 3D & Doanh thu nhàn rỗi (Screen 3 - Sanctuary & Idle)
    /// </summary>
    public class SanctuaryUIController : MonoBehaviour
    {
        [Header("Rương Vàng Khổng Lồ Thu Hoạch Xu")]
        [SerializeField] private Button harvestChestButton;
        [SerializeField] private Text pendingCoinsText;
        [SerializeField] private ParticleSystem coinFountainVFX;

        [Header("Khu nghỉ dưỡng")]
        [SerializeField] private GameObject catCafeZone;
        [SerializeField] private GameObject duckPoolZone;
        [SerializeField] private GameObject corgiBeachZone;

        private float _idleAccumulatedCoins = 480f;
        private float _coinsPerSecond = 0.5f;

        private void Update()
        {
            _idleAccumulatedCoins += _coinsPerSecond * Time.deltaTime;
            if (pendingCoinsText != null)
            {
                pendingCoinsText.text = $"Thu Hoạch +{Mathf.FloorToInt(_idleAccumulatedCoins)} Xu (Idle)";
            }
        }

        public void ClaimIdleIncome()
        {
            int amount = Mathf.FloorToInt(_idleAccumulatedCoins);
            if (amount > 0)
            {
                PlayerEconomyManager.Instance?.AddCoins(amount);
                _idleAccumulatedCoins = 0f;

                if (coinFountainVFX != null)
                {
                    coinFountainVFX.Play();
                }
            }
        }
    }
}
