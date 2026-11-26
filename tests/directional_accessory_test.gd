extends SceneTree
const ART=preload("res://scripts/wardrobe_assets.gd")
func _initialize(): call_deferred("run")
func run():
	var count=0
	for index in 24:
		var hashes={}
		for sector in 5:
			var texture=ART.directional_accessory(index,sector)
			assert(texture!=null and texture.get_width()>2 and texture.get_height()>2)
			hashes[texture.get_image().get_data().hex_encode().sha256_text()]=true
		assert(hashes.size()==2,"Each item uses the two original supplied front/back views")
	for path in ART.ATLAS_PATHS: assert(not ART.cache.has("bands_"+path),"Precomputed crops bypass expensive atlas scans")
	for gender in ["male","female"]:
		for outfit in 4:
			for sector in 5:
				var data={"gender":gender,"outfit":outfit}
				var direction=Vector2(sin(sector*PI/4),cos(sector*PI/4))
				var texture=ART.directional_character(data,{"direction":direction})
				var body=ART.fitted(texture,Rect2(20,30,180,320))
				for season in 4:
					for index in ART.CATALOG.items(gender,season):
						var item=ART.directional_accessory(index,sector)
						var fit=ART.directional_transform(index,body,data,sector)
						assert(fit.origin.is_finite() and fit.determinant()>0)
						if ART.CATALOG.slot_of(index)=="bag":
							assert((fit*(item.get_size()*Vector2(0.5,0.30))).distance_to(ART.pouch_mount(body,sector,data))<0.01,"Pouch anchored at waist, never hand or shoulder")
							assert(item.get_height()*fit.y.length()<=body.size.y*0.18,"Waist pouches remain proportional")
						if ART.CATALOG.slot_of(index)=="head" and season>=2: assert(item.get_height()*fit.y.length()<=body.size.y*0.281,"Beanies fit the head without excessive height")
						count+=1
	print("COLORFUL DIRECTIONAL PASS: 48 paired sprites; ",count," directional costume fittings; waist mounts and bounded pouch size")
	quit()
