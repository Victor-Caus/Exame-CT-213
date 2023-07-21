extends Button


func _on_pressed():
	var folder := OS.get_executable_path().get_base_dir()
	var file_name := folder + "/reward_convergency.txt"
	var file = FileAccess.open(file_name, FileAccess.WRITE)
	if not file:
		return
	# Take the space's history:
	var history = get_parent().get_parent().history
	for episode in history:
		file.store_line(str(episode))
	file.close()
