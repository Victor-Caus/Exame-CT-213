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
const INERTIA_WEIGHT = 0.9
const COGNITIVE_P = 0.6
const SOCIAL_P = 0.8


var time := 0.0


func _ready():
	generate_first_generation()


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
	
	spaceships.sort_custom(func(a, b): return a.reward > b.reward)
	print(spaceships[0].reward)
	for spaceship in spaceships:
		spaceship.position = Vector3.ZERO
		spaceship.rotation = Vector3.ZERO
		spaceship.linear_velocity = Vector3.ZERO
		spaceship.angular_velocity = Vector3.ZERO
		spaceship.get_child(0).PSO(INERTIA_WEIGHT, COGNITIVE_P, SOCIAL_P, spaceships[0].get_child(0))
		

