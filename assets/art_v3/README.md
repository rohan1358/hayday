# Kebun Ceria — Farm Art V3

Lima ilustrasi original bergaya *3/4 isometric* untuk game farming Godot. Model dibuat secara prosedural di Blender, dengan warna, sudut kamera, cahaya dan desain material yang mengikuti arah visual `assets/art_v2`. Tidak menggunakan aset Supercell.

## Aset siap pakai

| Nama sprite | Isi | Target lebar tampilan untuk viewport 450 px |
| --- | --- | ---: |
| `chicken_coop.png` | Rumah ayam, pagar menyatu, ayam, tempat pakan dan jerami | 194 px |
| `cow_pen.png` | Rumah sapi, pagar menyatu, sapi dan tempat pakan | 208 px |
| `corn_plot_ready.png` | Petak tanah dan baris jagung matang bertongkol | 164 px |
| `carrot_plot_ready.png` | Petak tanah dan baris wortel matang dengan akar terlihat | 164 px |
| `young_seedlings.png` | Petak tanah dan tanaman yang baru bertunas | 164 px |

Kelima file PNG mempunyai kanal alpha transparan (RGBA). Pagar sudah menjadi bagian dari sprite kandang, sehingga bisa langsung ditempatkan sebagai satu objek. Resolusi hasil ekspor dibatasi **768 px pada sisi terpanjang**, sesuai kebutuhan pratinjau game Android. Tidak perlu mempertahankan tekstur 1024 × 1024 dari Blender di runtime.

## Memasang di Godot

`anchors.json` berisi koordinat `foot_anchor_px` dalam piksel dari kiri atas PNG hasil trim ke **titik tanah di tengah objek**, berguna untuk mengunci posisi di atas petak dunia. `manifest.json` juga berisi ukuran aktual, ukuran hasil trim sebelum resize, alpha check, SHA-256, dan skala anjuran per aset.

Untuk setiap `Sprite2D`, gunakan `centered = false`, lalu set `offset = -Vector2(anchor_x, anchor_y)` pada ukuran PNG **sebelum menerapkan scale**. Atur `position` Sprite2D ke posisi tanah di dunia, kemudian `scale` ke angka `suggested_godot_scale` dari manifest (atau sesuai zoom kamera game). Jika mengurutkan kedalaman, gunakan Y dari posisi tanah sebagai dasar `z_index`/Y-sort, bukan bagian atap tertinggi.

Contoh GDScript untuk sprite dengan anchor di manifest:

```gdscript
var sprite := Sprite2D.new()
sprite.texture = load("res://assets/art_v3/chicken_coop.png")
sprite.centered = false
sprite.offset = -Vector2(anchors["chicken_coop"][0], anchors["chicken_coop"][1])
sprite.scale = Vector2.ONE * 0.25  # atau manifest suggested_godot_scale
sprite.position = ground_position
add_child(sprite)
```

## Regenerasi

Generator dapat dijalankan ulang dari root proyek `HayDay`, dengan Blender 5.2 dan Python yang memiliki Pillow (`py -m pip install pillow` jika belum ada):

```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --background --factory-startup --python assets/art_v3/generate_assets.py
py assets/art_v3/finalize_assets.py
```

`generate_assets.py` hanya membaca fungsi material dan geometri dari `assets/art_v2/generate_assets.py`, tanpa memodifikasinya. Semua output berada di `assets/art_v3`: render mentah dan anchor awal di `_render_source/`, lima PNG hasil trim dan pengecilan, `anchors.json`, `manifest.json`, dan `contact_sheet.jpg` untuk peninjauan. Gambar pratinjau memakai kotak-kotak latar untuk memperjelas transparansi; kotak-kotak **tidak** disimpan ke PNG sprite. Lingkaran merah kecil di contact sheet menandai ground anchor.

Validasi otomatis memeriksa format RGBA, keberadaan piksel transparan dan opak, crop yang tidak terpotong kamera, anchor yang masih ada di dalam PNG, serta hasil tulis-baca file. Gunakan `manifest.json` sebagai referensi dimensi terbaru setelah regenerasi.
