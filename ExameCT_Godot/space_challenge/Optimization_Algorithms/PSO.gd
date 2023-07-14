extends Node3D

@export_file() var spaceship_scene
@export var spaceships : Array[Node]
var best_brains : Array[NN]

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


func generate_first_generationORIGINAL():
	var spaceship_resource = load(spaceship_scene) as PackedScene
	for i in range(QUANTITY):
		var spaceship = spaceship_resource.instantiate()
		add_child(spaceship)
		spaceships.push_back(spaceship)
		spaceship.nn.mutateNetwork(0.5, 1)
		
func generate_first_generation():
	var spaceship_resource = load(spaceship_scene) as PackedScene
	for i in range(QUANTITY):
		var spaceship = spaceship_resource.instantiate()
		add_child(spaceship)
		spaceships.push_back(spaceship)
		spaceship.nn.PSO_InitializeLayer(INITIAL_MUTATION_CHANCE, INITIAL_VARIABILITY, MAX_INITIAL_VELOCITY)
		best_brains.push_back(spaceship.NN.copy_layers())

func natural_selection():
	spaceships.sort_custom(func(a, b): return a.position.y > b.position.y)
	for i in range(spaceships.size()):
		spaceships[i].position = Vector3.ZERO
		spaceships[i].rotation = Vector3.ZERO
		spaceships[i].linear_velocity = Vector3.ZERO
		spaceships[i].angular_velocity = Vector3.ZERO

