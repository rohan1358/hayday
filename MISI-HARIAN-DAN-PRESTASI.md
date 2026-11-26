# Misi — Harian dan Prestasi

Ikon Misi memakai Fredoka Bold 18 dengan area caption lebih tinggi, sehingga nama dan hitungan misi terbaca. Jumlah tugas pada ikon mengikuti tugas harian yang tersedia; tutorial tetap memakai hitungan tiga langkah. Judul halaman menjadi Misi.

Halaman baru memakai tab Harian/Prestasi, kartu krem berbingkai, ilustrasi, progres hijau, jumlah progres, hadiah koin/XP/permata dan tombol klaim. Tab Harian menampilkan hitung mundur reset tengah malam yang mengikuti tanggal lokal sistem game, serta bonus kunjungan harian. Prestasi memakai pencapaian seumur hidup dan callback klaim asli.

Misi harian menyesuaikan level: panen dari Lv1, pesanan dari Lv3, produksi dari Lv5. Target dan hadiah naik berdasarkan level dengan batas ekonomi yang wajar. Definisi tugas yang sudah mulai atau sudah diklaim disimpan sampai reset agar progres/hadiah tidak berubah di tengah pengerjaan. Saat naik level, tugas yang belum dimulai diperbarui dan jenis tugas yang baru terbuka ditambahkan. Pada reset hari berikutnya seluruh tugas memakai level terbaru. Tugas lama dari save terdahulu yang sudah mempunyai progres tetap dipertahankan meskipun berasal dari aturan level lama.

Data baru daily_specs disimpan bersama daily_progress dan daily_claimed; klaim, badge dan pemuatan save membaca definisi tugas yang sama. Save lama tanpa daily_specs dimigrasikan tanpa menghapus progres. Klaim ganda dan klaim ulang setelah reload ditolak. Misi perjalanan level tetap berada di menu Hadiah; upgrade tetap tersedia melalui rumah/menu upgrade.

File utama: scripts/missions_menu.gd, scripts/game_state.gd, scripts/main.gd, scripts/cheerful_hud.gd, scripts/menu_frame.gd. Pengujian: tests/leveled_missions_test.gd; fixture tests/achievements.gd dan daily_checkin.gd dibuat eksplisit sebagai pertanian legacy agar memakai stok awal dan dompet yang diharapkan oleh pengujian tersebut.

Hasil: uji gerbang level, skala tugas/hadiah, progres berjalan, rollover harian, migrasi, save/load, klaim sekali, kedua tab dan font ikon lulus. Audit layout 1.066 elemen: 0 masalah. Audit 17 halaman, achievements, daily_checkin, serta first_farm_test lulus. Log: work/leveled-missions-verified.log, work/missions-layout-audit.log, work/missions-achievements.log, work/missions-daily_checkin.log, work/missions-first_farm_test.log, work/missions-compile.log.

Screenshot: misi-harian-baru.png dan misi-prestasi-baru.png. APK belum diperbarui; belum diuji pada perangkat Android fisik.
