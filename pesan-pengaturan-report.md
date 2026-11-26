# Pesan, Aktivitas, dan Pengaturan — Cheerful Garden

Implementasi 13 November 2026.

- Amplop membuka Pesan; navigasi Pesanan tetap pesanan pelanggan; lonceng membuka Aktivitas Kebun.
- Pesan: Kotak Masuk, Hadiah, Pengumuman; kartu pengirim, tanggal, status baca, indikator belum dibaca, detail dan lampiran bergambar. Status baca dan klaim tersimpan.
- Hadiah harian berbagi transaksi dengan bonus kunjungan Misi. Klaim ganda dicegah, hadiah kedaluwarsa tidak dapat diklaim, lampiran inventaris memeriksa kapasitas sebelum transaksi.
- Aktivitas menggunakan pekerjaan siap yang benar-benar ada dan tombol menuju fitur terkait.
- Pengaturan: Audio, Kamera, Kontrol, Tata Letak, Kelola Aset, Pulihkan, Bahasa, Tentang. Audio, mode kamera, dan bahasa disimpan. Reset tetap memerlukan konfirmasi yang sudah ada.
- Bahasa Indonesia/English diterapkan melalui GardenLanguage pada UI dinamis, tooltip, daftar pilihan, dan label dunia; nama pemain dan ID gameplay tidak diterjemahkan. Katalog exact/phrase/word mendukung teks lama, sehingga terjemahan kalimat lama masih dapat disempurnakan secara editorial.
- Font global Lilita One, Fredoka, Nunito dipertahankan. Perbaikan callback tipografi mencegah akses panel yang sudah dihapus ketika berganti bahasa.

## File utama

scripts/mailbox.gd, mailbox_ui.gd, activities_ui.gd, settings_ui.gd, garden_language.gd; assets/locales/en.json. Integrasi pada main.gd, game_state.gd, cheerful_hud.gd, cheerful_menus.gd, menu_frame.gd, first_farm.gd, colorful_icons.gd, farm_view.gd, typography.gd, project.godot, export_presets.cfg.

## Pengujian

- mail_settings_language_test.gd: PASS, termasuk pemisahan rute, tab, status baca, klaim sekali, reload, kapasitas gudang, bonus harian bersama, audio, kamera, persistensi ID/EN.
- typography_layout_audit.gd: Indonesia 1.343 elemen, 0 overflow; English 1.343 elemen, 0 overflow. Termasuk 8 kategori pengaturan dan Pesan.
- daily_checkin.gd: 0 kegagalan.
- leveled_missions_test.gd: PASS pada mode grafis.
- Preview native: pesan-kotak-masuk.png, pengaturan-audio-baru.png, aktivitas-kebun-baru.png, settings-language-english.png, messages-english.png.

## Batasan

Kotak pesan bersifat lokal. Tidak ada layanan pengumuman, kampanye, atau hadiah jarak jauh yang dikonfigurasi; tidak dibuat event atau versi palsu. Teks yang sudah menyatu dalam ilustrasi tidak dapat diterjemahkan otomatis. Audit English masih menampilkan peringatan shutdown 4 ObjectDB instances, juga muncul pada pengujian sebelumnya; tidak ada crash pada pengujian akhir. APK belum dibangun ulang dalam tugas ini.
