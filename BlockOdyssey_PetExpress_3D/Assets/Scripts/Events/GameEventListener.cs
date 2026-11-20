using UnityEngine;
using UnityEngine.Events;

namespace BlockOdyssey.Events
{
    /// <summary>
    /// Component lắng nghe GameEventSO và kích hoạt phản hồi trên Inspector
    /// </summary>
    public class GameEventListener : MonoBehaviour
    {
        [Tooltip("Sự kiện ScriptableObject cần lắng nghe")]
        public GameEventSO gameEvent;

        [Tooltip("Hành động kích hoạt khi sự kiện xảy ra")]
        public UnityEvent response;

        private void OnEnable()
        {
            if (gameEvent != null)
            {
                gameEvent.RegisterListener(this);
            }
        }

        private void OnDisable()
        {
            if (gameEvent != null)
            {
                gameEvent.UnregisterListener(this);
            }
        }

        public void OnEventRaised()
        {
            response?.Invoke();
        }
    }
}
