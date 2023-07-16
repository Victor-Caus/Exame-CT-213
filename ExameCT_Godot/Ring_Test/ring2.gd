extends Area3D

var initial_positions : Dictionary


func _on_body_entered(body):
	initial_positions[body] = body.position


func _on_body_exited(body):
	if body in initial_positions:
		var ini = initial_positions[body]
		var final = body.position
		# Checks if body is exiting the area in the opposite side of the ring
		var product = position.direction_to(ini).dot(basis.z) * position.direction_to(final).dot(basis.z)
		initial_positions.erase(body)
		if product < 0:
			print(body.name + " passed a ring")
