# Perbaikan ukuran karakter, toko, dan jalan

- Pembesaran khusus petani pada kebun awal dihapus. Tinggi render tetangga disesuaikan dengan petani; kostum dan aksesori tetap menggunakan rig yang sama.
- Tombol **PINDAH ASET** membuka alat **PINDAH**, **+ JALAN**, **- HAPUS**, dan **GESER**. Panel misi disembunyikan selama pengaturan agar tidak menutupi kontrol.
- Bunga, semak, dan pagar bawaan kebun awal sekarang memiliki anchor dan posisi tersimpan masing-masing. Rumah, pohon buah, kandang, jalan, serta dekorasi yang dibeli tetap bisa dipindahkan.
- Toko menampilkan kategori **Jalan, Rumput, Bunga, Pohon, Gedung & Toko, Semua Dekorasi** di bagian paling atas. Akses dekorasi tidak lagi ikut terkunci oleh level dapur produksi.
- Rumput taman, pohon apel hias, dan kios hias dapat dibeli dengan koin, dipasang, disimpan, dan dipindahkan. Kios serta pohon hias diberi nama hias agar tidak tertukar dengan bangunan produksi atau kebun buah fungsional.
- Gedung fungsional tetap mengikuti progression. Level yang ditampilkan pada tombol pembelian sesuai validasi backend; kandang ayam pertama tetap terbuka pada Level 3.
- **Satu unit jalan yang dimiliki menghasilkan tepat satu ubin besar**. Renderer tidak lagi membagi satu ruas menjadi kumpulan paver kecil. Ukuran sprite jalan 75 × 44 unit dunia, dibandingkan rumah awal 300 unit lebar; posisi, harga, stok dan save jalan tetap kompatibel.
- Preview saat menyeret jalan memakai satu ubin dengan ukuran sama. Tiga varian tetap dijual memakai koin.

666 pemeriksaan pada suite akses toko, visual jalan, seret jalan, pembelian jalan, state pemain baru dan smoke legacy lulus. Uji UI memeriksa pembelian rumput/pohon, pemasangan, perpindahan bunga bawaan, dan persistensi setelah reload. Screenshot ditinjau pada:

- `outputs/garden-character-scale.png`
- `outputs/garden-shop-categories.png`
- `outputs/garden-tree-shop.png`
- `outputs/garden-one-road-tile.png`

APK pembaruan: `outputs/KebunCeria-Aset-Jalan-Besar.apk`. Memakai preset debug/offline dan signing key existing. Pembaruan tidak memerlukan reset save. Belum diuji pada HP Android fisik.
