extends RefCounted
# Cutout deformation keeps every bought costume and accessory in the same rig.
# All actions have a distinct pose/tool; only one visible player mesh is animated.
static func body(canvas: CanvasItem,texture: Texture2D,rect: Rect2,pose: Dictionary) -> void:
	var action=str(pose.get("activity","idle"))
	var clock=float(pose.get("clock",0))
	var pace=clock*(15 if action=="run" else 10)
	var walking=action in ["walk","run"]
	var working=action in ["plant","water","fertilize","harvest","feed","drink","collect","milk","eggs","shear","clean","pet","herd","chop","orchard","refill"]
	var uv_region: Rect2=pose.get("uv_region",Rect2(0,0,1,1))
	var columns=6
	var rows=10
	var vertices=PackedVector2Array()
	var uvs=PackedVector2Array()
	for y in range(rows+1):
		for x in range(columns+1):
			var uv=uv_region.position+Vector2(float(x)/columns,float(y)/rows)*uv_region.size
			var point=rect.position+uv*rect.size
			if walking and uv.y>0.65:
				var leg: float=-1 if uv.x<0.52 else 1
				var weight: float=(uv.y-0.65)/0.35
				point.x+=sin(pace)*leg*weight*rect.size.x*(0.08 if action=="run" else 0.05)
				point.y+=maxf(0,cos(pace)*leg)*weight*rect.size.y*0.025
			if action=="wave" and uv.x>0.70 and uv.y>0.4 and uv.y<0.74:
				point.y-=rect.size.y*(0.06+0.035*sin(clock*7))
				point.x+=rect.size.x*0.035*sin(clock*7)
			if working and uv.y>0.4 and uv.y<0.76 and (uv.x<0.3 or uv.x>0.78):
				point.y-=sin(clock*7)*rect.size.y*0.025
			vertices.append(point)
			uvs.append(uv)
	var indices=PackedInt32Array()
	for y in rows:
		for x in columns:
			var a=y*(columns+1)+x
			var b=a+1
			var c=a+columns+1
			var d=c+1
			indices.append_array(PackedInt32Array([a,b,d,a,d,c]))
	var arrays=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_TEX_UV]=uvs
	arrays[Mesh.ARRAY_INDEX]=indices
	var mesh=ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},Mesh.ARRAY_FLAG_USE_2D_VERTICES)
	var frame=Engine.get_process_frames()
	if int(canvas.get_meta("hybrid_mesh_frame",-1))!=frame:
		canvas.set_meta("hybrid_mesh_frame",frame)
		canvas.set_meta("hybrid_character_meshes",[])
	var retained: Array=canvas.get_meta("hybrid_character_meshes",[])
	retained.append(mesh)
	canvas.set_meta("hybrid_character_meshes",retained)
	canvas.draw_mesh(mesh,texture)
static func tool(view,pose: Dictionary) -> void:
	var action=str(pose.get("tool_action",pose.get("activity","idle")))
	var clock=float(pose.get("clock",0))
	var hand=Vector2(28,-60)+Vector2(sin(clock*7)*3,sin(clock*6)*3)
	var brown=Color("89603e")
	if action in ["plant","fertilize","feed"]:
		view.draw_rect(Rect2(hand-Vector2(9,12),Vector2(18,24)),Color("82b66c") if action=="plant" else Color("dbb369"))
		for i in 4:
			var t=fposmod(clock*1.6+i*0.25,1)
			view.draw_circle(hand+Vector2(12+t*20,-5+t*45),2.0,Color("f6d079"))
	elif action in ["water","drink","refill"]:
		view.ellipse(hand,12,9,Color("69afbc"))
		view.line(hand+Vector2(7,-2),hand+Vector2(27,8),Color("80c5cd"),5)
		view.draw_arc(hand-Vector2(3,5),9,PI,TAU,12,Color("417f91"),3,true)
		for i in 5:
			var t=fposmod(clock*2+i*0.2,1)
			view.draw_circle(hand+Vector2(26+t*12,8+t*28),1.8,Color("83d7ed"))
	elif action=="milk":
		view.draw_rect(Rect2(hand+Vector2(0,10),Vector2(23,22)),Color("91adb2"))
		view.ellipse(hand+Vector2(11,10),12,5,Color("f5f0d9"))
		view.line(hand-Vector2(8,9),hand+Vector2(4,sin(clock*8)*6),Color("d9ae88"),5)
		for i in 3: view.draw_circle(hand+Vector2(6+i*3,fposmod(clock*23+i*6,15)),1.8,Color("fff9ed"))
	elif action=="shear":
		var spread=0.4+absf(sin(clock*9))*0.6
		view.line(hand,hand+Vector2(24,-18).rotated(spread),Color("c1d0cf"),3)
		view.line(hand,hand+Vector2(24,-18).rotated(-spread),Color("c1d0cf"),3)
		view.draw_circle(hand-Vector2(3,0),5,Color("b27b58"))
	elif action in ["harvest","orchard","collect","eggs"]:
		view.ellipse(hand+Vector2(0,10),17,10,Color("be8d50"))
		view.draw_arc(hand+Vector2(0,4),12,PI,TAU,12,brown,3,true)
		if action in ["collect","eggs"]:
			view.draw_circle(hand+Vector2(0,6),6,Color("fff0d7"))
			view.draw_line(hand-Vector2(12,8),hand+Vector2(3,-5),Color("e8d49b"),4)
	elif action=="clean":
		var end=hand+Vector2(24+sin(clock*9)*12,42)
		view.line(hand,end,brown,4)
		for i in 5: view.line(end+Vector2((i-2)*4,-2),end+Vector2((i-2)*5,12),Color("deb566"),3)
	elif action=="pet":
		view.label("♥",hand+Vector2(4,-25-absf(sin(clock*3))*12),25,Color("eb8a9f"))
	elif action=="herd":
		view.line(hand+Vector2(12,-45),hand+Vector2(12,28),brown,4)
		view.draw_arc(hand+Vector2(4,-45),8,PI,TAU,12,brown,4,true)
	elif action=="chop":
		var tip=hand+Vector2(20+sin(clock*12)*15,-30)
		view.line(hand,tip,brown,4)
		view.draw_rect(Rect2(tip-Vector2(9,7),Vector2(23,14)),Color("dce3de"))
	elif action=="sit":
		view.ellipse(Vector2(0,0),25,9,Color("a8a084"))
