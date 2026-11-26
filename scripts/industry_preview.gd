extends Control
var window
func _draw():
 if window==null:return
 var canvas=window.host.farm
 var factor=size/Vector2(580,360 if window.kind=="tambang" else 210)
 draw_set_transform(Vector2.ZERO,0,factor)
 if window.kind=="penggilingan":
  var sprite=canvas.farm_art.sprites.region_mill
  var ratio=180.0/sprite.region.size.y
  draw_texture_rect_region(sprite.texture,Rect2(Vector2(290,195)-Vector2(sprite.region.size.x*.5,sprite.region.size.y)*ratio,sprite.region.size*ratio),sprite.region)
  return
 var jobs=load("res://scripts/industry_jobs.gd");var working=jobs.jobs(window.host.game).has("tambang") and jobs.remaining(window.host.game,"tambang")>0
 var ready=jobs.jobs(window.host.game).has("tambang") and not working
 var rock=canvas.farm_art.sprites.resource_boulder;var ratio=190.0/rock.region.size.x
 draw_texture_rect_region(rock.texture,Rect2(Vector2(345,290)-rock.anchor*ratio,rock.region.size*ratio),rock.region)
 var clock=window.clock
 var actor=Vector2(225,295)
 var pose={"activity":"chop" if working else "idle","direction":Vector2.RIGHT,"clock":clock}
 preload("res://scripts/wardrobe_assets.gd").paint(self,Rect2(actor-Vector2(65,220),Vector2(130,220)),window.host.game.seasonal,pose)
 if working:
  var hand=actor+Vector2(40,-100);var tip=hand+Vector2(70,18).rotated(-.3+sin(clock*8))
  draw_line(actor+Vector2(15,-135),hand,Color("cf9870"),9,true)
  draw_line(hand,tip,Color("88562b"),8,true);draw_line(tip+Vector2(-26,-7),tip+Vector2(25,10),Color("9aadb4"),12,true)
  for i in 6:
   var t=fposmod(clock*2+i*.16,1)
   draw_circle(Vector2(330,235)+Vector2((i-2.5)*t*18,-sin(t*PI)*45+t*20),3*(1-t),Color("deb97e"))
 if ready:
  for i in 3:
   var t=fposmod(clock*.7+i*.3,1);var icon=preload("res://scripts/colorful_icons.gd").texture("palu" if i==2 else "batu")
   if icon!=null:draw_texture_rect(icon,Rect2(Vector2(340+(i-1)*55,220-sin(t*PI)*120),Vector2(48,48)),false)
 draw_set_transform(Vector2.ZERO)
