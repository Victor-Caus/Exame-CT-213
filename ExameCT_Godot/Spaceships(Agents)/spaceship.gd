extends RigidBody3D

class_name Spaceship

# Dynamic constants
const THRUST = 50.0
const TURN_PITCH = 10.0
const TURN_YAW = 2.0
const TURN_ROLL = 5.0

# NN variables:
var nn : NN
var bestParticular : NN

# Rewards and targets components
var reward : float
@onready var best_reward := -INF
var target
var next_target

# Called when the node enters the scene tree for the first time.
func _ready():
	nn = $NN
	bestParticular = $BestParticular
	reward = 0

# Each physical time step:
func _physics_process(_delta):
	# Ship transparency depends on target transparency
	var ring_transparency = target.get_node("ringmesh").transparency
	$MeshInstance3D.transparency = clamp(ring_transparency * 5, 0, 0.9)
	$Exaust.visible = not (ring_transparency > 0.01)
	
	# Analyze the environment state
	var input : Array = []
	
	# Velocities (in the spaceships frame os reference)
	var relative_lin_vel = quaternion.inverse()*linear_velocity
	input.append_array([relative_lin_vel.x, relative_lin_vel.y, relative_lin_vel.z])
	var relative_ang_vel = quaternion.inverse()*angular_velocity
	input.append_array([relative_ang_vel.x, relative_ang_vel.y, relative_ang_vel.z])
	
	# First target position (in the spaceships frame os reference)
	var relative_pos_1 = quaternion.inverse()*(target.position - position)
	input.append_array([relative_pos_1.x, relative_pos_1.y, relative_pos_1.z])
	var dir_1 = quaternion.inverse()*target.basis.z # Ring direction
	input.append_array([dir_1.x, dir_1.y, dir_1.z])
	
	# Second target position (in the spaceships frame os reference)
	var relative_pos_2 = quaternion.inverse()*(next_target.position - position)
	input.append_array([relative_pos_2.x, relative_pos_2.y, relative_pos_2.z])
	var dir_2 = quaternion.inverse()*next_target.basis.z # Ring direction
	input.append_array([dir_2.x, dir_2.y, dir_2.z])
	
	# Select action:
	var output = nn.brain(input)
	
	# Limit outputs
	for i in range(output.size()):
		output[i] = clamp(output[i], -1, 1)
	apply_central_force(-basis.z * THRUST * (output[0] + 1)/2)
	
	var torque = quaternion * Vector3(output[1] * TURN_PITCH, output[2] * TURN_YAW, output[3] * TURN_ROLL)
	apply_torque(torque)
