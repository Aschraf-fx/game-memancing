using UnityEngine;

namespace Memancing.Fishing
{
    /// Lukis tali pancing dari hujung joran ke pelampung, melendut bila kendur.
    [RequireComponent(typeof(LineRenderer))]
    public class FishingLine : MonoBehaviour
    {
        public Transform rodTip;
        public Transform bobber;
        public int segments = 20;
        public float maxSag = 1.2f;

        [HideInInspector] public float tension01; // 0 = kendur, 1 = tegang habis

        LineRenderer lr;

        void Awake()
        {
            lr = GetComponent<LineRenderer>();
            lr.positionCount = segments;
            lr.useWorldSpace = true;
        }

        void LateUpdate()
        {
            bool show = bobber && bobber.gameObject.activeInHierarchy;
            lr.enabled = show;
            if (!show) return;

            Vector3 a = rodTip.position, b = bobber.position;
            float sag = maxSag * (1f - tension01) * Mathf.Clamp01(Vector3.Distance(a, b) / 10f);
            Vector3 mid = (a + b) * 0.5f + Vector3.down * sag * 2f;
            for (int i = 0; i < segments; i++)
            {
                float t = i / (segments - 1f);
                // Lengkung Bezier kuadratik
                Vector3 p = (1 - t) * (1 - t) * a + 2 * (1 - t) * t * mid + t * t * b;
                lr.SetPosition(i, p);
            }
        }
    }
}
