extends RigidBody3D

const THRUST = 50.0
const TURN_ACCELERATION = 10.0

var nn : NN
var reward : float
var best_reward: float

func _ready():
	nn = $NN
	reward = 0
	best_reward = -INF


func _physics_process(_delta):
	var output = nn.brain([rotation.x, rotation.y, rotation.z])
	for i in range(output.size()):
		output[i] = clamp(output[i], -1, 1)
	apply_central_force(-basis.z * THRUST * (output[0] + 1)/2)
	var torque = quaternion * Vector3(output[1], output[2], output[3]) * TURN_ACCELERATION
	apply_torque(torque)
