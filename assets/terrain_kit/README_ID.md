# Cheerful Garden — Paket aset medan modular

Paket ini berisi aset sumber dan komponen Godot untuk menyusun ulang peta dari
potongan terpisah. Paket ini belum mengganti renderer peta utama secara otomatis.
Peta referensi besar tetap digunakan sebagai acuan komposisi, bukan tekstur untuk
dibentangkan di seluruh lahan.

## Isi

- 9 material PNG baru, masing-masing 1254 × 1254 piksel: rumput semi, rumput panas,
  tanah gugur, salju, tanah kebun, air sungai, batu tebing, paving, dan papan kayu.
- 1 latar langit/pegunungan baru yang hanya digunakan untuk pemandangan jauh.
- 71 definisi sprite dari aset proyek: pohon empat musim; 12 pohon buah dalam
  keadaan berbuah dan tanpa buah; 14 tanaman dan 2 tahap tunas; bunga, batu,
  petak, pagar, lampu, rumah, gudang, toko, kendaraan dan bangunan produksi.
- PNG sumber sprite dan resource AtlasTexture `.tres` dengan region dan anchor.
- Pembentuk geometri tebing, sungai melengkung, jalan, jembatan dan air terjun.
- Shader aliran air serta pembuat Polygon2D air beranimasi.
- Scene preview material yang dapat digeser dan di-zoom sampai 2×.
- `catalog.json` berisi ukuran asli, region, anchor dan anggaran pembesaran.
- `generation.json` berisi prompt dan asal aset baru dari built-in imagegen.

## Pemakaian di Godot

Salin direktori `assets`, `scripts`, dan `scenes` dalam ZIP ke root proyek Godot 4.
Buka `res://scenes/TerrainKitPreview.tscn`, lalu jalankan scene tersebut. Roda mouse
mengubah zoom dan drag kiri menggeser tampilan. Godot akan mengimpor PNG otomatis.

Untuk sprite, resource berada di `res://assets/terrain_kit/props/<id>.tres`.
`metadata/ground_anchor` menggunakan koordinat relatif terhadap region sprite.
Gunakan anchor tersebut saat menempatkan kaki bangunan atau akar pohon di tanah.
Jangan memasang gambar atap dan akar dengan koordinat pusat yang sama.

Contoh menggambar medan melalui `_draw()` sebuah Node2D:

```gdscript
const KIT = preload("res://scripts/terrain_asset_kit.gd")

func _draw():
    KIT.rectangle(self, Rect2(0, 0, 1600, 1200), "spring_grass")
    KIT.river(self, PackedVector2Array([
        Vector2(100, 200), Vector2(400, 450), Vector2(1000, 300)
    ]), 100.0)
    KIT.bridge(self, Vector2(450, 350), Vector2(500, 550))
```

Jalan dan tebing memakai titik kontrol seperti sungai. Kurva disampel dan dibuat
menjadi poligon, sehingga bentuknya tidak harus mengikuti petak persegi. Gunakan
geometri jalur yang sama untuk collision, navigasi dan aturan penempatan.

## Ukuran dan ketajaman

Satu material 1254 piksel digunakan untuk 256 unit dunia: sekitar 4,90 piksel
sumber per unit. Pada zoom 2× masih ada sekitar 2,45 piksel sumber per piksel
layar, sebelum faktor skala viewport. Perhitungkan juga pengaturan stretch HP.

Jangan membentangkan satu material ke seluruh dunia 4320 × 7680. Ulangi material
secara lokal. Helper memakai pengulangan mirror untuk menghindari garis sambungan
keras; pola pengulangan masih dapat terlihat dan bisa divariasikan dengan ground
cover, tint lokal dan dekorasi. Tidak ada klaim bahwa setiap sisi PNG hasil
generasi identik secara matematis.

Untuk sprite, ikuti `recommended_width` dan `max_zoom_at_native_resolution` pada
katalog. Aset atlas mempunyai resolusi per region, bukan resolusi seluruh sheet.
Menambah ukuran PNG tanpa detail baru tidak menaikkan ketajaman sesungguhnya.

Untuk mobile, gunakan mipmap/filter linear pada material dan muat material per
kawasan/chunk. Texture repeat, geometri dan shader ditempatkan di dunia game;
HUD dan tombol tetap pada lapisan UI. Efek air tidak mengubah collision daratan.

## Pengujian dan batas paket

Katalog memeriksa material minimal 1024 piksel dan keberadaan setiap sprite.
Preview Godot memeriksa rendering material, geometri sungai/jembatan dan zoom 2×.
Screenshot ada dalam direktori `previews` ZIP. Renderer peta utama dan collision
per kawasan masih perlu dirakit memakai aset ini sebelum tampilan game sepenuhnya
memakai medan modular. Gedung dan UI yang sudah bekerja tidak diganti oleh paket.
