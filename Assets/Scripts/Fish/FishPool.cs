using System.Collections.Generic;
using UnityEngine;

namespace Memancing.Fish
{
    /// Senarai ikan yang ada dalam satu kawasan air (kolam, sungai, dll).
    /// Letak pada GameObject air bersama collider trigger.
    public class FishPool : MonoBehaviour
    {
        public string areaName = "Kolam Kampung";
        public List<FishSpecies> species = new List<FishSpecies>();

        [Tooltip("Purata saat sebelum ikan menyambar umpan.")]
        public Vector2 biteDelay = new Vector2(3f, 12f);

        public FishSpecies RollSpecies()
        {
            float total = 0f;
            foreach (var s in species) total += s.spawnWeight;
            float r = Random.value * total;
            foreach (var s in species)
            {
                r -= s.spawnWeight;
                if (r <= 0f) return s;
            }
            return species.Count > 0 ? species[species.Count - 1] : null;
        }

        public float RollBiteDelay() => Random.Range(biteDelay.x, biteDelay.y);
    }
}
