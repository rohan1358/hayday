extends SceneTree
func _initialize(): call_deferred("run")
func run():
 root.size=Vector2i(720,1280)
 var host=load("res://scenes/Main.tscn").instantiate()
 host.game.save_path="user://promotion_layout_visual.json"
 host.game.backup_path="user://promotion_layout_visual_backup.json"
 DirAccess.remove_absolute(host.game.save_path)
 DirAccess.remove_absolute(host.game.backup_path)
 root.add_child(host)
 load("res://scripts/cheerful_menus.gd").guide(host).start_adventure()
 host.toast_layer.hide()
 await create_timer(2.0).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("C:/Users/nuych/Documents/Codex/2026-11-09/bu/outputs/CheerfulGarden-Layout-Baru.png")
 var presentation=host.get_node("CheerfulPresentation")
 var guide=load("res://scripts/cheerful_menus.gd").guide(host)
 assert(guide.card.size.y<250,"Mission card must not cover the farm")
 assert(guide.card.get_global_rect().end.y<=host.navbar.position.y,"Mission must sit above navigation")
 host.game.skip_onboarding()
 host.game.ftue.step="done"
 host.game.level=10
 host.refresh_all()
 host.set_meta("first_farm_modal",false)
 presentation._process(0.0)
 assert(presentation.farm_shortcuts.size()==2)
 assert(presentation.farm_shortcuts[0].visible)
 presentation.farm_shortcuts[0].pressed.emit()
 assert(host.active_tab=="ternak")
 host.switch_tab("kebun")
 presentation.farm_shortcuts[1].pressed.emit()
 assert(host.active_tab=="pasar")
 print("PROMOTION LAYOUT PASS: compact guide, unobstructed navigation, functional ranch and market shortcuts")
 host.queue_free()
 await process_frame
 quit()
