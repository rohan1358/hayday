# Dokumentasi Lengkap Cheerful Garden (Kebun Ceria)

**Diperbarui:** 22 November 2026  
**Sumber acuan:** implementasi game Godot pada `project.godot`, `scripts/game_state.gd`, dan skrip subsistem terkait.  
**Cakupan:** gameplay, konten, mekanik, progres, ekonomi, dunia, pengaturan, iklan, penyimpanan, dan Android.

> Dokumen ini menggambarkan kondisi kode yang tersedia saat pembaruan. Level, koin, progres tutorial, kepemilikan, kapasitas gudang, dan layanan jarak jauh dapat mengubah fitur yang benar-benar terlihat oleh seorang pemain. Detail yang memerlukan pengujian pada perangkat diberi catatan.

## Daftar isi

1. [Identitas dan konsep](#1-identitas-dan-konsep)
2. [Pemain baru dan tutorial](#2-pemain-baru-dan-tutorial)
3. [UI dan kontrol](#3-ui-dan-kontrol)
4. [Lahan, bibit dan tanaman](#4-lahan-bibit-dan-tanaman)
5. [Kebun buah](#5-kebun-buah)
6. [Ternak dan pakan](#6-ternak-dan-pakan)
7. [Dapur dan produksi](#7-dapur-dan-produksi)
8. [Ekonomi dan perdagangan](#8-ekonomi-dan-perdagangan)
9. [Misi, level dan hadiah](#9-misi-level-dan-hadiah)
10. [Bangunan dan upgrade](#10-bangunan-dan-upgrade)
11. [Dekorasi, jalan dan penataan](#11-dekorasi-jalan-dan-penataan)
12. [Kawasan dan aktivitas](#12-kawasan-dan-aktivitas)
13. [Pulau, musim dan karakter](#13-pulau-musim-dan-karakter)
14. [Pesan, bahasa, pengaturan dan audio](#14-pesan-bahasa-pengaturan-dan-audio)
15. [Iklan](#15-iklan)
16. [Save dan kompatibilitas](#16-save-dan-kompatibilitas)
17. [Struktur teknis](#17-struktur-teknis)
18. [Menjalankan game dan membuat APK](#18-menjalankan-game-dan-membuat-apk)
19. [Status verifikasi](#19-status-verifikasi)

## 1. Identitas dan konsep

| Atribut | Kondisi saat ini |
| --- | --- |
| Nama proyek Godot | **Cheerful Garden** |
| Nama Indonesia | **Kebun Ceria** |
| Genre | Simulasi pertanian, manajemen sumber daya, pembangunan desa |
| Teknologi | **Godot 4.7.2**, GDScript, render **GL Compatibility** |
| Gaya visual | 2D stylized isometrik, suasana desa, pertanian, peternakan |
| UI | Layar portrait, viewport dasar **720 × 1280** |
| Scene awal | `res://scenes/Startup.tscn` |
| Data pemain | Lokal/offline menggunakan JSON pada `user://` |
| Paket Android | `com.kebunceria.farm` |
| Versi Android dalam preset | **1.1**, kode versi **2** |
| Arsitektur Android dalam preset | **arm64-v8a** |

**Siklus permainan utama** ialah memperoleh bibit dan sumber daya → menanam → memanen → mengolah hasil di dapur/pabrik → menjual atau memenuhi pesanan → memperoleh koin dan XP → meningkatkan level, fasilitas, lahan dan kawasan. Misi, check-in, prestasi, pulau dan koleksi dekorasi menjadi sasaran tambahan. Karakter petani bernama **Ujang** berinteraksi dengan dunia, termasuk mendatangi objek dan menebang pohon.

Waktu tanam, antrean produksi, hasil pohon buah, peternakan dan sejumlah kegiatan daerah memakai waktu nyata sehingga dapat berlanjut ketika game ditutup. Game menyimpan lokasi objek, inventaris, pesanan, konstruksi, jalan dan progres berbagai pulau.

## 2. Pemain baru dan tutorial

### 2.1 Kondisi awal

`scripts/game_state.gd` memiliki nilai inisialisasi dasar, lalu `scripts/first_farm.gd` **menggantinya untuk instalasi/pemain baru**. Karena itu, nilai dalam `new_game()` saja kurang tepat untuk menggambarkan sesi pemain baru.

| Data | Pemain baru dengan First Farm | Nilai dasar internal/sebelum penyesuaian |
| --- | ---: | ---: |
| Koin | **100** | 400 |
| Permata | **10** | 12 |
| Bibit gandum | **3** | 8 |
| Bibit jagung | **0** | 5 |
| Petak aktif dari 16 | **3** | 8 |
| Jenis pohon buah awal | **Apel** | Jeruk |
| Level awal | **1** | 1 |
| Kapasitas gudang | **60** | 60 |

Save lama yang tidak memakai FTUE versi baru memiliki jalur kompatibilitas dan progres kebun sebelumnya tetap dipertimbangkan.

### 2.2 Tahapan tutorial First Farm

1. **Sambutan:** ketuk salah satu dari tiga petak yang ditandai.
2. **Tanam 3 gandum:** pilih bibit gandum, tanam di tiga petak yang dibuka. Alur ini membatasi penanaman pertama pada gandum dan petak tutorial.
3. **Tunggu tanaman:** fase pertama dipercepat menjadi **8 detik** per gandum.
4. **Panen:** ambil hasil dari ketiga petak.
5. **Jual pada Bu Sari:** serahkan **3 gandum**, menerima **50 koin dan 30 XP**.
6. **Klaim hadiah/tutorial:** mendapat hadiah lanjutan termasuk **3 bibit gandum**, kemudian diarahkan ke level 2.
7. **Tutorial kandang ayam:** mulai **level 3**, kandang awal dapat dibangun seharga **80 koin**, menghasilkan kepemilikan **2 ayam**. Pemain diperkenalkan pada Pakan Ayam dan telur.

State tutorial `ftue` disimpan. Tahap yang telah dijalankan tidak perlu dimulai ulang setelah menutup game. Save lama dapat memiliki urutan onboarding berbeda dan tidak otomatis disamakan dengan First Farm baru.

### 2.3 Gerbang fitur

| Level | Fitur yang diperkenalkan / akses minimum |
| ---: | --- |
| 1 | Rumah, inventaris/gudang, tamu, toko, pertanian awal, produksi dasar sesuai alur |
| 2 | Perluasan lahan, jalan, dekorasi |
| 3 | Pesanan, peternakan, kandang ayam tutorial |
| 4 | Ekosistem kebun |
| 5 | Pengantar produksi lanjutan, misi produksi |
| 20 | Fitur evolusi sesuai gating sistem |

Fitur yang terlihat di layar tetap bergantung pada **fase FTUE, level, kepemilikan bangunan/kawasan, bahan, dan ruang untuk penempatan**. Beberapa level pada katalog merupakan syarat dasar sebelum penyesuaian tutorial. Pabrik Pakan, misalnya, memiliki level katalog **3**, tetapi alur unlock pemain baru mengarahkannya ke **level 5**.

## 3. UI dan kontrol

### 3.1 Bagian layar dan menu

HUD menampilkan **level, XP, koin, permata**, dan akses fungsi utama. Menu atau panel yang ada pada kode mencakup **Kebun, Toko, Pilih Bibit, Gudang, Pesanan, Produksi, Ternak, Kebun Buah, Bangun & Dekorasi, Jalan, Kawasan, Misi, Prestasi, Hadiah, Pesan, dan Pengaturan**. Sebagian menu bersifat kontekstual berdasarkan objek dan progres pemain.

Petak berinteraksi lewat **TANAM** dan **PANEN**, resep lewat aksi buat/ambil, pesanan lewat kirim/ganti, sedangkan bangunan/kawasan memiliki pembelian, penempatan, operasional dan peningkatan masing-masing.

### 3.2 Kontrol

| Aksi | Fungsi |
| --- | --- |
| Ketuk objek/petak | Memilih atau berinteraksi |
| Geser satu jari | Menggeser kamera jika tidak sedang memakai alat penempatan |
| Cubit dua jari | Zoom kamera |
| Drag mouse | Menggeser kamera di desktop |
| Scroll mouse | Zoom di desktop |
| WASD / joystick | Mengendalikan Ujang pada mode terkait |
| Kamera bebas / mengikuti | Opsi di menu pengaturan |
| **ATUR / OBJEK** | Memilih dan memindahkan objek yang didukung |
| **+ JALAN** | Memasang ruas jalan berdasarkan grid dan stok |
| **- HAPUS** | Menghapus ruas jalan dan mengembalikan stok |
| **GESER** | Menggeser pandangan ketika dalam penataan |

Penempatan memperhatikan tabrakan, batas dunia, objek lain dan snapping/alignment. Petak yang dipindahkan mempertahankan tanaman serta waktu tanamnya. Ujang memiliki gerakan, pekerjaan interaksi dan animasi.

## 4. Lahan, bibit dan tanaman

### 4.1 Mekanik pertanian

Ada **16 petak**. Pemain baru memulai dengan **3 petak terbuka**; beberapa save lama memakai **8 petak**. Perluasan tersedia seiring progres, dengan harga dasar sekitar **120 koin** dan kenaikan **85 koin** per petak yang sudah dibuka menurut progres lahan. Petak kosong yang aktif menerima bibit sesuai level. Penanaman mengurangi 1 bibit, lalu pemanenan menambah hasil dan XP.

Pertumbuhan memakai cap waktu aktual. Gudang harus menyediakan ruang untuk menerima hasil. Toko bibit mendukung beli **1/5** bibit. Mekanisme pemulihan bibit darurat didefinisikan sebesar **3 bibit** dengan cooldown **600 detik**.

### 4.2 Semua 14 tanaman

Harga bibit dan harga jual adalah **koin per unit**. Waktu dan XP adalah nilai dasar; hasil adalah banyak item per satu tanaman.

| Tanaman | Level | Tumbuh | Bibit | Jual | XP | Hasil |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Gandum | 1 | 12 dtk | 3 | 5 | 5 | 2 |
| Jagung | 1 | 26 dtk | 8 | 13 | 9 | 2 |
| Wortel | 2 | 42 dtk | 12 | 19 | 13 | 3 |
| Kedelai | 2 | 52 dtk | 15 | 23 | 15 | 3 |
| Tebu | 3 | 65 dtk | 22 | 30 | 19 | 3 |
| Kentang | 3 | 70 dtk | 24 | 36 | 20 | 3 |
| Stroberi | 4 | 90 dtk | 34 | 47 | 26 | 3 |
| Labu | 4 | 105 dtk | 38 | 58 | 29 | 3 |
| Padi | 5 | 135 dtk | 46 | 69 | 34 | 3 |
| Tomat | 6 | 150 dtk | 60 | 85 | 37 | 3 |
| Cabai Merah | 9 | 190 dtk | 78 | 108 | 43 | 3 |
| Biji Kopi (ladang) | 13 | 240 dtk | 95 | 132 | 50 | 3 |
| Nanas | 17 | 300 dtk | 115 | 162 | 58 | 3 |
| Stroberi Kristal | 20 | 420 dtk | 160 | 225 | 80 | 3 |

Item `kopi` yang ditanam di ladang berbeda dari item buah pohon kopi `biji_kopi` pada kebun buah. Keduanya punya level dan ekonomi berbeda.

## 5. Kebun buah

Kebun buah mempunyai **12 slot**. Pohon ditanam sesuai level, kemudian setiap kali matang menghasilkan **3 buah** dan dapat kembali berbuah setelah jeda. Waktu berlanjut secara offline dan gudang membatasi pengambilan. Pohon buah merupakan sumber panen berulang, sedangkan pohon liar bisa ditebang untuk kayu.

| Pohon buah | Level | Tumbuh ulang | Harga tanam | Jual/buah | XP | Hasil |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Jeruk Manis | 1 | 95 dtk | 120 | 27 | 18 | 3 |
| Apel Merah | 2 | 155 dtk | 220 | 41 | 28 | 3 |
| Pisang | 3 | 150 dtk | 240 | 43 | 29 | 3 |
| Mangga | 4 | 180 dtk | 280 | 52 | 32 | 3 |
| Lemon | 4 | 190 dtk | 300 | 57 | 32 | 3 |
| Ceri | 5 | 210 dtk | 340 | 65 | 35 | 3 |
| Pir | 5 | 230 dtk | 380 | 71 | 35 | 3 |
| Alpukat | 6 | 260 dtk | 440 | 82 | 38 | 3 |
| Kelapa | 6 | 240 dtk | 400 | 75 | 38 | 3 |
| Persik | 7 | 280 dtk | 480 | 90 | 41 | 3 |
| Kakao | 8 | 320 dtk | 580 | 115 | 44 | 3 |
| Buah Kopi | 8 | 300 dtk | 540 | 105 | 44 | 3 |

## 6. Ternak dan pakan

### 6.1 Semua jenis ternak aktif

Ternak yang memiliki alur interaksi/produksi teridentifikasi adalah **ayam, sapi, babi, kambing**. Peternakan menyimpan jumlah hewan, status kandang, bahan pakan, timer dan hasil. Pakan kemasan digunakan terlebih dahulu jika tersedia sesuai logika sistem.

| Hewan | Akses | Pakan mentah | Durasi produksi | Produk | Jual/unit |
| --- | --- | --- | ---: | --- | ---: |
| Ayam | Kandang ayam, tutorial level 3 | Pakan Ayam dari gandum | Timer telur tersendiri | Telur | 18 |
| Sapi | Kandang sapi | Gandum ×2, Jagung ×1 | 75 dtk | Susu ×2 | 28 |
| Babi | Beli Kandang Babi | Jagung ×2, Kedelai ×1 | 95 dtk | Daging babi ×2 | 44 |
| Kambing | Beli Kandang Kambing | Wortel ×2, Gandum ×1 | 110 dtk | Susu kambing ×2 | 48 |

`wol` atau **Wol Domba** sudah terdaftar sebagai item inventaris bernilai jual **36 koin**, tetapi alur peternakan domba yang dapat dibeli/dimainkan belum terkonfirmasi pada kode yang diperiksa.

### 6.2 Pabrik Pakan

Pabrik Pakan memiliki **antrean 3 proses FIFO**, timer offline, dan aturan gudang saat pengambilan. Tabel di bawah adalah syarat **level resep**, sementara kemampuan mengoperasikan pabrik tetap bergantung pada akses bangunannya.

| Produk | Level resep | Bahan | Lama | Hasil | XP | Jual/unit |
| --- | ---: | --- | ---: | ---: | ---: | ---: |
| Pakan Ayam | 3 | Gandum ×2 | 8 dtk | 1 | 4 | 8 |
| Pakan Sapi | 2 | Gandum ×3, Jagung ×2 | 25 dtk | 2 | 8 | 13 |
| Pakan Babi | 2 | Jagung ×3, Kedelai ×2 | 35 dtk | 2 | 10 | 21 |
| Pakan Kambing | 3 | Wortel ×3, Gandum ×2 | 40 dtk | 2 | 12 | 25 |

Mengetuk kandang juga memicu suara hewan. Perwujudan hewan pada peta melibatkan animasi dan objek dekoratif selain logika produksi.

## 7. Dapur dan produksi

### 7.1 Antrean dan bahan

Resep dapur dapat dimulai bila level dan persediaan memenuhi syarat. **Bahan dikurangi saat dimasukkan ke antrean**, kapasitas **3 antrean**, produksi **FIFO**, waktu berjalan ketika game tertutup, hasil diambil setelah selesai jika gudang memiliki ruang. **Toko Roti** dan **Pabrik Susu** memberi bonus kecepatan **20%** untuk kategori resep masing-masing. Angka tabel adalah durasi dan nilai jual dasar sebelum bonus.

### 7.2 Katalog 26 resep dapur

Setiap resep menghasilkan **1 produk**.

| Resep | Level | Bahan | Waktu | Jual | XP |
| --- | ---: | --- | ---: | ---: | ---: |
| Roti Hangat | 1 | Gandum ×3 | 32 dtk | 24 | 12 |
| Popcorn | 1 | Jagung ×3 | 45 dtk | 48 | 17 |
| Jus Wortel | 2 | Wortel ×2 | 60 dtk | 53 | 22 |
| Keju Desa | 2 | Susu ×2, Jagung ×1 | 75 dtk | 85 | 25 |
| Mentega | 2 | Susu ×2 | 60 dtk | 70 | 24 |
| Jus Apel | 2 | Apel ×2, Tebu ×1 | 84 dtk | 230 | 32 |
| Jus Jeruk | 2 | Jeruk ×2, Tebu ×1 | 84 dtk | 230 | 32 |
| Roti Manis | 3 | Gandum ×2, Tebu ×1 | 75 dtk | 88 | 25 |
| Keripik Kentang | 3 | Kentang ×3 | 80 dtk | 120 | 30 |
| Bacon Panggang | 3 | Daging babi ×2, Jagung ×1 | 95 dtk | 122 | 35 |
| Roti Pisang | 3 | Pisang ×2, Gandum ×1 | 96 dtk | 275 | 38 |
| Kue Stroberi | 4 | Gandum ×2, Telur ×2, Susu ×1, Stroberi ×1 | 125 dtk | 195 | 46 |
| Yogurt Kambing | 4 | Susu kambing ×2, Stroberi ×1 | 110 dtk | 158 | 41 |
| Puding Mangga | 4 | Mangga ×2, Tebu ×1 | 108 dtk | 320 | 44 |
| Limun Segar | 4 | Lemon ×2, Tebu ×1 | 108 dtk | 320 | 44 |
| Selai Ceri | 5 | Ceri ×2, Tebu ×1 | 120 dtk | 365 | 50 |
| Pai Pir | 5 | Pir ×2, Gandum ×1 | 120 dtk | 365 | 50 |
| Jus Alpukat | 6 | Alpukat ×2, Tebu ×1 | 132 dtk | 410 | 56 |
| Puding Kelapa | 6 | Kelapa ×2, Tebu ×1 | 132 dtk | 410 | 56 |
| Selai Persik | 7 | Persik ×2, Tebu ×1 | 144 dtk | 455 | 62 |
| Saus Tomat | 8 | Tomat ×2, Tebu ×1 | 130 dtk | 230 | 55 |
| Cokelat Kebun | 8 | Kakao ×2, Tebu ×1 | 156 dtk | 500 | 68 |
| Kopi Seduh | 8 | Buah kopi ×2, Tebu ×1 | 156 dtk | 500 | 68 |
| Sup Ikan Desa | 11 | Ikan ×1, Wortel ×1, Tepung ×1 | 80 dtk | 125 | 34 |
| Sambal Desa | 12 | Cabai ×2, Tomat ×1 | 170 dtk | 340 | 66 |
| Selai Nanas | 18 | Nanas ×2, Tebu ×1 | 210 dtk | 390 | 82 |

### 7.3 Penggilingan

**Kawasan Penggilingan** (level kota 2, harga **650 koin**) mengolah **2 gandum/jagung/kedelai/padi** menjadi varian **tepung/tepung jagung/tepung kedelai/tepung beras**. Waktu dasar **60 detik** bagi gandum/jagung dan **120 detik** bagi kedelai/padi; proses memberi XP setelah dikoleksi melalui sistem industri. Tepung biasa menjadi bahan Sup Ikan dan kegiatan kawasan Kafe.

## 8. Ekonomi dan perdagangan

### 8.1 Mata uang dan inventaris

- **Koin:** membeli bibit, bangunan, dekorasi, jalan, petak, kawasan, penggantian kontrak, serta biaya peningkatan.
- **Permata:** mata uang premium untuk sejumlah percepatan dan hadiah. Dapat diberikan oleh misi, prestasi, aktivitas tertentu, dan iklan berhadiah jika diaktifkan.
- **XP:** berkontribusi pada peningkatan level pemain dan pembukaan konten. Kota pada pulau lain mempunyai progres level tersendiri.
- **Gudang:** kapasitas awal **60 unit**, memuat hasil panen, buah, ternak, produk dapur/pakan, hasil kawasan, dan stok barang. Upgrade Gudang menambah **30 unit** kapasitas tiap kenaikan.
- **Material peningkatan:** kayu, batu, paku dan palu disimpan terpisah dalam sistem peningkatan bangunan.

### 8.2 Toko dan penjualan langsung

Toko menyediakan pembelian bibit satuan/kelipatan lima, bangunan, jalan dan dekorasi menurut kategori serta syarat level. Gudang menyediakan jual **1**, **5** atau **SEMUA** stok. Penjualan yang menghabiskan barang yang dibutuhkan pesanan aktif memunculkan dialog konfirmasi. Barang inventaris dapat menjadi bahan resep, perdagangan, misi dan aktivitas kawasan.

### 8.3 Pesanan truk

Ada **3 kontrak aktif** dengan kebutuhan barang, jumlah terpakai dan hadiah **koin + XP**. Seiring progres, kontrak dapat meminta **lebih dari satu jenis barang**. Pengiriman yang selesai memicu sistem truk, memperbarui penghitung pengiriman/misi/prestasi dan memberi **1 paku** sebagai material upgrade.

Opsi **GANTI** mengeluarkan **15 koin** per kontrak yang diputar dan memiliki cooldown tersimpan selama **45 detik** per slot. Sistem mengusahakan agar kontrak baru berbeda dari yang sedang aktif. Pesanan yang telah tersimpan pada save lama tetap bisa dipulihkan.

### 8.4 Pasar Pinggir Jalan

Pasar memiliki **3 lapak**. Pemain memasang barang dari gudang, kemudian pembeli NPC menyelesaikan transaksi secara otomatis setelah jeda dasar sekitar **75 detik**. Harga hasil jual pasar adalah **2 × nilai dasar penjualan gudang** dan menghasilkan XP sesuai logika pasar. Proses dapat selesai secara offline dan transaksi memiliki perlindungan klaim ganda. Penawaran belum laku dapat dibatalkan apabila gudang memiliki ruang.

Perdagangan pasar yang terimplementasi merupakan **transaksi simulasi dengan NPC**. Sistem multiplayer/jual-beli daring antarpemain belum terkonfirmasi.

### 8.5 Tamu desa

NPC pengunjung yang terdaftar adalah **Bu Sari**, **Pak Budi**, **Kak Rina** dan **Pak Tono**. Mereka dapat meminta barang dan menawarkan imbalan. Setelah permintaan **diterima** cooldown adalah **150 detik**, setelah **ditolak** cooldown **90 detik**. Kunjungan Bu Sari pertama mengikuti skenario tutorial dengan hasil khusus.

## 9. Misi, level dan hadiah

### 9.1 Tiga misi harian

Misi direset berdasarkan **tanggal lokal** dan perlu diambil melalui klaim. Progres/status klaim disimpan.

| Misi | Sasaran | Akses | Hadiah |
| --- | --- | --- | --- |
| Petani Rajin | Panen 6 hasil tanaman | Level 1 | **65 koin + 12 XP** |
| Kurir Desa | Kirim 2 pesanan | Level 3 | **100 koin + 18 XP + 1 permata** |
| Koki Kebun | Ambil 2 olahan | Level 5 | **85 koin + 20 XP + 1 permata** |

### 9.2 Empat prestasi permanen

Setiap rangkaian mempunyai **3 milestone** dengan klaim yang tersimpan.

| Prestasi | Target tahap 1/2/3 | Koin tahap 1/2/3 | XP tahap 1/2/3 | Permata tahap 1/2/3 |
| --- | --- | --- | --- | --- |
| Ahli Panen | 30 / 150 / 500 | 100 / 350 / 1050 | 25 / 75 / 180 | 0 / 1 / 2 |
| Juru Masak | 5 / 25 / 100 | 130 / 450 / 1250 | 30 / 90 / 200 | 0 / 1 / 2 |
| Kurir Andalan | 3 / 15 / 50 | 160 / 550 / 1650 | 35 / 105 / 230 | 0 / 1 / 2 |
| Sahabat Desa | 5 / 25 / 90 | 120 / 440 / 1250 | 30 / 90 / 190 | 0 / 1 / 2 |

Kelompoknya berturut-turut menghitung **panen termasuk buah**, **produk olahan/pakan yang dikoleksi**, **pengiriman**, dan **perdagangan** di gudang/pasar/tamu.

### 9.3 Check-in dan pesan hadiah

Sistem **hadiah kunjungan 7 hari** memiliki klaim harian, nilai hadiah bertingkat, dan bonus permata di bagian akhir siklus. Tanggal serta klaim disimpan untuk mencegah hadiah duplikat, termasuk ketika hadiah kunjungan dapat dibuka dari beberapa menu.

### 9.4 Misi perjalanan level

`scripts/level_journey.gd` membuat tugas per level berdasarkan baseline penghitung aktivitas saat tugas diterbitkan. Rumusnya:

| Aktivitas | Rumus target | Mulai level |
| --- | --- | ---: |
| Panen | `min(80, 3 + level × 2)` | 1 |
| Kirim pesanan | `min(8, 1 + floor(level / 8))` | 3 |
| Ambil produksi | `min(20, 2 + floor(level / 4))` | 5 |
| Hadiah koin | `min(100000, 30 + level × 10)` | Semua level |
| Hadiah XP | `min(500, 10 + level × 3)` | Semua level |

Misi perjalanan tidak hilang sebelum klaim. Level baru juga menampilkan daftar objek/tanaman/kawasan yang dibuka berdasarkan konfigurasi, dan progres mempengaruhi kapasitas menu yang tersedia.

## 10. Bangunan dan upgrade

### 10.1 Semua konstruksi utama

| Bangunan | Level katalog | Harga koin | Fungsi |
| --- | ---: | ---: | --- |
| Pabrik Pakan | 3 | 190 | Membuat pakan dengan antrean |
| Kandang Babi | 2 | 220 | Daging babi |
| Kandang Kambing | 3 | 320 | Susu kambing |
| Toko Roti | 1 | 0 | Mempercepat olahan kategori roti/kue **20%** |
| Pabrik Susu | 1 | 0 | Mempercepat olahan kategori susu **20%** |
| Taman Bunga | 1 | 55 | Dekorasi kebun |
| Gazebo Kayu | 2 | 130 | Dekorasi |
| Kincir Angin | 3 | 250 | Dekorasi animasi |
| Kolam Ikan | 4 | 290 | Dekorasi |

Syarat level katalog dapat **dinaikkan oleh progres FTUE**. Contohnya untuk pemain baru, Kandang Babi/Kambing efektif minimal **level 3** dan Pabrik Pakan **level 5** berdasarkan `level_journey.gd`. Pembelian juga bergantung ketersediaan lokasi yang tidak bertabrakan, uang serta jalur UI.

### 10.2 Tingkat peningkatan

`scripts/building_upgrades.gd` mencantumkan **Gudang Panen, Dapur, Rumah, Toko Roti, Pabrik Susu**, masing-masing tier **1 sampai 5**. Untuk meningkatkan tier saat ini **t** menjadi **t+1** (t = 1 hingga 4), pemain memulai tugas upgrade dan memenuhi:

| Komponen | Syarat |
| --- | --- |
| Koin | **100 × t²** |
| Batu | **4 × t** |
| Kayu | **5 × t** |
| Paku | **2 × t** |
| Palu | **t** |
| Panen selama misi | **6 × t** |
| Pengiriman selama misi | **t** |
| Pengambilan hasil produksi | **t**, khusus Dapur/Toko Roti/Pabrik Susu |
| Tambahan kapasitas | **+30** untuk Gudang saja |

Level yang diperlukan untuk tier **1→2 / 2→3 / 3→4 / 4→5**:

| Bangunan | Level minimum pada tiap tahap |
| --- | --- |
| Gudang | 2 / 5 / 8 / 11 |
| Dapur | 3 / 6 / 9 / 12 |
| Rumah | 1 / 2 / 3 / 4 |
| Toko Roti | 1 / 1 / 1 / 1 |
| Pabrik Susu | 1 / 1 / 1 / 1 |

Misi peningkatan memiliki baseline penghitung masing-masing. Setelah seluruh syarat terpenuhi, sumber daya dikurangi dan pemain mengklaim tier baru.

### 10.3 Perolehan kayu, batu, paku dan palu

| Sumber | Hasil dasar | Syarat / waktu |
| --- | --- | --- |
| Tebang pohon liar | **3 kayu + 6 koin + 3 XP** | Pohon aktif/belum ditebang, Ujang dapat menjangkau, **maksimal 3 gratis per hari** |
| Batu alam | **3 batu** | Cooldown **90 detik** per node |
| Pengiriman pesanan | **1 paku** | Menyelesaikan kontrak |
| Tambang | **2 batu + 1 palu** | Kawasan level 2, harga 150 koin, proses 75 dtk |

**Persyaratan menebang pohon saat ini** adalah pohon masih tersedia, dapat diinteraksi, Ujang memiliki jalur mendekat, dan pemain memiliki jatah tebang. Pemain dapat menebang **3 pohon liar gratis per hari** (tanggal lokal perangkat). Setelah batas tercapai, interaksi pohon menampilkan popup konfirmasi **Tonton iklan / Batal** untuk memperoleh **1 kesempatan tebang tambahan per iklan Rewarded atau Rewarded Interstitial** yang berhasil ditonton sampai SDK memberikan callback hadiah. Setelah iklan selesai dan hadiah diterima, perintah menebang pohon yang tadi dipilih langsung dilanjutkan, termasuk melalui antrean perintah Ujang. Menekan Batal atau gagal memperoleh hadiah membiarkan pohon tetap utuh. Kesempatan tambahan yang belum dipakai disimpan dalam save dan direset bersama jatah gratis saat tanggal berganti. Penghitungan berlaku gabungan untuk seluruh pulau dan seluruh jalur penebangan. Jika iklan tidak tersedia, pemain menunggu jatah gratis berikutnya. Ujang mengayunkan kapak sekitar **3 kali** sebelum pohon tumbang. Pohon yang ditebang dicatat **permanen pada save pulau tersebut**. Pohon buah produktif mengikuti mekanisme bagian 5.

## 11. Dekorasi, jalan dan penataan

### 11.1 Semua dekorasi dalam urutan katalog

`DECORATION_ORDER` menentukan dekorasi yang dipertimbangkan oleh urutan toko, lalu filter toko dan level menerapkan syarat masing-masing. Harga merupakan harga katalog per item. Item tanpa field level menggunakan nilai dasar level 1.

| Dekorasi | Level | Harga koin |
| --- | ---: | ---: |
| Rumput Taman | 1 | 10 |
| Pohon Apel Hias | 1 | 90 |
| Kios Kebun Hias | 1 | 120 |
| Hamparan Bunga | 1 | 35 |
| Semak Berbunga | 1 | 45 |
| Taman Bunga | 1 | 55 |
| Pagar Tanaman | 1 | 40 |
| Pagar Kayu | 1 | 40 |
| Gerbang Bunga | 1 | 90 |
| Lampu Kebun | 1 | 65 |
| Keranjang Panen | 1 | 60 |
| Papan Petunjuk | 1 | 45 |
| Sumur Harapan | 1 | 140 |
| Menara Air | 1 | 160 |
| Rumah Lebah | 1 | 95 |
| Rak Herbal | 1 | 90 |
| Penampung Hujan | 1 | 110 |
| Bulan Sabit Bunga | 1 | 75 |
| Kolam Hias | 1 | 190 |
| Rumah Kaca Hias | 8 | 240 |
| Sudut Komposter | 5 | 95 |
| Aliran Air Mini | 6 | 170 |
| Meja Riset Kebun | 7 | 125 |
| Peti Benih Warna | 2 | 75 |
| Pohon Sakura Kebun | 4 | 165 |
| Pohon Lentera Ungu | 12 | 230 |
| Taman Batu Kristal | 10 | 135 |
| Habitat Lebah Bunga | 3 | 90 |
| Habitat Katak | 6 | 110 |
| Taman Kupu-kupu | 4 | 95 |
| Rumpun Jamur Hias | 5 | 85 |
| Penyiram Taman | 2 | 90 |
| Traktor Hijau | 5 | 400 |
| Kolam Bebek | 3 | 180 |
| Silo Gandum | 5 | 320 |
| Rumah Sortir Buah | 6 | 360 |
| Pengatur Iklim | 8 | 270 |
| Ayunan Taman | 8 | 185 |
| Kios Bunga | 10 | 330 |
| Dermaga Kayu | 11 | 250 |
| Bengkel Tambang | 14 | 520 |
| Panggung Festival | 15 | 470 |
| Penggergajian | 14 | 440 |
| Tenda Camping | 18 | 220 |
| Air Mancur Bunga | 4 | 240 |
| Kotak Surat Desa | 2 | 75 |
| Meja Kafe | 22 | 170 |
| Istal Kuda | 25 | 600 |
| Sinyal Kereta | 26 | 190 |
| Kapal Dagang | 50 | 900 |
| Rumah Kaca Besar | 8 | 650 |
| Jembatan Batu | 11 | 240 |

Entri katalog **`DECORATIONS`** yang juga dideklarasikan tetapi **di luar `DECORATION_ORDER`** saat peninjauan adalah **Rumah Pengolah Gula, Sekolah Kecil, Papan Tulis dan Arena Panen**. Daftar di atas mencakup objek dasar, koleksi **Living Garden** (misalnya habitat/komposter/rumah kaca hias), dan objek dunia berlabel `ref_`. Kemunculan aktual tetap dapat dibatasi filter dan akses toko. Beberapa nama juga muncul sebagai ilustrasi di lingkungan, tanpa menjadi bangunan fungsional tersendiri.

### 11.2 Tiga jalan

| Jenis | ID | Harga per unit |
| --- | --- | ---: |
| Batu Pastel | `stone` | 3 |
| Bata Merah | `brick` | 5 |
| Batu Alam Berlumut | `moss` | 8 |

Jalan dibeli menjadi **stok**. Mode **+ JALAN** mengonsumsi satu stok per ruas, **- HAPUS** mengembalikan stoknya, dan mengganti jenis ruas mengembalikan stok lama sekaligus menggunakan stok baru. Jalan memakai grid. Data lama berjenis `wood` dimigrasikan menjadi `moss` oleh `road_catalog.gd`.

### 11.3 Tata dunia

Mode **ATUR** dapat memindahkan petak, gedung dan objek yang memenuhi syarat. Pemeriksaan posisi meliputi batas peta, permukaan tanah, area kawasan, jalan serta tabrakan. Snapping membantu merapikan objek pada pola isometrik. Tata letak tersimpan per pulau. Objek dekorasi, bangunan, petak dan jalan membentuk kawasan pertanian yang lebih luas dari tiga petak tutorial.

## 12. Kawasan dan aktivitas

### 12.1 Seluruh 25 kawasan

`scripts/world_regions.gd` mendaftarkan **25 kawasan**, terdiri dari **8 kawasan dasar** dan **17 kawasan yang dibeli**. Level merujuk ke **level kota pulau aktif**. Selain level dan koin, pembelian mengikuti status FTUE dan kepemilikan.

| Kawasan | Level | Harga koin | Peran |
| --- | ---: | ---: | --- |
| Desa Utama | 1 | Bawaan | Rumah, tetangga, pesanan |
| Pertanian | 1 | Bawaan | Petak dan panen |
| Hutan | 1 | Bawaan | Kayu dari pohon liar |
| Peternakan | 3 | Bawaan | Hewan dan kandang |
| Produksi | 5 | Bawaan | Dapur dan pakan |
| Gudang & Logistik | 5 | Bawaan | Penyimpanan dan pengiriman |
| Kebun Buah | 1 | Bawaan | Pohon buah |
| Pasar Desa | 1 | Bawaan | Perdagangan |
| Penggilingan | 2 | 650 | Tepung |
| Rumah Kaca | 9 | 720 | Bibit stroberi |
| Taman Bermain | 5 | 680 | Mini game |
| Pemancingan | 11 | 900 | Ikan |
| Tambang | 2 | 150 | Batu dan palu |
| Pusat Festival | 15 | 1300 | Hadiah acara |
| Area Camping | 18 | 850 | Kebahagiaan |
| Permukiman NPC | 20 | 1800 | Surat tetangga |
| Kafe & Restoran | 22 | 2100 | Hidangan desa |
| Pusat Berkuda | 24 | 2300 | Aktivitas wisata |
| Stasiun Kereta | 26 | 2600 | Pengiriman |
| Sekolah Desa | 28 | 2900 | Wawasan |
| Taman Botani | 30 | 3200 | Bunga langka |
| Resor Danau | 35 | 3900 | Paket wisata |
| Kota Wisata | 40 | 4700 | Ekonomi wisata |
| Arena Kompetisi | 45 | 5300 | Piala panen |
| Pelabuhan Dagang | 50 | 6200 | Kontrak berhadiah besar |

Semua kawasan yang dibeli memiliki sistem tier **1 sampai 5**. Upgrade pada tier **t** membutuhkan **koin = harga pembelian × t**, **kayu = 2 × t** dan **batu = t**. Peningkatan dapat memberi bonus penghasilan/output dan mengurangi waktu istirahat menurut kegiatan kawasan.

### 12.2 Aktivitas kawasan sampai level 18

| Kawasan | Persyaratan aksi | Hasil dasar | Cooldown |
| --- | --- | --- | ---: |
| Rumah Kaca | Memiliki kawasan | 2 bibit stroberi + 6 XP | 120 dtk |
| Taman Bermain | Memiliki kawasan | 4 jenis mini game dan hadiah sesuai aturannya | Per wahana |
| Pemancingan | Gudang tidak penuh | 1 ikan + 7 XP | 45 dtk |
| Tambang | Proses industri | 2 batu + 1 palu | 75 dtk |
| Area Camping | Memiliki kawasan | +10 kebahagiaan + 7 XP | 100 dtk |
| Pusat Festival | 20 kebahagiaan dan 3 gandum | 140 koin + 30 XP | 180 dtk |
| Penggilingan | 2 bahan sesuai jenis tepung | Tepung + XP | 60–120 dtk |

Pusat Festival **mengonsumsi 20 kebahagiaan dan 3 gandum** untuk hadiah. Empat wahana yang teridentifikasi pada Taman Bermain adalah **Komidi Putar, Lempar Bola, Tangkap Hewan, Cocokkan Buah**, dengan hadiah harian/progres terpisah.

### 12.3 Semua 10 kegiatan kawasan level 20–50

Tabel menunjukkan **nilai dasar tier 1**. Bahan dikurangi ketika aksi dilakukan, hadiah diterima menurut implementasi, lalu kawasan masuk cooldown. Tier yang lebih tinggi dapat memodifikasi hadiah dan waktu.

| Kawasan | Bahan | Hasil dasar | Cooldown |
| --- | --- | --- | ---: |
| Permukiman NPC | Gandum ×3 | Surat tetangga ×1, 80 koin, 20 XP | 75 dtk |
| Kafe & Restoran | Tepung ×1, Susu ×1 | Hidangan desa ×1, 25 XP | 90 dtk |
| Pusat Berkuda | Gandum ×2 | 55 koin, +12 kebahagiaan, 25 XP | 100 dtk |
| Stasiun Kereta | Ikan ×1, Hidangan desa ×1 | 240 koin, 34 XP | 130 dtk |
| Sekolah Desa | Roti ×1 | Wawasan ×1, +6 kebahagiaan, 30 XP | 120 dtk |
| Taman Botani | Stroberi ×1, Wawasan ×1 | Bunga langka ×1, 36 XP | 150 dtk |
| Resor Danau | Ikan ×1, Bunga langka ×1 | Paket wisata ×1, +10 kebahagiaan, 40 XP | 170 dtk |
| Kota Wisata | Hidangan desa ×1, Paket wisata ×1 | 460 koin, +14 kebahagiaan, 45 XP | 180 dtk |
| Arena Kompetisi | Gandum ×5 | Piala panen ×1, 180 koin, 50 XP | 200 dtk |
| Pelabuhan Dagang | Piala panen ×1, Bunga langka ×1 | 900 koin, 1 permata, 65 XP | 240 dtk |

**Kebahagiaan** disimpan pada state kawasan, dibatasi **0–100**. Rantai inventaris kawasan menghubungkan **ikan → sup/pengiriman**, **gandum → tepung → kafe**, **kafe → hidangan desa**, **sekolah → wawasan → botani → bunga langka → resor/pelabuhan**, **resor → paket wisata → kota wisata**, dan **arena → piala panen → pelabuhan**.

## 13. Pulau, musim dan karakter

### 13.1 Dunia dan perjalanan antarpulau

Sistem perjalanan berada pada `scripts/island_journey.gd`, sedangkan visual peta dan penempatan zona musim dikelola `scripts/four_seasons.gd`. Ukuran dunia musim yang didefinisikan adalah **4320 × 7680** unit.

| Urutan | ID internal | Nama lokasi | Tema |
| ---: | --- | --- | --- |
| 1 | `summer` | Summer Meadow | Musim panas dan kebun awal |
| 2 | `spring` | Spring Valley | Musim semi |
| 3 | `autumn` | Autumn Hollow | Musim gugur |
| 4 | `winter` | Winter Peak | Musim dingin |

`four_seasons.gd` juga memiliki area **Central Village** (`central`) sebagai lokasi visual di dunia. Daftar pulau yang dapat dipilih pemain berisi **empat** pulau di tabel di atas.

Pemain memulai perjalanan di **Summer Meadow**. Akses menuju pulau selanjutnya memerlukan pembukaan level yang cukup untuk seluruh **25 tipe kawasan** di setiap pulau sebelumnya. Pemeriksaan kode memakai jumlah kawasan yang sudah *terbuka berdasarkan level kota*, bukan jumlah kawasan yang sudah dibeli. Dengan daftar level kawasan saat ini, kebutuhan tersebut mencapai **level kota 50** pada pulau sebelumnya.

### 13.2 Progres masing-masing pulau

Masing-masing pulau memiliki progres **level kota dan XP kota**, serta kondisi dunia tersendiri. Pada pulau selain Summer Meadow, XP kota bertambah melalui `award_city_xp()`, dengan kebutuhan level berikutnya `100 + (level - 1) × 25` XP dan batas level **50**. Level Summer Meadow tersinkron dengan level utama pemain.

Ketika berpindah pulau, game menyimpan dan memulihkan kondisi berikut secara khusus per pulau.

- Posisi objek, dekorasi, ruas jalan, pohon yang disembunyikan atau ditebang, serta pohon tambahan.
- Kepemilikan dan tier kawasan, waktu aktivitas siap kembali, kebahagiaan kawasan, dan pekerjaan industri.
- Posisi karakter dan sejumlah data pemulihan area bermain.

Inventaris pemain dan fasilitas pertanian utama dibawa bersama karakter saat bepergian. Perpindahan pulau mengembalikan tampilan ke tab kebun, menyegarkan visual dan cuaca, serta menyimpan state permainan.

### 13.3 Karakter dan kostum

Karakter petani utama bernama **Ujang**. Pemain dapat berinteraksi dengan objek, berjalan melalui kontrol gerak, dan memberi perintah memotong pohon. Sistem tampilan karakter mempunyai pilihan variasi **perempuan/laki-laki** dan tampilan musiman.

`scripts/wardrobe_catalog.gd` mendefinisikan **24 aksesori** versi katalog **6**. Aksesori dikelompokkan menurut empat musim dan dua pilihan tampilan karakter. Setiap kombinasi menyediakan tiga slot, yaitu **kepala**, **leher**, dan **tas/pinggang**. Harga yang tertera dalam katalog adalah **45 koin** untuk aksesori kepala, **30 koin** untuk leher, dan **40 koin** untuk tas/pinggang. Pilihan kostum dan slot tersimpan pada data karakter.

## 14. Pesan, bahasa, pengaturan dan audio

### 14.1 Kotak pesan

Kotak pesan ada pada `scripts/mailbox.gd` dan `scripts/mailbox_ui.gd`. Antarmuka mempunyai kategori **Pesan**, **Hadiah**, dan **Pengumuman**. Setiap pesan dapat menyimpan ID, judul, isi, pengirim, tanggal, status dibaca, hadiah dan status klaim.

- Sistem menghasilkan pesan informasi dan tip pengelolaan kebun.
- Hadiah login harian dikirim ke kotak pesan, dengan jumlah hadiah sesuai pratinjau check-in pada menu Misi.
- Klaim check-in diproteksi agar mengambil dari kotak pesan dan dari menu Misi pada tanggal yang sama tidak menggandakan hadiah.
- Pesan berhadiah dan pengumuman dapat dipilah pada tab masing-masing. Hadiah yang tidak memenuhi syarat klaim ditandai tidak tersedia.

### 14.2 Pengaturan dan bahasa

Menu pengaturan pada `scripts/settings_ui.gd` menyediakan pengaturan volume **Musik**, **Efek Suara**, dan **Suasana Alam** dengan slider persentase, serta tombol **Matikan Semua Suara**. Pilihan audio disimpan oleh subsistem audio.

Menu pengaturan mempunyai **delapan kategori**, yaitu **Audio**, **Kamera**, **Kontrol**, **Tata Letak**, **Kelola Aset**, **Pulihkan**, **Bahasa**, dan **Tentang**. Kategori Kamera menawarkan mode **Eksplorasi Bebas**, **Ikuti Karakter**, dan **Kembalikan Kamera**. Kontrol menyediakan akses ke antrean tugas serta **Lewati Panduan** saat tutorial aktif. Tata Letak menghubungkan mode pemindahan aset dan penerapan tata letak contoh. Kelola Aset membuka daftar aset dan koleksi. Pulihkan menyediakan pemulihan posisi dan **Mulai Permainan Baru** dengan konfirmasi. Bahasa menawarkan **Indonesia (`id`)** dan **Inggris (`en`)** melalui `GardenLanguage`. Tab Tentang menjelaskan penyimpanan lokal dan dapat memunculkan pilihan privasi iklan saat iklan aktif.

Game mempunyai interaksi kamera untuk geser dan zoom, pengaturan posisi bangunan, serta tindakan pemulihan atau reset yang memerlukan konfirmasi sesuai menu terkait. Terjemahan dapat berbeda kelengkapannya antara teks yang sudah menggunakan sistem bahasa dan teks yang masih ditulis langsung pada skrip antarmuka.

### 14.3 Audio dan aset visual

Efek suara mencakup interaksi dan suara hewan; musik dan ambiens dipisahkan pada kanal volume pengaturan. Kredit suara tersedia pada `AUDIO_CREDITS.md`. Aset visual, ikon, sprite, dan beberapa iterasi karya berada di direktori `assets/`, termasuk kelompok `assets/art_v*/`. Berkas versi aset dalam repositori belum tentu semuanya dimuat sebagai objek aktif di gameplay. Acuan untuk fitur yang dapat digunakan pemain adalah pemanggilan aset dan kode scene saat ini.

## 15. Iklan

### 15.1 Status integrasi

Integrasi iklan Android telah diimplementasikan di `scripts/farm_ads.gd` dengan plugin **Poing Godot AdMob** dan konfigurasi jarak jauh **Firebase Remote Config**. Kode memeriksa bahwa game berjalan pada **Android** dan singleton `PoingGodotAdMob` tersedia.

Terdapat **enam format iklan** yang didukung.

| Format | Pemakaian/ketentuan yang tercantum pada kode | Flag Remote Config |
| --- | --- | --- |
| Banner | Iklan menetap pada ruang UI ketika berhasil dimuat | `EnableAdmobBanner` |
| Native | Overlay native, termasuk tampilan toko | `EnableAdmobNativeAdvance` |
| Interstitial | Iklan layar penuh setiap kelipatan **4 pesanan berhasil dikirim**, dengan cooldown **600 detik** | `EnableAdmobInterstisial` |
| Rewarded | Iklan berhadiah **2 permata**, dengan alur hadiah atau percepatan yang didukung pemanggil | `EnableAdmobReward` |
| Rewarded interstitial | Iklan layar penuh berhadiah **3 permata** | `EnableAdmobIntermediaryBonus` |
| App open | Iklan saat membuka/melanjutkan aplikasi menurut kondisi waktu, termasuk jeda latar belakang minimal **180 detik** | `EnableAdmobOpeningApp` |

Kode menyiapkan **unit iklan uji Google untuk debug build** dan **unit iklan milik proyek untuk release build**. Callback digunakan untuk status berhasil dimuat, kegagalan, penutupan, pemuatan ulang, dan pemberian hadiah. Ketika format iklan hadiah aktif, reward diberikan berdasarkan callback SDK. Khusus tombol bonus permata yang memanggil `show_rewarded()`, **jika format tersebut dinonaktifkan, kode langsung memberikan 2 atau 3 permata tanpa tayangan iklan**. Alur *percepatan proses* (`request_speedup`) berbeda: percepatan mensyaratkan iklan rewarded aktif dan callback hadiah SDK yang berhasil, tanpa hadiah langsung saat iklan dinonaktifkan.

**ID aplikasi AdMob Android** pada `project.godot` adalah `ca-app-pub-4976994447971905~7573169925`. `scripts/farm_ads.gd` memilih unit iklan lewat `ad_unit(kind)`, menggunakan ID **Google test** apabila `OS.is_debug_build()` bernilai `true`, atau ID **production proyek** untuk build release.

| Format | Ad Unit ID production |
| --- | --- |
| Banner | `ca-app-pub-4976994447971905/2631175294` |
| Interstitial | `ca-app-pub-4976994447971905/3313701576` |
| Rewarded interstitial | `ca-app-pub-4976994447971905/8494535208` |
| Rewarded | `ca-app-pub-4976994447971905/7181453530` |
| Native | `ca-app-pub-4976994447971905/4059807035` |
| App open | `ca-app-pub-4976994447971905/7061374891` |

### 15.2 Kapan iklan dapat muncul

Seluruh flag format dimulai pada nilai **`false`** di kode. Agar format tertentu dapat ditampilkan, perlu ada respons konfigurasi jarak jauh yang valid, format terkait bernilai **`true`**, dukungan plugin native, dan iklan telah berhasil dimuat. Flag induk `EnableAdmob` diperlakukan sebagai aktif apabila respons Remote Config valid **tetapi kunci induk tidak disediakan**; bila kunci itu secara eksplisit `false`, semua format diblokir.

Tayangan iklan **sudah dilaporkan muncul saat pengujian APK release di Android Emulator pada 22 November 2026**. Tayangan tersebut masih memiliki label **"Test"**, sesuai perilaku AdMob yang memperlakukan emulator sebagai perangkat uji meskipun aplikasi meminta unit iklan production. Ini membuktikan alur penayangan pada emulator dapat berjalan, tetapi **belum memverifikasi penayangan iklan production pada HP Android fisik**. Hasil penayangan juga bergantung pada perangkat, koneksi, persetujuan pengguna, dan ketersediaan iklan dari layanan AdMob.

Saat pemain mencapai batas **3 tebang pohon gratis per hari**, tombol **Tonton iklan** meminta format `rewarded` atau `rewarded_interstitial` yang tersedia. Satu callback hadiah dari SDK memberi satu kredit tebang tambahan, tanpa bonus otomatis ketika iklan tidak aktif atau gagal dimuat. Format iklan ini harus diaktifkan melalui Firebase Remote Config pada APK Android.

### 15.3 Remote Config dan privasi AdMob (22 November 2026)

Pada tangkapan layar **Firebase Remote Config versi 5** untuk Cheerful Garden, parameter yang telah dipublikasikan dengan cakupan **Fetch 100%** menunjukkan keadaan berikut. Nilai ini merupakan konfigurasi layanan yang terlihat saat pemeriksaan dan dapat berubah tanpa build APK baru.

| Parameter | Nilai dipublikasikan |
| --- | --- |
| `EnableAdmobBanner` | `false` |
| `EnableAdmobIntermediaryBonus` | `true` |
| `EnableAdmobInterstisial` | `true` |
| `EnableAdmobNativeAdvance` | `true` |
| `EnableAdmobOpeningApp` | `false` |
| `EnableAdmobReward` | `true` |

Artinya, permintaan **Interstitial**, **Rewarded**, **Rewarded interstitial**, dan **Native** diizinkan oleh flag masing-masing, sedangkan **Banner** dan **App open** dinonaktifkan. Status pemuatan aktual tetap mengikuti respons AdMob SDK dan logika masing-masing fitur. Pada cuplikan ini kunci induk `EnableAdmob` tidak terlihat; perilaku kunci induk mengikuti ketentuan pada bagian 15.2.

Pengaturan aplikasi di dashboard **AdMob** menunjukkan paket Google Play `com.kebunceria.farm`, status aplikasi **Diverifikasi**, dan **Status persetujuan: Siap**. Halaman **Privasi & pesan** memperlihatkan **1 pesan aktif untuk Peraturan Eropa** dan **1 pesan aktif untuk Peraturan negara bagian AS**. Kode aplikasi memakai **Google User Messaging Platform (UMP)** melalui `UserMessagingPlatform.consent_information.update()`, menampilkan formulir bila diperlukan dan tersedia, serta menyediakan `show_privacy_options()` bagi pengguna.

Dalam pemeriksaan Logcat emulator pada **22 November 2026 sekitar pukul 06.55 WIB**, UMP telah menerima respons server dan menulis data consent. Pesan kesalahan lama **`Publisher misconfiguration: no form(s) configured`** tidak terlihat pada proses aplikasi terbaru yang diperiksa. Ini adalah verifikasi komunikasi UMP pada sesi tersebut, bukan jaminan seluruh wilayah dan perangkat akan memperoleh formulir yang sama.

### 15.4 Perbedaan pengujian dan production

- **Debug APK** menggunakan ID unit uji resmi Google.
- **Release/production APK** menggunakan ID unit iklan pemilik proyek sesuai tabel bagian 15.1.
- **Android Emulator** diperlakukan sebagai perangkat pengujian sehingga iklan dapat tetap berlabel **"Test"** saat memakai unit production.
- **HP Android fisik** yang tidak terdaftar sebagai perangkat uji diperlukan untuk memvalidasi tampilan iklan production. Pastikan status test device di AdMob sesuai kebutuhan sebelum melakukan pengujian. Label test pada emulator tidak dengan sendirinya menandakan ID production salah.

## 16. Save dan kompatibilitas

Data permainan disimpan oleh `scripts/game_state.gd` sebagai JSON di lokasi aplikasi Godot (`user://`).

| Berkas | Fungsi |
| --- | --- |
| `user://kebun_ceria_v1.json` | Save utama |
| `user://kebun_ceria_backup.json` | Save cadangan |

Save versi data **1** memuat progres pertanian dan karakter, saldo, inventaris, penanaman/panen, waktu proses, misi, pesanan, bangunan, peternakan, kebun buah, dekorasi, jalan, pembersihan pohon, kawasan, pulau dan informasi lain yang diperlukan untuk melanjutkan permainan. Penghitungan proses berbasis waktu memungkinkan sejumlah proses selesai ketika game ditutup.

Kode memuat jalur kompatibilitas untuk sejumlah perubahan format lama, termasuk transisi tutorial First Farm, perubahan representasi jalan tertentu, dan pemisahan state antarpulau. Data dari save yang dibuat sebelum fitur baru mungkin memiliki nilai awal atau susunan benda berbeda dari instalasi baru. Simpanan pemain perlu dicadangkan sebelum uji reset atau migrasi manual.

## 17. Struktur teknis proyek

Proyek menggunakan **Godot 4.7.2**, GDScript, struktur `res://`, dan scene awal `Startup.tscn`. Tabel berikut merangkum titik masuk dan modul penting untuk pengembangan serta perawatan.

| Berkas/direktori | Tanggung jawab |
| --- | --- |
| `project.godot` | Identitas proyek, viewport, renderer, autoload, pengaturan proyek |
| `scenes/Startup.tscn` dan `scripts/startup.gd` | Scene awal serta inisialisasi permainan |
| `scripts/main.gd` | Orkestrasi antarmuka dan subsistem permainan |
| `scripts/game_state.gd` | Model progres, daftar konten, inventaris dan save/load |
| `scripts/first_farm.gd` | Onboarding dan progres pemain baru |
| `scripts/first_coop.gd` | Pengenalan serta alur kandang awal |
| `scripts/world_regions.gd` | Katalog 25 kawasan dan persyaratan levelnya |
| `scripts/industry_jobs.gd` | Aktivitas/pekerjaan industri kawasan |
| `scripts/level_journey.gd` | Gerbang pembukaan fitur berdasarkan level |
| `scripts/island_journey.gd`, `scripts/four_seasons.gd` | Perjalanan pulau, musim, visual dan data dunia |
| `scripts/building_upgrades.gd` | Upgrade bangunan dan biaya material |
| `scripts/road_catalog.gd` | Jenis jalan dan biaya pembangunannya |
| `scripts/wardrobe_catalog.gd`, `scripts/wardrobe_editor.gd` | Aksesori dan kostum |
| `scripts/mailbox.gd`, `scripts/mailbox_ui.gd` | Kotak pesan dan klaim hadiah |
| `scripts/settings_ui.gd`, `scripts/garden_language.gd` | Pengaturan dan bahasa |
| `scripts/farm_ads.gd` | Iklan dan Remote Config |
| `assets/` | Sprite, audio, ikon, font dan berkas aset |
| `addons/` | Plugin/add-on Godot |
| `tests/` | Berkas pengujian proyek |
| `export_presets.cfg`, `build/` | Konfigurasi ekspor dan keluaran build |

Sebagian subsistem berinteraksi melalui objek state yang sama dan autoload. Saat mengubah daftar tanaman, harga, durasi atau kunci state, periksa kode model data, antarmuka, pemanggil aktivitas dan kompatibilitas save secara bersamaan.

## 18. Menjalankan game dan membuat APK

### 18.1 Menjalankan lewat Godot

1. Buka direktori proyek atau `project.godot` menggunakan editor Godot **4.7.2**.
2. Izinkan editor melakukan impor aset yang diperlukan.
3. Tekan **F5** untuk menjalankan proyek melalui scene awal `scenes/Startup.tscn`.
4. Untuk Android, pastikan Android SDK, template ekspor Godot dan dependensi Gradle yang diperlukan tersedia.

### 18.2 Preset Android

File `export_presets.cfg` mendefinisikan lebih dari satu target Android.

| Preset | Output yang dikonfigurasi | Package | Versi |
| --- | --- | --- | --- |
| `Android` | `build/KebunCeria-debug.apk` untuk ekspor APK debug | `com.kebunceria.farm` | 1.1, code 2 |
| `Android AAB` | `build/KebunCeria-prod.aab` | `com.kebunceria.farm` | 1.1, code 2 |
| Preset hybrid Android | `../outputs/KebunCeria-Hybrid-Android.apk` | `com.kebunceria.hybrid` | 1.7-playground-farm, code 8 |

Preset utama memakai arsitektur **arm64-v8a** dan ekspor Android berbasis **Gradle**. Perintah contoh untuk membuat APK debug dari terminal dengan Godot yang tersedia pada PATH adalah berikut.

```powershell
godot --headless --path "D:\portfolio\farmer\game\HayDay" --export-debug "Android" "build/KebunCeria-debug.apk"
```

Contoh tersebut memerlukan penyiapan Android SDK/template ekspor yang valid pada komputer pembuat. Keberhasilan build dan pemasangan di ponsel perlu diperiksa lewat output perintah dan uji perangkat. Catatan pekerjaan APK sebelumnya dapat dilihat di `UPDATE-APK-TERBARU.md` bila berkas itu tersedia.

**APK release production terbaru yang telah dibuat** pada 22 November 2026 berada di `build/KebunCeria-22-Nov-2026-Production.apk` (sekitar **553 MB**). Identitas paket APK yang diperiksa adalah `com.kebunceria.farm`, versi **1.1**, `versionCode` **2**. APK tersebut telah dipasang pada Android Emulator untuk pengujian AdMob. Untuk menguji iklan monetisasi pada perangkat fisik, gunakan APK release ini dan pastikan perangkat tidak berada dalam daftar perangkat uji AdMob.

## 19. Status verifikasi dan pemeliharaan dokumentasi

Dokumentasi gameplay ditinjau berdasarkan **kode sumber dan konfigurasi proyek pada 21 November 2026**, dengan pembaruan **integrasi AdMob, konfigurasi jarak jauh, privasi, dan build Android pada 22 November 2026**. Angka konten, syarat level, formula, serta mekanik dalam tabel berasal dari implementasi dan katalog kode pada saat peninjauan. Tampilan aktual seorang pemain dapat bergantung pada save lama, fitur terkunci, pulau aktif, dan flag layanan jarak jauh.

| Area | Status dalam penyusunan dokumen |
| --- | --- |
| Katalog tanaman, buah, ternak, masakan, dekorasi dan kawasan | Ditelusuri dari definisi kode |
| Tutorial, ekonomi, pembuatan barang, pembukaan level, pergerakan pulau | Ditelusuri dari implementasi |
| Pengaturan, kotak pesan, save/load, ekspor | Ditelusuri dari skrip dan konfigurasi |
| Menjalankan seluruh game dari awal hingga level 50 pada perangkat | **Belum diverifikasi pada sesi dokumentasi** |
| Firebase Remote Config dan formulir Privasi & Pesan AdMob | **Terlihat aktif di dashboard pada 22 November 2026**; rincian bagian 15.3 |
| UMP pada Android Emulator | **Berhasil menerima respons server pada pemeriksaan Logcat 22 November 2026** |
| Tayangan AdMob pada Android Emulator | **Iklan telah terlihat menurut laporan pengujian pengguna**, dengan label "Test" |
| Tayangan iklan production serta pemberian hadiah pada HP Android fisik | **Belum diverifikasi** |
| Hasil build APK release terbaru dan pengujian instalasi | **APK production 22 November 2026 tersedia dan telah dipasang di emulator**; rincian bagian 18.2 |

**Jika implementasi berubah**, perbarui dokumen ini bersama kode pada bagian yang relevan. Untuk penambahan item baru, periksa nama, level, biaya, waktu, hasil, batas kapasitas, tampilan UI serta kompatibilitas save. Untuk perubahan iklan atau Android, periksa juga konfigurasi jarak jauh, preset ekspor, dan perilaku runtime pada perangkat.
