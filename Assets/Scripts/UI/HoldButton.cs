using UnityEngine;
using UnityEngine.EventSystems;

namespace Memancing.UI
{
    /// Butang yang dikira "ditekan" selagi jari masih di atasnya (Lontar / Gulung).
    public class HoldButton : MonoBehaviour, IPointerDownHandler, IPointerUpHandler
    {
        public enum Action { Cast, Reel }
        public Action action;

        public void OnPointerDown(PointerEventData e) => Set(true);
        public void OnPointerUp(PointerEventData e) => Set(false);
        void OnDisable() => Set(false);

        void Set(bool v)
        {
            var input = Core.MobileInput.I;
            if (input == null) return;
            if (action == Action.Cast) input.touchCast = v;
            else input.touchReel = v;
        }
    }
}
