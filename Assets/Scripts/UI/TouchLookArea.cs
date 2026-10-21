using UnityEngine;
using UnityEngine.EventSystems;

namespace Memancing.UI
{
    /// Kawasan lutsinar (separuh kanan skrin) untuk seret dan pusing kamera.
    public class TouchLookArea : MonoBehaviour, IDragHandler
    {
        [Tooltip("Sensitiviti seret (darjah per piksel lebih kurang).")]
        public float sensitivity = 0.15f;

        public void OnDrag(PointerEventData e)
        {
            Core.MobileInput.I.touchLook += e.delta * sensitivity;
        }
    }
}
