extends Button
var history = []

func _on_pressed():
	# Take the space's history:
	history = get_parent().get_parent().history
	var file = FileAccess.open("res://Data/reward_convergency.txt", FileAccess.WRITE)
	for reward in history:
		file.store_line(str(reward))

	# The file will be closed automatically when gets out of the scope
