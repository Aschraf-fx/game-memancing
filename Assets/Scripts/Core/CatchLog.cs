using System.Collections.Generic;
using UnityEngine;
using Memancing.Fish;
using Memancing.Fishing;

namespace Memancing.Core
{
    /// Rekod tangkapan dan syiling untuk sesi ini. Fasa 2 akan tambah simpan/muat dan kedai.
    public class CatchLog : MonoBehaviour
    {
        public FishingRod rod;

        public int Coins { get; private set; }
        public readonly List<(string name, float kg)> Catches = new List<(string, float)>();

        void OnEnable() => rod.Caught += OnCaught;
        void OnDisable() => rod.Caught -= OnCaught;

        void OnCaught(HookedFish f)
        {
            Catches.Add((f.species.displayName, f.weight));
            Coins += f.Value;
        }
    }
}
