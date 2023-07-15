extends Node3D

@export_file() var spaceship_scene
@export var spaceships : Array[Node]

const SELECTION_TIME = 1
const QUANTITY = 50
const SELECTED_QUANTITY = 10

# PSO hyperparameters
const INITIAL_MUTATION_CHANCE = 1
const INITIAL_VARIABILITY = 1
const MAX_INITIAL_VELOCITY = 2 * INITIAL_VARIABILITY
var INERTIA_WEIGHT : float = 0.9
const INERTIA_SCHEDULE = 0.01
const COGNITIVE_P = 0.6
const SOCIAL_P = 0.8

var iteration : int = 0
var time := 0.0


func _ready():
	generate_first_generation()
	iteration = 0


func _physics_process(delta):
	time += delta
	while time > SELECTION_TIME:
		natural_selection()
		time -= SELECTION_TIME

		
func generate_first_generation():
	var spaceship_resource = load(spaceship_scene) as PackedScene
	for i in range(QUANTITY):
		var spaceship = spaceship_resource.instantiate()
		add_child(spaceship)
		spaceships.push_back(spaceship)
		

func natural_selection():
	# In this example let's give the reward only in selection:
	for spaceship in spaceships:
		spaceship.reward = spaceship.position.y
		# Update best spaceship
		if spaceship.reward > spaceship.best_reward:
			spaceship.best_reward = spaceship.reward
			# Copy the current NN as the best NN of this particle
			spaceship.get_child(0).get_child(0).layers = spaceship.get_child(0).copyLayers()
	
	# sort so we can get the max
	spaceships.sort_custom(func(a, b): return a.reward > b.reward)
	
	#debug
	print(iteration)
	print(spaceships[0].reward)
	
	# Reset positions of spaceships
	for spaceship in spaceships:
		spaceship.position = Vector3.ZERO
		spaceship.rotation = Vector3.ZERO
		spaceship.linear_velocity = Vector3.ZERO
		spaceship.angular_velocity = Vector3.ZERO
		spaceship.get_child(0).PSO(INERTIA_WEIGHT, COGNITIVE_P, SOCIAL_P, spaceships[0].get_child(0))
	
	# Schedule for inertia weight
	iteration += 1
	INERTIA_WEIGHT = INERTIA_WEIGHT / 1 + INERTIA_SCHEDULE * iteration

