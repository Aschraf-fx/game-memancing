using UnityEngine;

namespace Memancing.Core
{
    /// Hanyut perlahan untuk objek terapung (daun, sampan tertambat) supaya air nampak hidup.
    public class WaterBob : MonoBehaviour
    {
        public float amplitude = 0.03f;
        public float frequency = 0.6f;
        public float tiltDegrees = 2f;

        Vector3 basePos;
        Quaternion baseRot;
        float seed;

        void Start()
        {
            basePos = transform.position;
            baseRot = transform.rotation;
            seed = Random.value * 100f;
        }

        void Update()
        {
            float t = Time.time * frequency + seed;
            transform.position = basePos + Vector3.up * Mathf.Sin(t * Mathf.PI * 2f) * amplitude;
            transform.rotation = baseRot * Quaternion.Euler(Mathf.Sin(t * 1.3f) * tiltDegrees, 0f, Mathf.Cos(t * 0.9f) * tiltDegrees);
        }
    }
}
