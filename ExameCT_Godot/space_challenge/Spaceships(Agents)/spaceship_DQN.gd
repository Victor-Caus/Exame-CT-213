extends RigidBody3D

class_name Spaceship_DQN

# Dynamic constants
const THRUST = 50.0
const TURN_PITCH = 10.0
const TURN_YAW = 2.0
const TURN_ROLL = 5.0
const SENSE = [-1.0 , 0.0 , 1.0] # Array that gives the "direction" of force

# NN variables:
var nn : NN # action-value
var fixed_nn : NN # target action-value
const OUTPUT_ENTRIES = 4
const ACTION_OPTIONS = 3

# Targets and Rewards:
@onready var cumulative_reward := 0.0
@onready var reward := 0.0
var target
var next_target


# DQN Agent attributes
var epsilon = 1
@export var epsilon_min = 0.05
@export var gamma = 0.98 # Gamma that makes past states values less
@export var learning_rate = 0.5 
var action_variability = 2
@onready var first_state = true
const BUFFER_SIZE = 4098
const BATCH_SIZE = 32 # batch size of experience replay 
@onready var replay_buffer = []
var return_history = []
var previous_state
var action




func _ready():
	nn = $NN_DQN
	fixed_nn = $FIXED_DQN
	randomize()


# Each physical time step:
func _physics_process(_delta):
	# Analyze the environment reward (R) and new state (S')
	var new_state = state()
	reward += instantaneous_reward()
	
	# Select action based on epsilon-greedy policy (A):
	var action = act(new_state)
	impulse(action) # Contribute to the next state, applying force
	
	if not first_state:
		# Append the experience (S, A, R, S', done), but let's see if it's done:
		if get_parent().time + _delta > get_parent().SELECTION_TIME: 
			replay_buffer.append(Experience.new(previous_state, action, reward, new_state,true))
		else:
			replay_buffer.append(Experience.new(previous_state, action, reward, new_state,false))
	
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
	var done : bool
	func _init(previous_state, action, reward, new_state,done):
		self.previous_state = previous_state
		self.action = action
		self.reward = reward
		self.new_state = new_state
		self.done = done

func add_to_buffer(item):
	replay_buffer.append(item)
	if replay_buffer.size() > BUFFER_SIZE:
		replay_buffer.pop_front()

func pick_random(batch_size):
	var indices = []
	for i in range(BATCH_SIZE):
		indices.append(randi() % replay_buffer.size())
	var minibatch = []
	for i in indices:
		minibatch.append(replay_buffer[i])
	return minibatch

# Learns from memorized experience
func replay(batch_size: int):
	"""
	Learns from memorized experience.

	:param batch_size: size of the minibatch taken from the replay buffer.
	:type batch_size: int.
	:return: loss computed during the neural network training.
	:rtype: float.
	"""
	var minibatch = pick_random(BATCH_SIZE)
	var states = []
	var targets = [[]]
	for experience in minibatch:
		var previous_state = experience[0]
		var reward = experience[2]
		var new_state = experience[3]
		var target = []
		for i in range(OUTPUT_ENTRIES):
			var entry_action = experience[1][i]
			if experience.done:
				target[i]= reward
			else:
				# Fixed Q-Target:
				target[i] = reward + gamma * max(to_matrix(fixed_nn.brain(new_state))[i])
			targets[i].append(target[i])
		# Filtering out states for training
		states.append(previous_state)
	var loss = nn.backpropagation(states, targets)
	#var history = self.model.fit(np.array(states), np.array(targets), epochs=1, verbose=0)
	# Keeping track of loss
	#var loss = history.history['loss'][0]
	pass

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
