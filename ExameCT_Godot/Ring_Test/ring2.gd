extends Area3D

class_name Ring

signal ring_scored(spaceship)

const RING_SCENE_FILE = "res://Ring_Test/ring2.tscn"

var initial_positions : Dictionary

static func spawn(root:Node, new_trans:Transform3D):
	var ring = load(RING_SCENE_FILE).instantiate()
	root.add_child(ring)
	ring.transform = new_trans
	return ring


func _on_body_entered(body):
	initial_positions[body] = body.position


func _on_body_exited(body):
	if body in initial_positions:
		# Checks if body is exiting the area in the opposite side of the ring
		var ini = initial_positions[body]
		var final = body.position
		var product = position.direction_to(ini).dot(basis.z) * position.direction_to(final).dot(basis.z)
		initial_positions.erase(body)
		
		# Reward the spaceship by passing through the ring
		if product < 0 and "reward" in body and "target" in body and body.target == self:
			ring_scored.emit(body)
#			body.reward += 1 - get_parent().get_parent().time*0.01
#			body.target = body.next_target
