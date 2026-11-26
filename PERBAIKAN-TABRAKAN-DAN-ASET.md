# Perbaikan tabrakan, kandang, dan aset milik pemain

1. Navigasi kebun awal memakai seluruh footprint aset yang benar-benar ada, termasuk gudang, kandang yang diperbesar, gedung produksi, pohon/pagar dan dekorasi. Perubahan kepemilikan sapi juga membatalkan cache navigasi. Karakter yang berada di dalam rintangan saat perbaikan save dipindah ke titik aman. Gambar aset di depan karakter digambar ulang sesuai kedalaman kaki, sehingga karakter di belakang pohon/bangunan tidak tampak berdiri di atasnya.

2. Pembelian kandang ayam/sapi/babi/kambing dan gedung produksi mencari lahan yang lolos collision dan tidak menumpuk secara visual dengan pohon atau aset lain. Jika tidak ada ruang, pembelian tidak diproses. Posisi baru disimpan, kamera diarahkan ke bangunan yang dibeli. Save kebun baru yang sudah memiliki kandang bertumpuk diperbaiki satu kali; posisi lama dicadangkan pada ftue.asset_overlap_backup. Koin dan jumlah hewan tidak diubah.

3. Koleksi sekarang mempunyai ASET MILIKMU: daftar seluruh dekorasi dengan gambar, status TERSIMPAN/TERPASANG, PASANG atau LIHAT DI KEBUN; bangunan milik pemain juga tercantum. Pembatalan penempatan tidak menghapus barang. Penempatan dekorasi memulai pratinjau di lahan kosong yang ditemukan, bukan langsung menimpa aset pada pusat kamera.

Pengujian lulus:
- asset_collision_purchase_test: seluruh footprint solid, jalur melintasi aset ditolak, lokasi ternak tidak bertumpuk, setiap dekorasi punya gambar dan tetap dimiliki setelah simpan/muat.
- existing_pen_repair_test: kandang yang ditempatkan pada pohon dipindah ke lahan aman, posisi asal dicadangkan, koin/hewan tetap, perbaikan tidak diulang dan hasil tersimpan.
- first_farm_test: 0 kegagalan.
- feature_buttons_audit: 17 halaman dan transaksi kandang/hewan, ketuk gedung, penempatan serta penyimpanan lulus.

Perubahan sudah berada pada proyek komputer. APK belum dibuat ulang. Belum diuji pada HP Android fisik.
