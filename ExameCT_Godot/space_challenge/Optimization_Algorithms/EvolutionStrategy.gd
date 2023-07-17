extends Node3D

@export_file("*.tscn") var spaceship_scene
@export var spaceships : Array[Node]

const SELECTION_TIME = 5
const QUANTITY = 50
const SELECTED_QUANTITY = 10

var time := 0.0


func _ready():
	generate_first_generation()


func _physics_process(delta):
	time += delta
	if time > SELECTION_TIME:
		natural_selection()
		time -= SELECTION_TIME


func generate_first_generation():
	var spaceship_resource = load(spaceship_scene) as PackedScene
	for i in range(QUANTITY):
		var spaceship = spaceship_resource.instantiate()
		spaceship.target = %Ring1
		spaceship.next_target = %Ring2
		add_child(spaceship)
		spaceships.push_back(spaceship)
		spaceship.nn.mutateNetwork(1, 1)


func natural_selection():
	%Ring1.clear_sequence()
	%Ring2.clear_sequence()
	for spaceship in spaceships:
		spaceship.reward -= spaceship.position.distance_to(spaceship.target.position) * 0.01
	spaceships.sort_custom(func(a, b): return a.reward > b.reward)
	print(spaceships[0].reward)
	
	# Selection and mutation
	for i in range(SELECTED_QUANTITY, spaceships.size()):
		spaceships[i].nn.layers = spaceships[i%SELECTED_QUANTITY].nn.copyLayers()
		spaceships[i].nn.mutateNetwork(0.1, 0.5)
		
	for spaceship in spaceships:
		# Reset positions, velocities, targets and rewards of spaceships
		spaceship.position = Vector3.ZERO
		spaceship.rotation = Vector3.ZERO
		spaceship.linear_velocity = Vector3.ZERO
		spaceship.angular_velocity = Vector3.ZERO
		spaceship.target = %Ring1
		spaceship.next_target = %Ring2
		spaceship.reward = 0
