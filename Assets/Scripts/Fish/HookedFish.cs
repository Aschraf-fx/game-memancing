using UnityEngine;

namespace Memancing.Fish
{
    /// Keadaan ikan yang sedang terkena mata kail (logik sahaja, tiada model).
    public class HookedFish
    {
        public readonly FishSpecies species;
        public readonly float weight;
        public float staminaLeft;

        float surgeTimer;
        float currentPull;

        public HookedFish(FishSpecies s)
        {
            species = s;
            // Taburan condong ke saiz kecil; ikan besar jarang.
            weight = Mathf.Lerp(s.minWeight, s.maxWeight, Mathf.Pow(Random.value, 2.2f));
            staminaLeft = s.stamina * Mathf.Lerp(0.8f, 1.4f, Mathf.InverseLerp(s.minWeight, s.maxWeight, weight));
        }

        public bool Exhausted => staminaLeft <= 0f;

        /// Tarikan ikan (N) bagi frame ini. Ikan meronta secara rawak, makin lemah bila letih.
        public float Tick(float dt)
        {
            surgeTimer -= dt;
            if (surgeTimer <= 0f)
            {
                bool surge = Random.value < species.aggression;
                float sizeFactor = 0.6f + weight / Mathf.Max(0.01f, species.maxWeight);
                currentPull = species.pullStrength * sizeFactor * (surge ? Random.Range(1.2f, 1.8f) : Random.Range(0.3f, 0.8f));
                surgeTimer = surge ? Random.Range(0.6f, 1.5f) : Random.Range(0.8f, 2.5f);
            }
            float fatigue = Mathf.Clamp01(staminaLeft / species.stamina);
            return currentPull * Mathf.Lerp(0.25f, 1f, fatigue);
        }

        public int Value => Mathf.RoundToInt(weight * species.coinsPerKg);
    }
}
