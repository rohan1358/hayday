extends SceneTree
const MAIL=preload("res://scripts/mailbox.gd")
const LANG=preload("res://scripts/garden_language.gd")
var host
func _initialize(): call_deferred("run")
func shot(id):
 for i in 5: await process_frame
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/"+id+".png"))
func run():
 var game=FarmGameState.new(false);game.save_path="user://mail_data_test.json";game.backup_path="user://mail_data_backup.json"
 game.new_game(false)
 assert(MAIL.ensure(game))
 var size=game.mailbox.messages.size();assert(not MAIL.ensure(game) and game.mailbox.messages.size()==size)
 assert(MAIL.deliver(game,"test_reward","Hadiah","Hadiah pengujian",{"coins":25,"xp":2,"seeds":{"gandum":2}}))
 assert(not MAIL.deliver(game,"test_reward","Duplikat","",{"coins":999}))
 assert(not MAIL.deliver(game,"invalid","Invalid","",{"seeds":{"missing":2}}))
 var coins=game.coins;var seeds=game.seeds.gandum
 assert(MAIL.claim(game,"test_reward") and game.coins==coins+25 and game.seeds.gandum==seeds+2)
 assert(not MAIL.claim(game,"test_reward"))
 var copy=FarmGameState.new(false);copy.save_path=game.save_path;copy.backup_path=game.backup_path
 assert(copy.load_game() and not MAIL.claim(copy,"test_reward"))
 var daily="daily_"+Time.get_date_string_from_system();coins=game.coins
 var expected=game.daily_checkin_preview().coins
 assert(MAIL.claim(game,daily) and game.coins==coins+expected)
 assert(game.claim_daily_checkin().is_empty() and not MAIL.claim(game,daily))
 assert(MAIL.deliver(game,"full_inventory","Hadiah","",{"coins":50,"inventory":{"gandum":2}}))
 game.storage_capacity=game.storage_used();coins=game.coins
 assert(not MAIL.claim(game,"full_inventory") and game.coins==coins and not MAIL.find(game,"full_inventory").claimed)
 host=load("res://scenes/Main.tscn").instantiate();host.game.save_path="user://mail_ui_test.json";host.game.backup_path="user://mail_ui_backup.json"
 DirAccess.remove_absolute(host.game.save_path);DirAccess.remove_absolute(host.game.backup_path)
 root.add_child(host)
 host.game.ftue.started=true;host.game.ftue.step="done";host.game.level=6
 for node in host.find_children("*","",true,false):
  if node.name=="NewPlayerWelcome": node.hide()
  if node.get_script()!=null and node.get_script().resource_path=="res://scripts/farm_progression.gd":
   node.set_process(false)
   if is_instance_valid(node.dialog): node.dialog.hide()
 var language=root.get_node("GardenLanguage");var previous=LANG.locale
 language.set_language("id")
 host.refresh_all()
 host.find_child("Cheerful_surat",true,false).pressed.emit();assert(host.active_tab=="pesan")
 await shot("pesan-kotak-masuk")
 var unread=MAIL.unread(host.game)
 host.sheet.find_child("OpenMail_"+daily,true,false).pressed.emit()
 assert(MAIL.unread(host.game)==unread-1 and MAIL.find(host.game,daily).read)
 host.sheet.find_child("MailTab_rewards",true,false).pressed.emit()
 assert(host.sheet.find_child("ClaimMailReward",true,false)!=null)
 host.sheet.find_child("MailTab_announcements",true,false).pressed.emit()
 assert(host.get_meta("mail_tab")=="announcements")
 host.find_child("Cheerful_notifikasi",true,false).pressed.emit();assert(host.active_tab=="aktivitas")
 await shot("aktivitas-kebun-baru")
 host.switch_tab("pesanan");assert(host.active_tab=="pesanan")
 host.switch_tab("pengaturan")
 for i in 8:
  host.sheet.find_child("SettingsTab_"+str(i),true,false).pressed.emit()
  assert(host.get_meta("settings_category")==i)
 host.sheet.find_child("SettingsTab_0",true,false).pressed.emit()
 await shot("pengaturan-audio-baru")
 var audio=host.get_node("GardenAudio");var saved=audio.volumes.duplicate();var muted=audio.muted
 host.sheet.find_child("Audio_music",true,false).value=31;assert(is_equal_approx(audio.volumes.music,0.31))
 host.sheet.find_child("SettingsMute",true,false).button_pressed=not muted;assert(audio.muted!=muted)
 for key in saved: audio.set_volume(key,saved[key])
 audio.muted=muted;audio.apply_volumes();audio.save_settings()
 host.sheet.find_child("SettingsTab_1",true,false).pressed.emit()
 host.sheet.find_child("CameraFree",true,false).pressed.emit();assert(not host.farm.hybrid_controller.data.follow)
 host.sheet.find_child("CameraFollow",true,false).pressed.emit();assert(host.farm.hybrid_controller.data.follow)
 host.sheet.find_child("SettingsTab_6",true,false).pressed.emit()
 var picker=host.sheet.find_child("SettingsLanguage",true,false);picker.select(1);picker.item_selected.emit(1)
 for i in 5: await process_frame
 assert(LANG.locale=="en" and LANG.text("Pilih Bibit")=="Pick seeds" and LANG.text("Pesanan")=="Orders")
 assert(host.sheet.find_child("MenuTitle",true,false).text=="Settings")
 await shot("settings-language-english")
 host.switch_tab("pesan");host.set_meta("mail_tab","inbox");host.show_sheet()
 await shot("messages-english")
 assert(host.sheet.find_child("MenuTitle",true,false).text=="Messages")
 var cfg=ConfigFile.new();assert(cfg.load("user://garden_language.cfg")==OK and cfg.get_value("language","locale")=="en")
 assert(not language.set_language("invalid"))
 language.set_language(previous)
 for i in 3: await process_frame
 print("MAIL SETTINGS LANGUAGE PASS: separate routes, read status, tabs, attachments, duplicate/storage guards, daily shared reward, reload, settings, audio, camera, ID/EN persistence")
 host.queue_free();await process_frame;quit()
