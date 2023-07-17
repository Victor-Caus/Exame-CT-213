extends Area3D

class_name Ring

const RING_SCENE_FILE = "res://Ring_Test/ring2.tscn"

var initial_positions : Dictionary
var second_ring : Node

static func spawn(root:Node, pos:Vector3):
	var ring = load(RING_SCENE_FILE).instantiate()
	root.add_child(ring)
	ring.position = pos
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
		
		if product < 0 and body is Spaceship and body.target == self:
			body.reward += 1 - get_parent().time*0.01
			body.target = body.next_target
			
			if not second_ring: #creates a new target if there is not enough
				var new_pos = Vector3(randf()*4-2, randf()*4-2, -(randf()*4+6)) + position
				second_ring = Ring.spawn(get_parent(), new_pos)
			body.next_target = second_ring
