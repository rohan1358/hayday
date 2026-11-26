extends Control
## Shared layered cream frame and illustrated wooden title for every menu.
const ICON=preload("res://scripts/colorful_icons.gd")
const TITLES={"rumah":"Rumah","babi":"Kandang Babi","kambing":"Kandang Kambing","pesan":"Pesan","aset":"Dekorasi Kebun","prestasi":"Prestasi","gudang":"Gudang","pesanan":"Pesanan","koleksi":"Koleksi","toko":"Toko","pengaturan":"Pengaturan","hadiah_pemula":"Hadiah","rumput":"Rumput","bunga":"Bunga","pohon":"Pohon","dekorasi":"Dekorasi","gedung":"Bangunan","ayam":"Peternakan Ayam","aktivitas":"Aktivitas Kebun","jalan":"Jalan","upgrade":"Upgrade Bangunan","misi":"Misi","produksi":"Dapur Produksi","roti":"Toko Roti","susu":"Pabrik Susu","pakan":"Pabrik Pakan","sapi":"Kandang Sapi","pasar":"Pasar Tetangga","pengunjung":"Tamu Kebun","kebun_buah":"Kebun Buah","ternak":"Peternakan","bangun":"Bangun & Dekorasi"}
const ICONS={"rumah":"kebun","babi":"hewan","kambing":"hewan","pesan":"surat","aset":"bunga","prestasi":"hadiah","gudang":"gudang","pesanan":"pesanan","koleksi":"koleksi","toko":"toko","pengaturan":"pengaturan","hadiah_pemula":"hadiah","rumput":"bibit","bunga":"bunga","pohon":"pohon","dekorasi":"bunga","gedung":"kebun","ayam":"hewan","aktivitas":"misi","jalan":"jalan","upgrade":"upgrade","misi":"misi","produksi":"produksi","roti":"produksi","susu":"produksi","pakan":"ranch_feed","sapi":"hewan","pasar":"toko","pengunjung":"karakter","kebun_buah":"pohon","ternak":"hewan","bangun":"bangun"}
var menu_id=""
static func box(fill: Color,border: Color,width: int,radius: int) -> StyleBoxFlat:
 var b=StyleBoxFlat.new();b.bg_color=fill;b.border_color=border;b.set_border_width_all(width);b.set_corner_radius_all(radius)
 b.anti_aliasing=true;return b
static func install(host,card,id: String,caption: String):
 card.set_meta("colorful_applied",true)
 card.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
 var frame=load("res://scripts/menu_frame.gd").new();frame.name="GardenMenuFrame";frame.menu_id=id
 frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
 card.add_child(frame)
 var heading=host.label(card,str(TITLES.get(id,id.capitalize())),Vector2(187,-13),Vector2(306,77),46 if str(TITLES.get(id,id)).length()<13 else 36,Color("fff9e8"),true)
 heading.name="MenuTitle";heading.set_meta("typography_role","title")
 heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;heading.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 heading.add_theme_color_override("font_outline_color",Color("653513"));heading.add_theme_constant_override("outline_size",5)
 heading.add_theme_color_override("font_shadow_color",Color("60331366"));heading.add_theme_constant_override("shadow_offset_y",3)
 var icon=ICON.add(card,str(ICONS.get(id,"kebun")),Vector2(113,-12),Vector2(72,72));icon.name="MenuTitleIcon"
 if id in ["ayam","sapi","babi","kambing","ternak"] and host.farm.ranch_animator!=null:
  icon.texture=host.farm.ranch_animator.frames.get((id if id in ["sapi","babi","kambing"] else "ayam")+"0",icon.texture)
 if id=="toko": caption="Pilihan untuk membangun dan mempercantik kebunmu."
 var description=host.label(card,caption,Vector2(35,87),Vector2(610,48),19,Color("604a2c"))
 description.name="MenuSubtitle";description.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 return frame
func _ready(): resized.connect(queue_redraw)
func leaf(center: Vector2,length: float,angle: float,color: Color):
 var points=PackedVector2Array()
 for side in [1,-1]:
  for i in 13:
   var t=float(i)/12 if side==1 else 1.0-float(i)/12
   points.append(center+Vector2((t-0.5)*length,sin(t*PI)*length*0.22*side).rotated(angle))
 draw_colored_polygon(points,color)
 var outline=points.duplicate();outline.append(points[0]);draw_polyline(outline,Color("4e8b17"),2,true)
 draw_line(center-Vector2(length*0.39,0).rotated(angle),center+Vector2(length*0.39,0).rotated(angle),Color("bce754"),2,true)
func _draw():
 if size.x<10 or size.y<10: return
 var rect=Rect2(Vector2.ZERO,size)
 var outer=box(Color("d99b48"),Color("8d542c"),3,40)
 outer.shadow_color=Color("30451d66");outer.shadow_size=10;outer.shadow_offset=Vector2(0,7)
 draw_style_box(outer,rect)
 draw_style_box(box(Color("ffcc72"),Color("ffe6a2"),4,36),rect.grow(-5))
 draw_style_box(box(Color("fff7dc"),Color("b88843"),2,31),rect.grow(-13))
 draw_style_box(box(Color("fff8e2"),Color("fffdf1"),3,28),rect.grow(-19))
 if menu_id=="toko":
  var stripe_width=(size.x-38)/12.0
  for i in 12:
   var color=Color("ed6043") if i%2==0 else Color("fff1cd")
   draw_rect(Rect2(19+i*stripe_width,18,stripe_width+1,23),color)
   draw_circle(Vector2(19+(i+0.5)*stripe_width,41),stripe_width*0.5,color)
 var left=Vector2(101,22);var right=Vector2(size.x-101,22)
 for spec in [[Vector2(-18,7),80.0,0.12,Color("6dad1c")],[Vector2(-13,-19),78.0,0.78,Color("83c526")],[Vector2(-30,24),70.0,-0.55,Color("8bd12c")]]:
  leaf(left+spec[0],spec[1],spec[2],spec[3]);leaf(right+Vector2(-spec[0].x,spec[0].y),spec[1],PI-spec[2],spec[3])
 var plaque=Rect2(100,-26,size.x-200,106)
 var wood=box(Color("dba05a"),Color("8c5427"),4,28)
 wood.shadow_color=Color("6d431944");wood.shadow_size=4;wood.shadow_offset=Vector2(0,5)
 draw_style_box(wood,plaque)
 draw_style_box(box(Color("eab773"),Color("ffd699"),2,23),plaque.grow(-6))
 # Short grain details stay at the edges, leaving clear space around the lettering.
 for y in [plaque.position.y+23,plaque.position.y+58,plaque.end.y-15]:
  draw_line(Vector2(108,y),Vector2(125,y-2),Color("a96a32"),2,true)
  draw_line(Vector2(size.x-125,y+2),Vector2(size.x-108,y),Color("a96a32"),2,true)
 for x in [112,size.x-112]:
  draw_circle(Vector2(x,plaque.position.y+16),3,Color("9e642f"))
  draw_line(Vector2(x-2,plaque.position.y+16),Vector2(x+2,plaque.position.y+16),Color("efc88d"),1)
