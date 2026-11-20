using System;
using UnityEngine;

namespace BlockOdyssey.Core
{
    /// <summary>
    /// Quản lý Kinh tế Người chơi: Tiền vàng, Kim cương, Chuỗi thắng (Win Streak), Cài đặt âm thanh
    /// </summary>
    public class PlayerEconomyManager : MonoBehaviour
    {
        public static PlayerEconomyManager Instance { get; private set; }

        [Header("Tài nguyên")]
        [SerializeField] private int coins = 2450;
        [SerializeField] private int gems = 15;
        [SerializeField] private int winStreak = 3;

        [Header("Cài đặt")]
        [SerializeField] private bool bgmEnabled = true;
        [SerializeField] private bool sfxEnabled = true;
        [SerializeField] private bool hapticsEnabled = true;

        public int Coins => coins;
        public int Gems => gems;
        public int WinStreak => winStreak;
        public bool BgmEnabled => bgmEnabled;
        public bool SfxEnabled => sfxEnabled;
        public bool HapticsEnabled => hapticsEnabled;

        public event Action OnEconomyUpdated;

        private void Awake()
        {
            if (Instance == null)
            {
                Instance = this;
                DontDestroyOnLoad(gameObject);
                LoadData();
            }
            else
            {
                Destroy(gameObject);
            }
        }

        public void AddCoins(int amount)
        {
            coins = Mathf.Max(0, coins + amount);
            SaveData();
            OnEconomyUpdated?.Invoke();
        }

        public bool SpendCoins(int amount)
        {
            if (coins >= amount)
            {
                coins -= amount;
                SaveData();
                OnEconomyUpdated?.Invoke();
                return true;
            }
            return false;
        }

        public void IncrementWinStreak()
        {
            winStreak++;
            SaveData();
            OnEconomyUpdated?.Invoke();
        }

        public void ResetWinStreak()
        {
            winStreak = 0;
            SaveData();
            OnEconomyUpdated?.Invoke();
        }

        public void SetAudioSettings(bool bgm, bool sfx, bool haptics)
        {
            bgmEnabled = bgm;
            sfxEnabled = sfx;
            hapticsEnabled = haptics;
            SaveData();
        }

        private void SaveData()
        {
            PlayerPrefs.SetInt("Player_Coins", coins);
            PlayerPrefs.SetInt("Player_Gems", gems);
            PlayerPrefs.SetInt("Player_Streak", winStreak);
            PlayerPrefs.SetInt("Setting_BGM", bgmEnabled ? 1 : 0);
            PlayerPrefs.SetInt("Setting_SFX", sfxEnabled ? 1 : 0);
            PlayerPrefs.SetInt("Setting_Haptics", hapticsEnabled ? 1 : 0);
            PlayerPrefs.Save();
        }

        private void LoadData()
        {
            coins = PlayerPrefs.GetInt("Player_Coins", 2450);
            gems = PlayerPrefs.GetInt("Player_Gems", 15);
            winStreak = PlayerPrefs.GetInt("Player_Streak", 3);
            bgmEnabled = PlayerPrefs.GetInt("Setting_BGM", 1) == 1;
            sfxEnabled = PlayerPrefs.GetInt("Setting_SFX", 1) == 1;
            hapticsEnabled = PlayerPrefs.GetInt("Setting_Haptics", 1) == 1;
        }
    }
}
