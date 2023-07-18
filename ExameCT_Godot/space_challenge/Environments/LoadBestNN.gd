extends Button


func _on_pressed():
	get_parent().get_parent().spaceships[1].nn.loadNN()
