using UnityEngine;
using Memancing.Core;

namespace Memancing.Player
{
    /// Pergerakan pemain berjalan kaki. Perlukan CharacterController.
    /// Arah pandang (yaw) dikawal oleh CameraRig; skrip ni cuma gerak relatif kepadanya.
    [RequireComponent(typeof(CharacterController))]
    public class AnglerController : MonoBehaviour
    {
        public float walkSpeed = 2.2f;
        public float gravity = -15f;
        public Animator animator; // pilihan: parameter float "Speed"

        [HideInInspector] public bool movementLocked; // dikunci semasa lontar/gulung

        CharacterController cc;
        float verticalVel;
        static readonly int SpeedHash = Animator.StringToHash("Speed");

        void Awake() => cc = GetComponent<CharacterController>();

        void Update()
        {
            Vector2 m = movementLocked ? Vector2.zero : MobileInput.I.Move;
            Vector3 dir = transform.right * m.x + transform.forward * m.y;

            verticalVel = cc.isGrounded ? -1f : verticalVel + gravity * Time.deltaTime;
            cc.Move((dir * walkSpeed + Vector3.up * verticalVel) * Time.deltaTime);

            if (animator) animator.SetFloat(SpeedHash, m.magnitude, 0.1f, Time.deltaTime);
        }
    }
}
