# Cheerful Garden / Kebun Ceria

Game simulasi pertanian dan pengembangan desa bergaya **2D isometrik** yang dibuat menggunakan **Godot 4.7.2** dan GDScript. Pemain bertani, beternak, mengolah bahan, memenuhi pesanan, menata lingkungan, membuka kawasan, dan menjelajahi pulau bermusim. Progres permainan disimpan secara lokal.

**Dokumentasi lengkap dan terbaru:** [DOKUMENTASI-LENGKAP-GAME.md](DOKUMENTASI-LENGKAP-GAME.md)

Dokumen lengkap memuat katalog konten beserta level, harga, waktu proses, hadiah, batasan dan persyaratan, serta penjelasan kode, iklan, save, dan ekspor Android. Gunakan dokumen itu sebagai referensi utama kondisi kode per **21 November 2026**.

## Gambaran fitur

| Komponen | Isi game saat ini |
| --- | --- |
| Permainan awal | Tutorial **First Farm**, mulai dari 3 petak gandum dan penjualan kepada Bu Sari |
| Pertanian | **14 jenis tanaman** dan 16 petak pertanian dengan progres pembukaan |
| Kebun buah | **12 jenis buah/pohon produktif** |
| Peternakan | **4 jenis ternak** dengan siklus pakan dan pengambilan produk |
| Produksi | **26 resep dapur**, pembuatan pakan dan kegiatan produksi lainnya |
| Ekonomi | Koin, permata, XP, gudang, toko, pesanan **3 slot**, dan pasar |
| Progres | Level, tutorial, misi, prestasi, hadiah harian dan kotak pesan |
| Bangunan | Fasilitas produksi, dekorasi, upgrade bertingkat dan penataan |
| Dunia | **25 jenis kawasan**, aktivitas kawasan, dan **4 pulau** musim |
| Karakter | Ujang, perjalanan ke objek, penebangan pohon, kostum dan **24 aksesori** |
| Iklan | Kode integrasi **6 format AdMob** dengan Firebase Remote Config |
| Penyimpanan | Save lokal JSON serta berkas backup |

Tidak semua konten tersedia di awal permainan. Level, sumber daya, pembelian, state save, dan pengaturan layanan jarak jauh menentukan akses pemain.

## Menjalankan proyek

1. Buka `project.godot` menggunakan **Godot 4.7.2**.
2. Tunggu editor mengimpor aset apabila diperlukan.
3. Tekan **F5** untuk menjalankan scene awal `scenes/Startup.tscn`.

Resolusi dasar proyek **720 × 1280**, orientasi portrait dengan renderer **GL Compatibility**. Kontrol mencakup ketuk objek, geser/zoom kamera, serta gerak karakter melalui WASD atau joystick pada mode terkait.

## Ekspor Android

Preset utama Android di `export_presets.cfg` menggunakan package **`com.kebunceria.farm`**, versi **1.1** (version code **2**) dan arsitektur **arm64-v8a**. Preset itu menghasilkan APK debug di `build/KebunCeria-debug.apk` ketika diekspor sebagai debug.

```powershell
godot --headless --path "D:\portfolio\farmer\game\HayDay" --export-debug "Android" "build/KebunCeria-debug.apk"
```

Ekspor Android memerlukan Android SDK, template ekspor dan dukungan Gradle yang telah dikonfigurasi. Proyek juga memiliki preset **Android AAB** dan **Android hybrid** dengan nama paket/versi terpisah. Rincian ada di [bagian ekspor dokumentasi lengkap](DOKUMENTASI-LENGKAP-GAME.md#18-menjalankan-game-dan-membuat-apk).

## Iklan dan data pemain

Enam format AdMob tersedia dalam implementasi, yaitu **banner, native, interstitial, rewarded, rewarded interstitial,** dan **app open**. Setiap format harus diaktifkan melalui konfigurasi jarak jauh yang sesuai. Keberhasilan penayangan pada Android memerlukan pengujian runtime. Penjelasan flag dan cara kerja hadiah ada pada [bagian iklan](DOKUMENTASI-LENGKAP-GAME.md#15-iklan).

Save utama disimpan pada `user://kebun_ceria_v1.json` dan cadangan pada `user://kebun_ceria_backup.json`. Progres dan pengaturan dari save lama dapat berbeda dari profil pemain baru.

## Referensi pengembangan

- [Dokumentasi lengkap gameplay dan teknis](DOKUMENTASI-LENGKAP-GAME.md)
- [Kredit audio](AUDIO_CREDITS.md)
- [Riwayat pembaruan APK](UPDATE-APK-TERBARU.md)
- `scripts/game_state.gd` untuk katalog konten dan save.
- `scripts/first_farm.gd` untuk tutorial.
- `scripts/world_regions.gd` dan `scripts/island_journey.gd` untuk kawasan dan pulau.
- `scripts/farm_ads.gd` untuk iklan.

**Catatan verifikasi:** dokumentasi ini diselaraskan dengan source code. Pengujian menyeluruh pada ponsel fisik, iklan AdMob, dan seluruh progres sampai level tertinggi belum dilakukan khusus untuk pembaruan dokumentasi ini.
