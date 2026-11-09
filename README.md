# Kebun Ceria — Farming Game (Godot 4)

Game pertanian 2D bernuansa kartun yang terinspirasi pengalaman membangun kebun seperti Hay Day. Ini adalah proyek orisinal **MVP offline**, bukan salinan aset atau kode Hay Day.

## Main sekarang

1. Buka `project.godot` di Godot 4.7.2, lalu tekan **F6/F5** (Jalankan Proyek).

   **Panduan pemain baru:** saat memulai game baru, ikuti tiga arahan di layar: **PANEN** gandum matang pada petak yang ditunjuk (petak keenam), **TANAM** kembali di petak yang sama, lalu buka tab **PESANAN**. Panah di dunia dan tanda seru di tab Pesanan menunjukkan langkah aktif. Progres panduan tersimpan otomatis; gunakan **LEWATI** untuk melewati panduan.
2. Pilih salah satu petak cokelat dan pilih bibit di panel bawah, lalu tekan **TANAM**.
3. Tunggu panen dalam beberapa detik (bertumbuh juga saat game ditutup), lalu tekan **PANEN**.
4. Buka **PESANAN** untuk mengirim hasil, **TOKO** untuk membeli bibit satuan atau paket 5, atau **GUDANG** untuk menjual stok sebanyak 1, 5, atau semua. Stok yang diperlukan pesanan dilindungi dengan dialog konfirmasi sebelum dijual; saat gudang penuh tersedia pintasan ke penjualan.
5. Buka **PRODUKSI** (ikon roda gigi) atau ketuk bangunan **DAPUR** untuk mengolah panen dan hasil ternak. Tersedia tiga belas resep, termasuk roti, popcorn, jus wortel, keju, mentega, kue, yogurt kambing, saus tomat, sambal, dan selai nanas; beberapa resep dibuka pada level berikutnya. Pilih resep ketika bahan cukup, tunggu waktu memasak, lalu tekan **AMBIL**.
6. Ketuk **kandang ayam** di sisi kanan atas peternakan untuk mengambil 2 telur saat gelembung siap muncul.
7. Ketuk **kandang sapi** di kiri bawah kebun. Berikan **2 gandum + 1 jagung** untuk pakan. Setelah **75 detik** (termasuk ketika aplikasi tertutup), perah **2 susu** dan dapatkan **10 XP**. Susu bisa dijual atau diolah menjadi **Keju Desa** di dapur dengan tambahan 1 jagung.
8. Ketuk petak hijau bertanda `+` untuk membuka lahan dengan koin.
9. Ketuk **MISI HARIAN** pada bagian kanan header atau papan kayu di kanan bawah kebun. Setiap hari ada 3 misi: memanen 6 hasil tanaman, mengirim 2 pesanan, dan mengambil 2 produk olahan. Selesaikan dan tekan **KLAIM** untuk mendapat koin, XP, dan permata. Progres serta status klaim disimpan dan otomatis diperbarui sesuai tanggal lokal.
10. Ketuk **gerobak PASAR** di sisi kanan atas kebun untuk membuka **Pasar Pinggir Jalan**. Pasang 1 atau 3 barang pada salah satu dari 3 lapak, lalu tunggu pembeli desa (75–105 detik). Setiap barang laku seharga dua kali harga jual gudang dan menghasilkan XP. Pembayaran terjadi otomatis, termasuk setelah aplikasi ditutup. Barang bisa dibatalkan sebelum laku asalkan gudang cukup ruang.
11. Ketuk **pohon buah** di sisi bawah kebun untuk membuka **KEBUN BUAH**. Satu pohon jeruk sudah tersedia sejak awal; petak kedua dapat ditanami jeruk (120 koin) atau apel mulai level 2 (220 koin). Setelah panen, pohon kembali menghasilkan 3 buah dalam 95 detik (jeruk) atau 155 detik (apel), termasuk saat aplikasi ditutup. Buah masuk gudang, bisa dijual di pasar atau gudang, dan dihitung pada misi panen.
12. Buka panel **TERNAK** untuk mengelola ayam, sapi, babi, dan kambing. Kandang babi serta kambing dibeli melalui **BANGUN & DEKORASI** dan terbuka setelah mencapai level yang diperlukan. Berikan pakan, tunggu timer, lalu ambil telur, susu, daging, atau susu kambing.
13. Buka **BANGUN & DEKORASI** untuk membeli kandang baru, **Rumah Roti** dan **Rumah Susu** (mempercepat produksi terkait 20%), serta dekorasi seperti taman bunga, gazebo, kincir angin, dan kolam.
14. Pada petak kebun yang kosong, daftar bibit dapat **digeser ke samping** untuk melihat seluruh jenis tanaman, termasuk tanaman yang terbuka di level lebih tinggi.
15. Ketuk papan **BANGUN** di kiri kebun atau **TERNAK** di kanan kebun untuk langsung membuka panel yang bersangkutan. Setelah dibeli, miniatur kandang babi/kambing dapat diketuk untuk mengelola ternak, sedangkan Rumah Roti/Rumah Susu membuka panel produksi.
16. Buka **PESANAN** untuk melihat kebutuhan setiap kontrak (jumlah stok yang dimiliki dibanding jumlah diminta), lengkap dengan **indikator progres terisi sebagian** dan hadiah koin/XP dalam bilangan bulat. Setelah beberapa pengiriman, kontrak dapat meminta **dua jenis barang** dari hasil pertanian, pohon buah, ternak atau dapur yang sudah dapat diakses. Ketuk **GANTI 15** untuk mengganti satu kontrak seharga **15 koin**; setiap slot memiliki cooldown **45 detik** yang tetap tersimpan saat game ditutup. Kontrak pengganti sekarang berusaha menghindari permintaan barang identik dengan kontrak aktif; kontrak yang sudah ada di save lama tetap dipertahankan.
17. **Jelajahi peta**: geser satu jari di area kebun untuk menggerakkan kamera, atau cubit dengan dua jari untuk memperbesar/memperkecil tampilan. Kamera bergerak halus dan berhenti di batas peta. Membuka petak lahan menambah area yang dapat dijelajahi. Di PC, tahan klik kiri lalu geser, atau gunakan roda mouse untuk zoom. Ketuk tanpa menggeser untuk memilih objek.
18. **Atur posisi kebun**: ketuk tombol **ATUR** di pojok kanan atas area peta. Sentuh dan geser petak pertanian, kandang sapi/ayam, dapur, gudang, pasar, pohon buah, maupun bangunan dan kandang tambahan yang sudah dibeli. Saat menggeser, **Object Snapping** membantu merapikan kebun: petak akan menempel pada pola isometrik petak tetangga, dan bangunan akan sejajar dengan sisi atau titik tengah bangunan lain jika cukup dekat. Garis seleksi berubah biru muda saat snapping aktif; di tempat lain posisi tetap bebas. Lepaskan untuk menyimpan posisi otomatis. Letakkan pada area kosong di dalam peta: lokasi yang bertabrakan, mengenai jalan, atau melewati tepi akan ditolak. Geser area kosong untuk menggerakkan kamera saat mengatur. Ketuk **SELESAI** untuk kembali menanam, memanen, atau berinteraksi. Tanaman yang sedang tumbuh tetap terikat pada petaknya setelah dipindahkan.
19. **Tebang pohon liar**: temukan salah satu pohon besar di area peta, lalu ketuk. **Ujang** otomatis mendekati pohon, mengayunkan kapak dan menumbangkannya. Pohon yang ditebang hilang permanen dari save game; setiap pohon memberi **6 koin dan 3 XP**. Ujang kembali berpatroli di pertanian dan peternakan setelah selesai.
20. **Dengarkan hewan**: ketuk kandang **ayam, sapi, babi, atau kambing** untuk mendengar suara hewan sesuai kandangnya (kandang tambahan hanya aktif setelah dibangun). Suara otomatis berhenti dalam 2,75 detik.
21. **Buat jalan sendiri**: ketuk **ATUR**, lalu pilih **+ JALAN**. Sentuh dan seret pada rumput kosong untuk menyusun jalan tanah lurus, berbelok, atau bercabang di atas petak grid; ruas yang dilewati jari otomatis tersambung. Jalan kustom kini menggunakan tampilan jalan tanah desa lama (lebar 75 unit, warna berlapis, dan permukaan berdebu). Pilih **- HAPUS** lalu seret di atas jalan untuk membongkar ruas yang tidak diinginkan. Pilih **OBJEK** untuk kembali memindahkan bangunan/petak, atau **GESER** untuk menjelajahi peta tanpa menggambar. Cubit dua jari untuk zoom. Ketuk **SELESAI** untuk kembali bermain. Seluruh jalan disimpan otomatis pada akhir setiap sapuan. Semua jalan permanen di peta dihapus; kebun dapat dirancang dari awal tanpa menghapus progres atau jalan kustom yang sudah disimpan.
22. **Tanam dan panen dengan satu usapan**: mulai mengusap dari petak yang siap panen untuk memanen beberapa petak sekaligus, atau dari petak kosong yang telah dibuka untuk menanam bibit terpilih. Petak yang akan diproses diberi garis bercahaya dan penghitung di bagian atas selama jari/mouse ditahan; perubahan baru diterapkan saat dilepas. Petak yang belum siap, terkunci, atau tidak memenuhi syarat akan dilewati, tanpa menghitung petak yang sama dua kali. Mengusap dari tanaman yang masih tumbuh atau rumput tetap menggeser kamera; cubit dua jari membatalkan usapan. Di PC gunakan klik kiri lalu seret.
23. **Antar pesanan dengan truk**: ketuk papan **PESANAN KIRIM** di samping depot dan peti kayu di kebun untuk membuka daftar kontrak. Setelah satu pesanan berhasil dikirim, truk bergerak keluar dari depot lalu kembali; animasinya tetap berjalan meskipun jalur permanen sudah dihapus. Animasi tidak memengaruhi saldo atau penghitungan hadiah yang sudah diselesaikan oleh sistem pesanan.
24. **Racik pakan ternak**: setelah mencapai **level 2**, beli **Pabrik Pakan** seharga **190 koin** lewat **BANGUN & DEKORASI**. Ketuk pabrik di dunia atau buka **PRODUKSI → PABRIK PAKAN** untuk membuat pakan sapi atau babi; pakan kambing terbuka di level 3. Setiap racikan menghasilkan **2 paket** setelah timer, dengan antrean maksimal **3** yang berjalan walau game ditutup. Tekan **AMBIL PAKAN** saat siap dan gudang cukup. Saat memberi makan ternak, **1 paket pakan** otomatis dipakai terlebih dahulu sebelum bahan panen mentah.
25. **Ambil hadiah kunjungan harian**: buka **MISI HARIAN** lalu tekan **AMBIL HADIAH**. Hadiah bertambah dari 35 koin pada hari ke-1 hingga 95 koin dan 1 permata pada hari ke-7. Klaim hanya bisa dilakukan sekali per tanggal lokal, hari terlewat mengulang siklus, dan progres tetap tersimpan setelah keluar dari game.

### Konten MVP

- Peta dunia berukuran 3600 × 2900 unit dengan ladang, bangunan, peternakan, kebun buah, dan 29 pohon liar yang dapat ditebang; 16 petak isometrik, 8 terbuka sejak awal.
- Kamera 2D bergaya isometrik dengan touch drag satu jari, pinch zoom dua jari, easing gerakan, zoom berpusat pada titik interaksi, dan batas kamera dinamis sesuai petak yang telah dibuka. Mouse drag dan scroll tersedia untuk desktop.
- 13 tanaman: gandum, jagung, wortel, tebu, stroberi, kedelai, kentang, labu, padi, tomat (level 6), cabai (level 9), kopi (level 13), dan nanas (level 17).
- Pertumbuhan berdasarkan jam asli dan tetap berjalan saat aplikasi tertutup.
- Gudang hasil panen, kapasitas dan upgrade, jual 1/5/SEMUA dengan konfirmasi ketika mengurangi kebutuhan pesanan, dan pembelian bibit 1/5.
- 3 pesanan aktif, hadiah koin + XP, kontrak gabungan, pergantian kontrak per slot seharga 15 koin dengan cooldown 45 detik, sistem level dan permata untuk percepat panen.
- Depot dengan papan yang dapat diketuk dan peti kayu, serta truk hasil panen yang berangkat dan kembali setelah transaksi pesanan yang berhasil.
- Peternakan ayam, sapi, babi, dan kambing: pakan, timer produksi, pengambilan telur/susu/daging, dan status yang bertahan saat game ditutup. Kandang babi/kambing dapat dibangun dengan koin dan syarat level.
- Kandang sapi dan ayam menggunakan ilustrasi isometrik asli dari Blender dengan hewan dekoratif serta hewan tambahan yang bergerak; kandang babi dan kambing memakai **ilustrasi Blender orisinal art_v8**. Hewan bergerak, menggerakkan kaki, ekor, dan kepala, serta sesekali berkedip atau mematuk. Kupu-kupu beterbangan dan kincir angin berputar. Animasi di `scripts/livestock_painter.gd` diperbarui sekitar 20 FPS saat kamera diam; telemetri debug Android telah dipakai untuk mengukur FPS di emulator, tetapi masih perlu verifikasi perangkat fisik.
- Dapur produksi dengan 13 resep (roti, popcorn, jus wortel, keju, mentega, roti manis, keripik kentang, kue, bacon, yogurt kambing, saus tomat, sambal, dan selai nanas), maksimal 3 antrean berurutan, dan timer yang tetap berjalan saat game ditutup.
- Pabrik Pakan dengan 3 resep terpisah (sapi, babi, kambing), antrean FIFO maksimal 3, 2 paket per racikan, timer offline, dan pengambilan sesuai kapasitas gudang. Pakan kemasan dipakai sebelum bahan panen mentah; antrean dan inventori pakan kompatibel dengan save lama.
- Pembangunan Rumah Roti dan Rumah Susu untuk bonus kecepatan produksi, dekorasi taman bunga/gazebo/kincir angin/kolam, serta pembukaan petak lahan baru dengan koin.
- Bahan langsung dipotong saat resep masuk antrean; produk siap dapat dikoleksi jika gudang masih memiliki ruang. Produk olahan bisa dijual atau diminta dalam pesanan lanjutan.
- Papan misi harian dengan progres panen, pesanan truk, dan produksi. Hadiah diberikan sekali per misi, klaim disimpan, dan misi direset setiap pergantian tanggal lokal.
- Kartu kunjungan harian tujuh hari di panel MISI, hadiah koin bertingkat dan satu permata pada hari ke-7. Klaim tanggal yang sama dan tanggal mundur ditolak; penyimpanan lama dimigrasikan secara kompatibel.
- Pasar Pinggir Jalan dengan tiga lapak, penyimpanan barang saat ditawarkan, pembelian NPC otomatis, hadiah koin dan XP, pembatalan, serta penjualan offline yang dibayar sekali saja. **Pasar saat ini disimulasikan oleh pembeli NPC; jual beli daring antarpemain/multiplayer belum tersedia.**
- Kebun buah dengan dua petak, pohon jeruk dan apel permanen, tiga buah per panen, siklus panen berulang, serta pembatasan kapasitas gudang dan level.
- Auto-save lokal JSON dengan file cadangan; antarmuka portrait dan dukungan sentuh.
- Posisi objek dapat disusun melalui mode ATUR dan disimpan ke file progres yang sama. Tampilan Android menggunakan aspect `expand` agar area layar memanjang terisi, termasuk di rasio lebih tinggi dari 9:16.
- Editor jalan menggunakan grid 80 unit dan jalan tanah selebar 75 unit dengan desain bekas jalur desa permanen, empat alat (OBJEK, + JALAN, - HAPUS, GESER), sambungan otomatis untuk goresan cepat, dan penyimpanan ke save game yang kompatibel dengan save lama. Ruas baru hanya dapat dibangun di lahan yang tersedia serta tidak menabrak bangunan, petak, dan pohon liar. Tidak ada lagi jalan permanen yang menghalangi penataan kebun.
- Ujang berpatroli memantau kandang, ladang, dan kebun. Tap pohon liar memicu perjalanan, ayunan kapak, serpihan kayu, animasi tumbang, serta hadiah koin dan XP. Status penebangan otomatis tersimpan.
- Tap kandang ayam, sapi, babi, atau kambing memutar suara hewan maksimal 2,75 detik. Ayunan kapak Ujang saat menebang pohon juga menghasilkan bunyi ketukan kayu. Kredit dan lisensi audio tercantum pada `AUDIO_CREDITS.md`.
- Visual farm menggabungkan ilustrasi isometrik orisinal hasil Blender (`assets/art_v2/` untuk rumah, gudang, pohon, tanah dan gandum; `assets/art_v3/` untuk kandang ayam/sapi, jagung, wortel dan bibit muda; `assets/art_v4/` untuk gerobak, pagar, semak dan jalan; `assets/art_v5/` untuk dekorasi seperti peti dan kolam; `assets/art_v6/` untuk keranjang panen, sumur, papan penunjuk, semak, gapura dan menara air; `assets/art_v7/` untuk Rumah Roti, Rumah Susu dan **Pabrik Pakan**; `assets/art_v8/` untuk kandang babi/kambing; `assets/art_v9/` untuk depot dan truk; `assets/art_v10/` untuk gerobak sortir dan papan penunjuk desa; `assets/art_v11/` untuk rumah penyerbuk, rak herba, penampung air hujan dan taman bunga melengkung) dengan gambar/animasi prosedural GDScript. `scripts/farm_art.gd` menggambar subregion tekstur impor secara langsung untuk menghindari penggandaan texture GPU. Tidak menggunakan aset Hay Day.
- Indikator animasi hasil siap muncul di atas dapur produksi, Pabrik Pakan, kandang sapi, babi, dan kambing ketika timer selesai. Ketukan pada indikator membuka panel terkait; penanda mengikuti bangunan ketika dipindah, dan tidak menghalangi mode ATUR. Rumah Roti, Rumah Susu, dan Pabrik Pakan memiliki area sentuh pada ilustrasinya.
- Lingkungan peternakan memiliki pepohonan buah, pagar semak, hamparan bunga, rumput terperinci, sumur, jerami, tong kayu, gerobak pasar, serta detail atap dan jendela bangunan. Area padang rumput selatan kini berisi kelompok bunga, semak berbunga, pagar tanaman, lampu pedesaan, sumur, gapura, keranjang panen, dan papan arah dari aset Blender orisinal yang sudah tersedia; tata letak menghindari tabrakan dengan objek kebun.
- Pratinjau: `preview.png` (kebun), `preview_misi.png`, `preview_pesanan.png`, `preview_production.png`, `preview_sapi.png`, `preview_pasar.png`, `preview_buah.png`, `preview_ternak.png` (hewan), `preview_pengunjung.png` (pengunjung), `preview_bangun.png` (bangunan/dekorasi), `preview_bangunan_produksi.png` (Rumah Roti/Susu pada kebun uji), dan `preview_bangunan_ternak.png` (kandang baru). Tangkapan layar Pabrik Pakan terdapat di `build/feed_mill_{locked,idle,ready,world}.png`. Gambar referensi pengguna berada di `referensi/`; pratinjau, gambar referensi, dan isi folder `build/` dikecualikan dari sumber daya APK.

### Status kualitas dan prioritas berikutnya

Pembaruan konten 7 November 2026 menambah empat tanaman level 6–17 (tomat, cabai, kopi, nanas) dengan ilustrasi tanaman prosedural dan tiga resep level 8–18 (saus tomat, sambal, selai nanas). Pengujian `tests/economy_level20.gd` mensimulasikan kemajuan dari level 5 hingga 20, pemulihan dari koin dan bibit kosong, produksi serta penjualan, batas gudang, dan kompatibilitas save lama. Pengujian ini memakai percepatan timer hanya di lingkungan QA; ritme permainan nyata perlu diuji oleh pemain.

Game ini masih prototipe orisinal offline, belum setara dengan kualitas, kelengkapan fitur, maupun presentasi visual Hay Day. Integrasi Rumah Roti/Susu, Pabrik Pakan, kandang babi/kambing, depot/truk, properti desa, serta hadiah kunjungan harian tersedia per 7 November 2026. Penjualan gudang 1/5/semua, perlindungan stok pesanan, pembelian bibit satuan, dan pencegahan kontrak duplikat telah diterapkan. Papan pesanan menampilkan status siap/kekurangan bahan dengan pintasan fasilitas, dan badge navigasi menandai kontrak siap kirim. Pemain juga dapat **mengambil hasil panen siap dari beberapa petak dengan satu usapan**, dengan pengecekan kapasitas gudang dan batas tiap petak. Rendering Ujang, truk, detail dunia, dan **16 petak ladang Android** kini menggunakan cache kanvas/tekstur yang disegarkan saat status berubah. **Sebelas suite regresi** lulus: `tests/smoke.gd`, `tests/inventory_ui_smoke.gd`, `tests/economy_progression.gd`, `tests/order_variety.gd`, `tests/order_guidance.gd`, `tests/economy_level20.gd`, `tests/economy_recovery.gd`, `tests/mobile_render_cache.gd`, `tests/daily_checkin.gd`, `tests/achievements.gd`, dan `tests/collect_ready_batch.gd` (`build/qa-pm-v21/`, seluruhnya `TOTAL FAILURES: 0`). APK v21 `build/KebunCeria-pm-plot-textures-20261107-debug-compatible.apk` telah dipasang melalui `adb install -r` dengan tanda tangan yang sama agar progres lama tidak terhapus; screenshot: `build/qa-pm-v21/android-v21-warm.png`. Pada sampel emulator v21, sekitar **327–330 draw calls**, **23–25 FPS**, dan **667.327 KiB PSS**; sebelumnya sampel v20 sekitar **498 draw calls**. Kondisi pengukuran belum dikontrol ketat sehingga pengurangan draw calls (~34%) belum menunjukkan kenaikan FPS yang sebanding. Target 60 FPS belum tercapai dan pengujian ponsel Android fisik belum dilakukan. Prioritas berikutnya ialah profiling render/GPU, keterbacaan UI layar kecil, konsistensi visual/animasi, dan validasi ritme ekonomi pada waktu nyata. Fitur sosial dan multiplayer belum tersedia.

### Jalankan / verifikasi

```powershell
& 'D:\AppData\Local\Programs\Godot\Godot_v4.7.2-stable_win64_console.exe' --path 'D:\portfolio\farmer\game\HayDay'
& 'D:\AppData\Local\Programs\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'D:\portfolio\farmer\game\HayDay' --script 'res://tests/smoke.gd'
& 'D:\AppData\Local\Programs\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'D:\portfolio\farmer\game\HayDay' --script 'res://tests/inventory_ui_smoke.gd'
& 'D:\AppData\Local\Programs\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'D:\portfolio\farmer\game\HayDay' --script 'res://tests/economy_progression.gd'
& 'D:\AppData\Local\Programs\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'D:\portfolio\farmer\game\HayDay' --script 'res://tests/order_variety.gd'
& 'D:\AppData\Local\Programs\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'D:\portfolio\farmer\game\HayDay' --script 'res://tests/order_guidance.gd'
& 'D:\AppData\Local\Programs\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'D:\portfolio\farmer\game\HayDay' --script 'res://tests/economy_level20.gd'
& 'D:\AppData\Local\Programs\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'D:\portfolio\farmer\game\HayDay' --script 'res://tests/economy_recovery.gd'
& 'D:\AppData\Local\Programs\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'D:\portfolio\farmer\game\HayDay' --script 'res://tests/mobile_render_cache.gd'
& 'D:\AppData\Local\Programs\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'D:\portfolio\farmer\game\HayDay' --script 'res://tests/daily_checkin.gd'
& 'D:\AppData\Local\Programs\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'D:\portfolio\farmer\game\HayDay' --script 'res://tests/achievements.gd'
& 'D:\AppData\Local\Programs\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'D:\portfolio\farmer\game\HayDay' --script 'res://tests/collect_ready_batch.gd'
& 'C:\Users\rohan\.local\bin\gdlint.exe' scripts tests
& 'C:\Users\rohan\.local\bin\gdformat.exe' --check scripts tests
```

Pengujian `tests/smoke.gd` memeriksa penanaman, pesanan tanaman/produk olahan/kontrak gabungan beserta perhitungan dan lebar indikator progres 25%, biaya penggantian kontrak, cooldown per slot, kebutuhan fasilitas, save/load, produksi, batas kapasitas gudang, antrean offline, peternakan, pembangunan/dekorasi, misi harian, klaim hadiah, pergantian hari, pasar dengan penjualan offline tanpa duplikasi pembayaran, dan kompatibilitas save lama. Pengujian kamera mencakup transformasi koordinat, zoom berpusat pada titik sentuh, drag, batas peta, perubahan batas ketika lahan dibuka, tap objek, pencegahan tap palsu saat drag, dan pinch dua jari.

Untuk memeriksa animasi ternak secara visual, jalankan `tests/capture_livestock.gd` tanpa `--headless`. Script ini menyimpan dua tangkapan layar kandang sapi/babi/kambing dengan selisih tiga detik dan satu gambar kandang ayam di `build/livestock_*.png`. Berkas di folder `build/` dikecualikan dari ekspor APK.

Untuk memperbarui seluruh gambar `preview*.png` dengan renderer OpenGL, jalankan perintah berikut **tanpa** `--headless` (mode headless tidak menyediakan tekstur viewport untuk screenshot):

```powershell
& 'D:\AppData\Local\Programs\Godot\Godot_v4.7.2-stable_win64_console.exe' --path 'D:\portfolio\farmer\game\HayDay' --script 'res://tests/capture.gd'
```

Untuk tangkapan layar interaksi usap dan indikator petak, jalankan `tests/capture_swipe.gd` dengan perintah yang sama dan ganti nama script. Kedua script ini digunakan untuk mengecek kualitas visual melalui hasil render Godot yang sebenarnya.

### Iklan AdMob (Android)

Enam format iklan terintegrasi melalui plugin **Poing Godot AdMob** (Gradle/Android):

- **Banner:** ditampilkan di ruang iklan bawah saat menjelajahi kebun dan panel selain toko.
- **Native advanced:** ditampilkan di bagian bawah ketika membuka **TOKO**; banner disembunyikan selama tampilan native aktif.
- **Interstitial:** tampil setelah setiap 4 pengiriman pesanan yang berhasil, dengan jeda minimal 10 menit antarpenayangan.
- **Rewarded:** tombol **Tonton iklan · +2 permata** di TOKO; permata hanya diberikan sesudah callback hadiah dari SDK.
- **Rewarded interstitial:** tombol pilihan **Tonton iklan bonus · +3 permata** di TOKO; hadiah diberikan sesudah callback SDK.
- **App open:** disiapkan untuk ditampilkan saat aplikasi kembali aktif setelah minimal 3 menit di background; iklan kedaluwarsa setelah 4 jam.

Konfigurasi ID produksi tersimpan di `scripts/farm_ads.gd`, sedangkan **App ID** `ca-app-pub-4976994447971905~7573169925` di `project.godot`. Build **debug** otomatis memakai unit iklan **tes resmi Google** untuk keenam format; build **release** memakai unit produksi pemilik aplikasi. Iklan hanya berjalan di Android dengan plugin aktif. Jika iklan belum siap atau jaringan bermasalah, game tetap bisa dimainkan. Permintaan interstitial, rewarded, rewarded interstitial, app open, dan native akan dicoba ulang setelah 60 detik bila gagal; native hanya diulang selama TOKO terbuka. Dua jenis hadiah iklan harus dipilih pemain sendiri.

**Firebase Remote Config:** Android terhubung menggunakan `google-services.json` (dimuat sebagai `android/build/google-services.json` saat build) dan plugin `FarmRemoteConfig`. Buat dan publikasikan parameter boolean berikut di Firebase Console (ejaan harus sama persis):

| Parameter | Fungsi |
| --- | --- |
| `EnableAdmob` | Sakelar global seluruh iklan |
| `EnableAdmobBanner` | Banner |
| `EnableAdmobInterstisial` | Interstitial pesanan |
| `EnableAdmobIntermediaryBonus` | Rewarded interstitial (+3 permata) |
| `EnableAdmobReward` | Rewarded (+2 permata) |
| `EnableAdmobNativeAdvance` | Native di toko |
| `EnableAdmobOpeningApp` | App open saat kembali dari background |

Secara default **semua parameter false**. Saat mulai, game memakai nilai Remote Config terakhir yang sudah diaktifkan di perangkat dan mencoba mengambil nilai terbaru; jika belum pernah berhasil, iklan tidak ditampilkan. Mengubah flag di Firebase Console perlu dipublikasikan dan diambil ulang oleh aplikasi (pada pembukaan berikutnya); pada build release periode fetch minimum 1 jam. Flag global dan flag per jenis sama-sama harus `true` agar jenis iklan tersebut boleh ditampilkan. Jika `EnableAdmob` atau flag untuk bonus terkait `false`, tombol bonus di TOKO memberi **+2/+3 permata langsung tanpa iklan** saat ditekan. Jika flag aktif, bonus hanya diberikan setelah callback hadiah dari SDK; iklan yang gagal dimuat tidak memberi bonus. Ruang iklan di bagian bawah hanya disediakan saat banner/native aktif. `google-services.json` tidak dimasukkan ke paket resource Godot.

**Perlu pengaturan AdMob:** buka **Privacy & messaging** pada akun AdMob dan siapkan formulir persetujuan (UMP) yang berlaku untuk aplikasi ini. Saat pengujian emulator 3 November 2026, Google mengembalikan kesalahan *no form(s) configured for the input app ID*. Build release tidak meminta iklan jika persetujuan tidak dapat ditentukan; hanya build debug yang dapat melanjutkan dengan iklan tes Google ketika UMP bermasalah. Emulator juga mengembalikan `net::ERR_CONNECTION_REFUSED` saat menghubungi server iklan Google. Tombol reward, bonus, dan privasi pada TOKO sudah diverifikasi tampil benar, tetapi penayangan iklan dan pemberian reward end-to-end belum dapat dikonfirmasi. Sebelum publikasi, verifikasi formulir privasi, koneksi ke server iklan, kebijakan Play Console, dan semua jenis iklan pada perangkat fisik.

### Android (APK debug)

APK debug PM **sudah berhasil dibuat, ditandatangani, dan dipasang** menggunakan Godot 4.7.2:

- File PM terbaru yang berhasil diekspor dan dipasang pada emulator: `build/KebunCeria-pm-scenery-selection-20261107-debug.apk` (**112.321.651 byte**). Termasuk fitur sebelumnya, indikator petak terpilih tanpa memaksa render ulang tekstur petak, dan reposisi empat properti dekorasi art_v11 agar terlihat dalam framing awal.
- Package: `com.kebunceria.farm`, versi `1.0`.
- Minimum Android API 24 (Android 7.0), target API 36, arsitektur ARM64.
- Orientasi: portrait.

Salin APK ke ponsel Android ARM64, lalu instal menggunakan pengelola berkas, atau hubungkan ponsel dengan USB debugging aktif dan jalankan:

```powershell
& 'C:\Users\rohan\AppData\Local\Android\Sdk\platform-tools\adb.exe' install -r 'D:\portfolio\farmer\game\HayDay\build\KebunCeria-pm-scenery-selection-20261107-debug.apk'
```

Untuk membangun ulang APK setelah mengedit proyek:

```powershell
& 'D:\AppData\Local\Programs\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --editor --path 'D:\portfolio\farmer\game\HayDay' --quit
& 'D:\AppData\Local\Programs\Godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'D:\portfolio\farmer\game\HayDay' --export-debug Android 'build/KebunCeria-debug.apk'
```

Build PM 7 November 2026 telah lulus **12 suite regresi** gameplay, UI, render cache, dan ekonomi (`build/qa-pm-v23/*-final.log`, semuanya `TOTAL FAILURES: 0`). `adb install -r` menghasilkan `Success` di emulator Android `emulator-5554`. Sertifikat SHA-256 APK lama dan baru identik (`9f11b542b92ce243ce01c476e5a0882c12d2f936dc8809be75ae52dd8448c338`), dan progres tetap **level 9, 101 koin, 59 permata**. Screenshot terbaru `build/qa-pm-v23/android-v23-late.png` memperlihatkan rumah penyerbuk, rak herba, penampung air, dan lengkung bunga dalam area dunia yang terlihat di atas navigasi bawah. Sampel `KEBUN_PERF` terbaru menunjukkan **18–25 FPS / 330–333 draw calls** di emulator; baseline APK sebelumnya sekitar 23–24 FPS / 327 draw calls pada sampel terdekat, sehingga perbaikan FPS belum terbukti. Laporan visual ada di `build/qa-design-v23/visual-audit.md`.

Tes tambahan `tests/economy_pacing_realistic.gd` memakai waktu virtual dengan durasi tumbuh asli dan save uji terisolasi. Jalur bertingkat aktif dari level 5 ke 20 memerlukan sekitar **41,3 menit waktu tanam virtual**, kunjungan tiap 10 menit **110 menit**, dan strategi gandum saja **18,8 menit** tetapi menghasilkan lebih sedikit koin. Angka simulasi ini mengecualikan waktu interaksi UI, pesanan, dan produksi, sehingga belum bisa dianggap waktu bermain nyata. Klaim hadiah dan penjualan langsung pada save pemain tidak dijalankan. **APK debug** belum mencapai 60 FPS dan belum diuji di ponsel fisik. Sebelum rilis Play Store masih dibutuhkan konfigurasi release, penandatanganan keystore pengembang, pengujian perangkat, dan konfigurasi consent UMP AdMob.

Pembaruan kamera dan peta pada **3 November 2026** telah lulus pengujian GDScript dan smoke test tanpa kegagalan. APK debug dibuat ulang, berhasil dipasang dengan `adb install -r`, dan berjalan di emulator yang sama. Gestur **geser satu jari** diverifikasi langsung; `build/emulator_camera_loaded.png` menampilkan posisi awal dan `build/emulator_camera_after_drag.png` menampilkan posisi setelah kamera digeser ke arah pasar. Pinch dua jari, pembatasan kamera, dan batas dinamis telah diperiksa melalui smoke test; pinch pada perangkat fisik belum diuji.
