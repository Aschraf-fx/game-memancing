using UnityEngine;
using Memancing.Core;

namespace Memancing.CameraRig
{
    /// Kamera boleh tukar antara FPV (mata pemain) dan TPV (atas bahu).
    /// Letak pada Main Camera. Pemain berpusing ikut yaw kamera.
    public class AnglerCamera : MonoBehaviour
    {
        public enum Mode { FirstPerson, ThirdPerson }

        public Transform player;
        public Transform headAnchor; // tulang kepala atau empty pada ketinggian mata
        [Tooltip("Renderer badan pemain yang disorok dalam FPV (bayang masih kekal).")]
        public Renderer[] hideInFirstPerson;

        public Mode mode = Mode.ThirdPerson;

        [Header("Pusing")]
        public float minPitch = -60f;
        public float maxPitch = 75f;

        [Header("TPV")]
        public Vector3 shoulderOffset = new Vector3(0.45f, 0.15f, 0f);
        public float distance = 3.2f;
        public float collisionRadius = 0.2f;
        public LayerMask collisionMask = ~0;
        public float smooth = 12f;

        float yaw, pitch = 10f;
        float currentDistance;

        void Start()
        {
            yaw = player.eulerAngles.y;
            currentDistance = distance;
            ApplyMode();
        }

        public void Toggle()
        {
            mode = mode == Mode.FirstPerson ? Mode.ThirdPerson : Mode.FirstPerson;
            ApplyMode();
        }

        void ApplyMode()
        {
            var shadows = mode == Mode.FirstPerson
                ? UnityEngine.Rendering.ShadowCastingMode.ShadowsOnly
                : UnityEngine.Rendering.ShadowCastingMode.On;
            foreach (var r in hideInFirstPerson) if (r) r.shadowCastingMode = shadows;
        }

        void LateUpdate()
        {
            if (MobileInput.I.ConsumeCameraToggle()) Toggle();

            Vector2 look = MobileInput.I.LookDelta;
            yaw += look.x;
            pitch = Mathf.Clamp(pitch - look.y, minPitch, maxPitch);
            player.rotation = Quaternion.Euler(0f, yaw, 0f);

            Quaternion rot = Quaternion.Euler(pitch, yaw, 0f);
            Vector3 head = headAnchor.position;

            if (mode == Mode.FirstPerson)
            {
                transform.SetPositionAndRotation(head, rot);
                return;
            }

            Vector3 pivot = head + rot * new Vector3(shoulderOffset.x, shoulderOffset.y, 0f);
            float target = distance;
            if (Physics.SphereCast(pivot, collisionRadius, rot * Vector3.back, out var hit, distance, collisionMask, QueryTriggerInteraction.Ignore))
                target = Mathf.Max(0.3f, hit.distance);
            // Masuk cepat bila terlanggar, keluar perlahan supaya tak tersentak.
            currentDistance = target < currentDistance ? target : Mathf.Lerp(currentDistance, target, smooth * Time.deltaTime);

            transform.SetPositionAndRotation(pivot + rot * Vector3.back * currentDistance, rot);
        }
    }
}
