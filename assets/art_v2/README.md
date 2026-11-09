# Kebun Ceria — farm sprites v2

Enam aset **orisinal** bergaya 3/4 ortografik untuk game pertanian Kebun Ceria. Bentuk dan material dirancang secara prosedural di Blender; tidak mengambil sprite atau komposisi aset dari Hay Day / Supercell. Warna hangat, bentuk sederhana dan kontur jelas diprioritaskan untuk ukuran tampilan ponsel.

| File PNG | Fungsi | Resolusi | Ground anchor (x, y) | Lebar saran untuk viewport 450 px |
| --- | --- | --- | --- | --- |
| `kitchen_cottage.png` | Rumah/dapur | 1024×1024 | (512, 768) | 160 px |
| `village_barn.png` | Gudang | 1024×1024 | (512, 781) | 165 px |
| `apple_tree.png` | Pohon apel | 1024×1024 | (512, 816) | 145 px |
| `soil_plot_empty.png` | Petak kosong | 1024×1024 | (512, 586) | 158 px |
| `wheat_plot_ready.png` | Gandum siap panen | 1024×1024 | (512, 663) | 158 px |
| `flower_garden.png` | Dekorasi taman | 1024×1024 | (512, 611) | 154 px |

Semua PNG menggunakan **RGBA dengan background alpha transparan**. File `contact_sheet.jpg` hanya lembar pratinjau dengan latar kotak-kotak agar transparansi dapat diperiksa. `anchors.json` menyimpan koordinat anchor untuk dipakai oleh renderer. `manifest.json` menyimpan checksum, bounding box, anchor dan saran ukuran untuk tiap sprite.

## Kontrak integrasi Godot 4

Posisi objek disimpan sebagai **posisi tanah/foot anchor** di layar. Gunakan `centered = false`, kemudian offset negatif dari koordinat anchor PNG. Skala berfungsi sebagai faktor zoom sprite (ukuran yang terlihat = 1024 × `scale`). Sebagai contoh, menempatkan rumah di titik tanah `(230, 420)`:

```gdscript
var home := Sprite2D.new()
home.texture = load("res://assets/art_v2/kitchen_cottage.png")
home.centered = false
home.offset = Vector2(-512, -768)
home.scale = Vector2.ONE * (160.0 / 1024.0)
home.position = Vector2(230, 420)
add_child(home)
```

Nilai `home.position` mewakili *ground anchor*. Untuk posisi tile pada dunia isometrik, konversikan koordinat tile ke layar terlebih dahulu lalu pakai hasilnya sebagai `position`. Jika ingin Y-sorting, aktifkan `y_sort_enabled` pada parent dan gunakan titik pijakan sebagai posisi item. Untuk pohon, gudang, dan petak tanaman, ganti tekstur, anchor, dan skala mengikuti tabel. Semua sprite memakai proyeksi kamera yang sama.

## Regenerasi dan pemeriksaan

Dalam PowerShell, jalankan (tidak mengubah skrip atau scene Godot):

```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --background --factory-startup --python 'assets\art_v2\generate_assets.py'
py 'assets\art_v2\finalize_assets.py'
```

Tahap pertama menghasilkan PNG dan `anchors.json`; tahap kedua memverifikasi **format, ukuran, rentang alpha, bounding box, dan anchor** seluruh sprite, kemudian menghasilkan `manifest.json` dan `contact_sheet.jpg`. Generator diuji di Blender 5.2.1. Semua output tetap berada di direktori `assets/art_v2/`.
