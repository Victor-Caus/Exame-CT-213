extends Node3D

var ring_dist : float = 6.0
var rings : Array[Ring]
var targets_index : Dictionary

func restart():
	# Delete all rings
	while not rings.is_empty():
		rings.pop_back().queue_free()
	# Generate 2 rings
	spawn_ring(Vector3.ZERO, ring_dist)
	spawn_ring(rings[0].position, ring_dist)


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
	var new_ring = Ring.spawn(self, new_ring_transform, get_parent().radius)
	new_ring.ring_scored.connect(spaceship_scored)
	rings.push_back(new_ring)
	return new_ring


func spaceship_scored(spaceship, ring_value):
	spaceship.reward += ring_value
	
	spaceship.target = spaceship.next_target
	targets_index[spaceship] += 1
	var ti = targets_index[spaceship]
	
	if not rings.size() > ti + 1:
		# Spawn new ring
		spawn_ring(rings[ti].position, ring_dist)
		# Increase the time that the generation executes the code
		get_parent().selection_time += get_parent().time_per_ring
		# Increase the trasparency of old rings
		rings[ti-1].get_node("ringmesh").transparency = 0.1
		if ti>2:
			for i in range(ti-2):
				rings[i].get_node("ringmesh").transparency *= 1.2
		# Swap best spaceship index
		var best_index = get_parent().spaceships.find(spaceship)
		var temp = get_parent().spaceships[0]
		get_parent().spaceships[0] = get_parent().spaceships[best_index]
		get_parent().spaceships[best_index] = temp
	
	spaceship.next_target = rings[ti+1]
