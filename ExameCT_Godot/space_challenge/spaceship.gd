extends RigidBody3D

var nn : NN
var time = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	nn = $NN

func mutate():
	nn.mutateNetwork(0.01, 1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	var output = nn.brain([position.x, position.y, position.z])
	linear_velocity = (Vector3(output[0], output[1], output[2]))

