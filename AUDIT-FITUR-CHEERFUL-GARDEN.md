# Audit fitur Cheerful Garden
Tanggal: 12 November 2026.

## Perbaikan
- Kandang sapi tidak otomatis diisi hewan saat refresh. Kandang dibeli 200 koin; sapi dibeli terpisah. Kandang kosong tidak bisa diberi pakan atau menghasilkan susu.
- Gudang muncul konsisten di kebun baru. Gudang, rumah/dapur dan kandang sapi dapat diketuk untuk membuka fitur masing-masing.
- Bangunan produksi/kandang yang benar-benar dibeli ikut digambar dan dapat dipindahkan tanpa mengganti latar dunia pada level 5.
- Bahan upgrade kembali terlihat dan bisa diketuk setelah tutorial; navigasi memperhitungkan rintangannya.
- Tes lama disesuaikan: skenario gudang/bibit/stroberi biasa menggunakan profil bebas tutorial; tes musim menggunakan paket figur terbaru, dan pemeriksaan kamera prototipe 3D dihapus karena game memakai kamera 2D.

## Pengujian berhasil
- Tes gabungan smoke: TOTAL FAILURES 0.
- feature_buttons_audit: 17 halaman (toko, gedung, gudang, upgrade, ternak, ayam, pakan, produksi, pesanan, misi, koleksi, pengaturan, jalan, dekorasi, rumput, bunga, pohon), tombol pembelian kandang aktual, pembelian sapi, ketukan gudang/rumah/kandang, editabilitas, antrean pengumpulan bahan, simpan/muat.
- first_farm_test dan first_farm_layout_test: tutorial, penanaman/panen, transaksi, hadiah, ayam/pakan/telur, batas layar sentuh dan pembatalan.
- progression_consistency_test: dunia konsisten level 1–6, jendela naik level, kepemilikan kandang.
- building_upgrade_test: rumah/dapur/gudang, bahan/misi, kapasitas, klaim dan persistensi.
- inventory_ui_smoke: stok pesanan, penjualan stok bebas, hasil ternak, navigasi gudang; TOTAL FAILURES 0.
- ranch_system_test, hybrid_system (60 pemeriksaan), garden_access_test, roads_purchase_test, road_move_test, isometric_roads_test, delivery_layout_test: 0 kegagalan.
- seed_picker_test, crystal_progression_test, seasonal_test, seasonal_pack_test, rewarded_speedup_test, cheerful_design_test: berhasil.

## Batas pengujian
Pengujian melalui Godot di komputer; belum diuji pada HP Android fisik. Semua halaman utama dan alur di atas diperiksa, bukan jaminan setiap kombinasi kondisi/perangkat telah dicoba. Logika percepatan berhadiah diuji dengan simulasi; iklan jaringan nyata tidak diverifikasi dan preset APK debug masih tanpa plugin AdMob native. APK tidak dibuat ulang pada audit ini.

Log tersedia di folder work: full-audit-smoke.log, audit-*.log, recheck-*.log, verified-audit-*.log, inventory-audit-fixed.log, final-audit-crystal_progression_test.log dan audit-world-verified.log. Hasil awal yang gagal karena asumsi tes lama tetap disimpan terpisah dari log verifikasi ulang.
