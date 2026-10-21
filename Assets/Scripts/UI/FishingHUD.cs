using UnityEngine;
using UnityEngine.UI;
using TMPro;
using Memancing.Core;
using Memancing.Fishing;

namespace Memancing.UI
{
    /// Paparan bar charge, bar ketegangan tali, mesej dan syiling.
    public class FishingHUD : MonoBehaviour
    {
        public FishingRod rod;
        public CatchLog log;

        [Header("Charge")]
        public GameObject chargeGroup;
        public Image chargeFill;

        [Header("Ketegangan")]
        public GameObject tensionGroup;
        public Image tensionFill;
        public Gradient tensionColor; // hijau → kuning → merah
        public TMP_Text fishStaminaText;

        [Header("Lain-lain")]
        public TMP_Text messageText;
        public TMP_Text coinsText;
        public GameObject strikePrompt; // "SENTAP!" bila ikan makan
        public float messageDuration = 3f;

        float messageTimer;

        void OnEnable() => rod.Message += ShowMessage;
        void OnDisable() => rod.Message -= ShowMessage;

        void ShowMessage(string m)
        {
            messageText.text = m;
            messageText.gameObject.SetActive(true);
            messageTimer = messageDuration;
        }

        void Update()
        {
            var s = rod.CurrentState;

            chargeGroup.SetActive(s == FishingRod.State.Charging);
            chargeFill.fillAmount = rod.Charge01;

            bool fighting = s == FishingRod.State.Fighting;
            tensionGroup.SetActive(fighting);
            if (fighting)
            {
                tensionFill.fillAmount = rod.Tension01;
                tensionFill.color = tensionColor.Evaluate(rod.Tension01);
                if (fishStaminaText)
                    fishStaminaText.text = rod.Fish.Exhausted ? "Ikan dah letih!" : $"{rod.LineLength:0.0} m";
            }

            if (strikePrompt) strikePrompt.SetActive(s == FishingRod.State.Biting);
            if (coinsText) coinsText.text = log.Coins.ToString("N0");

            if (messageTimer > 0f && (messageTimer -= Time.deltaTime) <= 0f)
                messageText.gameObject.SetActive(false);
        }
    }
}
