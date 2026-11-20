using System;
using System.Collections;
using UnityEngine;

namespace BlockOdyssey.Visuals
{
    /// <summary>
    /// Tạo quỹ đạo bay Parabol mượt mà theo đường cong Bezier cho thú cưng khi giải cứu
    /// Kèm hiệu ứng Squash & Stretch và tia sáng TrailRenderer
    /// </summary>
    public class ParabolicJumper : MonoBehaviour
    {
        [Header("Thông số đường bay Parabol")]
        [SerializeField] private float jumpDuration = 0.45f;
        [SerializeField] private float arcPeakHeight = 2.8f;
        [SerializeField] private AnimationCurve scaleCurve = AnimationCurve.EaseInOut(0, 1, 1, 1);

        [Header("Hiệu ứng Hạt & Vệt sáng")]
        [SerializeField] private TrailRenderer trailRenderer;
        [SerializeField] private ParticleSystem landingPuffParticles;

        /// <summary>
        /// Bắn thú cưng theo đường cong parabol từ startPos đến targetPos
        /// </summary>
        public void Launch(Vector3 startPos, Vector3 targetPos, Action onComplete = null)
        {
            StartCoroutine(JumpRoutine(startPos, targetPos, onComplete));
        }

        private IEnumerator JumpRoutine(Vector3 p0, Vector3 p2, Action onComplete)
        {
            transform.position = p0;

            if (trailRenderer != null)
            {
                trailRenderer.Clear();
                trailRenderer.emitting = true;
            }

            // Điểm đỉnh điều khiển Bezier P1: trung điểm đẩy lên cao theo trục Y
            Vector3 p1 = (p0 + p2) * 0.5f + Vector3.up * arcPeakHeight;

            float elapsed = 0f;
            Vector3 initialScale = transform.localScale;

            while (elapsed < jumpDuration)
            {
                elapsed += Time.deltaTime;
                float t = Mathf.Clamp01(elapsed / jumpDuration);

                // Công thức đường cong Quadratic Bezier: B(t) = (1-t)^2 * P0 + 2(1-t)t * P1 + t^2 * P2
                float oneMinusT = 1f - t;
                Vector3 currentPos = (oneMinusT * oneMinusT * p0) + (2f * oneMinusT * t * p1) + (t * t * p2);
                transform.position = currentPos;

                // Squash & Stretch: kéo dài nhẹ khi bay, nén nhẹ khi tiếp đất
                float stretchFactor = 1f + Mathf.Sin(t * Mathf.PI) * 0.25f;
                transform.localScale = new Vector3(
                    initialScale.x / Mathf.Sqrt(stretchFactor),
                    initialScale.y * stretchFactor,
                    initialScale.z / Mathf.Sqrt(stretchFactor)
                );

                yield return null;
            }

            transform.position = p2;
            transform.localScale = initialScale;

            if (trailRenderer != null)
            {
                trailRenderer.emitting = false;
            }

            if (landingPuffParticles != null)
            {
                landingPuffParticles.Play();
            }

            onComplete?.Invoke();
        }
    }
}
