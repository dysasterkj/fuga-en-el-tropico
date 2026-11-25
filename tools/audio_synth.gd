extends RefCounted
## Sintetizador usado SOLO en desarrollo para generar los .wav de la carpeta audio/.
## Ejecutar: godot --headless --path . --script tools/gen_audio.gd

const RATE := 22050


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


func to_wav(buf: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		bytes.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32000.0))
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = RATE
	st.stereo = false
	st.data = bytes
	return st


func _buf(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * RATE))
	return b


func _hz(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)


func sfx_set() -> Dictionary:
	var out := {}
	var b := _buf(0.18)
	_add(b, 0.0, 0.16, 320.0, 700.0, 0, 0.55)
	out["jump"] = to_wav(b)

	b = _buf(0.28)
	_add(b, 0.0, 0.26, 500.0, 160.0, 3, 0.22)
	_add(b, 0.0, 0.22, 260.0, 120.0, 0, 0.3)
	out["slide"] = to_wav(b)

	b = _buf(0.22)
	_add(b, 0.0, 0.09, 988.0, 988.0, 1, 0.22)
	_add(b, 0.07, 0.15, 1319.0, 1319.0, 1, 0.22)
	out["coin"] = to_wav(b)

	b = _buf(0.5)
	for i in 4:
		_add(b, i * 0.07, 0.2, _hz(72 + [0, 4, 7, 12][i]), _hz(72 + [0, 4, 7, 12][i]), 2, 0.4)
	out["power"] = to_wav(b)

	b = _buf(0.45)
	_add(b, 0.0, 0.35, 220.0, 70.0, 0, 0.7)
	_add(b, 0.0, 0.3, 400.0, 100.0, 3, 0.35)
	out["hit"] = to_wav(b)

	b = _buf(0.4)
	_add(b, 0.0, 0.35, 900.0, 200.0, 2, 0.5)
	out["shield"] = to_wav(b)

	b = _buf(0.8)
	for i in 4:
		_add(b, i * 0.12, 0.3, _hz(67 + [0, 5, 9, 12][i]), _hz(67 + [0, 5, 9, 12][i]), 1, 0.2)
	out["zone"] = to_wav(b)

	b = _buf(0.08)
	_add(b, 0.0, 0.06, 740.0, 640.0, 0, 0.45)
	out["click"] = to_wav(b)

	b = _buf(0.5)
	for i in 3:
		_add(b, i * 0.09, 0.25, _hz(76 + [0, 4, 9][i]), _hz(76 + [0, 4, 9][i]), 2, 0.45)
	out["buy"] = to_wav(b)

	b = _buf(0.5)
	for i in 3:
		_add(b, i * 0.1, 0.25, _hz(72 + [0, 4, 7][i]), _hz(72 + [0, 4, 7][i]), 2, 0.4)
	out["win"] = to_wav(b)

	b = _buf(0.9)
	for i in 4:
		_add(b, i * 0.18, 0.3, _hz(67 - [0, 2, 4, 7][i]), _hz(64 - [0, 2, 4, 7][i]), 4, 0.25)
	out["over"] = to_wav(b)
	return out


func music_set() -> Dictionary:
	var cfgs := [
		{"name": "music_menu", "bpm": 92.0, "root": 60, "scale": [0, 2, 4, 7, 9], "prog": [0, -3, -7, -5], "drums": 0, "seed": 7},
		{"name": "music_0", "bpm": 108.0, "root": 60, "scale": [0, 2, 4, 7, 9], "prog": [0, -3, -7, -5], "drums": 1, "seed": 11},
		{"name": "music_1", "bpm": 124.0, "root": 57, "scale": [0, 3, 5, 7, 10], "prog": [0, -4, -2, -5], "drums": 2, "seed": 23},
		{"name": "music_2", "bpm": 100.0, "root": 62, "scale": [0, 2, 4, 7, 9], "prog": [0, 5, -2, 7], "drums": 3, "seed": 41},
	]
	var out := {}
	for c in cfgs:
		out[c.name] = _render_track(c)
	return out


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
		var bass_steps: Array = [0.0, 1.5, 2.0, 3.0] if drums != 3 else [0.0, 0.75, 1.5, 2.5, 3.0]
		for s in bass_steps:
			_add(b, t0 + s * beat, beat * 0.6, _hz(root + off - 24), _hz(root + off - 24), 2, 0.35)
		var arp: Array = [0, 4, 7, 12, 7, 4, 7, 12]
		for i in 8:
			var m: int = root + off - 12 + int(arp[i])
			_add(b, t0 + i * beat * 0.5, beat * 0.45, _hz(m), _hz(m), 2, 0.1)
		for i in 8:
			if rng.randf() < 0.62:
				var deg: int = scale[rng.randi() % scale.size()]
				var oct: int = 12 if rng.randf() < 0.5 else 0
				var m2: int = root + off + deg + oct
				_add(b, t0 + i * beat * 0.5, beat * 0.5, _hz(m2), _hz(m2), 0, 0.17, 0.006)
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
	return to_wav(b)
