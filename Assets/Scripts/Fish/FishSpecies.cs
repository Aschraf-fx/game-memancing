using UnityEngine;

namespace Memancing.Fish
{
    /// Data satu spesies ikan. Buat aset baru: Create > Memancing > Fish Species.
    [CreateAssetMenu(menuName = "Memancing/Fish Species", fileName = "Ikan_")]
    public class FishSpecies : ScriptableObject
    {
        public string displayName = "Tilapia";
        public GameObject prefab;

        [Header("Saiz (kg)")]
        public float minWeight = 0.3f;
        public float maxWeight = 2f;

        [Header("Kelakuan")]
        [Tooltip("Kekuatan tarikan ikan (N). Lebih tinggi = lebih susah.")]
        public float pullStrength = 20f;
        [Tooltip("Berapa kerap ikan meronta (0-1).")]
        [Range(0, 1)] public float aggression = 0.4f;
        [Tooltip("Stamina ikan dalam saat sebelum letih.")]
        public float stamina = 12f;

        [Header("Ekonomi")]
        public int coinsPerKg = 10;

        [Header("Kebarangkalian")]
        [Tooltip("Pemberat peluang muncul berbanding ikan lain di kawasan sama.")]
        public float spawnWeight = 1f;
        [Tooltip("Kedalaman pilihan (m) dari permukaan.")]
        public Vector2 preferredDepth = new Vector2(0.5f, 3f);
    }
}
