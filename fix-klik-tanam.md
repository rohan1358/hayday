# Perbaikan input Tanam

Lapisan SeedPickerDim dibuat setelah menu sehingga menerima hit testing sebelum tombol, meskipun z_index visualnya berada di belakang. Penggantian pilihan Gandum otomatis sebelumnya tidak menyelesaikan masalah input ini.

seed_picker.gd sekarang secara konsisten mengurutkan dim lalu menu pada setiap rebuild, termasuk setelah memilih bibit. Menu menjadi penerima input paling depan dan dim tetap memblokir dunia di luarnya.

tests/seed_pointer_input_test.gd mengirim event mouse melalui Viewport.push_input, memeriksa gui_get_hovered_control untuk kartu Gandum dan Tanam, kemudian mengirim InputEventScreenTouch pada pembukaan berikutnya. Kedua jalur berhasil menutup popup, membuat pekerjaan tanam, mengisi petak, dan mengurangi stok. Sebelum perbaikan urutan stabil, test menemukan SeedPickerDim menutupi ConfirmSeedPlant setelah rebuild; setelah perbaikan, PASS.

Pengujian berupa event viewport Godot di desktop/headless; belum ada uji perangkat Android fisik.
