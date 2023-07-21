extends Button

@onready var space = get_parent().get_parent()


func _on_pressed():
	# Loads the NN in the last spaceship, doens't do anything if load fails
	if not space.spaceships[-1].nn.loadNN():
		return
	
	# Reset time, rings and spaceships, without causing natural selection
	space.time = 0
	space.selection_time = space.time_per_ring * 2
	space.ring_manager.restart()
	for i in range(space.spaceships.size()):
		space.call_deferred("reset_spaceship", space.spaceships[i])
