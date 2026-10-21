using UnityEngine;
using UnityEngine.EventSystems;

namespace Memancing.UI
{
    /// Joystick maya untuk berjalan. Letak pada Image bulat (latar) dengan anak "Knob".
    public class TouchJoystick : MonoBehaviour, IPointerDownHandler, IDragHandler, IPointerUpHandler
    {
        public RectTransform knob;
        public float radius = 90f;

        RectTransform rt;

        void Awake() => rt = (RectTransform)transform;

        public void OnPointerDown(PointerEventData e) => OnDrag(e);

        public void OnDrag(PointerEventData e)
        {
            RectTransformUtility.ScreenPointToLocalPointInRectangle(rt, e.position, e.pressEventCamera, out var local);
            var v = Vector2.ClampMagnitude(local, radius);
            if (knob) knob.anchoredPosition = v;
            Core.MobileInput.I.touchMove = v / radius;
        }

        public void OnPointerUp(PointerEventData e)
        {
            if (knob) knob.anchoredPosition = Vector2.zero;
            Core.MobileInput.I.touchMove = Vector2.zero;
        }
    }
}
