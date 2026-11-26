# Menu Hadiah per level

Nama menu dan tombol kebun diubah dari Hadiah Pemula menjadi Hadiah. Bingkai/papan judul memakai komponen menu yang sudah ada. Isi memakai banner, tugas dengan progress bar dan tanda selesai, ringkasan koin/XP, tombol Ambil Hadiah, dan Kembali ke Kebun.

Selama tutorial aktif, tiga tugas asli (tanam gandum, panen gandum, penjualan pertama) tetap berlaku. 50 koin dan 30 XP diberikan oleh transaksi penjualan pertama; klaim hanya memberi tiga bibit gandum. Menu menjelaskan ini supaya tidak menampilkan pemberian ganda.

Setelah tutorial, menu memakai LevelJourney yang sudah ada: target dan nilai hadiah mengikuti level. Contoh Lv6: panen 15, kirim 1, produksi 3; hadiah 90 koin dan 28 XP. Lv7: panen 17, kirim 1, produksi 3; hadiah 100 koin dan 31 XP. Halaman otomatis berpindah ke level baru ketika pemain naik level. Pilihan level memungkinkan tugas/hadiah lama tetap diselesaikan tanpa hilang. Progres tampil langsung, dan titik merah Hadiah menandai hadiah level yang siap diambil.

Tidak menambah pembayaran hadiah baru di luar transaksi tutorial dan LevelJourney. Status klaim memakai state tersimpan yang sudah ada, sehingga klik ganda dan muat ulang tidak menggandakan hadiah. Batas/formula ekonomi level yang sudah ada dipertahankan.

File: scripts/reward_menu.gd; scripts/cheerful_menus.gd; scripts/cheerful_hud.gd; scripts/main.gd; scripts/menu_frame.gd; tests/reward_menu_test.gd.

Uji native reward_menu_test lulus: nama menu, progres langsung, klaim sekali, save/load, berpindah Lv6→Lv7, memilih kembali hadiah lama, serta tutorial tanpa pembayaran ganda. Regresi level_notification_test (100 level), first_farm_test dan menu_frame_test (26 menu) juga lulus. Log: work/reward-menu-final.log, work/reward-menu-regression.log, work/reward-first_farm_test.log, work/reward-menu_frame_test.log. Screenshot: outputs/hadiah-level-6.png dan outputs/hadiah-level-7.png.

APK belum diperbarui.
