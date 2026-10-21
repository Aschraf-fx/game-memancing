using System;
using UnityEngine;
using Memancing.Fish;

namespace Memancing.Fishing
{
    /// Pelampung + umpan. Terbang ikut fizik bila dilontar, terapung bila kena air,
    /// dan dikawal terus (kinematik) semasa gulung dan bertarung dengan ikan.
    [RequireComponent(typeof(Rigidbody))]
    public class Bobber : MonoBehaviour
    {
        public float floatDamping = 4f;
        public float buoyancy = 18f;
        public ParticleSystem splashFx;
        public AudioSource splashSfx;

        public event Action<FishPool> LandedInWater;
        public event Action LandedOnGround;

        public bool InWater => pool != null;
        public FishPool Pool => pool;
        public float WaterHeight => waterY;

        Rigidbody rb;
        FishPool pool;
        float waterY;
        bool flying;
        float nibbleTimer, nibbleDepth;

        void Awake() => rb = GetComponent<Rigidbody>();

        public void Launch(Vector3 from, Vector3 velocity)
        {
            pool = null;
            flying = true;
            rb.isKinematic = false;
            rb.position = from;
            transform.position = from;
            rb.linearVelocity = velocity;
            gameObject.SetActive(true);
        }

        public void MakeKinematic() { rb.isKinematic = true; flying = false; }

        /// Gerak pelampung ke arah sasaran (dipanggil semasa gulung/bertarung).
        public void DriveTowards(Vector3 target, float maxStep)
        {
            Vector3 p = Vector3.MoveTowards(transform.position, target, maxStep);
            if (InWater) p.y = waterY - nibbleDepth;
            transform.position = p;
        }

        /// Pelampung terhenjut bila ikan menggigit.
        public void Nibble(float duration, float depth)
        {
            nibbleTimer = duration;
            nibbleDepth = depth;
        }

        public void Hide()
        {
            pool = null;
            flying = false;
            gameObject.SetActive(false);
        }

        void Update()
        {
            if (nibbleTimer > 0f)
            {
                nibbleTimer -= Time.deltaTime;
                if (nibbleTimer <= 0f) nibbleDepth = 0f;
            }
        }

        void FixedUpdate()
        {
            if (rb.isKinematic || !InWater) return;
            // Daya apung ringkas: tolak ke atas ikut kedalaman, redam halaju.
            float depth = waterY - rb.position.y - nibbleDepth;
            if (depth > 0f)
            {
                rb.AddForce(Vector3.up * buoyancy * Mathf.Clamp01(depth * 4f), ForceMode.Acceleration);
                rb.linearVelocity *= 1f - floatDamping * Time.fixedDeltaTime;
            }
        }

        void OnTriggerEnter(Collider other)
        {
            if (!flying) return;
            var p = other.GetComponentInParent<FishPool>();
            if (p == null) return;
            pool = p;
            waterY = other.bounds.max.y;
            flying = false;
            var v = rb.linearVelocity;
            rb.linearVelocity = new Vector3(v.x * 0.1f, v.y * 0.2f, v.z * 0.1f);
            if (splashFx) { splashFx.transform.position = new Vector3(transform.position.x, waterY, transform.position.z); splashFx.Play(); }
            if (splashSfx) splashSfx.Play();
            LandedInWater?.Invoke(pool);
        }

        void OnCollisionEnter(Collision c)
        {
            if (!flying) return;
            flying = false;
            LandedOnGround?.Invoke();
        }
    }
}
