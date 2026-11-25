extends Node3D
## Corredor: 3 carriles, salto, deslizamiento, vuelo, personalización y animación fluida.

const Toon = preload("res://scripts/toon.gd")

const LANE_W := 2.2
const GRAVITY := 30.0
const JUMP_V := 11.0

signal jumped
signal slid
signal landed

var lane := 1
var vy := 0.0
var on_ground := true
var slide_t := 0.0
var pending_slide := false
var run_phase := 0.0
var flying := false
var dead := false
var idle := true
var spin := false
var t := 0.0
var squash := 0.0

var model: Node3D
var body: Node3D
var head: Node3D
var thigh_l: Node3D
var shin_l: Node3D
var thigh_r: Node3D
var shin_r: Node3D
var uarm_l: Node3D
var farm_l: Node3D
var uarm_r: Node3D
var farm_r: Node3D
var cape: Node3D
var wing_l: Node3D
var wing_r: Node3D


func reset() -> void:
	lane = 1
	vy = 0.0
	on_ground = true
	slide_t = 0.0
	pending_slide = false
	flying = false
	dead = false
	idle = true
	spin = false
	squash = 0.0
	position = Vector3.ZERO
	visible = true
	if model:
		model.rotation = Vector3.ZERO
		model.position = Vector3.ZERO
		model.scale = Vector3.ONE


# ---------- Construcción del modelo ----------
func _pivot(parent: Node3D, pos: Vector3) -> Node3D:
	var p := Node3D.new()
	p.position = pos
	parent.add_child(p)
	return p


func _seg(parent: Node3D, color: Color, length: float, radius: float) -> void:
	Toon.part(parent, Toon.capsule(radius, length), color, Vector3(0, -length * 0.5, 0))


func set_look(look: Dictionary) -> void:
	if model != null and is_instance_valid(model):
		model.queue_free()
	cape = null
	wing_l = null
	wing_r = null
	model = Node3D.new()
	add_child(model)

	var ch: Dictionary = GameState.item_def("char", String(look.get("char", "mateo")))
	var co: Dictionary = GameState.item_def("costume", String(look.get("costume", "none")))
	var shirt := Color(String(co.shirt)) if String(co.shirt) != "" else Color(String(ch.shirt))
	var pants := Color(String(co.pants)) if String(co.pants) != "" else Color(String(ch.pants))
	var skin := Color(String(ch.skin))
	var hair := Color(String(ch.hair))
	var shoe := Color("f8fafc")

	# piernas (muslo + espinilla)
	thigh_l = _pivot(model, Vector3(-0.15, 0.85, 0))
	thigh_r = _pivot(model, Vector3(0.15, 0.85, 0))
	_seg(thigh_l, pants, 0.46, 0.125)
	_seg(thigh_r, pants, 0.46, 0.125)
	shin_l = _pivot(thigh_l, Vector3(0, -0.42, 0))
	shin_r = _pivot(thigh_r, Vector3(0, -0.42, 0))
	_seg(shin_l, skin, 0.42, 0.105)
	_seg(shin_r, skin, 0.42, 0.105)
	Toon.part(shin_l, Toon.box(Vector3(0.24, 0.12, 0.4)), shoe, Vector3(0, -0.4, -0.07))
	Toon.part(shin_r, Toon.box(Vector3(0.24, 0.12, 0.4)), shoe, Vector3(0, -0.4, -0.07))

	# tronco
	body = _pivot(model, Vector3(0, 0.85, 0))
	Toon.part(body, Toon.capsule(0.26, 0.92), shirt, Vector3(0, 0.4, 0))
	Toon.part(body, Toon.box(Vector3(0.56, 0.2, 0.36)), pants, Vector3(0, 0.0, 0), Vector3.ZERO, false)
	_costume_extra(String(co.extra), shirt, body)

	# brazos (brazo + antebrazo)
	uarm_l = _pivot(body, Vector3(-0.36, 0.72, 0))
	uarm_r = _pivot(body, Vector3(0.36, 0.72, 0))
	_seg(uarm_l, shirt, 0.36, 0.1)
	_seg(uarm_r, shirt, 0.36, 0.1)
	farm_l = _pivot(uarm_l, Vector3(0, -0.34, 0))
	farm_r = _pivot(uarm_r, Vector3(0, -0.34, 0))
	_seg(farm_l, skin, 0.34, 0.085)
	_seg(farm_r, skin, 0.34, 0.085)
	Toon.part(farm_l, Toon.sphere(0.1), skin, Vector3(0, -0.34, 0), Vector3.ZERO, false)
	Toon.part(farm_r, Toon.sphere(0.1), skin, Vector3(0, -0.34, 0), Vector3.ZERO, false)

	# cabeza
	head = _pivot(body, Vector3(0, 0.88, 0))
	Toon.part(head, Toon.sphere(0.25), skin, Vector3(0, 0.2, 0))
	Toon.part(head, Toon.sphere(0.045), Color("111111"), Vector3(-0.09, 0.22, -0.225), Vector3.ZERO, false)
	Toon.part(head, Toon.sphere(0.045), Color("111111"), Vector3(0.09, 0.22, -0.225), Vector3.ZERO, false)
	Toon.part(head, Toon.box(Vector3(0.1, 0.025, 0.02)), Color("7a3b2e"), Vector3(0, 0.1, -0.245), Vector3.ZERO, false)
	_hair(String(ch.style), hair)
	_head_acc(String(look.get("head", "none")))
	_face_acc(String(look.get("face", "none")), hair)
	_back_acc(String(look.get("back", "none")))


func _hair(style: String, c: Color) -> void:
	match style:
		"long":
			Toon.part(head, Toon.sphere(0.27), c, Vector3(0, 0.27, 0.05))
			Toon.part(head, Toon.capsule(0.14, 0.75), c, Vector3(0, -0.1, 0.2))
		"bun":
			Toon.part(head, Toon.sphere(0.27), c, Vector3(0, 0.27, 0.05))
			Toon.part(head, Toon.sphere(0.13), c, Vector3(0, 0.55, 0.08))
		"afro":
			Toon.part(head, Toon.sphere(0.4), c, Vector3(0, 0.32, 0.08))
		_:
			Toon.part(head, Toon.sphere(0.27), c, Vector3(0, 0.27, 0.05))


func _costume_extra(extra: String, shirt: Color, b: Node3D) -> void:
	match extra:
		"stripes":
			for y in [0.18, 0.42, 0.66]:
				Toon.part(b, Toon.cyl(0.265, 0.265, 0.07), Color("1d3557"), Vector3(0, y, 0), Vector3.ZERO, false)
		"vest":
			Toon.part(b, Toon.cyl(0.275, 0.275, 0.55), Color("588157"), Vector3(0, 0.38, 0), Vector3.ZERO, false)
		"sash":
			Toon.part(b, Toon.cyl(0.275, 0.275, 0.14), Color("ffd60a"), Vector3(0, 0.4, 0), Vector3(0, 0, 0.7), false)
		"number":
			Toon.part(b, Toon.box(Vector3(0.18, 0.22, 0.03)), Color("f8f9fa"), Vector3(0, 0.45, -0.265), Vector3.ZERO, false)
			Toon.part(b, Toon.box(Vector3(0.06, 0.14, 0.035)), Color("1d4ed8"), Vector3(0, 0.45, -0.27), Vector3.ZERO, false)
		"bowtie":
			Toon.part(b, Toon.box(Vector3(0.1, 0.1, 0.04)), Color("e63946"), Vector3(-0.07, 0.74, -0.22), Vector3(0, 0, 0.5), false)
			Toon.part(b, Toon.box(Vector3(0.1, 0.1, 0.04)), Color("e63946"), Vector3(0.07, 0.74, -0.22), Vector3(0, 0, -0.5), false)
			Toon.part(b, Toon.cyl(0.275, 0.275, 0.06), Color("f8f9fa"), Vector3(0, 0.55, 0), Vector3.ZERO, false)


func _head_acc(id: String) -> void:
	match id:
		"straw":
			Toon.part(head, Toon.cyl(0.18, 0.22, 0.22), Color("f2cc6b"), Vector3(0, 0.52, 0))
			Toon.part(head, Toon.cyl(0.5, 0.5, 0.04), Color("f2cc6b"), Vector3(0, 0.42, 0))
			Toon.part(head, Toon.cyl(0.225, 0.225, 0.05), Color("e63946"), Vector3(0, 0.45, 0), Vector3.ZERO, false)
		"pirate":
			Toon.part(head, Toon.cyl(0.26, 0.3, 0.18), Color("1f2937"), Vector3(0, 0.5, 0))
			Toon.part(head, Toon.box(Vector3(0.72, 0.05, 0.5)), Color("1f2937"), Vector3(0, 0.42, 0))
			Toon.part(head, Toon.sphere(0.055), Color("f8fafc"), Vector3(0, 0.52, -0.3), Vector3.ZERO, false)
		"flower":
			Toon.part(head, Toon.sphere(0.11), Color("ff9ecd"), Vector3(0.2, 0.44, -0.05))
			Toon.part(head, Toon.sphere(0.055), Color("ffd166"), Vector3(0.2, 0.44, -0.15), Vector3.ZERO, false)
		"cap":
			Toon.part(head, Toon.sphere(0.28, 0.4), Color("e63946"), Vector3(0, 0.38, 0))
			Toon.part(head, Toon.box(Vector3(0.32, 0.04, 0.26)), Color("e63946"), Vector3(0, 0.36, -0.3))
		"feather":
			Toon.part(head, Toon.cyl(0.265, 0.265, 0.07), Color("e63946"), Vector3(0, 0.41, 0), Vector3.ZERO, false)
			Toon.part(head, Toon.box(Vector3(0.05, 0.42, 0.1)), Color("06d6a0"), Vector3(0.13, 0.66, 0.05), Vector3(0, 0, -0.25))
			Toon.part(head, Toon.box(Vector3(0.05, 0.48, 0.1)), Color("ffd166"), Vector3(-0.03, 0.7, 0.05))
			Toon.part(head, Toon.box(Vector3(0.05, 0.42, 0.1)), Color("ef476f"), Vector3(-0.19, 0.66, 0.05), Vector3(0, 0, 0.25))
		"sombrero":
			Toon.part(head, Toon.cyl(0.18, 0.26, 0.32), Color("1f1f1f"), Vector3(0, 0.58, 0))
			Toon.part(head, Toon.cyl(0.65, 0.65, 0.04), Color("1f1f1f"), Vector3(0, 0.42, 0))
			Toon.part(head, Toon.cyl(0.265, 0.265, 0.06), Color("ffc233"), Vector3(0, 0.46, 0), Vector3.ZERO, false)
		"crown":
			Toon.part(head, Toon.cyl(0.2, 0.24, 0.18), Color("ffc233"), Vector3(0, 0.5, 0))
			for i in 5:
				var a := i * TAU / 5.0
				Toon.part(head, Toon.box(Vector3(0.06, 0.14, 0.06)), Color("ffc233"), Vector3(sin(a) * 0.2, 0.66, cos(a) * 0.2), Vector3.ZERO, false)


func _face_acc(id: String, hair: Color) -> void:
	match id:
		"sunglasses":
			Toon.part(head, Toon.box(Vector3(0.15, 0.09, 0.04)), Color("111827"), Vector3(-0.1, 0.23, -0.25))
			Toon.part(head, Toon.box(Vector3(0.15, 0.09, 0.04)), Color("111827"), Vector3(0.1, 0.23, -0.25))
			Toon.part(head, Toon.box(Vector3(0.08, 0.02, 0.04)), Color("111827"), Vector3(0, 0.25, -0.25), Vector3.ZERO, false)
		"eyepatch":
			Toon.part(head, Toon.box(Vector3(0.14, 0.12, 0.04)), Color("111111"), Vector3(0.1, 0.23, -0.245))
			Toon.part(head, Toon.cyl(0.255, 0.255, 0.03), Color("111111"), Vector3(0, 0.3, 0), Vector3(0.0, 0.0, 0.18), false)
		"mask":
			Toon.part(head, Toon.box(Vector3(0.46, 0.12, 0.04)), Color("8338ec"), Vector3(0, 0.23, -0.235))
			Toon.part(head, Toon.sphere(0.04), Color("f8f9fa"), Vector3(-0.09, 0.23, -0.26), Vector3.ZERO, false)
			Toon.part(head, Toon.sphere(0.04), Color("f8f9fa"), Vector3(0.09, 0.23, -0.26), Vector3.ZERO, false)
		"moustache":
			Toon.part(head, Toon.capsule(0.035, 0.24), hair.darkened(0.2), Vector3(0, 0.145, -0.245), Vector3(0, 0, PI / 2), false)


func _back_acc(id: String) -> void:
	match id:
		"backpack":
			Toon.part(body, Toon.box(Vector3(0.4, 0.5, 0.2)), Color("06d6a0"), Vector3(0, 0.4, 0.3))
			Toon.part(body, Toon.box(Vector3(0.42, 0.14, 0.22)), Color("04a47a"), Vector3(0, 0.56, 0.3), Vector3.ZERO, false)
		"surfboard":
			Toon.part(body, Toon.box(Vector3(0.3, 1.5, 0.06)), Color("ff6b6b"), Vector3(0.05, 0.38, 0.32), Vector3(0, 0, 0.2))
			Toon.part(body, Toon.box(Vector3(0.08, 1.4, 0.065)), Color("f8f9fa"), Vector3(0.05, 0.38, 0.32), Vector3(0, 0, 0.2), false)
		"cape":
			var p := _pivot(body, Vector3(0, 0.72, 0.24))
			Toon.part(p, Toon.box(Vector3(0.56, 0.9, 0.04)), Color("e63946"), Vector3(0, -0.45, 0.02))
			cape = p
		"wings":
			wing_l = _pivot(body, Vector3(-0.12, 0.55, 0.28))
			wing_r = _pivot(body, Vector3(0.12, 0.55, 0.28))
			Toon.part(wing_l, Toon.box(Vector3(0.75, 0.5, 0.03)), Color("ff9ecd"), Vector3(-0.38, 0.12, 0), Vector3(0, 0, 0.35))
			Toon.part(wing_r, Toon.box(Vector3(0.75, 0.5, 0.03)), Color("7dd3fc"), Vector3(0.38, 0.12, 0), Vector3(0, 0, -0.35))


# ---------- Control ----------
func head_h() -> float:
	return 0.75 if slide_t > 0.0 else 1.85


func move_lane(d: int) -> void:
	if dead:
		return
	lane = clampi(lane + d, 0, 2)


func jump() -> void:
	if dead or flying:
		return
	if on_ground:
		vy = JUMP_V
		on_ground = false
		slide_t = 0.0
		squash = -0.16
		jumped.emit()


func slide() -> void:
	if dead or flying:
		return
	if on_ground:
		slide_t = 0.75
		slid.emit()
	else:
		vy = -24.0
		pending_slide = true


func set_flying(v: bool) -> void:
	flying = v
	if v:
		slide_t = 0.0
		pending_slide = false


func die() -> void:
	dead = true
	slide_t = 0.0


func _ease(node: Node3D, axis: int, target: float, k: float) -> void:
	if node == null:
		return
	var r := node.rotation
	if axis == 0:
		r.x = lerpf(r.x, target, k)
	elif axis == 1:
		r.y = lerpf(r.y, target, k)
	else:
		r.z = lerpf(r.z, target, k)
	node.rotation = r


func step(delta: float, ground_h: float, speed: float) -> void:
	t += delta
	var tx := (lane - 1) * LANE_W
	var prev_x := position.x
	position.x = lerpf(position.x, tx, 1.0 - exp(-15.0 * delta))
	var lean := clampf((prev_x - position.x) * 16.0, -0.55, 0.55)
	var k := 1.0 - exp(-22.0 * delta)
	var ks := 1.0 - exp(-12.0 * delta)

	if dead:
		model.rotation.x = lerpf(model.rotation.x, -1.45, 1.0 - exp(-8.0 * delta))
		model.position.y = lerpf(model.position.y, 0.2, 1.0 - exp(-8.0 * delta))
		for n in [thigh_l, thigh_r, shin_l, shin_r, uarm_l, uarm_r, farm_l, farm_r]:
			_ease(n, 0, 0.0, ks)
		return

	var was_ground := on_ground
	var vy_before := vy
	if flying:
		position.y = lerpf(position.y, 3.4, 1.0 - exp(-4.0 * delta))
		vy = 0.0
		on_ground = false
	else:
		vy -= GRAVITY * delta
		position.y += vy * delta
		if position.y <= ground_h:
			position.y = ground_h
			vy = 0.0
			on_ground = true
			if not was_ground and vy_before < -5.0:
				squash = clampf(-vy_before * 0.011, 0.07, 0.2)
				landed.emit()
			if pending_slide:
				slide_t = 0.75
				pending_slide = false
		else:
			on_ground = false

	slide_t = maxf(0.0, slide_t - delta)
	var sliding := slide_t > 0.0
	run_phase += delta * (speed * 0.62 + 5.5)
	squash = lerpf(squash, 0.0, 1.0 - exp(-11.0 * delta))
	model.scale = Vector3(1.0 + squash * 0.5, 1.0 - squash, 1.0 + squash * 0.5)

	if idle:
		if spin:
			model.rotation.y += delta * 0.9
		else:
			model.rotation.y = lerpf(model.rotation.y, sin(t * 0.8) * 0.4, ks)
		model.rotation.x = lerpf(model.rotation.x, 0.0, ks)
		model.rotation.z = lerpf(model.rotation.z, 0.0, ks)
		model.position.y = 0.0
		body.position.y = 0.85 + sin(t * 2.2) * 0.012
		for n in [thigh_l, thigh_r, shin_l, shin_r]:
			_ease(n, 0, 0.0, ks)
		_ease(uarm_l, 0, sin(t * 2.0) * 0.07, ks)
		_ease(uarm_r, 0, -sin(t * 2.0) * 0.07, ks)
		_ease(farm_l, 0, 0.18, ks)
		_ease(farm_r, 0, 0.18, ks)
		_ease(head, 1, sin(t * 0.7) * 0.2, ks)
		_ease(body, 0, 0.0, ks)
		_ease(body, 1, 0.0, ks)
		_flap(0.35, 3.0)
		return

	model.rotation.y = lerpf(model.rotation.y, 0.0, ks)
	_ease(head, 1, 0.0, ks)

	if flying:
		model.rotation.x = lerpf(model.rotation.x, -1.15, k)
		model.position.y = lerpf(model.position.y, 0.35, k)
		_ease(thigh_l, 0, 0.2, k)
		_ease(thigh_r, 0, -0.1, k)
		_ease(shin_l, 0, -0.3, k)
		_ease(shin_r, 0, -0.1, k)
		_ease(uarm_l, 0, -2.9, k)
		_ease(uarm_r, 0, -2.9, k)
		_ease(farm_l, 0, 0.0, k)
		_ease(farm_r, 0, 0.0, k)
		_ease(body, 0, 0.0, k)
		_ease(body, 1, 0.0, k)
		_flap(0.5, 16.0)
	elif sliding:
		model.rotation.x = lerpf(model.rotation.x, 1.25, k)
		model.position.y = lerpf(model.position.y, 0.32, k)
		_ease(thigh_l, 0, 0.1, k)
		_ease(thigh_r, 0, 0.1, k)
		_ease(shin_l, 0, 0.0, k)
		_ease(shin_r, 0, 0.0, k)
		_ease(uarm_l, 0, -0.9, k)
		_ease(uarm_r, 0, -0.9, k)
		_ease(farm_l, 0, 0.5, k)
		_ease(farm_r, 0, 0.5, k)
		_ease(body, 0, 0.0, k)
		_flap(0.4, 6.0)
	elif not on_ground:
		model.rotation.x = lerpf(model.rotation.x, 0.0, k)
		model.position.y = lerpf(model.position.y, 0.0, k)
		var rising := vy > 0.0
		_ease(thigh_l, 0, 1.0 if rising else 0.5, k)
		_ease(shin_l, 0, -1.3 if rising else -0.4, k)
		_ease(thigh_r, 0, -0.45 if rising else -0.2, k)
		_ease(shin_r, 0, -0.5 if rising else -0.2, k)
		_ease(uarm_l, 0, -2.6 if rising else -1.6, k)
		_ease(uarm_r, 0, -2.6 if rising else -1.6, k)
		_ease(farm_l, 0, 0.3, k)
		_ease(farm_r, 0, 0.3, k)
		_ease(body, 0, -0.1, k)
		_ease(body, 1, 0.0, k)
		_flap(0.6 if rising else 0.9, 10.0)
	else:
		model.rotation.x = lerpf(model.rotation.x, 0.0, k)
		var s := sin(run_phase)
		var c := cos(run_phase)
		model.position.y = lerpf(model.position.y, 0.0, k)
		body.position.y = 0.85 + absf(s) * 0.07 - 0.035
		_ease(thigh_l, 0, s * 0.95, k)
		_ease(thigh_r, 0, -s * 0.95, k)
		_ease(shin_l, 0, -(0.15 + maxf(0.0, c) * 1.15), k)
		_ease(shin_r, 0, -(0.15 + maxf(0.0, -c) * 1.15), k)
		_ease(uarm_l, 0, -s * 0.95, k)
		_ease(uarm_r, 0, s * 0.95, k)
		_ease(farm_l, 0, 0.75 + maxf(0.0, -s) * 0.6, k)
		_ease(farm_r, 0, 0.75 + maxf(0.0, s) * 0.6, k)
		_ease(body, 0, -0.14 - minf(speed * 0.004, 0.1), k)
		_ease(body, 1, s * 0.16, k)
		_ease(head, 0, 0.12, k)
		_flap(0.35 + minf(speed * 0.012, 0.3), 9.0)

	model.rotation.z = lerpf(model.rotation.z, lean, k)
	_ease(body, 2, lean * 0.6, k)


func _flap(base: float, rate: float) -> void:
	if cape != null:
		cape.rotation.x = base + sin(t * rate) * 0.1
	if wing_l != null:
		wing_l.rotation.y = -0.2 - (sin(t * rate) * 0.5 + 0.5) * 0.7
		wing_r.rotation.y = 0.2 + (sin(t * rate) * 0.5 + 0.5) * 0.7
