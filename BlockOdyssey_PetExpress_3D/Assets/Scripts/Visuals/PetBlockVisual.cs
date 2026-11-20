using UnityEngine;

namespace BlockOdyssey.Visuals
{
    /// <summary>
    /// Diễn hoạt khối gạch thú cưng 3D: Nhịp thở bồng bềnh và chớp mắt Kawaii
    /// </summary>
    public class PetBlockVisual : MonoBehaviour
    {
        [Header("Nhịp thở bồng bềnh (Idle Breathing)")]
        [SerializeField] private float breatheSpeed = 2.4f;
        [SerializeField] private float breatheScaleDelta = 0.04f;

        [Header("Đôi mắt Kawaii")]
        [SerializeField] private Transform leftEye;
        [SerializeField] private Transform rightEye;

        private Vector3 _baseScale;
        private float _blinkTimer = 0f;
        private float _nextBlinkInterval = 3f;

        private void Start()
        {
            _baseScale = transform.localScale;
            _nextBlinkInterval = Random.Range(2.5f, 5.0f);
        }

        private void Update()
        {
            // 1. Nhịp thở
            float scaleMultiplier = 1.0f + Mathf.Sin(Time.time * breatheSpeed) * breatheScaleDelta;
            transform.localScale = new Vector3(
                _baseScale.x * scaleMultiplier,
                _baseScale.y * (2.0f - scaleMultiplier),
                _baseScale.z * scaleMultiplier
            );

            // 2. Chớp mắt
            _blinkTimer += Time.deltaTime;
            if (_blinkTimer >= _nextBlinkInterval)
            {
                if (leftEye != null && rightEye != null)
                {
                    leftEye.localScale = new Vector3(1f, 0.1f, 1f);
                    rightEye.localScale = new Vector3(1f, 0.1f, 1f);
                }

                if (_blinkTimer >= _nextBlinkInterval + 0.12f)
                {
                    if (leftEye != null && rightEye != null)
                    {
                        leftEye.localScale = Vector3.one;
                        rightEye.localScale = Vector3.one;
                    }
                    _blinkTimer = 0f;
                    _nextBlinkInterval = Random.Range(2.5f, 6.0f);
                }
            }
        }
    }
}
