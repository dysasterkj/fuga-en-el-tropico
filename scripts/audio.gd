extends Node
## Sonido generado por código: efectos y música por zona (sin archivos externos).

const RATE := 22050

var sfx: Dictionary = {}
var music: Dictionary = {}
var music_player: AudioStreamPlayer
var pool: Array = []
var thread: Thread
var cur_track := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -10.0
	add_child(music_player)
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.volume_db = -4.0
		add_child(p)
		pool.append(p)
	_build_sfx()
	thread = Thread.new()
	thread.start(_build_music)


func _exit_tree() -> void:
	if thread and thread.is_started():
		thread.wait_to_finish()


# ---------- Reproducción ----------
func play(name: String, pitch: float = 1.0, vol_db: float = 0.0) -> void:
	if not GameState.data.get("sfx", true) or not sfx.has(name):
		return
	for p in pool:
		if not p.playing:
			p.stream = sfx[name]
			p.pitch_scale = pitch
			p.volume_db = -4.0 + vol_db
			p.play()
			return
	var q: AudioStreamPlayer = pool[0]
	q.stream = sfx[name]
	q.pitch_scale = pitch
	q.play()


func play_music(idx: int) -> void:
	cur_track = idx
	_apply_music()


func _apply_music() -> void:
	if not GameState.data.get("music", true):
		music_player.stop()
		return
	if music.has(cur_track):
		if music_player.stream != music[cur_track] or not music_player.playing:
			music_player.stream = music[cur_track]
			music_player.play()


func refresh_settings() -> void:
	if GameState.data.get("music", true):
		_apply_music()
	else:
		music_player.stop()


func _on_music_ready(idx: int, st: AudioStreamWAV) -> void:
	music[idx] = st
	if idx == cur_track:
		_apply_music()


# ---------- Síntesis ----------
func _add(buf: PackedFloat32Array, start: float, dur: float, f0: float, f1: float, wave: int, vol: float, attack: float = 0.004) -> void:
	var n := int(dur * RATE)
	var s0 := int(start * RATE)
	if s0 >= buf.size():
		return
	n = mini(n, buf.size() - s0)
	var phase := 0.0
	var seed_v := 12345 + s0
	for i in n:
		var tt := float(i) / RATE
		var f := lerpf(f0, f1, tt / dur)
		phase += f / RATE
		var ph := phase - floorf(phase)
		var s := 0.0
		match wave:
			0: s = sin(phase * TAU)
			1: s = 1.0 if ph < 0.5 else -1.0
			2: s = 4.0 * absf(ph - 0.5) - 1.0
			3:
				seed_v = (seed_v * 1103515245 + 12345) & 0x7fffffff
				s = float(seed_v % 2000) / 1000.0 - 1.0
			4: s = 2.0 * ph - 1.0
		var env := minf(1.0, tt / attack) * exp(-3.2 * tt / dur)
		buf[s0 + i] += s * env * vol


func _to_wav(buf: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		bytes.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32000.0))
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = RATE
	st.stereo = false
	st.data = bytes
	if loop:
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_begin = 0
		st.loop_end = buf.size()
	return st


func _buf(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * RATE))
	return b


func _hz(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)


# ---------- Efectos ----------
func _build_sfx() -> void:
	var b := _buf(0.18)
	_add(b, 0.0, 0.16, 320.0, 700.0, 0, 0.55)
	sfx["jump"] = _to_wav(b, false)

	b = _buf(0.28)
	_add(b, 0.0, 0.26, 500.0, 160.0, 3, 0.22)
	_add(b, 0.0, 0.22, 260.0, 120.0, 0, 0.3)
	sfx["slide"] = _to_wav(b, false)

	b = _buf(0.22)
	_add(b, 0.0, 0.09, 988.0, 988.0, 1, 0.22)
	_add(b, 0.07, 0.15, 1319.0, 1319.0, 1, 0.22)
	sfx["coin"] = _to_wav(b, false)

	b = _buf(0.5)
	for i in 4:
		_add(b, i * 0.07, 0.2, _hz(72 + [0, 4, 7, 12][i]), _hz(72 + [0, 4, 7, 12][i]), 2, 0.4)
	sfx["power"] = _to_wav(b, false)

	b = _buf(0.45)
	_add(b, 0.0, 0.35, 220.0, 70.0, 0, 0.7)
	_add(b, 0.0, 0.3, 400.0, 100.0, 3, 0.35)
	sfx["hit"] = _to_wav(b, false)

	b = _buf(0.4)
	_add(b, 0.0, 0.35, 900.0, 200.0, 2, 0.5)
	sfx["shield"] = _to_wav(b, false)

	b = _buf(0.8)
	for i in 4:
		_add(b, i * 0.12, 0.3, _hz(67 + [0, 5, 9, 12][i]), _hz(67 + [0, 5, 9, 12][i]), 1, 0.2)
	sfx["zone"] = _to_wav(b, false)

	b = _buf(0.08)
	_add(b, 0.0, 0.06, 740.0, 640.0, 0, 0.45)
	sfx["click"] = _to_wav(b, false)

	b = _buf(0.5)
	for i in 3:
		_add(b, i * 0.09, 0.25, _hz(76 + [0, 4, 9][i]), _hz(76 + [0, 4, 9][i]), 2, 0.45)
	sfx["buy"] = _to_wav(b, false)

	b = _buf(0.5)
	for i in 3:
		_add(b, i * 0.1, 0.25, _hz(72 + [0, 4, 7][i]), _hz(72 + [0, 4, 7][i]), 2, 0.4)
	sfx["win"] = _to_wav(b, false)

	b = _buf(0.9)
	for i in 4:
		_add(b, i * 0.18, 0.3, _hz(67 - [0, 2, 4, 7][i]), _hz(64 - [0, 2, 4, 7][i]), 4, 0.25)
	sfx["over"] = _to_wav(b, false)

	b = _buf(0.35)
	_add(b, 0.0, 0.3, 200.0, 420.0, 3, 0.2)
	sfx["whoosh"] = _to_wav(b, false)


# ---------- Música (hilo aparte) ----------
func _build_music() -> void:
	var cfgs := [
		{"idx": 3, "bpm": 92.0, "root": 60, "scale": [0, 2, 4, 7, 9], "prog": [0, -3, -7, -5], "drums": 0, "seed": 7},
		{"idx": 0, "bpm": 108.0, "root": 60, "scale": [0, 2, 4, 7, 9], "prog": [0, -3, -7, -5], "drums": 1, "seed": 11},
		{"idx": 1, "bpm": 124.0, "root": 57, "scale": [0, 3, 5, 7, 10], "prog": [0, -4, -2, -5], "drums": 2, "seed": 23},
		{"idx": 2, "bpm": 100.0, "root": 62, "scale": [0, 2, 4, 7, 9], "prog": [0, 5, -2, 7], "drums": 3, "seed": 41},
	]
	for c in cfgs:
		var st := _render_track(c)
		call_deferred("_on_music_ready", int(c.idx), st)


func _render_track(c: Dictionary) -> AudioStreamWAV:
	var bpm: float = c.bpm
	var beat := 60.0 / bpm
	var bars := 8
	var total := beat * 4.0 * bars
	var b := _buf(total)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(c.seed)
	var scale: Array = c.scale
	var prog: Array = c.prog
	var root: int = c.root
	var drums: int = c.drums

	for bar in bars:
		var off: int = prog[bar % 4]
		var t0 := bar * beat * 4.0
		# bajo
		var bass_steps: Array = [0.0, 1.5, 2.0, 3.0] if drums != 3 else [0.0, 0.75, 1.5, 2.5, 3.0]
		for s in bass_steps:
			_add(b, t0 + s * beat, beat * 0.6, _hz(root + off - 24), _hz(root + off - 24), 2, 0.35)
		# arpegio
		var arp: Array = [0, 4, 7, 12, 7, 4, 7, 12]
		for i in 8:
			var m: int = root + off - 12 + int(arp[i])
			_add(b, t0 + i * beat * 0.5, beat * 0.45, _hz(m), _hz(m), 2, 0.1)
		# melodía
		for i in 8:
			if rng.randf() < 0.62:
				var deg: int = scale[rng.randi() % scale.size()]
				var oct: int = 12 if rng.randf() < 0.5 else 0
				var m2: int = root + off + deg + oct
				_add(b, t0 + i * beat * 0.5, beat * 0.5, _hz(m2), _hz(m2), 0, 0.17, 0.006)
		# percusión
		for q in 4:
			if drums >= 1:
				if q % 2 == 0 or drums == 2:
					_add(b, t0 + q * beat, 0.16, 130.0, 45.0, 0, 0.55)
			for h in 2:
				var hat_vol := 0.07 if drums >= 1 else 0.03
				_add(b, t0 + q * beat + h * beat * 0.5, 0.05, 8000.0, 8000.0, 3, hat_vol, 0.001)
			if drums == 3 and (q == 1 or q == 3):
				_add(b, t0 + q * beat + beat * 0.75, 0.1, 360.0, 300.0, 0, 0.22)
			if drums == 2 and q == 2:
				_add(b, t0 + q * beat, 0.12, 220.0, 120.0, 3, 0.3, 0.001)
	return _to_wav(b, true)
