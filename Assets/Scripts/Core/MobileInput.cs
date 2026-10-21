using UnityEngine;

namespace Memancing.Core
{
    /// Titik tunggal untuk semua input. Kawalan sentuh (UI) tulis ke medan "touch*",
    /// papan kekunci/tetikus (untuk uji dalam Editor) digabung dalam property di bawah.
    public class MobileInput : MonoBehaviour
    {
        public static MobileInput I { get; private set; }

        [HideInInspector] public Vector2 touchMove;
        [HideInInspector] public Vector2 touchLook;
        [HideInInspector] public bool touchCast;
        [HideInInspector] public bool touchReel;
        bool cameraTogglePressed;

        Vector2 keyMove, mouseLook;
        bool keyCast, keyReel;

        public Vector2 Move => touchMove.sqrMagnitude > keyMove.sqrMagnitude ? touchMove : keyMove;
        public Vector2 LookDelta => touchLook + mouseLook;
        public bool CastHeld => touchCast || keyCast;
        public bool ReelHeld => touchReel || keyReel;

        void Awake()
        {
            I = this;
            Application.targetFrameRate = 60;
        }

        public void PressCameraToggle() => cameraTogglePressed = true;

        public bool ConsumeCameraToggle()
        {
            bool v = cameraTogglePressed;
            cameraTogglePressed = false;
            return v;
        }

        void Update()
        {
#if UNITY_EDITOR || UNITY_STANDALONE
            // WASD gerak, tahan butang kanan tetikus untuk pusing kamera,
            // Space lontar, Shift kiri gulung, V tukar kamera.
            keyMove = Vector2.ClampMagnitude(new Vector2(Input.GetAxisRaw("Horizontal"), Input.GetAxisRaw("Vertical")), 1f);
            mouseLook = Input.GetMouseButton(1) ? new Vector2(Input.GetAxis("Mouse X"), Input.GetAxis("Mouse Y")) * 4f : Vector2.zero;
            keyCast = Input.GetKey(KeyCode.Space);
            keyReel = Input.GetKey(KeyCode.LeftShift);
            if (Input.GetKeyDown(KeyCode.V)) cameraTogglePressed = true;
#endif
        }

        void LateUpdate()
        {
            // touchLook ialah delta yang terkumpul dalam satu frame; kosongkan selepas dibaca.
            touchLook = Vector2.zero;
        }
    }
}
