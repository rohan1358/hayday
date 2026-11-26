extends Control
var host
var panel: Panel
var caption: Label
var rotate: Button
func _ready():
 host=get_parent();mouse_filter=Control.MOUSE_FILTER_IGNORE;z_index=75
 panel=host.panel(self,Vector2(15,285),Vector2(690,78),Color("fff3d1"),18,3)
 caption=host.label(panel,"Ketuk aset untuk memilih",Vector2(15,10),Vector2(430,58),20,Color("355b48"),true)
 rotate=host.button(panel,"PUTAR ↔",Vector2(465,13),Vector2(205,52),Color("16a265"),Color.WHITE,21)
 rotate.name="RotateWorldAsset";rotate.tooltip_text="Ubah arah hadap kiri / kanan"
 rotate.pressed.connect(func():load("res://scripts/asset_edit.gd").rotate(host,host.farm.edit_selected))
 panel.hide()
func _process(_dt):
 visible=host.active_tab=="kebun" and host.farm.edit_mode
 panel.visible=visible
 if not visible:return
 var key=str(host.farm.edit_selected)
 caption.text="Ketuk aset, lalu geser atau putar" if key=="" else "Dipilih: "+key.replace("region_","").replace("starter_","dekorasi ").replace("wild_","pohon ").replace("resource_","batu ").replace("_"," ").capitalize()
 rotate.disabled=key=="" or key.begins_with("road_")
