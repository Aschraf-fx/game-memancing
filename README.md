# Game Memancing (Fasa 1: Prototaip)

Game memancing realistik untuk telefon (Android dulu), latar Semenanjung Malaysia.
Fasa 1 ada satu kolam, lontaran charge, mini-game ketegangan tali, kamera FPV/TPV dan kawalan sentuh.

## Keperluan
- **Unity 6 LTS** (6000.0.x) dengan modul Android Build Support
- Template projek: **Universal 3D (URP)**
- Package: TextMeshPro (dah ada dalam uGUI), Cinemachine tak perlu

## Setup projek (sekali sahaja)
1. Buat projek baru dalam Unity Hub guna template *Universal 3D*, kemudian salin folder `Assets/Scripts` dari repo ni ke dalam projek.
2. **Edit > Project Settings > Player > Other Settings > Active Input Handling = Both** (skrip guna Input lama untuk uji papan kekunci dalam Editor; sentuhan guna EventSystem).
3. **File > Build Profiles > Android > Switch Platform.** Orientation: Landscape Left.
4. Kualiti mobile (realistik tapi lancar 60fps):
   - Guna aset `URP-Balanced` atau `Mobile_RPAsset`; hidupkan **HDR**, **MSAA 2x**, **Soft Shadows**, jarak bayang 40–60 m, 2 cascade.
   - Post-processing (Volume global): Tonemapping ACES, Bloom lembut, Color Adjustments sikit, Vignette rendah. Elak SSAO berat; guna *Screen Space Ambient Occlusion* mod *Low* sahaja kalau peranti mampu.
   - Lighting: Directional Light (matahari tropika, suhu ~5600K, sudut rendah untuk pagi/petang), bake Lightmap untuk objek statik, Skybox HDRI (Poly Haven, lesen CC0).

## Susun scene kolam (`Scenes/Kolam.unity`)
| Objek | Komponen | Nota |
|---|---|---|
| `Terrain` | Terrain | Tebing kolam, tekstur tanah merah/rumput (Poly Haven / Quixel Megascans percuma untuk Unity). Tambah pokok kelapa, pisang, rumput panjang. |
| `Air` | Mesh plane + **BoxCollider (Is Trigger)** + `FishPool` | Collider kotak setebal 3 m, **bahagian atas = paras air**. Letak spesies ikan dalam senarai. |
| `Pemain` | CharacterController + `AnglerController` | Layer `Player`. Anak: model, `Head` (empty pada paras mata ~1.65 m), `Joran` dengan anak `RodTip`. |
| `Main Camera` | `AnglerCamera` | `collisionMask` = semua kecuali `Player` dan `Water`. |
| `Pelampung` | Rigidbody (mass 0.05, Interpolate, Continuous) + SphereCollider kecil + `Bobber` | Layer `Bobber`. Jangan jadikan anak pemain. |
| `Tali` | LineRenderer (lebar 0.004, bahan Unlit putih separa lutsinar) + `FishingLine` | |
| `Sistem` | `MobileInput`, `FishingRod`, `CatchLog` | Isi semua rujukan dalam Inspector. |
| `Canvas` | `FishingHUD` | Lihat bahagian UI di bawah. |

Physics: dalam **Layer Collision Matrix** matikan `Bobber` ↔ `Player`.

### Shader air realistik (mobile)
Buat Shader Graph *URP Lit* untuk air: dua normal map bergerak (scroll arah berbeza), warna kedalaman guna *Scene Depth* (hijau keruh untuk kolam, coklat untuk sungai/muara), Smoothness 0.95, Fresnel untuk pantulan langit, dan buih tepi guna beza kedalaman. Hidupkan **Depth Texture** dan **Opaque Texture** dalam aset URP. Alternatif cepat: aset percuma *Stylized/Realistic Water* dari Asset Store, tapi pastikan sokong URP mobile.

### UI sentuh (Canvas Screen Space Overlay, Scale With Screen Size 1920×1080)
- Kiri bawah: `Joystick` (Image bulat + `TouchJoystick`, anak `Knob`).
- Separuh kanan: Image lutsinar penuh (alpha 0, Raycast Target on) + `TouchLookArea`, letak **di belakang** butang.
- Kanan bawah: butang besar **LONTAR** (`HoldButton` Action=Cast) dan **GULUNG** (`HoldButton` Action=Reel).
- Kanan atas: butang **Kamera** → OnClick `MobileInput.PressCameraToggle`.
- Tengah: `ChargeBar` (Image Filled), `TensionBar` (Image Filled + Gradient hijau→kuning→merah), teks mesej, ikon "SENTAP!", syiling.

## Cara main
1. **Tahan LONTAR** untuk charge, lepas untuk lontar. Charge penuh = jauh tapi kurang tepat.
2. Tunggu. Bila pelampung tenggelam dan muncul **SENTAP!**, tekan **GULUNG** cepat (dalam ~1 saat).
3. Tarik-tali: **tahan GULUNG** untuk tarik masuk, **lepas** bila bar ketegangan merah. Tegang sangat = tali putus. Kendur lama sangat = ikan lepas. Kekili akan lepaskan tali sendiri (drag) bila hampir putus.
4. Ikan makin letih bila tali tegang. Tarik sampai dekat untuk dapat syiling.
5. Tahan GULUNG masa menunggu untuk tarik pelampung balik.

Kawalan Editor: WASD, tahan klik kanan untuk pusing, Space lontar, Shift kiri gulung, V tukar kamera.

## Spesies contoh kolam (Create > Memancing > Fish Species)
| Ikan | Berat (kg) | Tarikan | Agresif | Stamina | Syiling/kg | Peluang |
|---|---|---|---|---|---|---|
| Tilapia | 0.2–1.5 | 14 | 0.3 | 8 | 8 | 4 |
| Keli | 0.3–3 | 20 | 0.35 | 12 | 10 | 3 |
| Lampam Jawa | 0.2–1.2 | 12 | 0.5 | 7 | 9 | 3 |
| Patin | 1–8 | 30 | 0.45 | 18 | 14 | 1.5 |
| Haruan | 0.5–3 | 26 | 0.6 | 12 | 16 | 1 |
| Toman | 2–10 | 38 | 0.7 | 22 | 22 | 0.3 |

Joran permulaan (Create > Memancing > Rod Stats): *Joran Buluh*, jarak 25 m, putus 60 N, gulung 1.6 m/s, daya 35 N, drag 0.85.

## Struktur skrip
```
Assets/Scripts/
  Core/       MobileInput, CatchLog, WaterBob
  Player/     AnglerController
  CameraRig/  AnglerCamera (FPV/TPV)
  Fishing/    FishingRod (state machine), Bobber, FishingLine
  Fish/       FishSpecies, FishPool, HookedFish
  Data/       RodStats
  UI/         TouchJoystick, TouchLookArea, HoldButton, FishingHUD
```

## Fasa seterusnya
2. Ekonomi: jual ikan, kedai joran/tali/umpan, simpan data
3. Semua kawasan (sungai, tasik, muara, pantai, laut) + kenderaan (kayak → sampan → bot kecil → bot laut dalam)
4. Multiplayer co-op 2–4 orang (Netcode for GameObjects / Unity Relay)
5. Cuaca, siang-malam, polish grafik
