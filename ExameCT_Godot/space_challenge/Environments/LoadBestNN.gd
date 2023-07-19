extends Button

@onready var space = get_parent().get_parent()

func _on_pressed():
	# Loads the NN in the last spaceship
	space.spaceships[-1].nn.loadNN()
	# Reset time, rings and spaceships, without causing natural selection
	space.time = 0
	space.SELECTION_TIME = 5
	space.ring_manager.restart()
	for i in range(space.spaceships.size()):
		space.call_deferred("reset_spaceship", space.spaceships[i])
