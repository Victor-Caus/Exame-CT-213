extends RigidBody3D

const THRUST = 50.0
const TURN_PITCH = 10.0
const TURN_YAW = 2.0
const TURN_ROLL = 5.0

var nn : NN
var bestParticular : NN
var reward : float
var best_reward: float
var target
var next_target
var time := 0.0

func _ready():
	nn = $NN
	bestParticular = $BestParticular
	reward = 0
	best_reward = -INF
	target = %Ring1
	next_target = %Ring2


func _physics_process(_delta):
	time += _delta
	print(reward)
#	var input = [linear_velocity.x, linear_velocity.y, linear_velocity.z]
#	input.append_array([angular_velocity.x, angular_velocity.y, angular_velocity.z])
	var relative_pos_1 = quaternion.inverse()*(target.position - position)
#	input.append_array([relative_pos_1.x, relative_pos_1.y, relative_pos_1.z])
	var relative_pos_2 = quaternion.inverse()*(next_target.position - position)
#	input.append_array([relative_pos_2.x, relative_pos_2.y, relative_pos_2.z])
#
#
#	var output = nn.brain(input)
#	for i in range(output.size()):
#		output[i] = clamp(output[i], -1, 1)
	if time < 0:
		apply_central_force(-basis.z * THRUST * (1 + 1)/2)
	var torque = quaternion * Vector3(1 * TURN_PITCH, 0 * TURN_YAW, 0 * TURN_ROLL)
	apply_torque(torque)
