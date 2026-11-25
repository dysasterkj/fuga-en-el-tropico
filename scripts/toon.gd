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
