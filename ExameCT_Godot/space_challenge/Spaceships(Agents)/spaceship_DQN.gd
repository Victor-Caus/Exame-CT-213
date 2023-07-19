extends RigidBody3D

class_name Spaceship_DQN

# Dynamic constants
const THRUST = 50.0
const TURN_PITCH = 10.0
const TURN_YAW = 2.0
const TURN_ROLL = 5.0
const SENSE = [-1.0 , 0.0 , 1.0] # Array that gives the "direction" of force

# NN variables:
var nn : NN
const OUTPUT_ENTRIES = 4
const ACTION_OPTIONS = 3

# Targets and Rewards:
@onready var cumulative_reward := 0.0
@onready var reward := 0.0
var target
var next_target


# DQN Agent attributes
var epsilon = 0.01
var action_variability = 2
@onready var first_state = true
const BATCH_SIZE = 32 # batch size of experience replay 
var replay_buffer = [Experience]
var return_history = []
var previous_state
var action
var gamma = 0.98 # Gamma that makes past states values less



func _ready():
	nn = $NN_DQN


# Each physical time step:
func _physics_process(_delta):
	# Analyze the environment reward (R) and new state (S')
	var new_state = state()
	reward += instantaneous_reward()
	
	# Select action based on epsilon-greedy policy (A):
	var action = act(new_state)
	impulse(action) # Contribute to the next state, applying force
	
	if not first_state:
		# Append the experience (S, A, R, S') to the experience replay buffer:
		replay_buffer.append(Experience.new(previous_state, action, reward, new_state))
	
	
	# Accumulate reward:
	cumulative_reward = gamma * cumulative_reward + reward
	
	# If we have enough experience in memory, update the policy:
	if replay_buffer.size() > 2 * BATCH_SIZE:
		var loss = replay(BATCH_SIZE)
	
	# Preparations to the next state:
	previous_state = new_state
	first_state = false # Now it's not anymore the first state
	reward = 0 

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
	
# Executes the mechanical action
func impulse(action) -> void:
	apply_central_force(-basis.z * THRUST * (SENSE[action[0]] + 1)/2)
	var torque = quaternion * Vector3(SENSE[action[1]] * TURN_PITCH, SENSE[action[2]] * TURN_YAW, SENSE[action[3]] * TURN_ROLL)
	apply_torque(torque)

# Epsilon-greedy policy
func act(input):
	var output = nn.brain(input)
	var action = to_matrix(output)
	var best_decisions = [] # best arguments for each entry
	
	# For each action entry, choose the epsilon greedy argument:
	for i in range(OUTPUT_ENTRIES):
		if randf_range(0, 1.0) < epsilon:
			best_decisions[i] = randi() % self.action_size
		else:	
			# Choose the action with greater value in the entry:
			best_decisions[i] = argmax(action[i])
	return best_decisions
			

	
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
	var minibatch := [Experience]
	var states := []
	var targets := []
	# Take random samples to compose the minibatch:
	for i in range(batch_size):
		var index = randi() % replay_buffer.size()
		minibatch.append(replay_buffer[index])
	for experience in minibatch:
		target = nn.brain(experience.previous_state)
		

# Reward given for each step:
func instantaneous_reward():
	# Punish the ships that got to far from their target 
	reward -= 0.0001 * position.distance_to(get_parent().ring_manager.rings[-2].position)
	# Punish if they get far from
	reward -= 0.00001 * position.distance_to(get_parent().ring_manager.rings[-1].position)
	# There will be one frame in which the ring will give a big reward.


# Utils:
func argmax(array):
	var max_value = -INF
	var max_index = -1
	for i in range(array.size()):
		if array[i] > max_value:
			max_value = array[i]
			max_index = i
	return max_index

func to_matrix(array):
	var matrix = [[]]
	var matrificator : int = 0
	# Transform output of the NN into a matrix:
	for i in range(OUTPUT_ENTRIES):
		for j in range(ACTION_OPTIONS):
			action[i][j] = array[matrificator]
			matrificator += 1
	return matrix
