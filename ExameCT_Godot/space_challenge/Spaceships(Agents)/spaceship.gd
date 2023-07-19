extends RigidBody3D

class_name Spaceship

# Dynamics Proprierties
const THRUST = 50.0
const TURN_PITCH = 10.0
const TURN_YAW = 2.0
const TURN_ROLL = 5.0


var nn : NN

# Rewards and targets components
var reward : float
var target
var next_target

func _ready():
	nn = $NN
	reward = 0
	

# Each physical time step:
func _physics_process(_delta):
	# Analyze the environment state
	var input : Array
	
	var relative_lin_vel = quaternion.inverse()*linear_velocity
	input.append_array([relative_lin_vel.x, relative_lin_vel.y, relative_lin_vel.z])
	var relative_ang_vel = quaternion.inverse()*angular_velocity
	input.append_array([relative_ang_vel.x, relative_ang_vel.y, relative_ang_vel.z])
	
	var relative_pos_1 = quaternion.inverse()*(target.position - position)
	input.append_array([relative_pos_1.x, relative_pos_1.y, relative_pos_1.z])
	var dir_1 = quaternion.inverse()*target.basis.z # Ring direction
	input.append_array([dir_1.x, dir_1.y, dir_1.z])
	
	var relative_pos_2 = quaternion.inverse()*(next_target.position - position)
	input.append_array([relative_pos_2.x, relative_pos_2.y, relative_pos_2.z])
	var dir_2 = quaternion.inverse()*next_target.basis.z # Ring direction
	input.append_array([dir_2.x, dir_2.y, dir_2.z])
	
	# Select action:
	var output = nn.brain(input)
	for i in range(output.size()):
		output[i] = clamp(output[i], -1, 1)
	apply_central_force(-basis.z * THRUST * (output[0] + 1)/2)
	
	var torque = quaternion * Vector3(output[1] * TURN_PITCH, output[2] * TURN_YAW, output[3] * TURN_ROLL)
	apply_torque(torque)

