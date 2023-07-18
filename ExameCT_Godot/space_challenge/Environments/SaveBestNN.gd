extends Button


func _on_pressed():
	get_parent().get_parent().spaceships[0].nn.saveLayers()
	
	
	
