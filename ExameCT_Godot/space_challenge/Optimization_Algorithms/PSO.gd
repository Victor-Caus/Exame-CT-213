extends Node3D

@export_file() var spaceship_scene
@export var spaceships : Array[Node]

var SELECTION_TIME = 3
const QUANTITY = 50
const SELECTED_QUANTITY = 10

# PSO hyperparameters
const INITIAL_MUTATION_CHANCE = 1
const INITIAL_VARIABILITY = 1
const MAX_INITIAL_VELOCITY = 2 * INITIAL_VARIABILITY
var INERTIA_WEIGHT : float = 0.9 #0.9
const INERTIA_SCHEDULE = 0.01
var COGNITIVE_P = 0.6 #0.6
const SOCIAL_P = 0.8 #0.8

var iteration : int = 0
var time := 0.0
var ring_manager : Node3D

# global max:
var globalBest : NN
var globalBestReward : float


func _ready():
	globalBest = NN.new()
	globalBestReward = -INF
	ring_manager = $RingManager
	generate_first_generation()
	iteration = 0


func _physics_process(delta):
	time += delta
	# Natural selection occurs every SELECTION_TIME seconds
	while time > SELECTION_TIME:
		natural_selection()		
		time -= SELECTION_TIME
		SELECTION_TIME = 3

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
		
	

func natural_selection():
	# Delete old rings
	ring_manager.restart()
	
	# In this example let's give the reward only in selection:
	for spaceship in spaceships:
		spaceship.reward -= spaceship.position.distance_to(spaceship.target.position) * 0.01
		# Update best spaceship
		if spaceship.reward > spaceship.best_reward:
			spaceship.best_reward = spaceship.reward
			# Copy the current NN as the best NN of this particle
			spaceship.bestParticular.layers = spaceship.nn.copyLayers()
	
	# Sort the fittest spaceships
	spaceships.sort_custom(func(a, b): return a.reward > b.reward)
	
	# Check if the best of the generation is the global best:
	if spaceships[0].reward > globalBestReward:
		print(globalBestReward)
		globalBestReward = spaceships[0].reward
		globalBest.layers = spaceships[0].nn.copyLayers()
	
	#debug
	print(iteration)
	print(spaceships[0].reward)
	print(globalBestReward)
	
	for spaceship in spaceships:
		# Update PSO
		spaceship.nn.PSO(INERTIA_WEIGHT, COGNITIVE_P, SOCIAL_P, globalBest)
		# Reset positions, velocities, targets and rewards of spaceships
		reset_spaceship(spaceship)
	
	# Schedule for inertia weight
	iteration += 1
	INERTIA_WEIGHT = INERTIA_WEIGHT / (1 + INERTIA_SCHEDULE * iteration)


func reset_spaceship(spaceship):
	spaceship.position = Vector3.ZERO
	spaceship.rotation = Vector3.ZERO
	spaceship.linear_velocity = Vector3.ZERO
	spaceship.angular_velocity = Vector3.ZERO
	ring_manager.targets_index[spaceship] = 0
	spaceship.target = ring_manager.rings[0]
	spaceship.next_target = ring_manager.rings[1]
	spaceship.reward = 0
