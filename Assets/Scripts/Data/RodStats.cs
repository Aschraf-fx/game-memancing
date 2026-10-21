using UnityEngine;

namespace Memancing.Data
{
    /// Statistik joran + tali. Fasa 2 kedai akan jual variasi aset ni.
    [CreateAssetMenu(menuName = "Memancing/Rod Stats", fileName = "Joran_")]
    public class RodStats : ScriptableObject
    {
        public string displayName = "Joran Buluh";
        [Tooltip("Jarak lontaran maksimum (m).")]
        public float maxCastDistance = 25f;
        [Tooltip("Masa (s) untuk charge penuh.")]
        public float chargeTime = 1.2f;
        [Tooltip("Had ketegangan tali sebelum putus (N).")]
        public float lineBreakTension = 60f;
        [Tooltip("Kelajuan gulung kekili (m/s).")]
        public float reelSpeed = 1.6f;
        [Tooltip("Daya gulung (N) bila butang reel ditekan.")]
        public float reelForce = 35f;
        [Tooltip("Drag kekili: lepaskan tali bila tegang melebihi nisbah ini.")]
        [Range(0.5f, 1f)] public float dragThreshold = 0.85f;
    }
}
