extends Label

@onready var space = get_parent().get_parent()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	text = "Time left: %.2f s" % (space.selection_time - space.time)
