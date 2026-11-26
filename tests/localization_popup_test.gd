extends SceneTree
const LANG = preload("res://scripts/garden_language.gd")
const POPUP = preload("res://scripts/tree_chop_ad_popup.gd")
class Host extends Node:
	var game = FarmGameState.new(false)
func _initialize():
	call_deferred("run")
func run():
	var language = root.get_node("GardenLanguage")
	var previous = LANG.locale
	var host = Host.new()
	root.add_child(host)
	var popup = POPUP.new()
	popup.host = host
	host.add_child(popup)
	var failures: Array[String] = []
	for code in ["en", "id", "en"]:
		language.set_language(code)
		for limit in [5,20,150]:
			host.game.max_daily_free_tree_cuts = limit
			host.game.wild_tree_chops_today = limit
			popup._update_quota_label()
			await process_frame
			await process_frame
			var expected = ("%d/%d FREE CUTS USED" if code=="en" else "%d/%d TEBANG GRATIS TERPAKAI") % [limit,limit]
			if popup.quota_label.text != expected: failures.append("Quota: "+popup.quota_label.text)
		var title = "Daily tree cutting limit" if code=="en" else "Batas tebang pohon harian"
		var explanation = "You've used all your free tree cuts today.\nWatch a rewarded ad to continue?" if code=="en" else "Jatah tebang gratis hari ini sudah habis.\nTonton iklan berhadiah untuk melanjutkan?"
		var reward = "1 ad = 1 extra tree cut" if code=="en" else "1 iklan = 1 kesempatan tebang tambahan"
		var labels = []
		for label in popup.find_children("*","Label",true,false):
			labels.append(label.text)
			if label.autowrap_mode == TextServer.AUTOWRAP_OFF and label.get_theme_font("font").get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,label.get_theme_font_size("font_size")).x > label.size.x+1:
				failures.append("Text overflow: "+label.text)
		for expected in [title,explanation,reward]:
			if expected not in labels: failures.append("Missing "+expected+"; actual "+str(labels))
		if popup.find_child("WatchRewardedAd",true,false).text != ("WATCH REWARDED AD" if code=="en" else "TONTON IKLAN BERHADIAH"): failures.append("Watch button")
		if popup.find_child("CancelButton",true,false).text != ("Cancel" if code=="en" else "Batal"): failures.append("Cancel button")
		if OS.get_environment("GARDEN_LOCALIZATION_CAPTURE") == "1" and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			var output = "res://build/localization-tree-popup-%s.png" % code
			if root.get_texture().get_image().save_png(ProjectSettings.globalize_path(output)) != OK:
				failures.append("Screenshot failed: " + output)
		if GameText.format_number(1500) != ("1,500" if code=="en" else "1.500"): failures.append("Number")
		if GameText.format_hud_currency(12500) != ("12.5K" if code=="en" else "12,5rb"): failures.append("Compact")
		var dialog = ConfirmationDialog.new()
		dialog.title = "Barang diperlukan pesanan"
		dialog.dialog_text = "Menjual %d %s akan menyisakan %d stok, sedangkan pesanan aktif membutuhkan %d. Tetap jual?" % [2,"Gandum",3,4]
		dialog.ok_button_text = "Tetap jual"
		dialog.cancel_button_text = "Batal"
		root.add_child(dialog)
		await process_frame
		await process_frame
		if code=="en" and dialog.dialog_text!="Selling 2 Wheat will leave 3 in stock, while active orders need 4. Sell anyway?": failures.append(dialog.dialog_text)
		dialog.queue_free()
	language.set_language(previous)
	host.queue_free()
	for issue in failures: printerr("FAIL: ",issue)
	print("LOCALIZATION POPUP ", "PASS" if failures.is_empty() else "FAIL: "+str(failures.size()))
	quit(0 if failures.is_empty() else 1)

