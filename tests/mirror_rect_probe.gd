extends SceneTree
class Probe extends Node2D:
 var texture
 func _ready():
  var image=Image.create(2,1,false,Image.FORMAT_RGBA8);image.set_pixel(0,0,Color.RED);image.set_pixel(1,0,Color.BLUE);texture=ImageTexture.create_from_image(image);queue_redraw()
 func _draw():draw_texture_rect_region(texture,Rect2(100,100,-40,20),Rect2(0,0,2,1))
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(720,1280);root.transparent_bg=true;root.add_child(Probe.new())
 await process_frame;await RenderingServer.frame_post_draw
 var image=root.get_texture().get_image()
 print("RECT ",image.get_used_rect()," DIM ",image.get_size())
 image.save_png(ProjectSettings.globalize_path("res://../outputs/mirror-probe.png"))
 for x in [65,95,105,135,145]:print(x,": ",image.get_pixel(x,110))
 quit()
