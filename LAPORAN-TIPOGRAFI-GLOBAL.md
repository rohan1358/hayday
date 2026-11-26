# Tipografi Global — Cheerful Garden

Sistem tipografi sudah diterapkan langsung pada proyek Godot, termasuk UI runtime dan teks canvas dunia kebun. Warna panel, ilustrasi, aset karakter/3D, navigasi dan transaksi gameplay dipertahankan.

## Font dan lisensi

| Penggunaan | Font |
| --- | --- |
| Judul menu/popup dan heading besar | Lilita One, outline cokelat dan shadow lembut |
| Heading, tombol, nama item/bangunan, harga dan angka penting | Fredoka Bold 700 |
| Tab, kategori, subtitle dan label | Fredoka SemiBold 600 |
| Deskripsi, tutorial, tooltip dan keterangan | Nunito SemiBold 600 |
| Fallback centang/diamond/play dan simbol Unicode | Noto Sans Symbols 2; bukan font teks utama |

File asli diunduh tanpa modifikasi dari repositori resmi Google Fonts: [Lilita One](https://github.com/google/fonts/tree/main/ofl/lilitaone), [Fredoka](https://github.com/google/fonts/tree/main/ofl/fredoka), [Nunito](https://github.com/google/fonts/tree/main/ofl/nunito), [simbol](https://github.com/google/fonts/tree/main/ofl/notosanssymbols2). Lisensi SIL OFL 1.1 lengkap berada di masing-masing folder font. `assets/fonts/SOURCES.json` berisi checksum SHA-256 dan sumber. Font utama sekitar 464 KB; termasuk fallback simbol total sekitar 1,7 MB. Preset ekspor menyertakan lisensi font.

Fredoka dan Nunito memakai FontVariation dengan koordinat OpenType asli. Pengujian membaca koordinat TextServer RID (wght=700/600), bukan hanya nama file atau nama family dasar Light/ExtraLight.

## File yang ditambah/diubah

- `hayday/assets/fonts/`: font asli, OFL, metadata sumber, checksum, README, empat reusable FontVariation di `styles/`, dan `garden_theme.tres`.
- `hayday/scripts/typography.gd`: autoload tipografi; role semantik, penerapan pada control runtime, pemilihan Theme variation, penyesuaian ukuran/wrapping melalui event layout. Tidak melakukan pemindaian UI setiap frame.
- `hayday/project.godot`: Theme proyek dan autoload global.
- `hayday/export_presets.cfg`: menyertakan `assets/fonts/*/OFL.txt` saat ekspor.
- `hayday/scripts/main.gd`: factory label/button memakai role terpusat; tinggi callout, notifikasi dan bahan resep menyesuaikan teks; ukuran scroll mempertimbangkan header toko.
- `hayday/scripts/farm_view.gd`: pengukuran dan penggambaran teks dunia memakai Fredoka Bold yang sama, menggantikan ThemeDB.fallback_font.
- `hayday/scripts/game_text.gd`: nilai HUD besar disingkat agar tidak menimpa tombol tambah; angka lengkap tetap tersedia lewat tooltip. Nilai ekonomi tidak berubah.
- `hayday/scripts/garden_shop_ui.gd`: tab Rekomendasi dilebarkan supaya nama lengkap tetap terbaca.
- `hayday/scripts/level_up_popup.gd`: label menyimpan extent untuk wrapping akurat; catatan permata dipersingkat tanpa mengubah arti.
- `hayday/scripts/wardrobe_editor.gd`: judul memakai role Lilita One.
- `hayday/tests/typography_test.gd`, `typography_layout_audit.gd`, `typography_gallery.gd`: audit font, glyph, bobot, layout dan render.
- `hayday/tests/feature_buttons_audit.gd`: memilih pembelian melalui nama tombol kartu toko yang baru.

Theme menyediakan GardenTitle, GardenHeading, GardenSubtitle, GardenBody, GardenPrice, GardenButton dan GardenTab. Default juga mencakup RichTextLabel, LineEdit, TextEdit, TooltipLabel, PopupMenu, ItemList, Tree dan ProgressBar. UI baru mewarisi Theme dan diproses saat ditambahkan ke tree; factory utama menyimpan ukuran yang dimaksud agar minimum-size teks tidak memperlebar panel.

## Layout dan responsivitas

Proyek mempertahankan canvas portrait 720 lebar dan scaling Godot yang sudah ada. Teks kecil memiliki batas minimum 16 unit; fitting dibatasi sekitar 15% sebelum wrapping. Panel keterangan, toast dan resep bertambah tinggi sesuai kebutuhan. Kategori toko tidak diperkecil berlebihan. Seluruh callback/tombol tetap aktif; halaman panjang tetap dapat digulir.

## Hasil pengujian

- Audit font: lulus pada 23 halaman, popup naik level dan control dinamis. Seluruh font control yang diperiksa menunjuk ke resource di `res://assets/fonts/`; tidak ditemukan resource font lama/missing font pada UI game yang diuji.
- Bobot: Fredoka 700/600 dan Nunito 600 terverifikasi melalui TextServer. Simbol ✓, ◆ dan ▶ tersedia melalui fallback yang dibundel.
- Audit layout final: **1.088 elemen, 0 masalah terdeteksi**; mencakup label, tombol, popup naik level, editor karakter dan notifikasi panjang. Pemeriksaan mengukur lebar teks, wrapping, jumlah baris terlihat dan ruang isi tombol.
- Render native Godot: 23 halaman, enam kategori toko, editor karakter dan popup. Variasi portrait diuji pada 360×640, 390×844 dan 720×1280; total 42 screenshot sesudah. Produksi dirender ulang setelah perbaikan tinggi bahan resep terakhir.
- Regresi: typography_test, feature_buttons_audit, garden_shop_test, ranch_presentation_test, truck_order_test dan first_farm_test semuanya exit 0. Pembelian/stok/save-load, kandang/hewan, pakan/telur, pengiriman/hadiah sekali serta FTUE tetap lulus.
- Tidak ditemukan SCRIPT ERROR/ERROR baru pada log validasi akhir.

Log utama: `work/typography-fonts-verified.log`, `work/typography-layout-release.log`, `work/typography-gallery-release.log`, `work/typography-production-final.log`, dan `work/font-final-*.log`.

## Bukti visual

Buka [perbandingan sebelum/sesudah](TIPOGRAFI-PERBANDINGAN.html). Screenshot lengkap berada di `outputs/typography-before/` dan `outputs/typography-after/`.

## Batasan yang masih ada

- Belum diuji pada perangkat Android fisik. APK belum dibangun ulang dalam tugas ini.
- Beberapa fixture pengujian masih menampilkan peringatan cleanup empat ObjectDB saat keluar. Peringatan serupa sudah muncul pada uji peternakan sebelum perubahan font; tidak ada kegagalan fitur yang terdeteksi, dan cleanup tersebut belum ditangani dalam tugas tipografi.
- Tulisan yang menyatu di logo/gambar/video serta aset editor/sample pihak ketiga tidak diganti. Ini mempertahankan ilustrasi dan aset sesuai permintaan; teks UI game yang dirender menggunakan sistem baru.
- Audit mencakup kondisi dan resolusi yang diuji, bukan bukti bahwa setiap kemungkinan isi save atau terjemahan masa depan pasti bebas overflow.
