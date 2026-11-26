extends Control
const GAME_SCENE="res://scenes/Main.tscn"
const OPENING_MARKER="user://kebun_ceria_opening_seen_v1.flag"
var status: Label
var progress: ProgressBar
static func should_show_opening() -> bool:
 return false
func _ready() -> void:
 DisplayServer.window_set_title("Cheerful Garden")
 var background=ColorRect.new();background.color=Color("d2edb5")
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(background)
 var box=VBoxContainer.new();box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
 box.position=Vector2(-240,-60);box.size=Vector2(480,120);background.add_child(box)
 status=Label.new();status.text="Menyiapkan kebun…";status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 status.add_theme_font_size_override("font_size",25);box.add_child(status)
 progress=ProgressBar.new();progress.custom_minimum_size=Vector2(480,30);box.add_child(progress)
 progress.indeterminate=true;progress.show_percentage=false
 open_game.call_deferred()
func open_game() -> void:
 # Script resources attach autoload UI observers while loading. Keep them on
 # the main thread; background scene compilation can leave buttons unbound.
 await get_tree().process_frame
 await get_tree().process_frame
 status.text="Memuat aset kebun…"
 var scene=load(GAME_SCENE) as PackedScene
 if scene==null:
  progress.indeterminate=false
  status.text="Kebun gagal dimuat. Tutup lalu buka kembali."
  return
 status.text="Membuka kebun…"
 await get_tree().process_frame
 var error=get_tree().change_scene_to_packed(scene)
 if error!=OK:
  progress.indeterminate=false
  status.text="Kebun gagal dibuka. Tutup lalu buka kembali."
