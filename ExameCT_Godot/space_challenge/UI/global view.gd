extends Button

var increase 
# Called when the region is pressed
func _on_pressed():
	var spaceship_view = $"../Spaceship View"
	var pivot = $"../../Pivot"
	var camera = $"../../Pivot/Camera3D"
	pivot.position.x = 0
	pivot.position.y = 0
	pivot.position.z = 0
	camera.position.z = 35
	camera.position.x = 0
	camera.position.y = 0
	camera.rotation.y = 0
	spaceship_view.view2 = false
