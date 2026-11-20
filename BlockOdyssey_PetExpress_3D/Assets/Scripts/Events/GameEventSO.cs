using System.Collections.Generic;
using UnityEngine;

namespace BlockOdyssey.Events
{
    /// <summary>
    /// ScriptableObject Event Architecture (Decoupled Architecture)
    /// Cho phép các hệ thống Grid, BusStation, UI, Audio truyền tin mà không cần tham chiếu trực tiếp nhau.
    /// </summary>
    [CreateAssetMenu(fileName = "GameEvent", menuName = "BlockOdyssey/Events/GameEvent")]
    public class GameEventSO : ScriptableObject
    {
        private readonly List<GameEventListener> _listeners = new List<GameEventListener>();

        public void Raise()
        {
            for (int i = _listeners.Count - 1; i >= 0; i--)
            {
                _listeners[i].OnEventRaised();
            }
        }

        public void RegisterListener(GameEventListener listener)
        {
            if (!_listeners.Contains(listener))
            {
                _listeners.Add(listener);
            }
        }

        public void UnregisterListener(GameEventListener listener)
        {
            if (_listeners.Contains(listener))
            {
                _listeners.Remove(listener);
            }
        }
    }
}
