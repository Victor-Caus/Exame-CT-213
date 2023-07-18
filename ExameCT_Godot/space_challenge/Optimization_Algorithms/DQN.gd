extends Node3D

# Permits to drag and drop the spaceship "prefab"
@export_file("*.tscn") var spaceship_scene
@export var spaceships : Array[Node]

# Episode proprieties
const SELECTION_TIME = 5
const QUANTITY = 1
const SELECTED_QUANTITY = 1

# DQN Agent attributes


var time := 0.0

# Executes when the scene begins:
func _ready():
	generate_first_generation()

# Executes in each physics time step
func _physics_process(delta):
	time += delta
	if time > SELECTION_TIME:
		natural_selection()
		time -= SELECTION_TIME

# First generation (In this case, there will be only one)
func generate_first_generation():
	var spaceship_resource = load(spaceship_scene) as PackedScene
	for i in range(QUANTITY):
		var spaceship = spaceship_resource.instantiate()
		spaceship.target = %Ring1
		spaceship.next_target = %Ring2
		add_child(spaceship)
		spaceships.push_back(spaceship)
		# Defines the initial guess about the NN:
		spaceship.nn.mutateNetwork(1, 1)


func natural_selection():
	# Free the other rings in sequence
	%Ring1.free_rings()
	%Ring2.free_rings()
	
	# Attribute the reward of the epoche
	for spaceship in spaceships:
		spaceship.reward -= spaceship.position.distance_to(spaceship.target.position) * 0.01
		
	
	# Selection and mutation

	# Reset the environment
	for spaceship in spaceships:
		# Reset positions, velocities, targets and rewards of spaceships
		spaceship.position = Vector3.ZERO
		spaceship.rotation = Vector3.ZERO
		spaceship.linear_velocity = Vector3.ZERO
		spaceship.angular_velocity = Vector3.ZERO
		spaceship.target = %Ring1
		spaceship.next_target = %Ring2
		spaceship.reward = 0  # Cumulative reward (return)
