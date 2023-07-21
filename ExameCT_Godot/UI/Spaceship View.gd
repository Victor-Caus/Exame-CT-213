extends Button

@onready var ring_manager = $"../../RingManager"
@onready var camera = $"../../Pivot/Camera3D"
@onready var pivot = $"../../Pivot"
var on

# Called when the node enters the scene tree for the first time.
func _ready():
	on = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if on:
		var reference = get_parent().get_parent().spaceships[0].position 
		pivot.position = reference


func _on_pressed():
	# Take the position of the previous best spaceship
	camera.position.z = 2
	camera.position.x = 0
	camera.position.y = 0
	camera.rotation.y = 0
	on = true
