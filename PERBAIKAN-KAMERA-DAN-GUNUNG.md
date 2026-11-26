# Aset terlihat mengambang di gunung

Penyebab: panorama gunung digambar dengan koordinat layar di dalam painter dunia kebun. Aset ikut transform kamera, sedangkan gunung tetap berada di tempat yang sama, sehingga saat pan/zoom keduanya bertumpuk.

Perbaikan:
- `scripts/first_farm_world.gd`: panorama tetap dihapus dari painter lahan; tanah dan aset seluruhnya memakai koordinat dunia.
- `scripts/header_landscape.gd`: panorama opaque dipisahkan ke latar HUD.
- `scripts/cheerful_hud.gd`: header berada di atas layer dunia, selebar viewport termasuk rasio layar yang lebih lebar. Panorama tidak menerima input.
- `scripts/farm_view.gd`: minimum zoom memperhitungkan ukuran viewport dan batas tanah untuk rasio portrait sangat tinggi; kontrol pan/zoom tetap berfungsi.
- `tests/horizon_camera_test.gd`: pengujian transform, batas kamera dan piksel header.

Hasil: uji native Godot lulus. Piksel area header identik sebelum/sesudah zoom maksimum, sementara rumah/jalan bergeser sesuai kamera. Pengujian pan ke semua batas dan min/max zoom pada tiga ukuran viewport lulus. Layout tersimpan tidak berubah. FTUE dan audit fitur juga diuji ulang. Screenshot `kamera-normal.png` dan `kamera-zoom-atas.png`; log `work/horizon-camera-test.log`, `work/camera-first_farm_test.log`, `work/camera-feature_buttons_audit.log`.

APK belum dibangun ulang.
