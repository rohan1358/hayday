extends Node
# Visual-only presentation. Economy, hit areas, saves and character sockets stay intact.
const SHADER=preload("res://assets/colorful_garden/vivid.gdshader")
const COLORS={"kebun":Color("239b61"),"pesanan":Color("cc628b"),"toko":Color("d99525"),"produksi":Color("8a63c6"),"gudang":Color("258da8")}
var material: ShaderMaterial
func _ready() -> void:
	material=ShaderMaterial.new()
	material.shader=SHADER
	get_tree().node_added.connect(added)
	visit(get_parent())
func _exit_tree() -> void:
	if get_tree()!=null and get_tree().node_added.is_connected(added): get_tree().node_added.disconnect(added)
func added(node: Node) -> void:
	apply.call_deferred(node)
func visit(node: Node) -> void:
	apply(node)
	for child in node.get_children(): visit(child)
func apply(node) -> void:
	if not is_instance_valid(node) or not get_parent().is_ancestor_of(node) or node.has_meta("colorful_applied"): return
	node.set_meta("colorful_applied",true)
	if node is CanvasItem:
		var in_world=get_parent().farm==node or get_parent().farm.is_ancestor_of(node)
		var script=node.get_script()
		var wardrobe=script!=null and str(script.resource_path).ends_with("wardrobe_preview.gd")
		if in_world or wardrobe or node is TextureRect:
			# Existing effect materials are preserved; new nodes receive the same grade.
			if node.material==null and not (node is TextureRect and node.texture is ViewportTexture): node.material=material
			node.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if node is Button: preload("res://scripts/colorful_icons.gd").decorate(node)
	if node is Control:
		for state in ["panel","normal","hover","pressed","disabled","focus"]:
			if not node.has_theme_stylebox_override(state): continue
			var original=node.get_theme_stylebox(state)
			if not original is StyleBoxFlat: continue
			var box=original.duplicate() as StyleBoxFlat
			box.bg_color=paper_color(box.bg_color)
			box.border_color=Color("bca478").lerp(box.bg_color,0.5)
			if box.shadow_size>0: box.shadow_color=Color(0.19,0.12,0.12,0.19)
			node.add_theme_stylebox_override(state,box)
static func paper_color(c: Color) -> Color:
	if c.a<0.75: return c
	if c.v>0.88 and c.s<0.16: return Color("fff6df") if c.b<c.g else Color("f1ecff")
	return Color.from_hsv(c.h,minf(0.85,c.s*1.22),minf(1.0,c.v*1.025),c.a)
static func accent(caption: String,bg: Color) -> Color:
	if bg.v>0.84 and bg.s<0.25: return paper_color(bg)
	var text=caption.to_upper()
	if "UPGRADE" in text or "MISI" in text: return Color("8960bc")
	if "BELI" in text or "TOKO" in text: return Color("c98a24")
	if "PRODUKSI" in text or "DAPUR" in text: return Color("9860bb")
	if "GUDANG" in text: return Color("278aa0")
	return paper_color(bg)
