# Kebun Ceria — art_v4

Paket lima aset baru isometrik 3/4 dengan warna hangat khas Kebun Ceria, dibuat prosedural di Blender. Karya original; **tidak menyalin aset Supercell**. Berkas siap diimpor ke Godot sebagai sprite transparan.

## Aset

| File PNG | Desain | Perkiraan lebar pada viewport 450 px |
| --- | --- | ---: |
| `market_cart.png` | Gerobak pasar dari kayu, dua roda berjari-jari, atap kain bergaris, nampan berisi buah dan sayur | 206 px |
| `fence_straight.png` | Pagar kayu lurus tiga tiang dua rel dengan bunga kecil | 140 px |
| `fence_corner.png` | Pagar dua sisi berbentuk L dengan tiang di titik sudut | 129 px |
| `flowering_hedge.png` | Semak tebal hijau dengan bunga pastel | 131 px |
| `stone_path_tile.png` | Susunan batu pijakan membentuk petak jalan dengan sela transparan | 146 px |

Kelima file menggunakan RGBA antialias dan transparansi asli. Texture dibatasi maksimal **768 px pada sisi terpanjang** untuk kebutuhan Android. Ukuran tepat, pivot, byte, hash SHA-256, dan skala per file disimpan dalam `manifest.json`.

## Pivot dan pemasangan Godot

`anchors.json` menyimpan `foot_anchor_px = [x, y]` dalam koordinat piksel **dari kiri atas PNG hasil trim dan resize** menuju titik tanah pada objek. Gunakan anchor ini untuk menempatkan gerobak/dekorasi ke tile posisi tanah, misalnya:

```gdscript
var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art_v4/anchors.json"))
var sprite := Sprite2D.new()
sprite.texture = load("res://assets/art_v4/market_cart.png")
sprite.centered = false
sprite.offset = -Vector2(data["market_cart"][0], data["market_cart"][1])
sprite.scale = Vector2.ONE * 0.2861 # contoh 206 / 720; lihat manifest untuk angka yang presisi
sprite.position = map_ground_position
add_child(sprite)
```

Untuk pagar sudut, anchor berada pada pangkal tiang sudut dunia lokal `(0, 0, 0.05)`. Pagar lurus berpatokan pada tiang tengah; dekorasi semak/jalan memakai titik tengah permukaan tanah. Karena dipotret dengan proyeksi isometrik, jalur dan pagar harus diletakkan berdasarkan grid permainan, lalu uji visual sambungan antarubin di Godot. `contact_sheet.jpg` menampilkan lingkaran merah kecil untuk mengecek anchor setiap aset.

## Pipeline yang dapat direproduksi

Blender 5.2 atau 5.2.1 dan Python yang memiliki Pillow diperlukan. Di folder project `HayDay`, jalankan:

```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --background --factory-startup --python assets/art_v4/generate_assets.py
py assets/art_v4/finalize_assets.py
```

`generate_assets.py` membaca fungsi primitive dan palet `assets/art_v2/generate_assets.py` secara **read-only**, tanpa membuat bytecode pada folder sumber. Render 1024×1024 tersimpan di `art_v4/_render_source/`. `finalize_assets.py` memotong margin kosong, mengecilkan texture dengan LANCZOS, menghitung ulang pivot secara presisi, dan memvalidasi kanal RGBA, alpha 0 dan 255, piksel antialias, tepi yang tidak terpotong, serta round-trip PNG. Hasilnya adalah lima sprite di root `art_v4/`, `anchors.json`, `manifest.json`, dan `contact_sheet.jpg`. Background kotak-kotak hanya ada pada contact sheet, bukan pada PNG.

**Catatan:** Baru berupa aset visual. Pemasangan, positioning, dan import Godot dilakukan pada tahap integrasi game.
