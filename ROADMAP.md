# Kebun Ceria — Roadmap menuju farm-sim yang matang

Dokumen kerja Project Manager, diperbarui 7 November 2026. Sasaran: pengalaman bertani yang kaya, nyaman di Android, dan memiliki identitas visual orisinal. Hay Day digunakan sebagai acuan **jenis pengalaman** (pertanian, produksi, pesanan, progresi, dekorasi), bukan sumber aset atau desain untuk disalin.

## Sudah tersedia / diverifikasi

- [x] Dunia 3600 × 2900, kamera geser/zoom, 16 petak, 13 tanaman, kebun buah, 4 jenis ternak, 13 resep, truk pesanan, pasar NPC, misi harian, bangun/atur, jalan, penyimpanan offline.
- [x] Tutorial awal tiga langkah dengan penanda dunia dan panduan pada pesanan.
- [x] Aset orisinal `art_v2` sampai `art_v11`; rumah produksi dan pabrik pakan memakai art v7, kandang babi/kambing art v8, depot dan truk art v9, gerobak sortir dan papan arah desa art v10, serta rumah penyerbuk, rak herba, penampung air hujan, dan taman bunga melengkung art v11.
- [x] Indikator animasi hasil siap di dapur/Pabrik Pakan/sapi/babi/kambing, mengikuti lokasi objek dan bisa diketuk.
- [x] Hitbox sentuh Rumah Roti dan Rumah Susu mengikuti tinggi sprite; uji sentuh atap ditambahkan.
- [x] Pabrik Pakan fungsional level 2: 3 resep, FIFO maksimal 3, timer offline, konsumsi paket sebelum panen mentah, save kompatibel, serta smoke UI/logic.
- [x] Kandang babi/kambing Blender art v8 terpasang dalam dunia dan kartu menu bangunan; QA aset dan preview desktop selesai.
- [x] Parser Godot exit 0, smoke `TOTAL FAILURES: 0`, dan 12 screenshot 450 × 800 desktop (7 November 2026).
- [x] Penjualan gudang JUAL 1/5/SEMUA, konfirmasi sebelum menjual stok yang diperlukan pesanan, pintasan saat gudang penuh, serta pembelian bibit 1/5; tes UI dan ekonomi terisolasi sebelumnya lulus.
- [x] Build PM *retained-details* (riwayat): `build/KebunCeria-pm-retained-details-20261107-debug.apk` (110.836.696 byte) terpasang tanpa menghapus save; screenshot `build/emulator_pm_retained_details.png`. Build lebih baru *ujang-cache* `build/KebunCeria-pm-ujang-cache-20261107-debug-signed.apk` (112.313.048 byte) berhasil dipasang dengan `adb install -r`, diuji ulang di `emulator-5554`, dan mempertahankan progres pemain (level 9, 101 koin, 59 permata pada sesi QA). Screenshot `build/qa-pm-v14/android-after-worker-cache-warm.png`.
- [x] Generator pesanan baru menghindari kebutuhan barang identik dengan kontrak aktif pada pengiriman/penggantian, tanpa mengubah kontrak yang telah disimpan. Regresi khusus ada di `tests/order_variety.gd`.
- [x] Papan pesanan menampilkan kontrak siap kirim, kekurangan barang dan pintasan ke fasilitas terkait; navigasi bawah memiliki badge pesanan siap.
- [x] Animasi Ujang memakai lapisan kanvas yang dipertahankan untuk mengurangi gambar ulang; waktu `KEBUN_ANIM` emulator sekitar 2–4 ms per sampel setelah perubahan. Area rumput selatan kini memiliki dekorasi Blender orisinal tambahan tanpa menghalangi objek kebun.
- [x] Truk pengiriman kini memakai `RetainedDeliveryTruck`: ketika parkir, geser kamera tidak memicu gambar ulang; ketika dikirim, truk tetap bergerak, menghilang selama putar balik, lalu pulang. `tests/mobile_render_cache.gd` memverifikasi seluruh siklus. Enam suite regresi kembali lulus tanpa kegagalan.
- [x] Setelah cache truk, sesi historis `KEBUN_ANIM` emulator tercatat sekitar 0,24–0,50 ms saat idle, sedangkan `KEBUN_PERF` tercatat 34–43 FPS dan 457 draw calls. Pengukuran ini **bukan benchmark terbaru** dan tidak dapat dibandingkan langsung dengan sesi Android lain.
- [x] Depot, halaman kirim, kebun buah, papan misi, dan papan petunjuk memakai layer `RetainedWorldDetails`. Kamera hanya mengubah transformasi; perubahan status pohon/misi memicu render ulang. Tes cache mencakup pan, menanam, dan buah siap panen.
- [x] APK `pm-retained-details` (sesi historis) diperiksa di emulator 1080 × 2400 dan 1080 × 1920. FPS 40–43, 457 draw calls, PSS 686.827 KiB merupakan hasil sesi terdahulu. Resolusi emulator sudah dikembalikan ke 1080 × 2400.
- [x] Konten lanjutan: tomat (level 6), cabai (9), kopi (13), nanas (17), saus tomat (8), sambal (12), dan selai nanas (18) terintegrasi dengan toko, lahan, gudang, produksi, pesanan, dan penyimpanan lama.
- [x] Simulasi ekonomi terisolasi `tests/economy_level20.gd` membuktikan jalur pemulihan dari 0 koin/0 bibit serta jalur panen ke level 20 dengan percepatan waktu khusus pengujian; mencakup resep baru, kapasitas gudang, ekspansi, dan migrasi save. Uji pacing nyata dan ekonomi non-optimal masih perlu dilakukan.
- [x] Pembaruan jalur navigasi Ujang mengurangi pemeriksaan penghalang yang tidak diperlukan setiap frame; sesi emulator APK *ujang-cache* mencatat sekitar **17–22 FPS**, **498–501 draw calls**, dengan update Ujang sekitar **0,43–0,61 ms** dan animasi sekitar **0,21–0,28 ms**. Eksperimen viewport resolusi rendah dibatalkan karena membuat tampilan buram tanpa kenaikan FPS bermakna.
- [x] Hadiah kunjungan harian siklus 7 hari sudah tersedia di panel MISI. Hadiah koin meningkat, hari ke-7 memberi 1 permata, skip satu hari mengulang siklus, klaim ganda/tanggal mundur ditolak, dan save lama tetap bisa dimuat. Semua **9 suite** (`smoke`, `inventory_ui_smoke`, `economy_progression`, `order_variety`, `order_guidance`, `economy_level20`, `economy_recovery`, `mobile_render_cache`, `daily_checkin`) lulus di Godot 4.7.2 headless (7 November 2026, `build/qa-pm-v16/`).
- [x] Seleksi petak pada renderer Android dipisahkan ke satu `RetainedSelectedPlotOutline`, sehingga denyut highlight dan perpindahan seleksi tidak membangun ulang tekstur tiap petak. Regresi di `tests/mobile_render_cache.gd` lulus.
- [x] Audit visual Designer4 `build/qa-design-v23/visual-audit.md` menghasilkan lima temuan prioritas. Empat properti art_v11 dipindahkan ke padang yang tampak pada kamera awal, tanpa mengubah interaksi lahan. Screenshot emulator sesudahnya: `build/qa-pm-v23/android-v23-late.png`; penempatan diuji terhadap area interaksi default melalui pemeriksaan `scenery_clear_of_farm`.
- [x] Audit ekonomi Programmer4 level 5–20 menambahkan `tests/economy_pacing_realistic.gd`: semua enam skenario lulus dengan waktu tumbuh virtual sesuai aturan, cek kelangkaan koin/bibit, transaksi, kapasitas gudang, dan restart. Temuan balancing: gandum saja memberi XP lebih cepat namun koin lebih sedikit. Belum dilakukan perubahan ke rumus ekonomi karena belum ada masalah pasti yang terbukti.
- [x] APK PM v23 `build/KebunCeria-pm-scenery-selection-20261107-debug.apk` (112.321.651 byte) ditandatangani dengan sertifikat yang sama, berhasil diinstal ulang memakai `adb install -r`, dan mempertahankan level 9 / 101 koin / 59 permata. **12 suite** regresi lulus (`build/qa-pm-v23/*-final.log`). Sampel emulator terbaru **18–25 FPS, 330–333 draw calls**; target 60 FPS tetap terbuka dan evaluasi GPU/perangkat fisik diperlukan.

## Sprint aktif

| Prioritas | Pekerjaan | Penanggung jawab | Syarat selesai |
| --- | --- | --- | --- |
| P0 | Profiling kinerja Android dan optimasi berdasar pengukuran | Project Manager / Programmer4 | Frame time gameplay dan penggunaan memori pada perangkat Android fisik terukur dan memenuhi target yang ditetapkan |
| P1 | Konsistensi layering objek, animasi produksi/panen, serta UI layar kecil | Designer4 / Programmer4 | QA visual dan uji gestur di beberapa ukuran perangkat, teks dan hitbox jelas |
| P1 | Audit ritme waktu nyata dan ekonomi level 5–20 untuk gaya bermain berbeda | Programmer4 / Project Manager | Skenario kas kosong, pesanan, gudang, dan produksi realistis bisa diselesaikan; uji pemain lulus |

## Kebutuhan produk setelah sprint aktif

Catatan pengukuran emulator 7 November 2026: APK *ujang-cache* pernah mencatat **17–22 FPS / 498–501 draw calls**, dan APK *retained-details* historis **40–43 FPS / 457 draw calls / 686.827 KiB PSS**. Sampel terdekat sebelum v23 (*idle-animation*) **23–24 FPS / 327 draw calls**; v23 **18–25 FPS / 330–333 draw calls**. Kondisi pengukuran tidak identik, sehingga belum terbukti kenaikan ataupun regresi FPS. Cache layar/kanvas mengurangi pekerjaan CPU tertentu, tetapi bottleneck keseluruhan belum teridentifikasi. Target 60 FPS belum tercapai; perlu profiling GPU/driver, pengujian di ponsel fisik, dan audit layar kecil. UMP AdMob masih melaporkan belum ada consent form yang dikonfigurasi untuk App ID aplikasi; pengaturan ini dilakukan di konsol AdMob.

1. **P1 — Konsistensi visual:** benahi kedalaman tumpukan objek/isometrik, animasi panen/produksi, keterbacaan penanda di dunia yang padat, konsistensi bangunan dan toko.
2. **P1 — Progresi dan ekonomi:** pengaturan ritme level 1–20, biaya ekspansi, kebutuhan pakan, hadiah pesanan, kapasitas gudang, dan pengujian agar pemain tidak terjebak karena stok/koin habis.
3. **P1 — Pengalaman sentuh:** UX onboarding singkat, lebih sedikit perpindahan tab saat pekerjaan berulang, ukuran area sentuh, panel dan tipografi pada 360–450 px serta perangkat rasio tinggi.
4. **P1 — Performa:** pengujian langsung 30/60 FPS pada Android kelas menengah, memori puncak, waktu startup, resolusi tekstur, baterai, freeze saat autosave.
5. **P2 — Konten lanjutan:** bangunan produksi dengan fungsi tersendiri, pekerjaan kota/NPC, dekorasi tambahan, rantai crafting, event dengan hadiah unik dan progres yang tidak pay-to-win.
6. **P2 — Sistem daring:** ekonomi pemain, pasar antarpemain, teman/komunitas, layanan sinkronisasi dan pengamanan transaksi. Semua ini masih di luar MVP offline sekarang.

## Gerbang kualitas wajib

- Save/load dan migrasi progres lama tidak mereset kebun; hindari menyentuh `user://` progres pemain saat QA.
- Gameplay tanaman, ternak, produksi, pesanan, pasar, dan pembangunan harus bebas regresi dalam `tests/smoke.gd`.
- Visual diuji dalam 450 × 800 dan sekurangnya satu rasio layar Android berbeda; tombol, tanda, dan teks tidak terpotong.
- Indikator pesanan siap dan pintasan bahan harus tetap benar setelah stok berubah, pengiriman, dan pembukaan tab; regresi `tests/order_guidance.gd` menggunakan save terpisah.
- APK terbaru bisa dipasang dan dibuka pada emulator; pengujian ponsel Android fisik tetap diwajibkan sebelum rilis.
- Aset buatan sendiri dan lisensi/audio terlacak. Jangan mengklaim kesetaraan penuh dengan Hay Day sebelum pengujian pemain dan konten memadai.
