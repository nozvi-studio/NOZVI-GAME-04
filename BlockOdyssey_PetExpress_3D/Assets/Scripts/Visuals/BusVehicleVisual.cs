using System.Collections;
using BlockOdyssey.Data;
using UnityEngine;

namespace BlockOdyssey.Visuals
{
    /// <summary>
    /// Diễn hoạt 3D xe buýt đồ chơi:
    /// - Nhún lò xo (Chassis Spring Bounce) khi nhận khách
    /// - 2 tai Corgi / Mèo ve vẩy trên nóc
    /// - Đèn pha rực sáng chiếu quầng vàng
    /// - Tiến vào trạm và cua chữ U xuất bến
    /// </summary>
    public class BusVehicleVisual : MonoBehaviour
    {
        [Header("Bộ phận thân xe")]
        [SerializeField] private Transform chassisRoot;
        [SerializeField] private Transform leftEar;
        [SerializeField] private Transform rightEar;
        [SerializeField] private Light[] headlights;

        [Header("Thông số Nhún lò xo")]
        [SerializeField] private float bounceIntensity = 0.25f;
        [SerializeField] private float bounceDuration = 0.28f;

        private Vector3 _originalChassisPos;
        private Coroutine _bounceCoroutine;

        private void Awake()
        {
            if (chassisRoot != null)
            {
                _originalChassisPos = chassisRoot.localPosition;
            }
        }

        private void Update()
        {
            // Ve vẩy tai dễ thương theo nhịp xoay nhẹ trục Z
            if (leftEar != null && rightEar != null)
            {
                float earWiggle = Mathf.Sin(Time.time * 6.5f) * 6.0f;
                leftEar.localRotation = Quaternion.Euler(0, 0, earWiggle);
                rightEar.localRotation = Quaternion.Euler(0, 0, -earWiggle);
            }
        }

        /// <summary>
        /// Kích hoạt gầm xe nhún nảy đàn hồi khi hành khách nhảy vào lòng xe
        /// </summary>
        public void TriggerBoardingBounce()
        {
            if (_bounceCoroutine != null)
            {
                StopCoroutine(_bounceCoroutine);
            }
            _bounceCoroutine = StartCoroutine(BounceChassisRoutine());
        }

        private IEnumerator BounceChassisRoutine()
        {
            if (chassisRoot == null) yield break;

            float elapsed = 0f;
            while (elapsed < bounceDuration)
            {
                elapsed += Time.deltaTime;
                float progress = elapsed / bounceDuration;

                // Sóng nhún damped spring
                float yOffset = -Mathf.Sin(progress * Mathf.PI * 2f) * bounceIntensity * (1f - progress);
                chassisRoot.localPosition = _originalChassisPos + new Vector3(0, yOffset, 0);

                yield return null;
            }

            chassisRoot.localPosition = _originalChassisPos;
        }

        /// <summary>
        /// Xe buýt xuất bến theo đường cong chữ U (Hairpin loop)
        /// </summary>
        public IEnumerator DepartRoutine(Vector3 exitTarget, float duration = 0.85f)
        {
            Vector3 startPos = transform.position;
            Quaternion startRot = transform.rotation;
            Quaternion targetRot = Quaternion.Euler(0, 180f, 0);

            float elapsed = 0f;
            while (elapsed < duration)
            {
                elapsed += Time.deltaTime;
                float t = Mathf.SmoothStep(0f, 1f, elapsed / duration);

                transform.position = Vector3.Lerp(startPos, exitTarget, t);
                transform.rotation = Quaternion.Slerp(startRot, targetRot, t);

                yield return null;
            }
        }
    }
}
