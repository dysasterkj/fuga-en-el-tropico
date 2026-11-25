extends Node
## Sonido: reproduce los .wav de audio/ (generados con tools/gen_audio.gd).

const SFX_NAMES := ["jump", "slide", "coin", "power", "hit", "shield", "zone", "click", "buy", "win", "over"]
const MUSIC_FILES := {3: "music_menu", 0: "music_0", 1: "music_1", 2: "music_2"}

var sfx: Dictionary = {}
var music: Dictionary = {}
var music_player: AudioStreamPlayer
var pool: Array = []
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
	for n in SFX_NAMES:
		var st = load("res://audio/%s.wav" % n)
		if st:
			sfx[n] = st
	for idx in MUSIC_FILES:
		var st = load("res://audio/%s.wav" % MUSIC_FILES[idx])
		if st is AudioStreamWAV:
			st.loop_mode = AudioStreamWAV.LOOP_FORWARD
			st.loop_begin = 0
			st.loop_end = st.data.size() / 2
			music[idx] = st


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
