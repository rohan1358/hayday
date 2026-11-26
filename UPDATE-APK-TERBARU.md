# Pembaruan gabungan CheerfulGarden-Terbaru.apk

File terbaru merupakan salinan identik dari build CheerfulGarden-Joystick-Fix.apk, ditandatangani debug v2/v3 dan lolos pemeriksaan zipalign 16KB.

Memuat: jalan satu baris balok isometrik yang tersambung ke tangga rumah dan dapat dipindahkan; harga lahan positif dengan pengurangan koin yang tepat; ayam dan ternak menggunakan tujuan acak, mematuk/merumput dan jeda istirahat; kandang serta pembelian satu hewan sapi/kambing/babi tersedia di Toko mulai level 3; rumah/upgrade tersedia level 2, produksi level 5; tampilan kebun tidak berganti otomatis pada level 5; paket karakter lima arah empat musim.

Perbaikan input: joystick memproses gerakan drag melalui koordinat lokal GUI, pelepasan ditangani meski di luar lingkaran; panel bibit dinaikkan ke depan dan kartu panduan disembunyikan selama panel terbuka; pindah halaman membersihkan menu dan fokus lama; emulasi mouse dari sentuhan dinyatakan eksplisit.

Verifikasi: real_controls_test dan scaled_controls_test lulus input keyboard, drag mouse, drag sentuh, pilihan bibit, tombol tanam dan pelepasan pengunci setelah navigasi. saved_controls_test memakai salinan save pengguna dan lulus tanpa memodifikasi save asli. Alur tanam/panen/jual/naik level/kandang lulus pada first_farm_visual. Log: work/saved-controls.log, work/scaled-joystick-drag.log, work/joystick-drag-local-test.log, work/controls-release-e2e.log, work/android-joystick-fix-export.log. Pengujian sentuh dilakukan dalam engine komputer, bukan verifikasi pada perangkat Android fisik.
