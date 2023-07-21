extends Area3D

class_name Ring

signal ring_scored(spaceship, ring_spawn_time)

const RING_SCENE_FILE = "res://Ring_Test/ring2.tscn"

var initial_positions : Dictionary
var ring_value


static func spawn(root:Node, new_trans:Transform3D, radius:float):
	var ring = load(RING_SCENE_FILE).instantiate()
	root.add_child(ring)
	ring.transform = new_trans
	ring.ring_value = 1
	ring.get_node("ringmesh").scale *= radius
	ring.get_node("CollisionShape3D").scale *= radius
	return ring


func _physics_process(delta):
	ring_value = ring_value * 0.98 ** (delta)


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
			ring_scored.emit(body, ring_value)
