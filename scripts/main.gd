extends Node3D
## Director del juego: estados, entrada, cámara, colisiones, power-ups, misiones y perseguidor.

const WorldScript = preload("res://scripts/world.gd")
const PlayerScript = preload("res://scripts/player.gd")
const HudScript = preload("res://scripts/hud.gd")
const Toon = preload("res://scripts/toon.gd")

enum State { MENU, PLAY, DEAD, PAUSE }

const ZONE_LEN := 500.0

var state: int = State.MENU
var world
var player
var hud
var camera: Camera3D
var chaser: Node3D
var chaser_legs: Array = []

var cam_mode := "menu"
var cam_look := Vector3(0, 1.3, 0)
var speed := 0.0
var dist := 0.0
var score := 0.0
var zone := 0
var run: Dictionary = {}
var timers := {"magnet": 0.0, "shield": 0.0, "x2": 0.0, "fly": 0.0}
var stumble_t := 0.0
var invuln_t := 0.0
var clean_dist := 0.0
var chaser_z := 8.0
var dead_t := 0.0
var over_shown := false
var mission_t := 0.0
var swipe_start := Vector2.ZERO
var swiping := false
var anim_t := 0.0

# --- modo de pruebas (solo con argumentos de línea de comandos) ---
var autoplay := false
var shot_path := ""
var shot_frame := 0
var frame_count := 0
var bot_t := 0.0
var test_page := ""
var test_look: Dictionary = {}


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a == "--autoplay":
			autoplay = true
		elif a.begins_with("--shot="):
			shot_path = a.substr(7)
		elif a.begins_with("--shotframe="):
			shot_frame = int(a.substr(12))
		elif a.begins_with("--page="):
			test_page = a.substr(7)
		elif a.begins_with("--look="):
			for pair in a.substr(7).split(","):
				var kv := pair.split(":")
				if kv.size() == 2:
					test_look[kv[0]] = kv[1]

	world = WorldScript.new()
	add_child(world)
	player = PlayerScript.new()
	add_child(player)
	player.set_look(GameState.look())
	player.jumped.connect(func():
		run["jumps"] = int(run.get("jumps", 0)) + 1
		Sfx.play("jump"))
	player.slid.connect(func():
		run["slides"] = int(run.get("slides", 0)) + 1
		Sfx.play("slide"))
	player.landed.connect(func(): Sfx.play("click", 0.6, -6.0))
	chaser = _build_chaser()
	add_child(chaser)
	camera = Camera3D.new()
	camera.fov = 66.0
	camera.far = 280.0
	add_child(camera)
	camera.current = true
	camera.position = Vector3(1.9, 1.9, 4.2)

	hud = HudScript.new()
	add_child(hud)
	hud.play_pressed.connect(_start_game)
	hud.retry_pressed.connect(_start_game)
	hud.menu_pressed.connect(_enter_menu)
	hud.pause_pressed.connect(_toggle_pause)
	hud.resume_pressed.connect(_toggle_pause)
	hud.look_preview.connect(func(l): player.set_look(l))
	hud.update_pressed.connect(_open_update)
	hud.page_opened.connect(func(page):
		cam_mode = "chars" if page == "shop" else "menu"
		player.spin = page == "shop")
	world.event_warning.connect(func(t):
		hud.banner(t, Color("ff7b54"))
		Sfx.play("zone"))

	_enter_menu()
	if test_page != "":
		hud.open_page(test_page)
	if not test_look.is_empty():
		player.set_look(GameState.look(test_look))
	_check_update()


# ---------- Actualizaciones desde GitHub ----------
const REPO := "dysasterkj/fuga-en-el-tropico"
var update_url := ""


func _version_newer(remote: String, local: String) -> bool:
	var r := remote.trim_prefix("v").split(".")
	var l := local.trim_prefix("v").split(".")
	for i in 3:
		var a := int(r[i]) if i < r.size() else 0
		var b := int(l[i]) if i < l.size() else 0
		if a != b:
			return a > b
	return false


func _check_update() -> void:
	if autoplay or shot_path != "":
		return
	var http := HTTPRequest.new()
	http.timeout = 8.0
	add_child(http)
	http.request_completed.connect(func(result, code, _h, body):
		http.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			return
		var json = JSON.parse_string(body.get_string_from_utf8())
		if not (json is Dictionary):
			return
		var tag := String(json.get("tag_name", ""))
		var local := String(ProjectSettings.get_setting("application/config/version", "0.0.0"))
		if tag == "" or not _version_newer(tag, local):
			return
		update_url = String(json.get("html_url", "https://github.com/%s/releases/latest" % REPO))
		for a in json.get("assets", []):
			if String(a.get("name", "")).ends_with(".apk"):
				update_url = String(a.get("browser_download_url", update_url))
		hud.set_update(tag))
	http.request("https://api.github.com/repos/%s/releases/latest" % REPO, ["User-Agent: fuga-en-el-tropico"])


func _open_update() -> void:
	if update_url != "":
		OS.shell_open(update_url)


# ---------- Perseguidor ----------
func _build_chaser() -> Node3D:
	var c := Node3D.new()
	var fur := Color("ffa62b")
	var dark := Color("4a2c14")
	Toon.part(c, Toon.capsule(0.4, 1.5), fur, Vector3(0, 0.8, 0), Vector3(PI / 2, 0, 0))
	Toon.part(c, Toon.sphere(0.36), fur, Vector3(0, 1.05, -0.95))
	Toon.part(c, Toon.sphere(0.17), Color("fff1d6"), Vector3(0, 0.95, -1.25))
	Toon.part(c, Toon.sphere(0.07), dark, Vector3(0, 1.0, -1.4), Vector3.ZERO, false)
	Toon.part(c, Toon.sphere(0.12), fur, Vector3(-0.24, 1.38, -0.9))
	Toon.part(c, Toon.sphere(0.12), fur, Vector3(0.24, 1.38, -0.9))
	Toon.part(c, Toon.sphere(0.06), Color("ffee00"), Vector3(-0.15, 1.12, -1.26), Vector3.ZERO, false)
	Toon.part(c, Toon.sphere(0.06), Color("ffee00"), Vector3(0.15, 1.12, -1.26), Vector3.ZERO, false)
	for i in 5:
		Toon.part(c, Toon.sphere(0.1), dark, Vector3(((i % 2) - 0.5) * 0.5, 1.12, 0.45 - i * 0.3), Vector3.ZERO, false)
	Toon.part(c, Toon.capsule(0.08, 1.0), fur, Vector3(0, 1.0, 1.0), Vector3(-0.9, 0, 0))
	var i := 0
	for sx in [-0.22, 0.22]:
		for sz in [-0.5, 0.5]:
			var pv := Node3D.new()
			pv.position = Vector3(sx, 0.55, sz)
			c.add_child(pv)
			Toon.part(pv, Toon.capsule(0.11, 0.62), fur, Vector3(0, -0.28, 0))
			chaser_legs.append(pv)
			i += 1
	c.visible = false
	return c


# ---------- Estados ----------
func _enter_menu() -> void:
	state = State.MENU
	player.reset()
	player.set_look(GameState.look())
	player.idle = true
	Sfx.play_music(3)
	world.reset()
	world.advance(0.0, 0.0, 0.0, Vector3.ZERO, false)
	chaser.visible = false
	cam_mode = "menu"
	run = _new_run()
	hud.show_menu()


func _new_run() -> Dictionary:
	return {"coins": 0, "jumps": 0, "slides": 0, "dist": 0.0, "powerups": 0, "zone": 0, "score": 0, "clean_best": 0.0}


func _start_game() -> void:
	state = State.PLAY
	player.reset()
	player.idle = false
	world.reset()
	run = _new_run()
	speed = 12.0
	dist = 0.0
	score = 0.0
	zone = 0
	for k in timers:
		timers[k] = 0.0
	stumble_t = 0.0
	invuln_t = 0.0
	clean_dist = 0.0
	chaser_z = 8.0
	dead_t = 0.0
	over_shown = false
	mission_t = 0.0
	cam_mode = "play"
	player.spin = false
	Sfx.play_music(0)
	Sfx.play("zone")
	chaser.visible = false
	world.advance(0.0, 0.0, 0.0, Vector3.ZERO, false)
	hud.show_game()
	hud.banner("¡ZONA 1 · %s!" % String(world.zone_name(0)).to_upper(), Color("ffc233"))


func _toggle_pause() -> void:
	if state == State.PLAY:
		state = State.PAUSE
		hud.show_pause()
	elif state == State.PAUSE:
		state = State.PLAY
		hud.show_game()


# ---------- Entrada ----------
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_LEFT, KEY_A: _cmd_lane(-1)
			KEY_RIGHT, KEY_D: _cmd_lane(1)
			KEY_UP, KEY_W, KEY_SPACE:
				if state == State.MENU:
					_start_game()
				elif state == State.DEAD and over_shown:
					_start_game()
				else:
					_cmd_jump()
			KEY_DOWN, KEY_S: _cmd_slide()
			KEY_ESCAPE, KEY_P: _toggle_pause()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		swiping = event.pressed
		swipe_start = event.position
	elif event is InputEventMouseMotion and swiping:
		var d: Vector2 = event.position - swipe_start
		if d.length() > 45.0:
			if absf(d.x) > absf(d.y):
				_cmd_lane(1 if d.x > 0.0 else -1)
			elif d.y < 0.0:
				_cmd_jump()
			else:
				_cmd_slide()
			swiping = false


func _cmd_lane(d: int) -> void:
	if state == State.PLAY:
		player.move_lane(d)


func _cmd_jump() -> void:
	if state == State.PLAY:
		player.jump()


func _cmd_slide() -> void:
	if state == State.PLAY:
		player.slide()


# ---------- Bucle ----------
func _process(delta: float) -> void:
	anim_t += delta
	frame_count += 1
	match state:
		State.MENU:
			player.step(delta, 0.0, 0.0)
			if autoplay and frame_count > 10:
				_start_game()
		State.PLAY:
			if autoplay:
				_bot(delta)
			_play(minf(delta, 0.05))
		State.DEAD:
			_dead(delta)
	_animate_chaser(delta)
	_update_camera(delta)
	if shot_path != "" and frame_count == shot_frame:
		_take_shot()


func _take_shot() -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(shot_path)
	print("[test] screenshot saved: ", shot_path)
	get_tree().quit()


func _play(delta: float) -> void:
	for k in timers:
		var before: float = timers[k]
		timers[k] = maxf(0.0, before - delta)
		if k == "fly" and before > 0.0 and timers[k] <= 0.0:
			player.set_flying(false)
			invuln_t = 1.6
	stumble_t = maxf(0.0, stumble_t - delta)
	invuln_t = maxf(0.0, invuln_t - delta)

	var target := 12.0 + minf(dist * 0.0035, 16.0)
	if stumble_t > 0.0:
		target *= 0.85
	if timers.fly > 0.0:
		target *= 1.2
	speed = move_toward(speed, target, 14.0 * delta)
	dist += speed * delta
	clean_dist += speed * delta
	run["clean_best"] = maxf(float(run.clean_best), clean_dist)
	var mult := float(GameState.data.multiplier) * (2.0 if timers.x2 > 0.0 else 1.0)
	score += speed * delta * 0.4 * mult

	world.advance(delta, speed, dist, player.position, timers.magnet > 0.0)

	var gh: float = world.ground_height(player.position.x)
	if timers.fly <= 0.0 and player.on_ground and gh - player.position.y > 0.55 and invuln_t <= 0.0:
		_on_hit({})
	player.step(delta, gh, speed)

	if timers.fly <= 0.0 and invuln_t <= 0.0 and state == State.PLAY:
		var e: Dictionary = world.check_hit(player.position.x, player.position.y, player.head_h())
		if not e.is_empty():
			_on_hit(e)
	if state != State.PLAY:
		return

	var res: Dictionary = world.collect(player.position)
	if int(res.coins) > 0:
		var add := int(res.coins) * (2 if timers.x2 > 0.0 else 1)
		run["coins"] = int(run.coins) + add
		score += add * 5.0 * mult
		Sfx.play("coin", 0.95 + randf() * 0.15, -3.0)
	for k in res.picks:
		_activate(String(k))

	var new_zone := int(dist / ZONE_LEN)
	if new_zone > zone:
		zone = new_zone
		run["zone"] = zone
		world.set_zone(zone)
		Sfx.play("zone")
		Sfx.play_music(zone % 3)
		hud.banner("¡ZONA %d · %s!\n¡MÁS DIFÍCIL!" % [zone + 1, String(world.zone_name(zone)).to_upper()], Color("ff7b54"))

	player.visible = invuln_t <= 0.0 or int(invuln_t * 14.0) % 2 == 0

	mission_t -= delta
	if mission_t <= 0.0:
		mission_t = 0.3
		run["dist"] = dist
		for m in GameState.check_run_missions(run):
			hud.toast(String(m))
			Sfx.play("win")

	var disp_mult := int(GameState.data.multiplier) * (2 if timers.x2 > 0.0 else 1)
	hud.update_game(int(run.coins), int(score), disp_mult, int(dist), timers, GameState.run_progress(run))

	# perseguidor
	var want := 8.0
	if stumble_t > 0.0:
		want = 3.0
	chaser_z = lerpf(chaser_z, want, 1.0 - exp(-4.0 * delta))
	chaser.visible = chaser_z < 6.5
	chaser.position = Vector3(player.position.x, 0, chaser_z)


func _activate(kind: String) -> void:
	run["powerups"] = int(run.powerups) + 1
	Sfx.play("power")
	match kind:
		"magnet":
			timers.magnet = 10.0
			hud.toast("¡Imán de monedas!")
		"shield":
			timers.shield = 12.0
			hud.toast("¡Escudo activado!")
		"x2":
			timers.x2 = 10.0
			hud.toast("¡Puntos dobles!")
		"fly":
			timers.fly = 5.0
			player.set_flying(true)
			world.spawn_sky_coins(speed * 5.0)
			hud.toast("¡A volar!")


func _on_hit(e: Dictionary) -> void:
	if invuln_t > 0.0 or timers.fly > 0.0:
		return
	if autoplay:
		print("[test] hit kind=%s y=%.2f vy=%.1f slide=%.2f extra=%s dist=%d speed=%.1f" % [String(e.get("kind", "wall")), player.position.y, player.vy, player.slide_t, str(e.get("extra", 0)), int(dist), speed])
	if timers.shield > 0.0:
		timers.shield = 0.0
		invuln_t = 1.2
		Sfx.play("shield")
		if not e.is_empty():
			world.remove_entity(e)
		hud.toast("¡El escudo te salvó!")
		return
	if stumble_t > 0.0:
		_game_over()
		return
	stumble_t = 7.0
	invuln_t = 1.6
	clean_dist = 0.0
	Sfx.play("hit")
	speed *= 0.6
	hud.toast("¡Tropezaste! ¡El jaguar te sigue de cerca!")
	if not e.is_empty():
		world.remove_entity(e)


func _game_over() -> void:
	state = State.DEAD
	dead_t = 0.0
	over_shown = false
	Sfx.play("hit")
	Sfx.play("over")
	Sfx.play_music(3)
	player.die()
	player.visible = true
	run["dist"] = dist
	run["score"] = int(score)
	run["zone"] = zone
	if autoplay:
		print("[test] game over: dist=%d score=%d coins=%d zone=%d jumps=%d slides=%d" % [int(dist), int(score), int(run.coins), zone, int(run.jumps), int(run.slides)])


func _dead(delta: float) -> void:
	dead_t += delta
	player.step(delta, 0.0, 0.0)
	chaser_z = lerpf(chaser_z, 1.0, 1.0 - exp(-5.0 * delta))
	chaser.visible = true
	chaser.position = Vector3(player.position.x, 0, chaser_z)
	if dead_t > 1.1 and not over_shown:
		over_shown = true
		var new_best := int(run.score) > int(GameState.data.best)
		var msgs: Array = GameState.check_run_missions(run)
		msgs.append_array(GameState.finish_run(run))
		hud.show_over(run, msgs, new_best)
	if autoplay and dead_t > 1.5:
		_start_game()


func _animate_chaser(delta: float) -> void:
	if not chaser.visible:
		return
	var ph := anim_t * 16.0
	for i in chaser_legs.size():
		chaser_legs[i].rotation.x = sin(ph + (i % 2) * PI + (i / 2) * 0.8) * 0.9
	chaser.position.y = absf(sin(ph)) * 0.12


func _update_camera(delta: float) -> void:
	var k := 1.0 - exp(-7.0 * delta)
	var pos: Vector3
	var look: Vector3
	match cam_mode:
		"menu":
			pos = Vector3(2.6, 1.8, 3.6)
			look = Vector3(0, 1.25, 0)
		"chars":
			pos = Vector3(0.7, 1.55, -3.9)
			look = Vector3(0, 1.1, 0)
		_:
			pos = Vector3(player.position.x * 0.6, 4.7 + player.position.y * 0.55, 8.4)
			look = Vector3(player.position.x * 0.5, 1.2 + player.position.y * 0.3, -8.0)
	camera.position = camera.position.lerp(pos, k)
	cam_look = cam_look.lerp(look, k)
	camera.look_at(cam_look)


# ---------- Bot de pruebas ----------
func _bot(delta: float) -> void:
	bot_t -= delta
	if bot_t > 0.0:
		return
	bot_t = 0.04
	# primero: si hay un obstáculo cercano en mi carril y otro carril está libre, cambiar
	var blocked := [false, false, false]
	for e in world.ents:
		var zz: float = e.node.position.z
		if e.kind != "plat" and zz > -22.0 and zz < 2.0:
			for l in e.lanes:
				blocked[int(l)] = true
	if blocked[player.lane]:
		for d in [-1, 1]:
			var nl: int = player.lane + d
			if nl >= 0 and nl <= 2 and not blocked[nl]:
				player.move_lane(d)
				return
	for e in world.ents:
		var z: float = e.node.position.z
		var reach := -(speed + float(e.extra)) * 0.26
		if z > reach and z < 1.5 and e.lanes.has(player.lane):
			match e.kind:
				"low": player.jump()
				"beam": player.slide()
