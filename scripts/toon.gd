extends RefCounted
## Utilidades para crear piezas 3D con look cartoon (sombreado toon + contorno).

static var _mats: Dictionary = {}
static var _ol_round: ShaderMaterial
static var _ol_flat: ShaderMaterial


static func mat(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		m.roughness = 1.0
		_mats[key] = m
	return _mats[key]


static func _outline(flat: bool) -> ShaderMaterial:
	if flat:
		if _ol_flat == null:
			_ol_flat = ShaderMaterial.new()
			_ol_flat.shader = load("res://shaders/outline.gdshader")
			_ol_flat.set_shader_parameter("width", 0.0)
		return _ol_flat
	if _ol_round == null:
		_ol_round = ShaderMaterial.new()
		_ol_round.shader = load("res://shaders/outline.gdshader")
		_ol_round.set_shader_parameter("width", 0.03)
	return _ol_round


static func box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


static func cyl(top: float, bottom: float, h: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = 14
	m.rings = 1
	return m


static func sphere(r: float, h: float = -1.0) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = h if h > 0.0 else r * 2.0
	m.radial_segments = 14
	m.rings = 7
	return m


static func capsule(r: float, h: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = maxf(h, r * 2.0)
	m.radial_segments = 12
	m.rings = 4
	return m


static func part(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO, outline: bool = true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat(color)
	mi.position = pos
	mi.rotation = rot
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	if outline:
		var ol := MeshInstance3D.new()
		if mesh is BoxMesh:
			var b := BoxMesh.new()
			b.size = (mesh as BoxMesh).size + Vector3.ONE * 0.07
			ol.mesh = b
			ol.material_override = _outline(true)
		else:
			ol.mesh = mesh
			ol.material_override = _outline(false)
		ol.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.add_child(ol)
	return mi


# ---------- Materiales brillantes (neón, láser, imán) ----------
static var _glows: Dictionary = {}


static func glow_mat(color: Color, alpha: float = 1.0) -> StandardMaterial3D:
	var key := color.to_html() + str(alpha)
	if not _glows.has(key):
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(color.r, color.g, color.b, alpha)
		if alpha < 1.0:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_glows[key] = m
	return _glows[key]


static func glow(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO, alpha: float = 1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = glow_mat(color, alpha)
	mi.position = pos
	mi.rotation = rot
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


static func torus(inner: float, outer: float) -> TorusMesh:
	var t := TorusMesh.new()
	t.inner_radius = inner
	t.outer_radius = outer
	t.rings = 24
	t.ring_segments = 8
	return t


## Imán de herradura de verdad: arco rojo con las puntas blancas.
static func horseshoe(parent: Node3D, s: float = 1.0, pos: Vector3 = Vector3.ZERO) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	n.scale = Vector3.ONE * s
	parent.add_child(n)
	var r := 0.34
	var steps := 8
	for i in steps + 1:
		var a := PI * float(i) / steps
		part(n, box(Vector3(0.2, 0.2, 0.2)), Color("e11d2e"), Vector3(cos(a) * r, sin(a) * r, 0), Vector3(0, 0, a + PI / 2))
	for sx in [-r, r]:
		part(n, box(Vector3(0.2, 0.3, 0.2)), Color("e11d2e"), Vector3(sx, -0.15, 0))
		part(n, box(Vector3(0.21, 0.12, 0.21)), Color("f1f5f9"), Vector3(sx, -0.36, 0))
	return n
