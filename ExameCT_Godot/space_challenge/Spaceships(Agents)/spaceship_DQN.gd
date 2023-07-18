extends RigidBody3D

class_name Spaceship_DQN

# Dynamic constants
const THRUST = 50.0
const TURN_PITCH = 10.0
const TURN_YAW = 2.0
const TURN_ROLL = 5.0

# NN Components:
var nn : NN
var bestParticular : NN

# Targets and Rewards:
var reward : float
var best_reward: float
var target
var next_target
@onready var cumulative_reward := 0.0

# DQN Agent attributes
var epsilon = 0.01
var action_variability = 2
@onready var first_state = true
const BATCH_SIZE = 32 # batch size of experience replay 
var replay_buffer = []
var return_history = []
var previous_state
var action
var gamma = 0.98 # Gamma that makes past states values less



func _ready():
	nn = $NN
	bestParticular = $BestParticular
	reward = 0
	best_reward = -INF

# Each physical time step:
func _physics_process(_delta):
	# Analyze the environment state (S)
	var new_state = state()

	# Select action based on epsilon-greedy policy (A):
	var output = act(new_state)
	
	# Contribute to the next state: (S'):
	apply_central_force(-basis.z * THRUST * (output[0] + 1)/2)
	var torque = quaternion * Vector3(output[1] * TURN_PITCH, output[2] * TURN_YAW, output[3] * TURN_ROLL)
	apply_torque(torque)
	
	if not first_state:
		# Append the experience (S, A, R, S') to the experience replay buffer:
		replay_buffer.append(Experience.new(previous_state, action, reward, new_state))
	
	# Preparations to the next state:
	previous_state = new_state
	action = output
	first_state = false # Now it's not anymore the first state
	
	# Accumulate reward:
	cumulative_reward = gamma * cumulative_reward + reward
	
	# If we have enough experience in memory, update the policy:
	if replay_buffer.size() > 2 * BATCH_SIZE:
		var loss = replay(BATCH_SIZE)


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

# Epsilon-greedy policy
func act(input):
	var output = nn.brain(input)
	if randf_range(0, 1.0) < epsilon:
		for i in range(output.size()):
			# Clamping to valorize "extreme actions"/"binary decisions"
			output[i] = clamp(randf_range(-1.0, 1.0)*action_variability, -1, 1)
	else:	
		for i in range(output.size()):
			output[i] = clamp(output[i], -1, 1)
			
#
class Experience:
	var previous_state
	var action
	var reward
	var new_state
	func _init(previous_state, action, reward, new_state):
		self.previous_state = previous_state
		self.action = action
		self.reward = reward
		self.new_state = new_state
		
# Learns from memorized experience
func replay(batch_size : int):
	var minibatch := []
	for i in range(batch_size):
		var index = randi() % replay_buffer.size()
		minibatch.append(replay_buffer[index])

