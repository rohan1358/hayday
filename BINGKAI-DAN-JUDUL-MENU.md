# Bingkai dan judul menu

Seluruh 24 menu utama/submenu memakai komponen `hayday/scripts/menu_frame.gd`: panel krem dengan bingkai emas berlapis dan shadow, papan kayu, dekorasi daun, ikon sesuai menu, judul Lilita One putih dengan outline cokelat, dan tombol tutup merah. Toko mempertahankan atap merah-krem di belakang papan judul. Isi menu, navigasi dan transaksi tidak diganti.

`main.gd` memasang komponen bersama dan menyediakan ruang header/scroll yang sama pada semua menu. Header khusus lama pada `ranch_presentation.gd` dan `garden_shop_ui.gd` sudah dihapus agar tidak ada gaya yang berbeda. Tidak menambah aset eksternal; bingkai/papan/daun dirender Godot dan ikon memakai aset game yang sudah ada.

Pengujian: `menu_frame_test.gd` lulus untuk 24 menu (frame, ikon, font Lilita One, outline, judul muat, tombol tutup kembali ke kebun); audit layout memeriksa 1.093 elemen dengan 0 masalah; audit fitur 17 halaman lulus. Render portrait tersedia di `outputs/typography-after/`, termasuk 360×640, 390×844, dan 720×1280. Log: `work/menu-frame-test.log`, `work/menu-frame-layout.log`, `work/menu-frame-feature-audit.log`, `work/menu-frame-visual-final.log`.

Contoh: menu-baru-gudang.png, menu-baru-toko.png, menu-baru-pesanan.png, menu-baru-koleksi.png. APK belum dibangun ulang.
