# Musik dan suara Cheerful Garden

Musik orisinal Meadow Morning: 48 detik, 80 BPM, petikan hangat dengan melodi lembut dan bass ringan; loop seamless tanpa rekaman unduhan. Suasana alam burung/angin 24 detik, hujan dan angin 8 detik mengikuti cuaca. Seluruh aset baru dibuat secara prosedural dengan Python standar (work/build_garden_audio.py), bukan mengambil musik pihak ketiga.

20 efek: klik, buka/tutup, menanam, menyiram, pupuk, panen, koin, pembangunan, perpindahan, kesalahan, naik level, misi, pakan, koleksi hasil, bersih-bersih, mengelus, memerah, langkah, mengumpulkan bahan. Efek terhubung ke tombol dinamis, feedback dunia, pekerjaan karakter, transaksi koin dan notifikasi hasil. Rekaman ayam/sapi/babi/kambing serta tebang pohon yang sudah ada tetap digunakan.

Tiga bus: Musik, Efek suara, Suasana alam. Buka Pengaturan melalui ikon roda gigi untuk slider volume dan MATIKAN SEMUA SUARA. Konfigurasi disimpan di user://garden_audio.cfg, terpisah dari progres kebun. Maksimal delapan efek bersamaan, debounce efek sejenis, cache stream dan jeda musik/suasana ketika aplikasi Android masuk background.

Folder aset: hayday/assets/audio/garden/ (24 WAV, sekitar 4.2 MB). Pengaturan dan penghubung: hayday/scripts/garden_audio.gd.

Pengujian garden_audio_test berhasil: stream musik/suasana valid dan loop aktif, 20 efek valid, delapan voice maksimum, bus suara hewan, pengikatan tombol baru, slider/mute, konfigurasi persisten dan pergantian hujan/angin. first_farm_test dan feature_buttons_audit juga lulus. Belum diuji pendengaran pada HP Android fisik.

APK: CheerfulGarden-Musik-Suara.apk. Preset debug tanpa plugin iklan native tetap sama seperti versi sebelumnya.
