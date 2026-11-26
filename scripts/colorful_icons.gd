extends RefCounted
# Repo-native SVG icons retain crisp edges at every Android density.
static var cache: Dictionary={}
static func texture(id: String) -> Texture2D:
	if not cache.has(id):
		var mapped={"misi":"pesanan","karakter":"pengaturan","rumah":"kebun","panen":"bibit","jalan":"bangun","produksi":"bangun","pindah":"bangun"}.get(id,id)
		var path="res://assets/cheerful/"+str(mapped)+".png"
		if not ResourceLoader.exists(path): path="res://assets/ui_icons/"+id+".svg"
		cache[id]=load(path) as Texture2D if ResourceLoader.exists(path) else null
	return cache[id]
static func for_caption(caption: String) -> String:
	var s=caption.to_upper()
	var slots={"KEPALA":"aksesoris","MATA":"kacamata","LEHER":"syal","TAS":"tas"}
	if slots.has(s.strip_edges()): return str(slots[s.strip_edges()])
	for pair in [["PERCEPAT","upgrade"],["KACAMATA","kacamata"],["PEREMPUAN","perempuan"],["LAKI","laki"],["AKSESORI","aksesoris"],["TOPI","aksesoris"],["KOSTUM","pakaian"],["PAKAIAN","pakaian"],["KARAKTER","karakter"],["BATAL","batal"],["LEPAS","batal"],["UPGRADE","upgrade"],["MISI","misi"],["PRESTASI","misi"],["BATU","batu"],["KAYU","kayu"],["PALU","palu"],["PAKU","paku"],["GUDANG","gudang"],["RUMAH","rumah"],["DAPUR","produksi"],["PRODUKSI","produksi"],["PAKAN","pakan"],["TERNAK","hewan"],["HEWAN","hewan"],["SAPI","hewan"],["AYAM","hewan"],["KANDANG","hewan"],["BIBIT","bibit"],["TANAM","bibit"],["SIRAM","air"],["AIR","air"],["PUPUK","pupuk"],["PANEN","panen"],["KUMPUL","panen"],["AMBIL","panen"],["PESANAN","pesanan"],["KIRIM","pesanan"],["JUAL","jual"],["BELI","toko"],["TOKO","toko"],["PASAR","toko"],["MUSIM","musim"],["CUACA","cuaca"],["SEMI","semi"],["PANAS","panas"],["GUGUR","gugur"],["DINGIN","dingin"],["PERLUAS","upgrade"],["DEKORASI","bangun"],["BUAT","produksi"],["HAPUS","batal"],["BANGUN","bangun"],["ATUR","bangun"],["KONTROL","kontrol"],["TUGAS","pesanan"],["TAMU","karakter"],["AKTIVITAS","misi"],["KLAIM","misi"],["SELESAI","pakai"],["SIMPAN","pakai"],["DIPAKAI","pakai"],["JALAN","jalan"],["KEBUN","kebun"],["GAME BARU","kebun"]]:
		if pair[0] in s: return pair[1]
	return ""
static func decorate(button: Button) -> void:
	if button.flat or button.icon!=null or button.text.strip_edges().length()<3: return
	var original: Dictionary=button.get_meta("language_text",{})
	var id=for_caption(str(original.get("source",button.text)))
	if id.is_empty(): return
	button.icon=texture(id)
	button.expand_icon=true
	button.add_theme_constant_override("icon_max_width",22 if button.size.x>0 and button.size.x<220 else 28)
	button.add_theme_constant_override("h_separation",7)
	for state in ["icon_normal_color","icon_hover_color","icon_pressed_color","icon_focus_color"]: button.add_theme_color_override(state,Color.WHITE)
	button.add_theme_color_override("icon_disabled_color",Color(1,1,1,0.45))
static func add(parent: Node,id: String,at: Vector2,dimensions: Vector2) -> TextureRect:
	var icon=TextureRect.new()
	icon.name="ColorfulIcon_"+id
	icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture=texture(id)
	icon.position=at
	icon.size=dimensions
	icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)
	return icon
