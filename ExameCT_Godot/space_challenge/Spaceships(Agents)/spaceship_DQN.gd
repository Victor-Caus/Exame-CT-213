extends RigidBody3D

class_name Spaceship_DQN

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

# DQN Agent attributes
var epsilon = 0.01

func _ready():
	nn = $NN
	bestParticular = $BestParticular
	reward = 0
	best_reward = -INF

# Each physical time step:
func _physics_process(_delta):
	# Analyze the environment state
	var input = state()
	# Select action based on epsilon-greedy policy:
	var output = nn.brain(input)
	for i in range(output.size()):
		output[i] = clamp(output[i], -1, 1)
	apply_central_force(-basis.z * THRUST * (output[0] + 1)/2)
	
	var torque = quaternion * Vector3(output[1] * TURN_PITCH, output[2] * TURN_YAW, output[3] * TURN_ROLL)
	apply_torque(torque)


# State (represented by the inputs)
func state():
	var input = [linear_velocity.x, linear_velocity.y, linear_velocity.z]
	input.append_array([angular_velocity.x, angular_velocity.y, angular_velocity.z])
	
	var relative_pos_1 = quaternion.inverse()*(target.position - position)
	input.append_array([relative_pos_1.x, relative_pos_1.y, relative_pos_1.z])
	var dir_1 = quaternion.inverse()*target.basis.z # Ring direction
	input.append_array([dir_1.x, dir_1.y, dir_1.z])
	
	var relative_pos_2 = quaternion.inverse()*(next_target.position - position)
	input.append_array([relative_pos_2.x, relative_pos_2.y, relative_pos_2.z])
	var dir_2 = quaternion.inverse()*next_target.basis.z # Ring direction
	input.append_array([dir_2.x, dir_2.y, dir_2.z])
	
	return input
	
