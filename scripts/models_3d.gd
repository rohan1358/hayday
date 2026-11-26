extends RefCounted

static func material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	return m

static func shape(parent: Node3D, kind: String, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	if kind == "sphere":
		var mesh := SphereMesh.new()
		mesh.radius = 0.5
		mesh.height = 1
		mesh.radial_segments = 24
		mesh.rings = 12
		node.mesh = mesh
	elif kind == "cone" or kind == "cylinder":
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.0 if kind == "cone" else 0.5
		mesh.bottom_radius = 0.5
		mesh.height = 1
		mesh.radial_segments = 24
		node.mesh = mesh
	else:
		node.mesh = BoxMesh.new()
	node.material_override = material(color)
	node.position = at
	node.scale = size
	parent.add_child(node)
	return node

static func accessory(index: int) -> Node3D:
	var n := Node3D.new()
	var colors := [Color("ef96b4"), Color("404a63"), Color("d47a40"), Color("74bace")]
	if index == 0:
		shape(n,"cylinder",Vector3.ZERO,Vector3(0.95,0.06,0.85),Color("e5bf77"))
		shape(n,"cylinder",Vector3(0,0.16,0),Vector3(0.6,0.3,0.55),Color("e5bf77"))
		for j in 5:
			shape(n,"sphere",Vector3(0.32,0.14,0) + Vector3(0,cos(j*TAU/5)*0.08,sin(j*TAU/5)*0.08),Vector3.ONE*0.12,colors[0])
	elif index == 1:
		for x in [-0.2,0.2]:
			shape(n,"sphere",Vector3(x,0,0.04),Vector3(0.34,0.23,0.09),colors[1])
		shape(n,"box",Vector3.ZERO,Vector3(0.2,0.04,0.05),Color("d5b65d"))
	elif index == 2:
		shape(n,"cylinder",Vector3.ZERO,Vector3(0.64,0.18,0.6),colors[2])
		shape(n,"box",Vector3(0.18,-0.25,0.3),Vector3(0.19,0.6,0.1),colors[2])
	else:
		shape(n,"sphere",Vector3(0,0.1,0),Vector3(0.72,0.6,0.66),colors[3])
		shape(n,"cylinder",Vector3(0,-0.04,0),Vector3(0.76,0.12,0.7),Color("e4edf1"))
		shape(n,"sphere",Vector3(0,0.45,0),Vector3.ONE*0.2,Color.WHITE)
	return n

static func person(data: Dictionary) -> Node3D:
	var n := Node3D.new()
	var female := str(data.get("gender", "male")) == "female"
	var skin := Color("eeb18a")
	var hair := Color("664334")
	var shirt := Color("ec9874") if female else Color("f2cb7c")
	var overalls := Color("839464") if female else Color("506f96")
	var index := int(data.get("outfit", -1))
	if index >= 0:
		shirt = Color(["ec9874","f2cb7c","b8754d","8ebfce"][clampi(index,0,3)])
	# Rounded boots, cuffed trousers and the two animated limbs keep their IDs.
	for side in [-1,1]:
		var leg := Node3D.new()
		leg.name = "LegL" if side == -1 else "LegR"
		n.add_child(leg)
		shape(leg,"cylinder",Vector3(side*0.18,0.46,0),Vector3(0.24,0.65,0.26),skin if female else overalls)
		shape(leg,"cylinder",Vector3(side*0.18,0.27,0),Vector3(0.29,0.13,0.29),Color("efe1c6") if female else overalls.lightened(0.22))
		shape(leg,"sphere",Vector3(side*0.18,0.13,0.08),Vector3(0.34,0.29,0.49),Color("855435"))
		shape(leg,"box",Vector3(side*0.18,0.035,0.1),Vector3(0.34,0.065,0.47),Color("503b2c"))
		for j in 3:
			shape(leg,"box",Vector3(side*0.18,0.18+j*0.035,0.28-j*0.025),Vector3(0.17,0.018,0.025),Color("d8b474"))
		shape(n,"sphere",Vector3(side*0.17,0.78,0),Vector3(0.35,0.38,0.42),overalls)
		var arm := Node3D.new()
		arm.name = "ArmL" if side == -1 else "ArmR"
		n.add_child(arm)
		var sleeve := shape(arm,"sphere",Vector3(side*0.4,1.1,0),Vector3(0.28,0.48,0.3),shirt)
		sleeve.rotation.z = side*0.18
		shape(arm,"cylinder",Vector3(side*0.43,0.95,0),Vector3(0.29,0.1,0.31),shirt.lightened(0.13))
		shape(arm,"sphere",Vector3(side*0.47,0.76,0.02),Vector3(0.18,0.42,0.2),skin)
		shape(arm,"sphere",Vector3(side*0.49,0.56,0.04),Vector3(0.2,0.24,0.15),skin)
		shape(arm,"sphere",Vector3(side*0.4,0.57,0.11),Vector3(0.09,0.14,0.09),skin)
	shape(n,"sphere",Vector3(0,1.04,0),Vector3(0.64,0.7,0.44),shirt)
	shape(n,"sphere",Vector3(0,0.91,0.05),Vector3(0.59,0.43,0.45),overalls)
	shape(n,"box",Vector3(0,1.07,0.22),Vector3(0.41,0.34,0.055),overalls)
	shape(n,"box",Vector3(0,0.99,0.26),Vector3(0.22,0.14,0.025),overalls.lightened(0.08))
	for side in [-1,1]:
		shape(n,"box",Vector3(side*0.23,1.23,0.17),Vector3(0.085,0.34,0.07),overalls)
		shape(n,"sphere",Vector3(side*0.2,1.2,0.23),Vector3.ONE*0.075,Color("cda05a"))
		var collar := shape(n,"box",Vector3(side*0.1,1.31,0.19),Vector3(0.17,0.13,0.06),shirt.lightened(0.1))
		collar.rotation.z = side*0.4
	shape(n,"cylinder",Vector3(0,1.37,0),Vector3(0.25,0.2,0.26),skin)
	# Large expressive face, warm cheeks, layered brown eyes and smile.
	shape(n,"sphere",Vector3(0,1.82,0),Vector3(0.95,0.94,0.76),skin)
	for side in [-1,1]:
		shape(n,"sphere",Vector3(side*0.46,1.77,-0.01),Vector3(0.22,0.29,0.16),skin)
		shape(n,"sphere",Vector3(side*0.48,1.77,0.06),Vector3(0.11,0.17,0.035),Color("d99374"))
		shape(n,"sphere",Vector3(side*0.29,1.68,0.305),Vector3(0.19,0.095,0.025),Color("ed9b80"))
		shape(n,"sphere",Vector3(side*0.19,1.86,0.335),Vector3(0.27,0.32,0.095),Color("fff7e9"))
		shape(n,"sphere",Vector3(side*0.19,1.85,0.387),Vector3(0.18,0.24,0.045),Color("75482c"))
		shape(n,"sphere",Vector3(side*0.19,1.85,0.411),Vector3(0.1,0.17,0.022),Color("2d251e"))
		shape(n,"sphere",Vector3(side*0.19-0.035,1.91,0.426),Vector3.ONE*0.045,Color.WHITE)
		var brow := shape(n,"sphere",Vector3(side*0.19,2.075,0.3),Vector3(0.25,0.065,0.055),hair)
		brow.rotation.z = -side*0.13
		for j in 3:
			shape(n,"sphere",Vector3(side*(0.22+j*0.05),1.73+(j%2)*0.035,0.347-j*0.014),Vector3.ONE*0.014,Color("c5815a"))
		if female:
			var lash := shape(n,"box",Vector3(side*0.32,1.99,0.35),Vector3(0.08,0.025,0.025),hair)
			lash.rotation.z = side*0.6
	shape(n,"sphere",Vector3(0,1.74,0.39),Vector3(0.14,0.11,0.12),Color("e8a17c"))
	shape(n,"sphere",Vector3(0,1.58,0.338),Vector3(0.25,0.17,0.055),Color("713c2c"))
	shape(n,"sphere",Vector3(0,1.535,0.369),Vector3(0.13,0.055,0.019),Color("df8e78"))
	shape(n,"box",Vector3(0,1.64,0.371),Vector3(0.14,0.035,0.02),Color("fff4da"))
	# Layered locks and long braids follow the supplied reference silhouette.
	shape(n,"sphere",Vector3(0,2.13,-0.1),Vector3(1,0.57,0.77),hair)
	for j in 7:
		var lock := shape(n,"sphere",Vector3(-0.43+j*0.14,2.15+sin(j*0.8)*0.13,0.15),Vector3(0.27,0.48,0.24),hair.lightened((j%3)*0.025))
		lock.rotation.z = -0.5 if female else (j-3)*0.22
	for side in [-1,1]:
		shape(n,"sphere",Vector3(side*0.41,1.99,-0.09),Vector3(0.23,0.58,0.54),hair)
		if female:
			for j in 7:
				shape(n,"sphere",Vector3(side*(0.4+0.045*sin(j*1.6)),1.62-j*0.085,-0.17+(j%2)*0.035),Vector3(0.2-j*0.012,0.19,0.19),hair.lightened((j%2)*0.04))
			shape(n,"sphere",Vector3(side*0.41,1.04,-0.14),Vector3(0.12,0.2,0.12),hair)
			shape(n,"cylinder",Vector3(side*0.41,1.12,-0.14),Vector3(0.14,0.04,0.14),Color("d9af6b"))
		else:
			for j in 3:
				var tuft := shape(n,"sphere",Vector3(side*(0.4+j*0.035),2.03+j*0.12,-0.02),Vector3(0.27,0.25,0.31),hair)
				tuft.rotation.z = side*0.6
	var acc := int(data.get("accessory",-1))
	if acc >= 0:
		var item := accessory(acc)
		item.position = Vector3(0,2.38,0) if acc in [0,3] else (Vector3(0,1.86,0.43) if acc==1 else Vector3(0,1.36,0))
		item.scale = Vector3.ONE*1.35
		n.add_child(item)
	return n

static func building(color: Color, glass := false) -> Node3D:
	var n := Node3D.new()
	shape(n,"box",Vector3(0,0.65,0),Vector3(1.8,1.3,1.5),Color("b9ddd9") if glass else color)
	var roof := shape(n,"cylinder",Vector3(0,1.55,0),Vector3(2.25,0.8,1.95),Color("b85c49"))
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0
	mesh.bottom_radius = 0.5
	mesh.height = 1
	mesh.radial_segments = 4
	roof.mesh = mesh
	roof.rotation.y = PI/4
	shape(n,"box",Vector3(0,0.4,0.77),Vector3(0.42,0.8,0.08),Color("76523e"))
	for x in [-0.57,0.57]:
		shape(n,"box",Vector3(x,0.85,0.77),Vector3(0.33,0.4,0.09),Color("d8f2ed"))
	return n

static func tree(autumn := false) -> Node3D:
	var n := Node3D.new()
	shape(n,"cylinder",Vector3(0,0.6,0),Vector3(0.25,1.2,0.25),Color("855b3e"))
	for j in 3:
		shape(n,"sphere",Vector3((j-1)*0.32,1.4+ (0.3 if j==1 else 0),0),Vector3(1.1,1.25,1),Color("d59a4b") if autumn else Color("65a968"))
	return n

static func animal(kind: String) -> Node3D:
	var n := Node3D.new()
	var color := Color("f1e6cf")
	if kind == "babi": color = Color("eca7a3")
	if kind == "ayam": color = Color("fff2d0")
	shape(n,"sphere",Vector3(0,0.53,0),Vector3(0.85,0.65,1.15),color)
	shape(n,"sphere",Vector3(0,0.8,0.55),Vector3(0.5,0.5,0.5),color)
	for x in [-0.26,0.26]:
		for z in [-0.33,0.33]:
			shape(n,"cylinder",Vector3(x,0.22,z),Vector3(0.13,0.45,0.13),Color("72533e"))
	for x in [-0.15,0.15]:
		shape(n,"sphere",Vector3(x,0.88,0.77),Vector3.ONE*0.065,Color("303235"))
		shape(n,"cone",Vector3(x*1.8,1.05,0.5),Vector3(0.18,0.3,0.2),color)
	if kind == "sapi":
		shape(n,"sphere",Vector3(0.36,0.6,0),Vector3(0.1,0.35,0.5),Color("554840"))
	if kind == "ayam":
		shape(n,"cone",Vector3(0,0.75,0.86),Vector3(0.22,0.22,0.3),Color("e1a33b"))
		shape(n,"sphere",Vector3(0,1.08,0.53),Vector3(0.14,0.24,0.23),Color("d3584f"))
		n.scale = Vector3.ONE*0.6
	return n

static func prop(kind: String, index: int) -> Node3D:
	if kind == "accessory": return accessory(index)
	if kind == "outfit": return person({"outfit":index,"accessory":-1})
	if kind == "equipment": return building(Color(["a1b96d","729fca","b78959","9ec6c5"][index]),index==3)
	var n := Node3D.new()
	if index == 3:
		for j in 3:
			shape(n,"sphere",Vector3(0,0.3+j*0.4,0),Vector3.ONE*(0.85-j*0.2),Color("f4f8fa"))
		shape(n,"cone",Vector3(0,1.2,0.27),Vector3(0.12,0.12,0.28),Color("e9a34b"))
	elif index == 1:
		shape(n,"cylinder",Vector3(0,0.7,0),Vector3(0.06,1.4,0.06),Color("94724d"))
		shape(n,"cone",Vector3(0,1.4,0),Vector3(1.6,0.45,1.6),Color("e8be68"))
	elif index == 2:
		shape(n,"box",Vector3(0,0.4,0),Vector3(0.45,0.8,0.45),Color("825e40"))
		shape(n,"sphere",Vector3(0,0.5,0),Vector3.ONE*0.4,Color("ffdc82"))
	else:
		shape(n,"cylinder",Vector3(0,0.2,0),Vector3(0.6,0.4,0.6),Color("b77557"))
		for j in 5:
			shape(n,"sphere",Vector3(cos(j)*0.2,0.55,sin(j)*0.2),Vector3.ONE*0.23,Color("e597b1"))
	return n
