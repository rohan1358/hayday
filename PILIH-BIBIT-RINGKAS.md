# Jendela pilih bibit ringkas

`hybrid/seed_picker.gd` membuat popup terpusat maksimum 620×650 unit virtual (tutorial maksimum 470 tinggi), sekitar setengah tinggi layar portrait. Daftar kartu tiga kolom memiliki scroll sendiri; stok, waktu tumbuh, tanda pilihan, status level terkunci, jumlah petak dan tombol Tanam tersedia. Pembelian satu bibit tetap tersedia untuk stok habis. Tutorial hanya menampilkan gandum gratis dan tetap membutuhkan pemilihan bibit sebelum Tanam aktif.

Jumlah petak dibatasi petak kosong dan stok tersedia; target pertama adalah petak yang diketuk, disusul petak kosong terdekat. Perintah menggunakan antrean pekerjaan yang sudah ada. Bibit dikurangi saat pekerjaan benar-benar menanam, bukan saat popup dikonfirmasi. Antrean yang sedang dipertahankan tidak memakai target/bibit ganda. Konfirmasi mengecek ulang kondisi target. Lapisan redup menahan input kebun di belakang popup; joystick dilepas saat membuka popup. Menu kontrol lain kembali memakai ukuran normal.

File: `scripts/hybrid/seed_picker.gd`, `scripts/hybrid/control_ui.gd`, `tests/compact_seed_picker_test.gd`.

Uji native lulus: ukuran ringkas, pilih gandum, tambah jumlah menjadi dua, dua target unik dan penanaman nyata, pengurangan stok tepat, bibit kosong, pembelian satu jagung, bibit kristal terkunci di Lv6, tutup popup, menu kontrol normal, serta tutorial gandum gratis. FTUE regression juga lulus. Log: `work/compact-seed-picker-final.log`, `work/seed-picker-ftue.log`. Screenshot: `outputs/pilih-bibit-ringkas.png`.

APK belum diperbarui.
