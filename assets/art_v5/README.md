# Kebun Ceria — Original Art V5

Lima dekorasi pertanian orisinal bergaya isometrik 3/4, dibuat secara prosedural di Blender 5.2 dengan kamera ortografik, tiga softbox hangat, dan palet pastel yang sesuai dengan koleksi `art_v2`–`art_v4`.

| Sprite | Deskripsi |
| --- | --- |
| `wooden_crates.png` | Tiga peti kayu bertumpuk, hasil panen dan karung goni |
| `hay_stack.png` | Tiga bal jerami berikat tali dan serat tersebar |
| `flower_patch.png` | Taman bunga kecil berwarna-warni di atas tanah oval |
| `decorative_pond.png` | Kolam turkuois, batu tepi, teratai, riak dan gelagah |
| `rustic_lamp.png` | Tiang kayu, lentera kuningan bercahaya dan alas batu |

## Isi paket

- Lima PNG transparan RGBA, crop ber-padding, sisi terpanjang maksimal 768 piksel.
- `anchors.json`: koordinat `[x, y]` pada PNG **setelah crop** menuju titik tanah sprite.
- `manifest.json`: ukuran, skala contoh untuk viewport 450 px, checksum SHA-256 dan statistik alpha.
- `contact_sheet.jpg`: tampilan seluruh aset pada checkerboard; titik merah menunjukkan anchor tanah.
- `generate_assets.py`: membuat render sumber 1024×1024 ke `_render_source/`.
- `finalize_assets.py`: validasi dan ekspor PNG final beserta metadata/lembar pratinjau.

## Memakai di Godot 4

Gunakan `Sprite2D` dengan `centered = false`, `offset = -Vector2(anchor_x, anchor_y)` dan `position` pada proyeksi titik tanah item. Sesuaikan `scale` dengan properti `suggested_godot_scale` di `manifest.json` atau ukuran tile proyek. Pivot semua aset adalah titik tanah dunia `(0, 0, 0.05)`, sehingga objek bisa diurutkan secara Y pada area isometrik.

## Regenerasi (PowerShell, dari root HayDay)

```powershell
& "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" --background --factory-startup --python assets/art_v5/generate_assets.py
py assets/art_v5/finalize_assets.py
```

Memerlukan Blender 5.2 dan Pillow pada Python. Generator hanya membaca primitive `art_v2` tanpa membuat cache Python di sana. Semua output berada di `assets/art_v5/`; tidak ada modifikasi terhadap scene, script, atau folder art sebelumnya. Tidak menggunakan karya seni Supercell.
