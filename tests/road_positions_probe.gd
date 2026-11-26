extends SceneTree
func _initialize():
 var image=load("res://assets/world_background/summer_island_v2.png").get_image()
 for y in [4100,4250,4320,4450,4570,4700,4850,4950]:
  var row=int(float(y)/7680*image.get_height());var groups=[]
  for x in range(int(450.0/4320*image.get_width()),int(2200.0/4320*image.get_width())):
   var c=image.get_pixel(x,row)
   if c.r>.82 and c.g>.64 and c.b<c.g*.85 and c.r>c.g*1.03:
    var wx=float(x)/image.get_width()*4320
    if groups.is_empty() or wx-groups[-1][-1]>15:groups.append([wx])
    else:groups[-1].append(wx)
  var out=[]
  for group in groups:
   if group[-1]-group[0]>20:out.append([group[0],group[-1]])
  print(y," ",out)
 quit()
