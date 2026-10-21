# Game Memancing

Game memancing 3D gaya **low-poly** (kartun) untuk telefon Android, berlatarkan Semenanjung Malaysia.
Dibina dengan **Godot 4** (percuma, ringan, jalan lancar walaupun PC biasa).

**Fasa 1 (sekarang):** satu kolam kampung, lontaran charge, sentap, tarik-tali dengan bar ketegangan, kamera FPV/TPV, kawalan sentuh, 6 jenis ikan kolam.

---

## Bahagian A: Pasang Godot dan main di PC (±10 minit)

1. Pergi ke **https://godotengine.org/download**, pilih sistem PC kau (Windows/Mac/Linux), download versi **Godot Engine (Standard)** 4.4 atau lebih baru. *Jangan* ambil versi ".NET".
2. Fail tu zip. Extract ke mana-mana folder (contoh `C:\Godot`). Tak perlu install, terus klik dua kali `Godot_v4.x-stable_win64.exe`.
3. Download projek ni: dalam GitHub, tekan butang hijau **Code > Download ZIP**, kemudian extract (contoh ke `Documents\game-memancing`).
4. Dalam Godot (Project Manager), tekan **Import**, pilih fail `project.godot` dalam folder tadi, tekan **Import & Edit**.
5. Tunggu Godot siap import (kali pertama je lambat sikit). Tekan butang **▶ (F5)** kat atas kanan untuk main.

### Kawalan
| Aksi | Fon | PC |
|---|---|---|
| Berjalan | Joystick kiri bawah | W A S D |
| Pusing kamera | Seret jari di separuh kanan skrin | Klik kiri + seret di kanan skrin, atau tahan klik kanan |
| Lontar | **Tahan LONTAR**, lepas untuk lontar | Tahan Space |
| Sentap / Gulung | **GULUNG** | Shift atau E |
| Tukar FPV/TPV | **KAMERA** | V |

### Cara main
1. **Tahan LONTAR** untuk charge (bar biru), lepas untuk lontar. Charge penuh = jauh tapi kurang tepat.
2. Tunggu. Bila pelampung terhenjut dan keluar **SENTAP!**, tekan **GULUNG** cepat (dalam ±1 saat).
3. Tarik-tali: **tahan GULUNG** untuk tarik ikan masuk, **lepas** bila bar jadi kuning/merah.
   - Tali tegang sangat = **putus**.
   - Tali kendur terlalu lama = **ikan lepas**.
   - Kekili akan lepaskan tali sendiri (drag) bila hampir putus.
4. Ikan makin letih bila tali tegang. Tarik sampai dekat pangkalan untuk dapat syiling.
5. Tak dapat apa? Tahan GULUNG masa menunggu untuk tarik pelampung balik dan lontar semula.

---

## Bahagian B: Main di fon Android (±30 minit, sekali setup je)

1. **Java (JDK 17):** download dari https://adoptium.net (pilih *Temurin 17 LTS*), install.
2. **Android SDK:** cara paling senang install **Android Studio** (https://developer.android.com/studio). Buka sekali, biar dia download SDK. Ingat lokasi SDK (Android Studio > Settings > Android SDK, contoh `C:\Users\NAMA\AppData\Local\Android\Sdk`).
3. Dalam Godot: **Editor > Editor Settings > Export > Android**
   - *Java SDK Path* = folder JDK 17 (contoh `C:\Program Files\Eclipse Adoptium\jdk-17...`)
   - *Android SDK Path* = lokasi SDK tadi
4. **Editor > Manage Export Templates > Download and Install.**
5. **Project > Export > Add... > Android.** Biar tetapan asal. Tekan **Export Project**, nama fail `memancing.apk` (biar *Export With Debug* bertanda untuk uji).
6. Salin `memancing.apk` ke fon (kabel USB / Google Drive / WhatsApp ke diri sendiri), buka dan **Install** (benarkan "Install unknown apps" kalau ditanya).

> Kalau keluar ralat pasal *keystore*, tutup dan buka semula Godot selepas langkah 3 (Godot akan buat debug keystore sendiri). Kalau masih ralat, screenshot dan hantar.

Cara lebih laju lepas ni: hidupkan **USB debugging** kat fon (Settings > About phone > tekan Build number 7 kali > Developer options), sambung kabel, dan tekan ikon Android kat atas kanan Godot untuk terus main di fon.

---

## Struktur projek
```
project.godot            tetapan projek (renderer Mobile, landskap)
scenes/
  main.tscn              scene utama: kolam, air, pemain, HUD, kawalan sentuh
  angler.tscn            watak pemain + joran + kamera
  bobber.tscn            pelampung + percikan air
scripts/
  core/      main.gd (syiling, tunjuk ikan), game_input.gd (kekunci + seret kamera)
  player/    angler.gd (jalan, pusing, FPV/TPV)
  fishing/   fishing_rod.gd (logik memancing), bobber.gd, fishing_line.gd, rod_stats.gd
  fish/      fish_species.gd, fish_pool.gd, hooked_fish.gd, fish_model.gd
  world/     pond_world.gd (jana tanah, pokok, batu, pangkalan, pondok)
  ui/        hud.gd, touch_controls.gd
shaders/water.gdshader   air low-poly berombak
data/fish/*.tres         data ikan (boleh ubah dalam Inspector)
data/rods/*.tres         data joran
tests/test_flow.gd       ujian automatik
```

### Ubah sendiri (mudah)
- **Ikan:** buka `data/fish/` > klik fail ikan > ubah berat, kekuatan, syiling dalam panel Inspector.
- **Joran:** `data/rods/joran_buluh.tres` (jarak lontar, had putus tali, laju gulung).
- **Kolam:** klik node `PondWorld` dalam `main.tscn`, ubah saiz kolam / `world_seed`, tekan **Regenerate**.

### Ikan kolam
| Ikan | Berat (kg) | Tarikan | Agresif | Syiling/kg | Peluang |
|---|---|---|---|---|---|
| Tilapia | 0.2–1.5 | 14 | 0.3 | 8 | tinggi |
| Keli | 0.3–3 | 20 | 0.35 | 10 | tinggi |
| Lampam Jawa | 0.2–1.2 | 12 | 0.5 | 9 | tinggi |
| Patin | 1–8 | 30 | 0.45 | 14 | sederhana |
| Haruan | 0.5–3 | 26 | 0.6 | 16 | rendah |
| Toman | 2–10 | 38 | 0.7 | 22 | jarang |

### Ujian automatik
```
godot --headless --path . -s res://tests/test_flow.gd
```
Ujian ni jalan, tukar kamera, lontar, sentap, tarik-tali sampai dapat ikan, dan lontar ke darat.

---

## Fasa seterusnya
2. Ekonomi: jual ikan, kedai joran/tali/umpan, simpan data
3. Semua kawasan (sungai, tasik, muara, pantai, laut) + kenderaan (kayak → sampan → bot kecil → bot laut dalam)
4. Multiplayer co-op 2–4 orang
5. Cuaca, siang-malam, bunyi, polish
