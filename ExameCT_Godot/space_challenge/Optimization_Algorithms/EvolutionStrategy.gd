extends Node3D

@export_file("*.tscn") var spaceship_scene
@export var spaceships : Array[Node]

var SELECTION_TIME = 5
const QUANTITY = 50

var iteration : int = 0
var time := 0.0
var ring_manager : Node3D

# Data
var history = []

func _ready():
	ring_manager = $RingManager
	generate_first_generation()
	iteration = 0


func _physics_process(delta):
	time += delta
	
	# Natural selection occurs every SELECTION_TIME seconds
	while time > SELECTION_TIME:
		natural_selection()
		time -= SELECTION_TIME
		SELECTION_TIME = 5

func generate_first_generation():
	# Prepare the rings
	ring_manager.restart()
	
	# Spawn all spaceships
	var spaceship_resource = load(spaceship_scene) as PackedScene
	for i in range(QUANTITY):
		var spaceship = spaceship_resource.instantiate()
		reset_spaceship(spaceship)
		add_child(spaceship)
		spaceships.push_back(spaceship)
		spaceship.nn.mutateNetwork(1)


func natural_selection():
	# Delete old rings
	var scored_rings = ring_manager.rings.size()
	ring_manager.restart()
	
	# Punish the ships that got to far from their target
	for spaceship in spaceships:
		spaceship.reward -= spaceship.position.distance_to(ring_manager.rings.back().position) * 0.001
	
	# Sort the fittest spaceships
	spaceships.sort_custom(func(a, b): return a.reward > b.reward)
	
	#debug
	print("Iteration: %d  Scored rings: %d  Reward: %f" % [iteration, scored_rings - 2, spaceships[0].reward])
	history.append(spaceships[0].reward)
	
	# Selection and mutation
	for i in range(1, spaceships.size()):
		spaceships[i].nn.layers = spaceships[0].nn.copyLayers()
		spaceships[i].nn.mutateNetwork(0.1)
	
	# Reset positions, velocities, targets and rewards of spaceships
	for spaceship in spaceships:
		reset_spaceship(spaceship)
	
	iteration += 1


func reset_spaceship(spaceship):
	spaceship.position = Vector3.ZERO
	spaceship.rotation = Vector3.ZERO
	spaceship.linear_velocity = Vector3.ZERO
	spaceship.angular_velocity = Vector3.ZERO
	ring_manager.targets_index[spaceship] = 0
	spaceship.target = ring_manager.rings[0]
	spaceship.next_target = ring_manager.rings[1]
	spaceship.reward = 0
