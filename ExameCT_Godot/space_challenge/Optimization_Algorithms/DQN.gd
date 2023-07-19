extends Node3D

@export_file("*.tscn") var spaceship_scene
@export var spaceships : Array[Node]

# Constants
@export var Q_TARGET_TIME = 0.3
var SELECTION_TIME = 5
const QUANTITY = 1
const GLIE_RATE = 0.01

var epoche : int = 0
var time := 0.0
var q_time := 0.0
var ring_manager : Node3D

# Data
var history = []

func _ready():
	ring_manager = $RingManager
	generate_first_generation()
	epoche = 0


func _physics_process(delta):
	time += delta
	q_time += delta
	
	# Natural selection occurs every SELECTION_TIME seconds
	while time > SELECTION_TIME:
		natural_selection()
		time -= SELECTION_TIME
		SELECTION_TIME = 5
		
	# Copy nn to Fixed Q-Target:
	while q_time >= Q_TARGET_TIME:
		q_time -= Q_TARGET_TIME
		spaceships[0].fixed_nn.layers = spaceships[0].nn.copyLayers()
	

func generate_first_generation():
	# Prepare the rings
	ring_manager.restart()
	
	# Spawn all spaceships (in the case only one)
	var spaceship_resource = load(spaceship_scene) as PackedScene
	for i in range(QUANTITY):
		var spaceship = spaceship_resource.instantiate()
		reset_spaceship(spaceship)
		add_child(spaceship)
		spaceships.push_back(spaceship)
		spaceship.nn.mutateNetwork(1)
		# Fixed nn starts copying the parameters of action-value:
		spaceship.fixed_nn.layers = spaceship.nn.copyLayers()


func natural_selection():
	# Delete old rings
	var scored_rings = ring_manager.rings.size()
	ring_manager.restart()
	
	# Sort the fittest spaceships
	spaceships.sort_custom(func(a, b): return a.reward > b.reward)
	
	# Debug and save in story array for convergency graphs
	print("Epoche: %d  Scored rings: %d  Reward: %f" % [epoche, scored_rings - 2, spaceships[0].reward])
	history.append(spaceships[0].reward)
	
	# Selection and mutation
	for i in range(1, spaceships.size()):
		spaceships[i].nn.layers = spaceships[0].nn.copyLayers()
		spaceships[i].nn.mutateNetwork(0.1)
	
	# Reset positions, velocities, targets and rewards of spaceships
	for spaceship in spaceships:
		reset_spaceship(spaceship)
	
	glie_schedule(GLIE_RATE) #GLIE schedule of epsilon
	epoche += 1


func reset_spaceship(spaceship : Spaceship):
	spaceship.position = Vector3.ZERO
	spaceship.rotation = Vector3.ZERO
	spaceship.linear_velocity = Vector3.ZERO
	spaceship.angular_velocity = Vector3.ZERO
	ring_manager.targets_index[spaceship] = 0
	spaceship.target = ring_manager.rings[0]
	spaceship.next_target = ring_manager.rings[1]
	spaceship.reward = 0
	spaceship.cumulative_reward = 0
	spaceship.first_state = 0
	
# Epsilon Decay:
func glie_schedule(rate):
	spaceships[0].epsilon = max(spaceships[0].epsilon*rate, spaceships[0].epsilon_min)
