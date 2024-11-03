extends Node2D

func create_one_shot_audio_stream(nombre: String, sound_array: Array[AudioStream], parent) -> void:
	if sound_array.size() == 0:
		push_warning("Cannot create one shot audio for empty array")
		return
	
	var audio_stream = AudioStreamPlayer2D.new()
	audio_stream.name = nombre + "_" + str(hash(Time.get_unix_time_from_system()))
	audio_stream.stream = sound_array[randi_range(0, sound_array.size() - 1)]
	parent.add_child.call_deferred(audio_stream)
	await audio_stream.tree_entered
	audio_stream.play()
	audio_stream.finished.connect(
		func():
			audio_stream.queue_free()
	)
