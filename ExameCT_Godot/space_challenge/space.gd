extends Node3D

@export_file() var spaceship_scene
@export var spaceships : Array[Node]

const SELECTION_TIME = 3
const QUANTITY = 50
const SELECTED_QUANTITY = 10

var time := 0.0

func _ready():
	generate_first_generation()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	time += delta
	if time > SELECTION_TIME:
		natural_selection()
		time = 0


func generate_first_generation():
	var spaceship_resource = load(spaceship_scene) as PackedScene
	for i in range(QUANTITY):
		var spaceship = spaceship_resource.instantiate()
		add_child(spaceship)
		spaceships.push_back(spaceship)
		spaceship.mutate()


func natural_selection():
	spaceships.sort_custom(func(a, b): return a.position.y > b.position.y)
	print(spaceships[0].position.y)
	print(spaceships[1].position.y)
	for i in range(spaceships.size()):
		spaceships[i].position = Vector3.ZERO
		spaceships[i].rotation = Vector3.ZERO
		spaceships[i].linear_velocity = Vector3.ZERO
		spaceships[i].angular_velocity = Vector3.ZERO
	for i in range(SELECTED_QUANTITY, spaceships.size()):
		spaceships[i].nn.layers = spaceships[i%SELECTED_QUANTITY].nn.copyLayers()
		spaceships[i].mutate()
