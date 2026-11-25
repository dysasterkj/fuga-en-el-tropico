extends Node3D
## Mundo: suelo por segmentos, escenografía por zona, obstáculos, monedas y power-ups.

const Toon = preload("res://scripts/toon.gd")

signal event_warning(text: String)

const LANE_W := 2.2
const SEG_LEN := 24.0
const SEG_COUNT := 10
const SPAWN_AHEAD := 150.0
const ZONE_LEN := 500.0
const PLAT_H := 1.4
const RAMP_LEN := 4.0

var ZONES: Array = [
	{"name": "Playa Dorada", "sky_top": Color("2f9bff"), "sky_hor": Color("c4f1ff"), "fog": Color("d3f4ff"),
		"track": Color("e3c88f"), "left": Color("33c9d9"), "right": Color("f3d98e"),
		"crate": Color("c98a3a"), "accent": Color("ff6b6b"), "event": "¡LLUVIA DE COCOS!", "ball": Color("6b4423")},
	{"name": "Selva Esmeralda", "sky_top": Color("2a9d7a"), "sky_hor": Color("b9f0c8"), "fog": Color("c4ecd2"),
		"track": Color("8d6b46"), "left": Color("1f7a3d"), "right": Color("2b8f48"),
		"crate": Color("7a5230"), "accent": Color("ffd93d"), "event": "¡ESTAMPIDA DE ROCAS!", "ball": Color("8d99ae")},
	{"name": "Ciudad Colonial", "sky_top": Color("ff7e5f"), "sky_hor": Color("ffd6a5"), "fog": Color("ffe3c7"),
		"track": Color("8c8fa8"), "left": Color("d98c5f"), "right": Color("e0a070"),
		"crate": Color("b5651d"), "accent": Color("4cc9f0"), "event": "¡BARRILES DESBOCADOS!", "ball": Color("a0522d")},
]

var PICKS := {
	"magnet": [Color("3a86ff"), "IMÁN"],
	"shield": [Color("2ec4b6"), "ESCUDO"],
	"x2": [Color("ffbe0b"), "x2"],
	"fly": [Color("ff006e"), "VUELO"],
}

var env: Environment
var sky_mat: ProceduralSkyMaterial
var sun: DirectionalLight3D
var cur: Dictionary = {}
var target_zone := 0
var segs: Array = []
var ents: Array = []
var coins: Array = []
var picks: Array = []
var next_z := -45.0
var event_done: Dictionary = {}
var pending_events: Array = []
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	_setup_zones()
	_build_environment()
	_build_sky()
	for i in SEG_COUNT:
		var s := _make_segment()
		add_child(s)
		segs.append(s)
	reset()


func zone_name(level: int) -> String:
	return ZONES[level % ZONES.size()].name


func _build_environment() -> void:
	cur = _zone_cur(target_zone) if level_mode else _zone_cur(0)
	var we := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky_mat = ProceduralSkyMaterial.new()
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.86, 0.9, 1.0)
	env.ambient_light_energy = 0.75
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_depth_begin = 70.0
	env.fog_depth_end = 170.0
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 1.05
	add_child(sun)
	_apply_visual()


func _apply_visual() -> void:
	sky_mat.sky_top_color = cur.sky_top
	sky_mat.sky_horizon_color = cur.sky_hor
	sky_mat.ground_horizon_color = cur.sky_hor
	sky_mat.ground_bottom_color = cur.fog
	env.fog_light_color = cur.fog
	env.ambient_light_color = cur.amb
	sun.light_color = cur.sun


func set_zone(level: int) -> void:
	target_zone = level % ZONES.size()


func _ease_visual(delta: float) -> void:
	var k := 1.0 - exp(-1.6 * delta)
	var z: Dictionary = ZONES[target_zone]
	for key in cur:
		cur[key] = (cur[key] as Color).lerp(z[key], k)
	_apply_visual()


# ---------- Segmentos de suelo ----------
func _make_segment() -> Node3D:
	var s := Node3D.new()
	var mats: Array = []
	var specs: Array = [
		[Vector3(7.4, 0.6, SEG_LEN), Vector3(0, -0.3, 0)],
		[Vector3(40, 0.6, SEG_LEN), Vector3(-23.7, -0.45, 0)],
		[Vector3(40, 0.6, SEG_LEN), Vector3(23.7, -0.45, 0)],
		[Vector3(0.09, 0.02, SEG_LEN), Vector3(-1.1, 0.01, 0)],
		[Vector3(0.09, 0.02, SEG_LEN), Vector3(1.1, 0.01, 0)],
		[Vector3(0.4, 0.12, SEG_LEN), Vector3(-3.85, 0.04, 0)],
		[Vector3(0.4, 0.12, SEG_LEN), Vector3(3.85, 0.04, 0)],
	]
	for sp in specs:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = sp[0]
		mi.mesh = bm
		mi.position = sp[1]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var m := StandardMaterial3D.new()
		m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		m.roughness = 1.0
		mi.material_override = m
		s.add_child(mi)
		mats.append(m)
	s.set_meta("mats", mats)
	var decor := Node3D.new()
	decor.name = "Decor"
	s.add_child(decor)
	return s


func _style_segment(s: Node3D, biome: int) -> void:
	var z: Dictionary = ZONES[biome]
	var mats: Array = s.get_meta("mats")
	mats[0].albedo_color = z.track
	mats[1].albedo_color = z.left
	mats[2].albedo_color = z.right
	mats[3].albedo_color = z.lane
	mats[4].albedo_color = z.lane
	mats[5].albedo_color = z.edge
	mats[6].albedo_color = z.edge
	for gi in [3, 4, 5, 6]:
		mats[gi].emission_enabled = float(z.glow) > 0.0
		mats[gi].emission = mats[gi].albedo_color
	_fill_decor(s, biome)


func _fill_decor(s: Node3D, biome: int) -> void:
	var d: Node3D = s.get_node("Decor")
	for c in d.get_children():
		c.queue_free()
	for side in [-1.0, 1.0]:
		match biome:
			0: _decor_beach(d, side)
			1: _decor_jungle(d, side)
			2: _decor_colonial(d, side)
			3: _decor_neon(d, side)
			4: _decor_space(d, side)
			5: _decor_hero(d, side)


func _palm(p: Node3D, pos: Vector3) -> void:
	var n := Node3D.new()
	n.position = pos
	n.rotation.y = rng.randf() * TAU
	p.add_child(n)
	var h := rng.randf_range(3.6, 4.9)
	Toon.part(n, Toon.cyl(0.16, 0.26, h), Color("b07c42"), Vector3(0, h * 0.5, 0), Vector3(0, 0, rng.randf_range(-0.1, 0.1)))
	var top := Node3D.new()
	top.position = Vector3(0, h, 0)
	n.add_child(top)
	Toon.part(top, Toon.sphere(0.2), Color("6b4423"), Vector3(0.12, -0.15, 0), Vector3.ZERO, false)
	Toon.part(top, Toon.sphere(0.2), Color("6b4423"), Vector3(-0.1, -0.15, 0.1), Vector3.ZERO, false)
	for i in 5:
		var pv := Node3D.new()
		pv.rotation.y = i * TAU / 5.0
		top.add_child(pv)
		Toon.part(pv, Toon.box(Vector3(2.0, 0.08, 0.55)), Color("3bb273") if i % 2 == 0 else Color("2fa564"), Vector3(1.0, -0.05, 0), Vector3(0, 0, -0.45), false)


func _jungle_tree(p: Node3D, pos: Vector3) -> void:
	var n := Node3D.new()
	n.position = pos
	p.add_child(n)
	var h := rng.randf_range(4.5, 6.5)
	Toon.part(n, Toon.cyl(0.3, 0.45, h), Color("6b4a2b"), Vector3(0, h * 0.5, 0))
	Toon.part(n, Toon.sphere(1.9), Color("2d6a4f"), Vector3(0, h + 0.6, 0))
	Toon.part(n, Toon.sphere(1.3), Color("40916c"), Vector3(1.1, h + 1.2, 0.4), Vector3.ZERO, false)
	Toon.part(n, Toon.sphere(1.1), Color("52b788"), Vector3(-1.0, h + 0.2, -0.5), Vector3.ZERO, false)


func _bush(p: Node3D, pos: Vector3) -> void:
	Toon.part(p, Toon.sphere(0.8, 1.1), Color("52b788"), pos + Vector3(0, 0.45, 0))
	Toon.part(p, Toon.sphere(0.55, 0.8), Color("74c69d"), pos + Vector3(0.6, 0.3, 0.3), Vector3.ZERO, false)


func _umbrella(p: Node3D, pos: Vector3) -> void:
	var n := Node3D.new()
	n.position = pos
	p.add_child(n)
	Toon.part(n, Toon.cyl(0.05, 0.05, 2.3), Color("f1f1f1"), Vector3(0, 1.15, 0), Vector3.ZERO, false)
	Toon.part(n, Toon.cyl(0.05, 1.3, 0.55), Color("ff6b6b") if rng.randf() < 0.5 else Color("ffd166"), Vector3(0, 2.45, 0))


func _house(p: Node3D, pos: Vector3, side: float) -> void:
	var n := Node3D.new()
	n.position = pos
	p.add_child(n)
	var cols := ["ff6b6b", "ffd166", "06d6a0", "4cc9f0", "f78c6b", "c77dff"]
	var w := rng.randf_range(3.2, 4.4)
	var h := rng.randf_range(3.6, 6.2)
	var wall := Color(cols[rng.randi() % cols.size()])
	Toon.part(n, Toon.box(Vector3(w, h, 4.2)), wall, Vector3(0, h * 0.5, 0))
	Toon.part(n, Toon.box(Vector3(w + 0.5, 0.45, 4.7)), Color("9d4b3a"), Vector3(0, h + 0.22, 0))
	var fx := -side * (w * 0.5 + 0.03)
	for zz in [-1.1, 1.1]:
		Toon.part(n, Toon.box(Vector3(0.1, 0.9, 0.7)), Color("264653"), Vector3(fx, h * 0.62, zz), Vector3.ZERO, false)
	Toon.part(n, Toon.box(Vector3(0.1, 1.6, 0.8)), Color("5c3d2e"), Vector3(fx, 0.8, 0), Vector3.ZERO, false)


func _lamp(p: Node3D, pos: Vector3) -> void:
	Toon.part(p, Toon.cyl(0.07, 0.09, 3.6), Color("2b2d42"), pos + Vector3(0, 1.8, 0))
	Toon.part(p, Toon.sphere(0.25), Color("ffe66d"), pos + Vector3(0, 3.7, 0), Vector3.ZERO, false)


# ---------- Reinicio ----------
func reset() -> void:
	for e in ents:
		e.node.queue_free()
	ents.clear()
	for c in coins:
		c.queue_free()
	coins.clear()
	for p in picks:
		p.node.queue_free()
	picks.clear()
	_reset_extra()
	event_done.clear()
	pending_events.clear()
	next_z = -45.0
	target_zone = int(lvl.biome) if level_mode else 0
	cur = _zone_cur(target_zone) if level_mode else _zone_cur(0)
	_apply_visual()
	for i in segs.size():
		segs[i].position = Vector3(0, 0, 36.0 - i * SEG_LEN)
		_style_segment(segs[i], target_zone)


# ---------- Bucle ----------
func advance(delta: float, speed: float, dist: float, ppos: Vector3, magnet: bool) -> void:
	var move := speed * delta
	_ease_visual(delta)
	_sky_anim(delta)

	for s in segs:
		s.position.z += move
	for s in segs:
		if s.position.z > SEG_LEN * 2.5:
			var far := 0.0
			for o in segs:
				far = minf(far, o.position.z)
			s.position.z = far - SEG_LEN
			_style_segment(s, _biome_at(dist - s.position.z))

	for i in range(ents.size() - 1, -1, -1):
		var e: Dictionary = ents[i]
		var n: Node3D = e.node
		n.position.z += move + float(e.extra) * delta
		if e.has("roller"):
			(e.roller as Node3D).rotation.x += (speed + float(e.extra)) * delta / 0.55
		if n.position.z > 14.0:
			n.queue_free()
			ents.remove_at(i)

	var center := ppos + Vector3(0, 0.95, 0)
	for i in range(coins.size() - 1, -1, -1):
		var c: Node3D = coins[i]
		c.position.z += move
		c.rotation.y += 3.2 * delta
		if magnet:
			var dv := center - c.position
			var dl := dv.length()
			if (dl < 11.0 or c.has_meta("pull")) and dl > 0.05:
				var pt: float = float(c.get_meta("pull", 0.0)) + delta
				c.set_meta("pull", pt)
				var sp := 14.0 + pt * 70.0 + (11.0 - minf(dl, 11.0)) * 2.0
				c.position += dv.normalized() * minf(dl, sp * delta)
				c.scale = Vector3.ONE * (1.35 + 0.2 * sin(pt * 22.0))
				c.rotation.y += 9.0 * delta
		elif c.has_meta("pull"):
			c.remove_meta("pull")
			c.scale = Vector3.ONE
		if c.position.z > 12.0:
			c.queue_free()
			coins.remove_at(i)

	for i in range(picks.size() - 1, -1, -1):
		var pk: Dictionary = picks[i]
		var n: Node3D = pk.node
		n.position.z += move
		n.rotation.y += 2.0 * delta
		(pk.orb as Node3D).position.y = 0.15 * sin(Time.get_ticks_msec() * 0.005)
		if n.position.z > 12.0:
			n.queue_free()
			picks.remove_at(i)

	_update_projs(delta)
	_update_fx(delta, move)
	_update_finish(dist, move)

	for i in range(pending_events.size() - 1, -1, -1):
		if dist >= float(pending_events[i].at):
			event_warning.emit(pending_events[i].text)
			pending_events.remove_at(i)

	next_z += move
	while next_z > -SPAWN_AHEAD:
		var sd := dist - next_z
		if level_mode and sd > float(lvl.goal) - 14.0:
			break
		var plen := _spawn_pattern(next_z, sd)
		var level := int(sd / ZONE_LEN)
		var gap := clampf(19.0 - level * 2.0 - sd * 0.001, 9.0, 19.0)
		if level_mode:
			gap = float(lvl.gap)
		next_z -= plen + gap


# ---------- Consultas ----------
func ground_height(x: float) -> float:
	var h := 0.0
	for e in ents:
		if e.kind != "plat":
			continue
		if absf((int(e.lanes[0]) - 1) * LANE_W - x) > 0.95:
			continue
		var depth: float = e.node.position.z
		if depth < 0.0:
			continue
		if depth <= RAMP_LEN:
			h = maxf(h, PLAT_H * depth / RAMP_LEN)
		elif depth <= RAMP_LEN + float(e.length):
			h = maxf(h, PLAT_H)
	return h


func check_hit(px: float, py: float, head: float) -> Dictionary:
	for e in ents:
		if e.kind == "plat":
			continue
		var z: float = e.node.position.z
		if absf(z) > float(e.half) + 0.35:
			continue
		var in_lane := false
		for l in e.lanes:
			if absf((int(l) - 1) * LANE_W - px) < 0.8:
				in_lane = true
		if not in_lane:
			continue
		if e.kind == "low":
			if py < float(e.top) - 0.05:
				return e
		elif e.kind == "beam":
			if py + head > float(e.bottom) and py < float(e.top):
				return e
	return {}


func remove_entity(e: Dictionary) -> void:
	var i := ents.find(e)
	if i >= 0:
		e.node.queue_free()
		ents.remove_at(i)


func collect(p: Vector3) -> Dictionary:
	var got := 0
	var kinds: Array = []
	var center := p + Vector3(0, 0.95, 0)
	for i in range(coins.size() - 1, -1, -1):
		var c: Node3D = coins[i]
		var d := c.position - center
		if absf(d.x) < 0.95 and absf(d.y) < 1.25 and absf(d.z) < 0.9:
			got += 1
			c.queue_free()
			coins.remove_at(i)
	for i in range(picks.size() - 1, -1, -1):
		var pk: Dictionary = picks[i]
		var d: Vector3 = (pk.node as Node3D).position + Vector3(0, 0.6, 0) - center
		if absf(d.x) < 1.0 and absf(d.y) < 1.4 and absf(d.z) < 1.0:
			kinds.append(pk.kind)
			(pk.node as Node3D).queue_free()
			picks.remove_at(i)
	return {"coins": got, "picks": kinds}


func spawn_sky_coins(length: float) -> void:
	var lane := rng.randi_range(0, 2)
	var count := int(length / 2.2)
	for i in count:
		if i % 8 == 0:
			lane = rng.randi_range(0, 2)
		_add_coin(_x(lane), 4.4, -16.0 - i * 2.2)


# ---------- Constructores de entidades ----------
func _x(lane: int) -> float:
	return (lane - 1) * LANE_W


func _add_ent(node: Node3D, kind: String, lanes: Array, half: float, z: float, extra: float = 0.0, top: float = 0.95, bottom: float = 0.0, length: float = 0.0) -> Dictionary:
	var xs := (float(lanes.min()) + float(lanes.max())) * 0.5
	node.position = Vector3((xs - 1.0) * LANE_W, 0, z)
	add_child(node)
	var e := {"node": node, "kind": kind, "lanes": lanes, "half": half, "extra": extra, "top": top, "bottom": bottom, "length": length}
	ents.append(e)
	return e


func _add_coin(x: float, y: float, z: float) -> void:
	var n := Node3D.new()
	n.position = Vector3(x, y, z)
	Toon.part(n, Toon.cyl(0.36, 0.36, 0.1), Color("ffc400"), Vector3.ZERO, Vector3(PI / 2, 0, 0))
	add_child(n)
	coins.append(n)


func _coin_line(lane: int, z: float, count: int, y: float = 0.95, step: float = 2.0) -> void:
	for i in count:
		_add_coin(_x(lane), y, z - i * step)


func _add_pickup(kind: String, lane: int, z: float) -> void:
	var info: Array = PICKS[kind]
	var n := Node3D.new()
	n.position = Vector3(_x(lane), 1.0, z)
	var orb := Node3D.new()
	n.add_child(orb)
	var c: Color = info[0]
	Toon.part(orb, Toon.cyl(0.62, 0.62, 0.06), c.lightened(0.55), Vector3(0, 0.35, 0), Vector3(PI / 2, 0, 0), false)
	match kind:
		"magnet":
			Toon.part(orb, Toon.box(Vector3(0.15, 0.52, 0.15)), Color("e63946"), Vector3(-0.2, 0.36, 0))
			Toon.part(orb, Toon.box(Vector3(0.15, 0.52, 0.15)), Color("3a86ff"), Vector3(0.2, 0.36, 0))
			Toon.part(orb, Toon.box(Vector3(0.55, 0.15, 0.15)), Color("6b7280"), Vector3(0, 0.1, 0))
			Toon.part(orb, Toon.box(Vector3(0.15, 0.1, 0.16)), Color.WHITE, Vector3(-0.2, 0.64, 0), Vector3.ZERO, false)
			Toon.part(orb, Toon.box(Vector3(0.15, 0.1, 0.16)), Color.WHITE, Vector3(0.2, 0.64, 0), Vector3.ZERO, false)
		"life":
			Toon.part(orb, Toon.sphere(0.2), Color("f43f5e"), Vector3(-0.14, 0.46, 0))
			Toon.part(orb, Toon.sphere(0.2), Color("f43f5e"), Vector3(0.14, 0.46, 0))
			Toon.part(orb, Toon.box(Vector3(0.34, 0.34, 0.2)), Color("f43f5e"), Vector3(0, 0.28, 0), Vector3(0, 0, PI / 4))
			Toon.part(orb, Toon.sphere(0.06), Color("ffffff"), Vector3(-0.2, 0.54, -0.16), Vector3.ZERO, false)
		"w_coco":
			Toon.part(orb, Toon.sphere(0.27), Color("7c4a1e"), Vector3(0, 0.36, 0))
			Toon.part(orb, Toon.sphere(0.07), Color("e7d5b3"), Vector3(0, 0.46, -0.24), Vector3.ZERO, false)
		"w_boom":
			Toon.part(orb, Toon.box(Vector3(0.5, 0.11, 0.18)), Color("fbbf24"), Vector3(-0.17, 0.36, 0), Vector3(0, 0, -0.5))
			Toon.part(orb, Toon.box(Vector3(0.5, 0.11, 0.18)), Color("f59e0b"), Vector3(0.17, 0.36, 0), Vector3(0, 0, 0.5))
		"w_bomb":
			Toon.part(orb, Toon.sphere(0.28), Color("1f2937"), Vector3(0, 0.34, 0))
			Toon.glow(orb, Toon.sphere(0.09), Color("fb923c"), Vector3(0, 0.66, 0))
			Toon.part(orb, Toon.box(Vector3(0.04, 0.14, 0.04)), Color("a16207"), Vector3(0, 0.6, 0), Vector3.ZERO, false)
		"shield":
			Toon.part(orb, Toon.cyl(0.36, 0.2, 0.14), c, Vector3(0, 0.36, 0), Vector3(PI / 2, 0, 0))
			Toon.part(orb, Toon.sphere(0.12), Color.WHITE, Vector3(0, 0.36, -0.1), Vector3.ZERO, false)
		"x2":
			Toon.part(orb, Toon.cyl(0.26, 0.26, 0.08), Color("ffc400"), Vector3(-0.14, 0.36, 0.05), Vector3(PI / 2, 0, 0))
			Toon.part(orb, Toon.cyl(0.26, 0.26, 0.08), Color("ffd84d"), Vector3(0.14, 0.36, -0.05), Vector3(PI / 2, 0, 0))
			Toon.part(orb, Toon.sphere(0.07), Color("e63946"), Vector3(0, 0.7, 0), Vector3.ZERO, false)
		"fly":
			Toon.part(orb, Toon.sphere(0.16), Color("ffd166"), Vector3(0, 0.36, 0))
			Toon.part(orb, Toon.box(Vector3(0.38, 0.12, 0.05)), Color("ff9ecd"), Vector3(-0.3, 0.44, 0), Vector3(0, 0, 0.45))
			Toon.part(orb, Toon.box(Vector3(0.38, 0.12, 0.05)), Color("7dd3fc"), Vector3(0.3, 0.44, 0), Vector3(0, 0, -0.45))
	add_child(n)
	picks.append({"node": n, "kind": kind, "orb": orb})


func _add_low(lanes: Array, z: float, biome: int) -> void:
	var zn: Dictionary = ZONES[biome]
	var n := Node3D.new()
	var width := (float(lanes.max()) - float(lanes.min())) * LANE_W + 1.7
	Toon.part(n, Toon.box(Vector3(width, 0.95, 0.9)), zn.crate, Vector3(0, 0.475, 0))
	Toon.part(n, Toon.box(Vector3(width + 0.02, 0.17, 0.93)), zn.accent, Vector3(0, 0.22, 0), Vector3.ZERO, false)
	Toon.part(n, Toon.box(Vector3(width + 0.02, 0.17, 0.93)), zn.accent, Vector3(0, 0.74, 0), Vector3.ZERO, false)
	_add_ent(n, "low", lanes, 0.45, z, 0.0, 0.95)


func _add_beam(lanes: Array, z: float, biome: int) -> void:
	var zn: Dictionary = ZONES[biome]
	var n := Node3D.new()
	var x0 := (float(lanes.min()) - float(lanes.max())) * 0.5 * LANE_W - 0.95
	var x1 := (float(lanes.max()) - float(lanes.min())) * 0.5 * LANE_W + 0.95
	var width := x1 - x0
	Toon.part(n, Toon.cyl(0.12, 0.14, 2.7), Color("5c4033"), Vector3(x0, 1.35, 0))
	Toon.part(n, Toon.cyl(0.12, 0.14, 2.7), Color("5c4033"), Vector3(x1, 1.35, 0))
	Toon.part(n, Toon.box(Vector3(width, 1.2, 0.22)), zn.accent, Vector3(0, 1.95, 0))
	Toon.part(n, Toon.box(Vector3(width - 0.3, 0.16, 0.24)), Color("ffffff"), Vector3(0, 1.95, 0), Vector3.ZERO, false)
	_add_ent(n, "beam", lanes, 0.2, z, 0.0, 2.6, 1.35)


func _add_platform(lane: int, z: float, length: float, biome: int) -> void:
	var zn: Dictionary = ZONES[biome]
	var n := Node3D.new()
	var ramp_len := sqrt(RAMP_LEN * RAMP_LEN + PLAT_H * PLAT_H)
	Toon.part(n, Toon.box(Vector3(1.9, 0.25, ramp_len)), zn.accent, Vector3(0, PLAT_H * 0.5 - 0.12, -RAMP_LEN * 0.5), Vector3(atan2(PLAT_H, RAMP_LEN), 0, 0))
	Toon.part(n, Toon.box(Vector3(1.9, PLAT_H, length)), zn.crate, Vector3(0, PLAT_H * 0.5, -RAMP_LEN - length * 0.5))
	Toon.part(n, Toon.box(Vector3(1.94, 0.14, length + 0.02)), zn.accent, Vector3(0, PLAT_H - 0.05, -RAMP_LEN - length * 0.5), Vector3.ZERO, false)
	_add_ent(n, "plat", [lane], 0.0, z, 0.0, PLAT_H, 0.0, length)
	# la entidad debe quedar con el nodo en el borde frontal (z = 0 del nodo)
	n.position.x = _x(lane)
	for i in 5:
		_add_coin(_x(lane), PLAT_H + 0.95, z - RAMP_LEN - 1.5 - i * 1.8)


func _add_ball(lane: int, z: float, biome: int, extra: float) -> void:
	var zn: Dictionary = ZONES[biome]
	var n := Node3D.new()
	var roller := Node3D.new()
	roller.position = Vector3(0, 0.55, 0)
	n.add_child(roller)
	Toon.part(roller, Toon.sphere(0.55), zn.ball, Vector3.ZERO)
	Toon.part(roller, Toon.box(Vector3(0.3, 0.12, 0.3)), Color("00000033"), Vector3(0, 0.5, 0), Vector3(0.4, 0.2, 0.3), false)
	var e := _add_ent(n, "low", [lane], 0.55, z, extra, 1.0)
	e["roller"] = roller


# ---------- Patrones ----------
func _pick(w: Dictionary) -> String:
	var total := 0.0
	for k in w:
		total += float(w[k])
	var r := rng.randf() * total
	for k in w:
		r -= float(w[k])
		if r <= 0.0:
			return k
	return "coins"


func _spawn_pattern(z: float, sd: float) -> float:
	var eff_sd := sd
	var level := int(sd / ZONE_LEN)
	var biome := level % ZONES.size()
	if level_mode:
		eff_sd = float(lvl.n) * 45.0 + sd * 0.4
		level = (int(lvl.n) - 1) / 8
		biome = int(lvl.biome)
		if int(lvl.n) >= 3 and sd > float(lvl.goal) * 0.62 and not event_done.has(0):
			event_done[0] = true
			pending_events.append({"at": sd - 55.0, "text": ZONES[biome].event})
			return _spawn_event(z, biome)
	elif fmod(sd, ZONE_LEN) > ZONE_LEN * 0.82 and not event_done.has(level):
		event_done[level] = true
		pending_events.append({"at": sd - 55.0, "text": ZONES[biome].event})
		return _spawn_event(z, biome)

	var w := {"coins": 2.0, "low": 4.0, "beam": 3.0}
	if eff_sd > 110.0:
		w["enemy"] = 2.5 + level * 0.8
	if eff_sd > 150.0:
		w["plat"] = 1.5
	if eff_sd > 300.0 or level >= 1:
		w["double"] = 2.5
		w["moving"] = 2.0
	if level >= 1:
		w["wide"] = 2.0
		w["plat"] = 2.0
	if level >= 2:
		w["double"] = 4.0
		w["moving"] = 3.5
		w["wide"] = 3.0

	var kind := _pick(w)
	var lane := rng.randi_range(0, 2)
	match kind:
		"coins":
			_coin_line(lane, z, 8)
			if rng.randf() < 0.26:
				var pw := {"magnet": 1.0, "shield": 1.0, "x2": 1.8, "fly": 0.8, "life": 0.5, "w_coco": 1.5}
				if plevel >= 2 and (eff_sd > 150.0 or level >= 1):
					pw["w_boom"] = 1.2
				if plevel >= 4:
					pw["w_bomb"] = 1.0
				_add_pickup(_pick(pw), (lane + 1) % 3, z - 6.0)
			return 18.0
		"low":
			_add_low([lane], z, biome)
			_add_coin(_x(lane), 1.9, z + 1.8)
			_add_coin(_x(lane), 2.3, z)
			_add_coin(_x(lane), 1.9, z - 1.8)
			_coin_line((lane + rng.randi_range(1, 2)) % 3, z + 2.0, 5)
			return 5.0
		"beam":
			_add_beam([lane], z, biome)
			_coin_line(lane, z + 4.0, 4, 0.8)
			return 6.0
		"double":
			var free_lane := lane
			for l in 3:
				if l == free_lane:
					continue
				if rng.randf() < 0.5:
					_add_low([l], z, biome)
				else:
					_add_beam([l], z, biome)
			_coin_line(free_lane, z + 4.0, 6)
			return 8.0
		"wide":
			if rng.randf() < 0.5:
				_add_low([0, 1, 2], z, biome)
				for l in 3:
					_add_coin(_x(l), 2.1, z)
			else:
				_add_beam([0, 1, 2], z, biome)
				for l in 3:
					_add_coin(_x(l), 0.8, z + 3.0)
			return 6.0
		"plat":
			var length := rng.randf_range(8.0, 13.0)
			_add_platform(lane, z, length, biome)
			return RAMP_LEN + length + 2.0
		"enemy":
			_add_enemy(lane, z, biome)
			if level >= 1 and rng.randf() < 0.6:
				_add_enemy((lane + 1 + rng.randi_range(0, 1)) % 3, z - 6.0, biome)
			_coin_line((lane + 1) % 3, z + 2.0, 5)
			return 10.0
		"moving":
			_add_ball(lane, z, biome, 6.0)
			_coin_line((lane + 1) % 3, z + 2.0, 5)
			return 7.0
	return 6.0


func _spawn_event(z: float, biome: int) -> float:
	var rows := 7
	var lane := rng.randi_range(0, 2)
	for i in rows:
		lane = clampi(lane + rng.randi_range(-1, 1), 0, 2)
		var rz := z - i * 11.0
		for l in 3:
			if l != lane:
				_add_ball(l, rz, biome, 7.0)
		_coin_line(lane, rz + 3.0, 3, 0.95, 2.0)
	_add_pickup("shield", lane, z - rows * 11.0 - 4.0)
	return rows * 11.0 + 10.0


# ======================= Mundos nuevos, cielo, armas y efectos =======================
var level_mode := false
var lvl: Dictionary = {}
var projs: Array = []
var fx: Array = []
var finish_node: Node3D
var clouds_node: Node3D
var stars_node: Node3D
signal destroyed(count: int)


func _extra_zones() -> Array:
	return [
		{"name": "Ciudad Neón", "sky_top": Color("0a0420"), "sky_hor": Color("6d28d9"), "fog": Color("2e1065"),
			"track": Color("1e1b3a"), "left": Color("14102e"), "right": Color("1a1238"), "crate": Color("3730a3"),
			"accent": Color("22d3ee"), "event": "¡PERSECUCIÓN DE DRONES!", "ball": Color("38bdf8"),
			"edge": Color("f0abfc"), "lane": Color("22d3ee"), "glow": 1.0, "amb": Color(0.55, 0.5, 0.95), "sun": Color("a78bfa")},
		{"name": "Galaxia Lejana", "sky_top": Color("020617"), "sky_hor": Color("4338ca"), "fog": Color("1e1b4b"),
			"track": Color("475569"), "left": Color("0b1220"), "right": Color("0b1220"), "crate": Color("64748b"),
			"accent": Color("f97316"), "event": "¡LLUVIA DE ASTEROIDES!", "ball": Color("78716c"),
			"edge": Color("38bdf8"), "lane": Color("38bdf8"), "glow": 1.0, "amb": Color(0.6, 0.65, 0.95), "sun": Color("c7d2fe")},
		{"name": "Metrópolis Héroe", "sky_top": Color("2563eb"), "sky_hor": Color("bae6fd"), "fog": Color("dbeafe"),
			"track": Color("52525b"), "left": Color("71717a"), "right": Color("71717a"), "crate": Color("b91c1c"),
			"accent": Color("facc15"), "event": "¡LLUVIA DE ESCOMBROS!", "ball": Color("52525b"),
			"edge": Color("facc15"), "lane": Color("fde047"), "glow": 0.0, "amb": Color(0.86, 0.9, 1.0), "sun": Color.WHITE},
	]


func _setup_zones() -> void:
	ZONES.append_array(_extra_zones())
	for z in ZONES:
		if not z.has("edge"):
			z["edge"] = (z.track as Color).lightened(0.55)
		if not z.has("lane"):
			z["lane"] = (z.track as Color).lightened(0.4)
		if not z.has("glow"):
			z["glow"] = 0.0
		if not z.has("amb"):
			z["amb"] = Color(0.86, 0.9, 1.0)
		if not z.has("sun"):
			z["sun"] = Color.WHITE
	PICKS["life"] = [Color("f43f5e"), "VIDA"]
	PICKS["w_coco"] = [Color("a16207"), "COCO"]
	PICKS["w_boom"] = [Color("eab308"), "BUMERÁN"]
	PICKS["w_bomb"] = [Color("475569"), "BOMBA"]


func _zone_cur(i: int) -> Dictionary:
	var z: Dictionary = ZONES[i]
	return {"sky_top": z.sky_top, "sky_hor": z.sky_hor, "fog": z.fog, "amb": z.amb, "sun": z.sun}


func _biome_at(d: float) -> int:
	if level_mode:
		return int(lvl.biome)
	return int(d / ZONE_LEN) % ZONES.size()


func set_level(def: Dictionary) -> void:
	level_mode = true
	lvl = def


func set_endless() -> void:
	level_mode = false
	lvl = {}


func _reset_extra() -> void:
	for p in projs:
		(p.node as Node3D).queue_free()
	projs.clear()
	for f in fx:
		(f.node as Node3D).queue_free()
	fx.clear()
	if finish_node:
		finish_node.queue_free()
		finish_node = null


# ---------- Cielo: nubes y estrellas ----------
func _build_sky() -> void:
	clouds_node = Node3D.new()
	add_child(clouds_node)
	for i in 11:
		var c := Node3D.new()
		c.position = Vector3(rng.randf_range(-150, 150), rng.randf_range(26, 52), rng.randf_range(-170, -90))
		clouds_node.add_child(c)
		var wmat := Color("ffffff")
		for k in 4:
			Toon.glow(c, Toon.sphere(rng.randf_range(4.5, 8.0), rng.randf_range(4.0, 6.0)), wmat, Vector3(k * 6.0 - 9.0, rng.randf_range(-1, 1.5), rng.randf_range(-2, 2)), Vector3.ZERO, 0.92)
	stars_node = Node3D.new()
	add_child(stars_node)
	for i in 90:
		var col := Color("ffffff") if i % 3 != 0 else Color("a5f3fc")
		Toon.glow(stars_node, Toon.sphere(rng.randf_range(0.35, 0.8)), col, Vector3(rng.randf_range(-150, 150), rng.randf_range(10, 75), rng.randf_range(-130, -95)))
	stars_node.visible = false


func _sky_anim(delta: float) -> void:
	var lum := (cur.sky_top as Color).get_luminance()
	stars_node.visible = lum < 0.1
	clouds_node.visible = lum > 0.1
	if clouds_node.visible:
		for c in clouds_node.get_children():
			c.position.x += 1.4 * delta
			if c.position.x > 170.0:
				c.position.x -= 340.0


# ---------- Armas ----------
func fire(kind: String, x: float) -> void:
	var n := Node3D.new()
	n.position = Vector3(x, 1.05, -1.4)
	add_child(n)
	match kind:
		"coco":
			Toon.part(n, Toon.sphere(0.3), Color("7c4a1e"))
			Toon.part(n, Toon.sphere(0.08), Color("e7d5b3"), Vector3(0, 0.12, -0.26), Vector3.ZERO, false)
		"boom":
			Toon.part(n, Toon.box(Vector3(0.95, 0.13, 0.22)), Color("fbbf24"), Vector3(-0.3, 0, 0), Vector3(0, 0.55, 0))
			Toon.part(n, Toon.box(Vector3(0.95, 0.13, 0.22)), Color("f59e0b"), Vector3(0.3, 0, 0), Vector3(0, -0.55, 0))
		"punch":
			Toon.glow(n, Toon.sphere(0.34), Color("fde047"), Vector3.ZERO, Vector3.ZERO, 0.95)
			Toon.glow(n, Toon.sphere(0.2), Color("ffffff"))
		"bomb":
			Toon.part(n, Toon.sphere(0.36), Color("1f2937"))
			Toon.glow(n, Toon.sphere(0.12), Color("fb923c"), Vector3(0, 0.4, 0))
	projs.append({"node": n, "kind": kind, "pierce": 3 if kind == "boom" else 1, "dmg": {"punch": 1, "coco": 2, "boom": 1, "bomb": 3}.get(kind, 1)})
	Sfx.play("power", 1.6, -8.0)


func _lane_hit(e: Dictionary, px: float, w: float) -> bool:
	for l in e.lanes:
		if absf(_x(int(l)) - px) < w:
			return true
	return false


func destroy_ent(e: Dictionary) -> void:
	var pos: Vector3 = (e.node as Node3D).position + Vector3(0, 0.8, 0)
	var col: Color = Color("ffb703")
	_burst(pos, col, 9)
	remove_entity(e)
	destroyed.emit(1)


func _burst(pos: Vector3, col: Color, n: int = 8) -> void:
	for i in n:
		var m := Node3D.new()
		Toon.part(m, Toon.box(Vector3(0.24, 0.24, 0.24)), col if i % 2 == 0 else Color("ffffff"), Vector3.ZERO, Vector3.ZERO, false)
		m.position = pos
		add_child(m)
		fx.append({"node": m, "vel": Vector3(rng.randf_range(-4, 4), rng.randf_range(2, 7), rng.randf_range(-5, 2)), "life": 0.7, "grow": 0.0})


func _explode(pos: Vector3) -> void:
	var f := Node3D.new()
	Toon.glow(f, Toon.sphere(1.0), Color("fb923c"), Vector3.ZERO, Vector3.ZERO, 0.55)
	f.position = pos
	add_child(f)
	fx.append({"node": f, "vel": Vector3.ZERO, "life": 0.45, "grow": 14.0})
	_burst(pos, Color("fb923c"), 12)
	var cnt := 0
	for e in ents.duplicate():
		if e.kind == "plat":
			continue
		if absf((e.node as Node3D).position.z - pos.z) < 7.0:
			_kill_or_destroy(e)
			cnt += 1
	Sfx.play("hit", 1.3, -4.0)


func _update_projs(delta: float) -> void:
	for i in range(projs.size() - 1, -1, -1):
		var p: Dictionary = projs[i]
		var n: Node3D = p.node
		n.position.z -= 60.0 * delta
		n.rotation.y += 14.0 * delta if p.kind == "boom" else 0.0
		n.rotation.x -= 10.0 * delta if p.kind != "boom" else 0.0
		var dead := false
		for e in ents.duplicate():
			if e.kind == "plat":
				continue
			var ez: float = (e.node as Node3D).position.z
			if absf(ez - n.position.z) > 1.5 or not _lane_hit(e, n.position.x, 1.0):
				continue
			if p.kind == "bomb":
				_explode(n.position)
				dead = true
				break
			if _proj_hit(p, e):
				dead = true
				break
		if p.kind == "bomb" and n.position.z < -34.0 and not dead:
			_explode(n.position)
			dead = true
		if dead or n.position.z < -80.0 or (p.kind == "punch" and n.position.z < -26.0):
			n.queue_free()
			projs.remove_at(i)


func _update_fx(delta: float, move: float) -> void:
	for i in range(fx.size() - 1, -1, -1):
		var f: Dictionary = fx[i]
		var n: Node3D = f.node
		f["life"] = float(f.life) - delta
		var v: Vector3 = f.vel
		v.y -= 18.0 * delta
		f["vel"] = v
		n.position += v * delta
		n.position.z += move
		if float(f.grow) > 0.0:
			n.scale += Vector3.ONE * float(f.grow) * delta
		else:
			n.scale = Vector3.ONE * clampf(float(f.life) / 0.7, 0.05, 1.0)
		if float(f.life) <= 0.0:
			n.queue_free()
			fx.remove_at(i)


# ---------- Meta del nivel ----------
func _build_finish() -> Node3D:
	var n := Node3D.new()
	for sx in [-4.4, 4.4]:
		Toon.part(n, Toon.box(Vector3(0.7, 7.0, 0.7)), Color("f8fafc"), Vector3(sx, 3.5, 0))
	for i in 12:
		var dark := i % 2 == 0
		Toon.part(n, Toon.box(Vector3(0.72, 0.6, 0.5)), Color("111827") if dark else Color("f8fafc"), Vector3(-3.96 + i * 0.72, 6.7 + (0.3 if dark else -0.3) * 0.0, 0), Vector3.ZERO, false)
		Toon.part(n, Toon.box(Vector3(0.72, 0.6, 0.5)), Color("f8fafc") if dark else Color("111827"), Vector3(-3.96 + i * 0.72, 6.1, 0), Vector3.ZERO, false)
	for i in 8:
		Toon.glow(n, Toon.box(Vector3(1.1, 0.02, 1.1)), Color("111827") if i % 2 == 0 else Color("f8fafc"), Vector3(-3.85 + i * 1.1, 0.03, 0))
	Toon.glow(n, Toon.box(Vector3(8.8, 0.35, 0.3)), Color("22d3ee"), Vector3(0, 5.65, 0.2))
	return n


func _update_finish(dist: float, move: float) -> void:
	if not level_mode:
		return
	if finish_node == null:
		if float(lvl.goal) - dist < SPAWN_AHEAD - 5.0:
			finish_node = _build_finish()
			finish_node.position = Vector3(0, 0, -(float(lvl.goal) - dist))
			add_child(finish_node)
	else:
		finish_node.position.z += move
		if finish_node.position.z > 14.0:
			finish_node.queue_free()
			finish_node = null
			lvl["goal"] = 1e9


# ---------- Decorados nuevos ----------
func _building(p: Node3D, pos: Vector3, side: float, w: float, h: float, dd: float, wall: Color, win: Color, nwin: int) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	p.add_child(n)
	Toon.part(n, Toon.box(Vector3(w, h, dd)), wall, Vector3(0, h * 0.5, 0))
	var fx0 := -side * (w * 0.5 + 0.04)
	for i in nwin:
		var wy := rng.randf_range(1.2, h - 0.8)
		var wz := rng.randf_range(-dd * 0.4, dd * 0.4)
		Toon.glow(n, Toon.box(Vector3(0.06, 0.55, 0.7)), win, Vector3(fx0, wy, wz))
	return n


func _mountain(p: Node3D, side: float, col: Color, snow: bool) -> void:
	var x := side * rng.randf_range(48.0, 72.0)
	var h := rng.randf_range(16.0, 30.0)
	var r := h * rng.randf_range(0.8, 1.2)
	var n := Node3D.new()
	n.position = Vector3(x, 0, rng.randf_range(-10, 10))
	p.add_child(n)
	Toon.part(n, Toon.cyl(0.0, r, h), col, Vector3(0, h * 0.5 - 1.0, 0))
	if snow:
		Toon.part(n, Toon.cyl(0.0, r * 0.28, h * 0.28), Color("f8fafc"), Vector3(0, h * 0.86 - 1.0, 0), Vector3.ZERO, false)


func _decor_beach(d: Node3D, side: float) -> void:
	for i in 3:
		var x: float = side * rng.randf_range(6.0, 15.0)
		var zz := (float(i) + rng.randf()) * (SEG_LEN / 3.0) - SEG_LEN * 0.5
		_palm(d, Vector3(x, 0, zz))
	if rng.randf() < 0.5:
		_umbrella(d, Vector3(side * rng.randf_range(4.8, 6.0), 0, rng.randf_range(-10, 10)))
	if side < 0.0:
		if rng.randf() < 0.45:
			_boat(d, Vector3(rng.randf_range(-24.0, -10.0), 0, rng.randf_range(-10, 10)))
	else:
		Toon.part(d, Toon.sphere(3.0, 1.6), Color("f0d9a0"), Vector3(rng.randf_range(16.0, 26.0), 0, rng.randf_range(-10, 10)), Vector3.ZERO, false)
	_torch(d, Vector3(side * 4.3, 0, rng.randf_range(-9, 9)))
	if rng.randf() < 0.4:
		_mountain(d, side, Color("3a7d44"), false)


func _boat(p: Node3D, pos: Vector3) -> void:
	var n := Node3D.new()
	n.position = pos + Vector3(0, 0.1, 0)
	n.rotation.y = rng.randf_range(-0.5, 0.5)
	p.add_child(n)
	Toon.part(n, Toon.box(Vector3(1.4, 0.5, 3.4)), Color("c2410c"), Vector3(0, 0.25, 0))
	Toon.part(n, Toon.cyl(0.05, 0.05, 3.6), Color("f8fafc"), Vector3(0, 2.2, 0), Vector3.ZERO, false)
	Toon.part(n, Toon.box(Vector3(0.06, 2.6, 1.8)), Color("f8fafc"), Vector3(0, 2.0, 0.6), Vector3.ZERO, false)


func _torch(p: Node3D, pos: Vector3) -> void:
	Toon.part(p, Toon.cyl(0.06, 0.08, 1.7), Color("6b4423"), pos + Vector3(0, 0.85, 0), Vector3.ZERO, false)
	Toon.glow(p, Toon.sphere(0.2, 0.4), Color("fb923c"), pos + Vector3(0, 1.85, 0))


func _decor_jungle(d: Node3D, side: float) -> void:
	for i in 3:
		var x: float = side * rng.randf_range(6.0, 15.0)
		var zz := (float(i) + rng.randf()) * (SEG_LEN / 3.0) - SEG_LEN * 0.5
		_jungle_tree(d, Vector3(x, 0, zz))
	_bush(d, Vector3(side * rng.randf_range(4.4, 5.4), 0, rng.randf_range(-10, 10)))
	if rng.randf() < 0.6:
		_mushroom(d, Vector3(side * rng.randf_range(4.6, 7.0), 0, rng.randf_range(-10, 10)))
	if rng.randf() < 0.5:
		_fern(d, Vector3(side * rng.randf_range(4.6, 8.0), 0, rng.randf_range(-10, 10)))
	if rng.randf() < 0.22:
		var n := Node3D.new()
		n.position = Vector3(side * 38.0, 0, rng.randf_range(-8, 8))
		d.add_child(n)
		Toon.part(n, Toon.box(Vector3(10, 22, 7)), Color("6b4a2b"), Vector3(0, 10, 0))
		Toon.glow(n, Toon.box(Vector3(2.2, 20, 0.3)), Color("bae6fd"), Vector3(-side * 4.0, 10, 0), Vector3.ZERO, 0.8)
	if rng.randf() < 0.4:
		_mountain(d, side, Color("2f6f4f"), false)


func _mushroom(p: Node3D, pos: Vector3) -> void:
	Toon.part(p, Toon.cyl(0.14, 0.18, 0.7), Color("f8fafc"), pos + Vector3(0, 0.35, 0), Vector3.ZERO, false)
	Toon.part(p, Toon.sphere(0.55, 0.6), Color("ef4444"), pos + Vector3(0, 0.8, 0))
	Toon.part(p, Toon.sphere(0.09), Color("f8fafc"), pos + Vector3(0.2, 1.0, -0.2), Vector3.ZERO, false)


func _fern(p: Node3D, pos: Vector3) -> void:
	for i in 5:
		var pv := Node3D.new()
		pv.position = pos
		pv.rotation.y = i * TAU / 5.0
		p.add_child(pv)
		Toon.part(pv, Toon.box(Vector3(1.5, 0.06, 0.4)), Color("4ade80") if i % 2 == 0 else Color("22c55e"), Vector3(0.7, 0.55, 0), Vector3(0, 0, 0.5), false)


func _decor_colonial(d: Node3D, side: float) -> void:
	for i in 3:
		var zz := (float(i) + rng.randf()) * (SEG_LEN / 3.0) - SEG_LEN * 0.5
		_house(d, Vector3(side * rng.randf_range(7.5, 11.0), 0, zz), side)
	_lamp(d, Vector3(side * 4.3, 0, rng.randf_range(-6, 6)))
	if rng.randf() < 0.18:
		var n := Node3D.new()
		n.position = Vector3(side * rng.randf_range(16.0, 24.0), 0, rng.randf_range(-8, 8))
		d.add_child(n)
		Toon.part(n, Toon.box(Vector3(4, 13, 4)), Color("f1e3c8"), Vector3(0, 6.5, 0))
		Toon.part(n, Toon.cyl(0.0, 3.2, 4.0), Color("b45309"), Vector3(0, 15, 0))
		Toon.part(n, Toon.box(Vector3(1.0, 1.8, 0.2)), Color("1e293b"), Vector3(-side * 2.05, 9.5, 0), Vector3.ZERO, false)
	if side < 0.0 and rng.randf() < 0.55:
		_bunting(d, rng.randf_range(-9, 9))
	if rng.randf() < 0.35:
		_mountain(d, side, Color("b8734a"), false)


func _bunting(p: Node3D, z: float) -> void:
	var cols := [Color("ef4444"), Color("facc15"), Color("22c55e"), Color("3b82f6"), Color("ec4899")]
	for sx in [-4.4, 4.4]:
		Toon.part(p, Toon.cyl(0.07, 0.09, 4.6), Color("5c4033"), Vector3(sx, 2.3, z), Vector3.ZERO, false)
	Toon.part(p, Toon.box(Vector3(8.8, 0.04, 0.04)), Color("1e293b"), Vector3(0, 4.45, z), Vector3.ZERO, false)
	for i in 9:
		Toon.part(p, Toon.box(Vector3(0.5, 0.5, 0.04)), cols[i % cols.size()], Vector3(-3.9 + i * 0.98, 4.15, z), Vector3(0, 0, PI / 4), false)


func _decor_neon(d: Node3D, side: float) -> void:
	var neon := [Color("22d3ee"), Color("f472b6"), Color("a78bfa"), Color("facc15"), Color("4ade80")]
	for i in 2:
		var zz := (float(i) + rng.randf()) * (SEG_LEN / 2.0) - SEG_LEN * 0.5
		var h := rng.randf_range(7.0, 18.0)
		var w := rng.randf_range(3.5, 5.0)
		var wall := Color("1e1b4b") if rng.randf() < 0.5 else Color("172554")
		var b := _building(d, Vector3(side * rng.randf_range(7.5, 10.0), 0, zz), side, w, h, 4.6, wall, neon[rng.randi() % neon.size()], 9)
		var nc: Color = neon[rng.randi() % neon.size()]
		Toon.glow(b, Toon.box(Vector3(0.12, 0.3, w * 0.9)), nc, Vector3(-side * (w * 0.5 + 0.05), h + 0.1, 0))
		if rng.randf() < 0.6:
			Toon.glow(b, Toon.box(Vector3(0.1, 1.2, 2.4)), neon[rng.randi() % neon.size()], Vector3(-side * (w * 0.5 + 0.7), h * 0.5, 0))
	var far_h := rng.randf_range(24.0, 48.0)
	Toon.part(d, Toon.box(Vector3(6, far_h, 6)), Color("0f0a2e"), Vector3(side * rng.randf_range(18.0, 34.0), far_h * 0.5, rng.randf_range(-10, 10)), Vector3.ZERO, false)
	var lp := Vector3(side * 4.3, 0, rng.randf_range(-6, 6))
	Toon.part(d, Toon.cyl(0.07, 0.09, 3.6), Color("1e293b"), lp + Vector3(0, 1.8, 0), Vector3.ZERO, false)
	Toon.glow(d, Toon.sphere(0.3), neon[rng.randi() % neon.size()], lp + Vector3(0, 3.7, 0))
	if side < 0.0 and rng.randf() < 0.3:
		var ac: Color = neon[rng.randi() % neon.size()]
		var az := rng.randf_range(-8, 8)
		Toon.glow(d, Toon.box(Vector3(0.25, 6.0, 0.25)), ac, Vector3(-4.6, 3.0, az))
		Toon.glow(d, Toon.box(Vector3(0.25, 6.0, 0.25)), ac, Vector3(4.6, 3.0, az))
		Toon.glow(d, Toon.box(Vector3(9.4, 0.25, 0.25)), ac, Vector3(0, 6.0, az))


func _decor_space(d: Node3D, side: float) -> void:
	for i in 2:
		var x: float = side * rng.randf_range(6.0, 22.0)
		var zz := (float(i) + rng.randf()) * (SEG_LEN / 2.0) - SEG_LEN * 0.5
		if rng.randf() < 0.5:
			var h := rng.randf_range(3.0, 7.0)
			Toon.part(d, Toon.cyl(0.25, 0.4, h), Color("94a3b8"), Vector3(x, h * 0.5, zz))
			Toon.glow(d, Toon.torus(0.45, 0.6), Color("38bdf8"), Vector3(x, h * 0.7, zz))
			Toon.glow(d, Toon.sphere(0.3), Color("f97316"), Vector3(x, h + 0.3, zz))
		else:
			Toon.part(d, Toon.sphere(rng.randf_range(0.9, 2.2), rng.randf_range(0.9, 1.6)), Color("6b7280"), Vector3(x, rng.randf_range(1.5, 8.0), zz))
	if rng.randf() < 0.45:
		var pn := Node3D.new()
		pn.position = Vector3(side * rng.randf_range(40.0, 66.0), rng.randf_range(10.0, 28.0), rng.randf_range(-10, 10))
		d.add_child(pn)
		var pc: Color = [Color("f97316"), Color("a855f7"), Color("22d3ee"), Color("ef4444")][rng.randi() % 4]
		var pr := rng.randf_range(6.0, 12.0)
		Toon.part(pn, Toon.sphere(pr), pc, Vector3.ZERO)
		Toon.glow(pn, Toon.torus(pr * 1.3, pr * 1.5), Color("fde68a"), Vector3.ZERO, Vector3(0.4, 0, 0.3), 0.7)
	if side > 0.0 and rng.randf() < 0.3:
		var m := Node3D.new()
		m.position = Vector3(rng.randf_range(14.0, 26.0), rng.randf_range(4.0, 12.0), rng.randf_range(-8, 8))
		d.add_child(m)
		Toon.part(m, Toon.cyl(1.4, 1.4, 5.0), Color("e2e8f0"), Vector3.ZERO, Vector3(0, 0, PI / 2))
		for k in 4:
			Toon.glow(m, Toon.sphere(0.25), Color("fde047"), Vector3(-1.8 + k * 1.2, 0.2, -1.4))


func _decor_hero(d: Node3D, side: float) -> void:
	var walls := [Color("64748b"), Color("475569"), Color("94a3b8"), Color("7c2d12"), Color("1e3a8a")]
	for i in 2:
		var zz := (float(i) + rng.randf()) * (SEG_LEN / 2.0) - SEG_LEN * 0.5
		var h := rng.randf_range(9.0, 24.0)
		var w := rng.randf_range(3.5, 5.5)
		var b := _building(d, Vector3(side * rng.randf_range(7.5, 11.0), 0, zz), side, w, h, 5.0, walls[rng.randi() % walls.size()], Color("fde68a"), 8)
		if rng.randf() < 0.4:
			Toon.part(b, Toon.cyl(0.05, 0.08, 3.0), Color("94a3b8"), Vector3(0, h + 1.5, 0), Vector3.ZERO, false)
	var th := rng.randf_range(34.0, 60.0)
	var tw := Vector3(side * rng.randf_range(22.0, 40.0), 0, rng.randf_range(-10, 10))
	Toon.part(d, Toon.box(Vector3(7, th, 7)), Color("1e40af"), tw + Vector3(0, th * 0.5, 0))
	Toon.glow(d, Toon.box(Vector3(2.6, 2.6, 0.3)), Color("fde047"), tw + Vector3(-side * 3.6, th * 0.8, 0))
	if rng.randf() < 0.5:
		var bp := Vector3(side * rng.randf_range(5.2, 6.2), 0, rng.randf_range(-8, 8))
		Toon.part(d, Toon.cyl(0.1, 0.12, 5.0), Color("334155"), bp + Vector3(0, 2.5, 0), Vector3.ZERO, false)
		Toon.part(d, Toon.box(Vector3(0.2, 2.2, 3.4)), Color("0f172a"), bp + Vector3(0, 5.6, 0))
		Toon.glow(d, Toon.box(Vector3(0.1, 1.6, 2.8)), [Color("ef4444"), Color("22c55e"), Color("3b82f6")][rng.randi() % 3], bp + Vector3(-side * 0.16, 5.6, 0))
	if rng.randf() < 0.4:
		var sp := Vector3(side * rng.randf_range(10.0, 18.0), 0, rng.randf_range(-8, 8))
		Toon.glow(d, Toon.cyl(0.1, 1.4, 40.0), Color("fef9c3"), sp + Vector3(0, 20, 0), Vector3(0, 0, -side * 0.12), 0.18)
	if rng.randf() < 0.3:
		_mountain(d, side, Color("64748b"), true)


# ======================= Enemigos y combate =======================
signal enemy_down
var plevel := 1


func _proj_hit(p: Dictionary, e: Dictionary) -> bool:
	var n: Node3D = p.node
	if e.has("enemy"):
		e["hp"] = int(e.hp) - int(p.dmg)
		if int(e.hp) <= 0:
			_kill_enemy(e)
		else:
			_burst((e.node as Node3D).position + Vector3(0, 1.3, 0), Color("ffffff"), 4)
			(e.node as Node3D).position.z -= 1.5
	elif p.kind == "punch":
		_burst(n.position, Color("fde047"), 4)
		return true
	else:
		destroy_ent(e)
	p["pierce"] = int(p.pierce) - 1
	return int(p.pierce) <= 0


func _kill_enemy(e: Dictionary) -> void:
	var pos: Vector3 = (e.node as Node3D).position
	_burst(pos + Vector3(0, 1.2, 0), Color("ef4444"), 12)
	for i in 3:
		_add_coin(pos.x, 1.0 + i * 0.3, pos.z + i * 0.8 - 0.8)
	remove_entity(e)
	enemy_down.emit()


func _kill_or_destroy(e: Dictionary) -> void:
	if e.has("enemy"):
		_kill_enemy(e)
	else:
		destroy_ent(e)


func _anim_legs(e: Dictionary) -> void:
	var t := Time.get_ticks_msec() * 0.012
	var legs: Array = e.legs
	for i in legs.size():
		(legs[i] as Node3D).rotation.x = sin(t + i * PI) * 0.9


func blast(length: float) -> void:
	var f := Node3D.new()
	Toon.glow(f, Toon.sphere(1.0), Color("fde047"), Vector3.ZERO, Vector3.ZERO, 0.5)
	f.position = Vector3(0, 1.2, -10.0)
	add_child(f)
	fx.append({"node": f, "vel": Vector3.ZERO, "life": 0.55, "grow": 30.0})
	for e in ents.duplicate():
		if e.kind == "plat":
			continue
		var z: float = (e.node as Node3D).position.z
		if z > -length and z < 3.0:
			_kill_or_destroy(e)
	Sfx.play("hit", 0.8, -2.0)


func coin_rain() -> void:
	for lane in 3:
		for i in 12:
			_add_coin(_x(lane), 0.95, -14.0 - i * 2.0)


func _add_enemy(lane: int, z: float, biome: int) -> void:
	var zn: Dictionary = ZONES[biome]
	var n := Node3D.new()
	var skin: Color = [Color("c68642"), Color("e0ac69"), Color("8d5524")][rng.randi() % 3]
	var cloth: Color = (zn.accent as Color).darkened(0.35)
	if biome == 4:
		skin = Color("86efac")
		cloth = Color("7c3aed")
	var legs: Array = []
	for sx in [-0.18, 0.18]:
		var pv := Node3D.new()
		pv.position = Vector3(sx, 0.85, 0)
		n.add_child(pv)
		Toon.part(pv, Toon.capsule(0.13, 0.85), cloth.darkened(0.3), Vector3(0, -0.4, 0))
		legs.append(pv)
	Toon.part(n, Toon.capsule(0.32, 1.05), cloth, Vector3(0, 1.3, 0))
	Toon.part(n, Toon.sphere(0.29), skin, Vector3(0, 2.05, 0))
	Toon.part(n, Toon.box(Vector3(0.1, 0.05, 0.04)), Color("111111"), Vector3(-0.1, 2.12, -0.27), Vector3(0, 0, -0.35), false)
	Toon.part(n, Toon.box(Vector3(0.1, 0.05, 0.04)), Color("111111"), Vector3(0.1, 2.12, -0.27), Vector3(0, 0, 0.35), false)
	Toon.part(n, Toon.capsule(0.1, 0.75), skin, Vector3(-0.44, 1.4, -0.25), Vector3(-0.9, 0, 0))
	Toon.part(n, Toon.capsule(0.1, 0.75), skin, Vector3(0.44, 1.4, -0.25), Vector3(-0.9, 0, 0))
	match biome:
		0:
			Toon.part(n, Toon.cyl(0.3, 0.3, 0.1), Color("dc2626"), Vector3(0, 2.28, 0), Vector3.ZERO, false)
		1:
			Toon.part(n, Toon.box(Vector3(0.06, 0.4, 0.12)), Color("22c55e"), Vector3(0.12, 2.5, 0.05), Vector3(0, 0, -0.3))
		2:
			Toon.part(n, Toon.box(Vector3(0.5, 0.14, 0.06)), Color("111827"), Vector3(0, 2.1, -0.27), Vector3.ZERO, false)
			Toon.part(n, Toon.cyl(0.4, 0.4, 0.04), Color("57534e"), Vector3(0, 2.3, 0))
		3:
			Toon.glow(n, Toon.box(Vector3(0.5, 0.1, 0.05)), Color("22d3ee"), Vector3(0, 2.1, -0.28))
		4:
			for sx in [-0.12, 0.12]:
				Toon.part(n, Toon.cyl(0.015, 0.015, 0.35), Color("a3e635"), Vector3(sx, 2.45, 0), Vector3.ZERO, false)
				Toon.glow(n, Toon.sphere(0.06), Color("f472b6"), Vector3(sx, 2.65, 0))
		5:
			Toon.part(n, Toon.box(Vector3(0.52, 0.2, 0.06)), Color("0f172a"), Vector3(0, 2.1, -0.26))
	if biome >= 3:
		Toon.glow(n, Toon.cyl(0.04, 0.04, 1.1), Color("ef4444"), Vector3(-0.44, 1.4, -0.65), Vector3(PI / 2, 0, 0))
	else:
		Toon.part(n, Toon.cyl(0.07, 0.09, 0.9), Color("6b4423"), Vector3(-0.44, 1.45, -0.6), Vector3(PI / 2, 0, 0), false)
	n.rotation.y = PI
	var e := _add_ent(n, "low", [lane], 0.5, z, 3.5, 2.4)
	e["enemy"] = true
	e["hp"] = 3 if level_mode and int(lvl.n) > 12 else 2
	e["legs"] = legs
