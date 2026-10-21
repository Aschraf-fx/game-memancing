using System;
using UnityEngine;
using Memancing.Core;
using Memancing.Data;
using Memancing.Fish;
using Memancing.Player;

namespace Memancing.Fishing
{
    /// Otak memancing: charge → lontar → tunggu → sambar → tarik-tali → dapat / putus.
    public class FishingRod : MonoBehaviour
    {
        public enum State { Idle, Charging, Flying, Waiting, Biting, Fighting, Retrieving }

        [Header("Rujukan")]
        public RodStats rod;
        public Transform rodTip;
        public Bobber bobber;
        public FishingLine line;
        public AnglerController angler;
        public Transform aim; // biasanya Main Camera
        public Animator animator; // pilihan: trigger "Cast", bool "Reeling"

        [Header("Lontaran")]
        public float launchAngle = 32f;
        [Tooltip("Ketepatan berkurang bila charge penuh (darjah).")]
        public float fullChargeSpread = 4f;

        [Header("Sambar")]
        [Tooltip("Masa (s) pemain sempat tekan Gulung selepas pelampung tenggelam.")]
        public float strikeWindow = 1.1f;

        [Header("Tarik-tali")]
        public float landDistance = 1.8f;
        [Tooltip("Tali kendur terlalu lama (s) = ikan terlepas.")]
        public float slackEscapeTime = 2.5f;
        public float slackTension = 0.08f;

        public State CurrentState { get; private set; }
        public float Charge01 { get; private set; }
        public float Tension01 { get; private set; }
        public HookedFish Fish { get; private set; }
        public float LineLength { get; private set; }

        public event Action<HookedFish> Caught;
        public event Action<string> Message;

        float timer, slackTimer;
        bool castWasHeld, reelWasHeld;
        FishPool pool;
        Vector3 fishWander;

        static readonly int CastHash = Animator.StringToHash("Cast");
        static readonly int ReelHash = Animator.StringToHash("Reeling");

        void Start()
        {
            bobber.Hide();
            bobber.LandedInWater += OnLandedInWater;
            bobber.LandedOnGround += () => { Message?.Invoke("Kena darat. Gulung balik."); Enter(State.Retrieving); };
        }

        void Update()
        {
            var input = MobileInput.I;
            bool castDown = input.CastHeld && !castWasHeld;
            bool castUp = !input.CastHeld && castWasHeld;
            bool reelDown = input.ReelHeld && !reelWasHeld;
            castWasHeld = input.CastHeld;
            reelWasHeld = input.ReelHeld;

            switch (CurrentState)
            {
                case State.Idle:
                    if (castDown) Enter(State.Charging);
                    break;

                case State.Charging:
                    Charge01 = Mathf.Clamp01(Charge01 + Time.deltaTime / rod.chargeTime);
                    if (castUp) Cast();
                    break;

                case State.Flying:
                    // Jatuh luar peta atau tersangkut: tarik balik.
                    if ((timer -= Time.deltaTime) <= 0f || bobber.transform.position.y < -50f) Enter(State.Retrieving);
                    break;

                case State.Waiting:
                    timer -= Time.deltaTime;
                    if (input.ReelHeld) RetrieveStep(rod.reelSpeed * 0.8f);
                    else if (timer <= 0f) StartBite();
                    break;

                case State.Biting:
                    timer -= Time.deltaTime;
                    if (reelDown) Hook();
                    else if (timer <= 0f)
                    {
                        Message?.Invoke("Ikan lari, tak sempat sentap!");
                        Fish = null;
                        timer = pool.RollBiteDelay();
                        CurrentState = State.Waiting;
                    }
                    break;

                case State.Fighting:
                    Fight(input.ReelHeld);
                    break;

                case State.Retrieving:
                    RetrieveStep(rod.reelSpeed * 2f);
                    break;
            }

            line.tension01 = CurrentState == State.Fighting ? Tension01 : 0.15f;
            if (animator) animator.SetBool(ReelHash, input.ReelHeld && CurrentState >= State.Waiting);
        }

        void Enter(State s)
        {
            CurrentState = s;
            angler.movementLocked = s != State.Idle;
            if (s == State.Idle) { Charge01 = 0f; Tension01 = 0f; Fish = null; bobber.Hide(); }
            if (s == State.Retrieving) bobber.MakeKinematic();
        }

        void Cast()
        {
            float dist = Mathf.Lerp(3f, rod.maxCastDistance, Charge01);
            float spread = fullChargeSpread * Charge01 * Charge01;
            Vector3 flat = Vector3.ProjectOnPlane(aim.forward, Vector3.up).normalized;
            flat = Quaternion.Euler(0f, UnityEngine.Random.Range(-spread, spread), 0f) * flat;

            // Halaju projektil untuk capai jarak "dist" pada sudut tetap (anggap paras sama).
            float ang = launchAngle * Mathf.Deg2Rad;
            float g = -Physics.gravity.y;
            float speed = Mathf.Sqrt(dist * g / Mathf.Sin(2f * ang));
            Vector3 vel = flat * Mathf.Cos(ang) * speed + Vector3.up * Mathf.Sin(ang) * speed;

            if (animator) animator.SetTrigger(CastHash);
            bobber.Launch(rodTip.position, vel);
            timer = 6f;
            Enter(State.Flying);
        }

        void OnLandedInWater(FishPool p)
        {
            pool = p;
            timer = p.RollBiteDelay();
            LineLength = Vector3.Distance(rodTip.position, bobber.transform.position);
            Enter(State.Waiting);
        }

        void StartBite()
        {
            Fish = new HookedFish(pool.RollSpecies());
            timer = strikeWindow;
            bobber.Nibble(strikeWindow, 0.12f);
            CurrentState = State.Biting;
            Handheld.Vibrate();
        }

        void Hook()
        {
            bobber.MakeKinematic();
            Tension01 = 0.4f;
            slackTimer = 0f;
            fishWander = Vector3.zero;
            Message?.Invoke("Dapat sambar! Jaga tali jangan putus.");
            CurrentState = State.Fighting;
        }

        void Fight(bool reeling)
        {
            float dt = Time.deltaTime;
            float pull = Fish.Tick(dt);

            // Ketegangan sasaran: tarikan ikan + daya gulung bila butang ditekan.
            float targetTension = reeling ? pull + rod.reelForce * 0.6f : pull * 0.35f;
            float tensionN = Mathf.Lerp(Tension01 * rod.lineBreakTension, targetTension, 6f * dt);
            Tension01 = tensionN / rod.lineBreakTension;

            // Drag kekili: lepaskan tali bila terlalu tegang supaya tak terus putus.
            float over = Tension01 - rod.dragThreshold;
            if (over > 0f)
            {
                LineLength += over * 6f * dt;
                Tension01 -= over * 0.5f * dt * 6f;
            }

            if (Tension01 >= 1f)
            {
                Message?.Invoke($"Tali putus! {Fish.species.displayName} terlepas.");
                Enter(State.Idle);
                return;
            }

            slackTimer = Tension01 < slackTension ? slackTimer + dt : 0f;
            if (slackTimer > slackEscapeTime)
            {
                Message?.Invoke("Tali kendur, ikan lepas mata kail.");
                Enter(State.Idle);
                return;
            }

            // Ikan letih lagi cepat bila tali tegang.
            Fish.staminaLeft -= dt * (0.4f + Tension01 * 1.2f);

            // Gulung masuk lawan tarikan ikan; ikan bawa lari tali bila tak digulung.
            float pullRatio = pull / (pull + rod.reelForce);
            if (reeling) LineLength -= rod.reelSpeed * (1f - pullRatio) * dt;
            else LineLength += rod.reelSpeed * 0.5f * pullRatio * dt;
            LineLength = Mathf.Max(landDistance * 0.9f, LineLength);

            // Pelampung ikut ikan: meliuk kiri-kanan di atas air.
            fishWander = Vector3.Lerp(fishWander, UnityEngine.Random.insideUnitSphere * 1.5f, dt);
            Vector3 fromRod = bobber.transform.position - rodTip.position;
            fromRod.y = 0f;
            Vector3 dir = (fromRod.normalized + new Vector3(fishWander.x, 0f, fishWander.z) * 0.15f).normalized;
            Vector3 target = rodTip.position + dir * LineLength;
            target.y = bobber.WaterHeight;
            bobber.DriveTowards(target, 4f * dt);

            if (LineLength <= landDistance)
            {
                var f = Fish;
                Message?.Invoke($"Dapat {f.species.displayName} {f.weight:0.00} kg (+{f.Value} syiling)");
                Caught?.Invoke(f);
                Enter(State.Idle);
            }
        }

        void RetrieveStep(float speed)
        {
            Vector3 target = rodTip.position;
            if (bobber.InWater) target.y = bobber.WaterHeight;
            bobber.MakeKinematic();
            bobber.DriveTowards(target, speed * Time.deltaTime);
            if (Vector3.Distance(bobber.transform.position, target) < landDistance) Enter(State.Idle);
        }
    }
}
