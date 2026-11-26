# Skala kandang dan ternak

Patokan ukuran dunia: karakter berpakaian sekitar 120 unit tinggi, rumah 300 unit lebar. Lebar tubuh ayam 32, sapi 128, babi 90, kambing 84. Lebar kandang dasar ayam 360, sapi 560, babi 460, kambing 480 termasuk halaman berpagar. Penggambaran aset, posisi pijak animasi, area pemilihan, dan collision menggunakan ukuran terpusat di ranch_state.gd. Upgrade kandang membesarkan lahan sesuai tier, tidak membesarkan tubuh hewan.

Sapi naik dari lebar 42 menjadi 128; ayam dari 20/30 menjadi 32, babi dan kambing dari 34 menjadi 90/84. Margin tepi dan jarak antarhewan menyesuaikan tubuh baru, agar hewan tidak berdiri terlalu dekat pagar atau bertumpuk.

Tes ranch_proportion_test lulus: kesamaan ukuran render dan collision, tier, spawn aman, delapan agen hidup dan perbandingan spesies. ranch_system_test, feature_buttons_audit dan first_farm_test juga lulus. Visual skala bersama rumah dan karakter diperiksa pada skala-kandang-hewan-rumah.png. Data kepemilikan dan posisi tersimpan tidak dipindahkan otomatis; pemain tetap dapat menata ulang kandang lewat PINDAH ASET bila ruang lama sempit.

APK belum dibuat ulang pada perubahan ukuran ini.
