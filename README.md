# Game Memancing

Game memancing 3D gaya **low-poly** (kartun) untuk telefon Android, berlatarkan Semenanjung Malaysia.
Dibina dengan **Godot 4** (percuma, ringan, jalan lancar walaupun PC biasa).

**Main terus di browser fon:** https://aschraf-fx.github.io/game-memancing/

**Fasa 1:** satu kolam kampung, lontaran charge, sentap, tarik-tali dengan bar ketegangan, kamera FPV/TPV, kawalan sentuh.
**Fasa 2 (sekarang):** beg ikan, jual ikan dapat syiling, kedai peralatan (joran, kekili, tali, mata kail, umpan), simpan automatik. 7 jenis ikan kolam.

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
| Beg ikan | **BEG** (kiri atas) | B |
| Kedai | **KEDAI** (kiri atas) | K |
| Tutup menu | **TUTUP** | Esc |

### Cara main
1. **Tahan LONTAR** untuk charge (bar biru), lepas untuk lontar. Charge penuh = jauh tapi kurang tepat.
2. Tunggu. Bila pelampung terhenjut dan keluar **SENTAP!**, tekan **GULUNG** cepat (dalam ±1 saat).
3. Tarik-tali: **tahan GULUNG** untuk tarik ikan masuk, **lepas** bila bar jadi kuning/merah.
   - Tali tegang sangat = **putus**.
   - Tali kendur terlalu lama = **ikan lepas**.
   - Kekili akan lepaskan tali sendiri (drag) bila hampir putus.
4. Ikan makin letih bila tali tegang. Tarik sampai dekat pangkalan, ikan masuk **beg** (muat 20 ekor).
5. Tak dapat apa? Tahan GULUNG masa menunggu untuk tarik pelampung balik dan lontar semula.
6. Buka **BEG** untuk jual ikan. Harga ikut jenis ikan, berat, dan kejarangan (Biasa x1, Luar Biasa x1.5, Jarang x2.5, Sangat Jarang x4). Ikan hampir saiz maksimum dapat bonus sampai +50%.
7. Buka **KEDAI** untuk beli peralatan. Barang baru terus dipakai. Game berhenti sekejap masa menu dibuka.
8. Semua disimpan automatik (syiling, beg, peralatan). Di browser, simpanan kekal walaupun tutup tab, kecuali guna mod incognito atau padam data laman. Nak mula semula: KEDAI > **PADAM SIMPANAN** (tekan dua kali).

### Kedai
| Jenis | Barang (harga syiling) | Kesan |
|---|---|---|
| Joran | Buluh (ada) · Gentian Kaca (250) · Karbon (1500) | Jarak lontar, kuasa tarik |
| Kekili | Lama (ada) · Spinning (200) · Baitcaster (1200) | Laju gulung, drag lebih licin |
| Tali | Nilon 6 kg (ada) · Nilon 12 kg (150) · Sulam PE 20 kg (900) | Had tali putus |
| Mata kail | No. 10 (ada) · Tajam No. 6 (120) · Circle No. 2 (600) | Masa sentap lebih lama, ikan besar lebih kerap |
| Umpan | Cacing (percuma) · Dedak (15/10 biji) · Udang Hidup (60/10) · Anak Ikan Hidup (150/10) | Ikan gigit lebih cepat, ikan jarang lebih kerap |

Umpan berbayar berkurang satu setiap kali ikan makan. Bila habis, tukar balik ke cacing.

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
  core/      main.gd (data pemain, simpan automatik, tunjuk ikan), game_input.gd (kekunci + seret kamera)
  economy/   player_data.gd (syiling, beg, peralatan), save_game.gd (simpan/baca),
             gear_item.gd, gear_catalog.gd (senarai barang kedai)
  player/    angler.gd (jalan, pusing, FPV/TPV)
  fishing/   fishing_rod.gd (logik memancing), bobber.gd, fishing_line.gd, rod_stats.gd
  fish/      fish_species.gd, fish_pool.gd, hooked_fish.gd, fish_model.gd
  world/     pond_world.gd (jana tanah, pokok, batu, pangkalan, pondok)
  ui/        hud.gd, touch_controls.gd, game_menu.gd (beg + kedai)
shaders/water.gdshader   air low-poly berombak
data/fish/*.tres         data ikan (boleh ubah dalam Inspector)
data/gear/*.tres         data barang kedai (joran, kekili, tali, mata kail, umpan)
tests/test_flow.gd       ujian automatik
```

### Ubah sendiri (mudah)
- **Ikan:** buka `data/fish/` > klik fail ikan > ubah berat, kekuatan, syiling dalam panel Inspector.
- **Barang kedai:** buka `data/gear/` > klik fail > ubah harga dan statistik. Barang baru: buat fail `.tres` baru (New Resource > GearItem) dan tambah satu baris dalam `scripts/economy/gear_catalog.gd`.
- **Kolam:** klik node `PondWorld` dalam `main.tscn`, ubah saiz kolam / `world_seed`, tekan **Regenerate**.

### Ikan kolam
| Ikan | Berat (kg) | Tarikan | Agresif | Syiling/kg | Kejarangan |
|---|---|---|---|---|---|
| Tilapia | 0.2–1.5 | 14 | 0.3 | 8 | Biasa |
| Keli | 0.3–3 | 20 | 0.35 | 10 | Biasa |
| Lampam Jawa | 0.2–1.2 | 12 | 0.5 | 9 | Biasa |
| Patin | 1–8 | 30 | 0.45 | 14 | Luar Biasa |
| Haruan | 0.5–3 | 26 | 0.6 | 16 | Luar Biasa |
| Jelawat | 1–6 | 28 | 0.5 | 18 | Jarang |
| Toman | 2–10 | 38 | 0.7 | 22 | Sangat Jarang |

### Ujian automatik
```
godot --headless --path . -s res://tests/test_flow.gd
```
Ujian ni jalan, tukar kamera, lontar, sentap, tarik-tali sampai dapat ikan, jual ikan, beli barang, guna umpan, simpan/muat data, dan lontar ke darat.

---

## Fasa seterusnya
3. Semua kawasan (sungai, tasik, muara, pantai, laut) + kenderaan (kayak → sampan → bot kecil → bot laut dalam)
4. Multiplayer co-op 2–4 orang
5. Cuaca, siang-malam, bunyi, polish
