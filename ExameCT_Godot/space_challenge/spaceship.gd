extends RigidBody3D

const THRUST = 100.0
const TURN_ACCELERATION = 10.0

var nn : NN
var time = 0


func _ready():
	nn = $NN


func mutate():
	nn.mutateNetwork(0.05, 0.1)


func _physics_process(_delta):
	var output = nn.brain([rotation.x, rotation.y, rotation.z])
	for i in range(output.size()):
		output[i] = clamp(output[i], -1, 1)
	apply_central_force(-basis.z * THRUST * output[0])
	var torque = Vector3(output[1], output[2], output[3])
	apply_torque(torque)
