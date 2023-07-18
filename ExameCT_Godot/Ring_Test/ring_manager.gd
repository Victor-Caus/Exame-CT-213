extends Node3D

const RING_DIST = 6.0

var rings : Array[Ring]
var targets_index : Dictionary

func restart():
	# Delete all rings
	while not rings.is_empty():
		rings.pop_back().queue_free()
	# Generate 2 rings
	spawn_ring(Vector3.ZERO, RING_DIST)
	spawn_ring(rings[0].position, RING_DIST)


func spawn_ring(origin :Vector3, spawn_distance :float):
	# Generate random position
	var theta = randf_range(0, 2*PI)
	var z = randf_range(-1, 1)
	var spawn_pos = Vector3(sqrt(1 - z*z)*cos(theta), sqrt(1 - z*z)*sin(theta), z) * spawn_distance + origin
	
	# Generate z direction
	theta = randf_range(0, 2*PI)
	z = randf_range(-1, 1)
	var z_direction = Vector3(sqrt(1 - z*z)*cos(theta), sqrt(1 - z*z)*sin(theta), z)
	
	# Generate x and y directions
	var y_direction
	if z_direction.cross(Vector3.UP) != Vector3.ZERO:
		y_direction = z_direction.cross(Vector3.UP).normalized()
	else:
		y_direction = z_direction.cross(Vector3.RIGHT).normalized()
	
	var x_direction = y_direction.cross(z_direction)
	var new_ring_transform = Transform3D(x_direction, y_direction, z_direction, spawn_pos)

	# Spawn new ring, connect signal and add it to list
	var new_ring = Ring.spawn(self, new_ring_transform)
	new_ring.ring_scored.connect(spaceship_scored)
	rings.push_back(new_ring)
	return new_ring


func spaceship_scored(spaceship):
	spaceship.reward += 1 - 0.01 * (get_parent().time - spaceship.time_last_ring)**2
	
	spaceship.target = spaceship.next_target
	targets_index[spaceship] += 1
	var ti = targets_index[spaceship]
	if not rings.size() > ti + 1:
		spawn_ring(rings[ti].position, RING_DIST)
		get_parent().SELECTION_TIME += 2
	spaceship.next_target = rings[ti + 1]
	spaceship.time_last_ring = get_parent().time
	
