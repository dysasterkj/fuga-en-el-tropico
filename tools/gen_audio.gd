extends SceneTree
## Genera los archivos de sonido en audio/*.wav (solo desarrollo).


func _initialize() -> void:
	var synth = load("res://tools/audio_synth.gd").new()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://audio"))
	var sets: Array = [synth.sfx_set(), synth.music_set()]
	for s in sets:
		for k in s:
			var st: AudioStreamWAV = s[k]
			var err := st.save_to_wav("res://audio/%s.wav" % k)
			print("[audio] ", k, " -> ", err)
	quit()
