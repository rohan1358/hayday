# Kebun Ceria — pengalaman pemain baru

Implementasi 11 November 2026. APK uji: `KebunCeria-FTUE-Android.apk` (124,2 MiB).

## Perilaku yang diterapkan

- Layar pembuka dengan ilustrasi dua petani, logo, tagline, dan tombol native Godot **Mulai Petualangan**.
- Pemain baru mulai pada Level 1, 0/100 XP, 100 koin, 10 permata, tiga bibit gandum gratis, tiga petak kosong, satu rumah, satu pohon apel, jalan batu awal, bunga, dan pagar sederhana.
- Rumah, lahan, karakter, tanaman, jalan, dan NPC tetap objek game yang bisa berinteraksi. Ilustrasi pembuka tidak dipakai untuk menggantikan gameplay.
- Panduan data-driven: sambutan → pilih bibit → tanam tiga petak → pertumbuhan → panen → pembeli pertama → naik level → preview kandang.
- Highlight dan panah menandai lahan; kamera berpindah dengan interpolasi. Joystick/WASD tetap memakai sistem hybrid. Pekerjaan menanam dan memanen dijalankan karakter melalui antrean dan pathfinding sebenarnya.
- Gandum tutorial tumbuh selama **8 detik**, memakai `planted_at` dan `ready_at` yang sama dengan tanaman normal. Setelah tutorial, waktu gandum normal kembali **12 detik**. Perubahan visual benih, tunas, tanaman muda, dewasa, dan indikator siap panen membaca progress tanaman tersebut.
- Tiga gandum dicadangkan untuk transaksi tutorial agar penjualan dari gudang tidak membuat tutorial buntu. Hasil lebih tetap berada di inventory.
- NPC Bu Sari membeli tepat tiga gandum dengan hadiah **50 koin dan 30 XP**. Transaksi tidak dapat diklaim dua kali.

| Aktivitas tutorial | XP |
| --- | ---: |
| Menanam tiga petak | 20 + 20 + 15 = 55 |
| Memanen tiga petak | 5 + 5 + 5 = 15 |
| Penjualan pertama | 30 |
| Total | 100 → Level 2 |

- Popup Level 2 memberi tiga bibit gandum lanjutan sekali saja. Kandang ayam masih terkunci; tomat tetap mengikuti level existing, tidak diberikan sebagai hadiah tutorial.
- Pada Level 3 pemain dapat membangun kandang seharga **80 koin**, mendapatkan dua ayam, mengolah **2 gandum → 1 pakan ayam** melalui antrean **8 detik**, memberikan pakan, menunggu produksi telur **38 detik**, kemudian mengumpulkan empat telur. Siklus berikutnya memerlukan pakan lagi.
- Panel kandang memperbarui status tanpa membangun ulang daftar setiap detik, sehingga tidak mengganggu posisi scroll Android.
- Kebun kecil dipakai hingga Level 4; pada Level 5 tampilan dunia existing dilanjutkan menggunakan state yang sama. Jalan yang dibeli tetap menggunakan koin; jalan dan dekorasi milik pemain tetap dapat diatur.

## Save dan kompatibilitas

State FTUE disimpan pada dictionary `ftue` versi 1 di save existing versi 1. Save lama tanpa field ini mendapat dictionary kosong; layout, ekonomi, level, tanaman, hewan, upgrade, serta tutorial lamanya dipertahankan. Indeks petak yang dibaca dari JSON dinormalisasi menjadi integer.

Bibit awal hanya diberikan oleh inisialisasi permainan baru. Claim lanjutan, penjualan, pembangunan, konsumsi pakan, dan pengambilan hasil memakai validasi backend serta penanda persisten. Skip tidak memberikan XP atau koin tambahan dan tidak menghapus tanaman yang sedang tumbuh.

Preview desktop memakai direktori `work/ftue-preview-data`, terpisah dari profil kerja sebelumnya. APK memakai package dan debug keystore existing, sehingga pembaruan tidak sengaja mengubah save lama menjadi kebun tutorial. Alur baru berlaku untuk permainan baru.

## Struktur

- `hayday/scripts/first_farm.gd`: definisi langkah, progression awal, validasi, reward, restore.
- `hayday/scripts/first_farm_input.gd`: interaksi kebun awal melalui antrean hybrid.
- `hayday/scripts/first_farm_world.gd`: komposisi awal memakai aset dan anchor objek existing.
- `hayday/scripts/first_farm_ui.gd`: opening, dialog misi, progress, skip, reward, dan preview kandang.
- `hayday/scripts/first_coop.gd`: pembangunan, misi pakan, dan UI peternakan awal.
- Integrasi dengan `game_state.gd`, `main.gd`, inventory, navigasi, animasi karakter, dan ranch existing.

Proyek ini memakai rendering **2D dengan ilustrasi isometrik bergaya 3D**. Aset game existing dipakai kembali; tidak ada klaim konversi mesh atau rig Blender.

## Aset pembuka

Gambar dibuat dengan **built-in image_gen** dan disimpan di:

`C:/Users/nuych/Documents/Codex/2026-11-09/atau-ke-chatgpt-suruh-clone-project/hayday/assets/onboarding/welcome.png`

Prompt final lengkap dan tool disimpan dalam `outputs/ftue-art-prompts.json`. Teks, logo, tombol, dan interaksi tetap native Godot, bukan bagian dari gambar referensi.

## Hasil pengujian

**840 pemeriksaan lulus, tanpa kegagalan pada sembilan suite**, ditambah uji UI end-to-end melalui pergerakan karakter, penanaman, panen, tombol penjualan, naik level, pembangunan kandang, timer pakan asli, dan timer produksi telur asli.

| Suite | Pemeriksaan |
| --- | ---: |
| State pemain baru, resume, transaksi, progres alami sampai Lv3, produksi dan legacy save | 65 |
| Layout Android, tombol, path awal dan input | 14 |
| Smoke legacy | 528 |
| Hybrid movement | 60 |
| Peternakan existing | 54 |
| Upgrade bangunan | 63 |
| Pembelian jalan | 24 |
| Seret jalan | 12 |
| Mobil dan rumah/depot | 20 |

Resolusi diperiksa: 360×640, 720×1280, 720×1600, 1080×2400. Screenshot gameplay tersimpan pada `outputs/ftue-01-pembuka.png` hingga `outputs/ftue-11-telur-pertama.png`.

Validasi APK: ZIP CRC, modul FTUE, gambar pembuka, pengecualian tests, tanda tangan v2/v3, dan alignment 16 KiB diperiksa. Detail tersimpan di `ftue-validation.json` dan `ftue-apk-validation.json`.

APK menggunakan preset debug/offline existing. Pengujian runtime dan UI dilakukan pada Godot Windows; **belum diuji pada perangkat Android fisik**.

Plugin AdMob mencatat pesan bahwa export native iklan memerlukan Gradle; preset APK prebuilt ini tetap menghasilkan APK bertanda tangan yang valid, tetapi tidak menyertakan native ads. Pesan export tersebut bukan hasil pengujian runtime FTUE. Integrasi iklan source existing dipertahankan untuk preset Gradle.
