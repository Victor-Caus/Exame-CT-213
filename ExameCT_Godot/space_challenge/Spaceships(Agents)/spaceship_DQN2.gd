extends RigidBody3D

class_name Spaceship_DQN2

# Dynamic constants
const THRUST = 50.0
const TURN_PITCH = 10.0
const TURN_YAW = 2.0
const TURN_ROLL = 5.0
const SENSE = [-1.0 , 0.0 , 1.0] # Array that gives the "direction" of force

# NN variables:
var nn : NN_DQN # action-value
var fixed_nn : NN_DQN # target action-value
const OUTPUT_ENTRIES = 1
const ACTION_OPTIONS = 4

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
@onready var first_state = true
const BUFFER_SIZE = 1048576
const BATCH_SIZE = 8 # batch size of experience replay 
@onready var replay_buffer = []
var return_history = []
var previous_state
var previous_action




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
		if get_parent().time + _delta > get_parent().selection_time: 
			add_to_buffer(Experience.new(previous_state, previous_action, reward, new_state,true))
		else:
			add_to_buffer(Experience.new(previous_state, previous_action, reward, new_state,false))
	
	# Accumulate reward:
	cumulative_reward = gamma * cumulative_reward + reward
	
	# If we have enough experience in memory, update the policy:
	if replay_buffer.size() > 2 * BATCH_SIZE:
		replay()
	
	# Preparations to the next state:
	previous_state = new_state
	previous_action = action
	first_state = false # Now it's not anymore the first state
	reward = 0 

# State (represented by the inputs)
func state():
	# Analyze the environment state
	var input : Array = []
	
	# Input in spherical coordinates
	# Velocities (in the spaceships frame os reference) 
	var relative_lin_vel = spherical_coordinate(quaternion.inverse()*linear_velocity)
	input.append_array([relative_lin_vel.x, relative_lin_vel.y, relative_lin_vel.z])
	var relative_ang_vel = quaternion.inverse()*angular_velocity # Cartesian coordinates
	input.append_array([relative_ang_vel.x, relative_ang_vel.y, relative_ang_vel.z])
	# First target position (in the spaceships frame os reference) 
	var relative_pos_1 = spherical_coordinate(quaternion.inverse()*(target.position - position))
	input.append_array([relative_pos_1.x, relative_pos_1.y, relative_pos_1.z])
	var dir_1 = spherical_coordinate(quaternion.inverse()*target.basis.z)
	input.append_array([dir_1.y, dir_1.z])  # Ring direction
	# Second target position (in the spaceships frame os reference) 
	var relative_pos_2 = spherical_coordinate(quaternion.inverse()*(next_target.position - position))
	input.append_array([relative_pos_2.x, relative_pos_2.y, relative_pos_2.z])
	var dir_2 = spherical_coordinate(quaternion.inverse()*next_target.basis.z)
	input.append_array([dir_2.y, dir_2.z]) # Ring direction
	
	return input
	
# Executes the mechanical action
func impulse(action) -> void:
	match(action[0]):
		0:
			apply_central_force(-basis.z * THRUST)
		1:
			apply_torque(quaternion * Vector3(TURN_PITCH, 0,0))
		2:
			apply_torque(quaternion * Vector3(0, TURN_YAW,0))
		3:
			apply_torque(quaternion * Vector3(0, 0,TURN_ROLL))

# Epsilon-greedy policy
func act(input):
	var output = nn.brain(input)
	var action = to_matrix(output)
	var best_decisions = [] # best arguments for each entry
	
	# For each action entry, choose the epsilon greedy argument:
	for i in range(OUTPUT_ENTRIES):
		if randf_range(0, 1.0) < epsilon:
			best_decisions.push_back(randi() % ACTION_OPTIONS)
		else:
			# Choose the action with greater value in the entry:
			best_decisions.push_back(argmax(action[i]))
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

func pick_random():
	var indices = []
	for i in range(BATCH_SIZE):
		indices.append(randi() % replay_buffer.size())
	var minibatch = []
	for i in indices:
		minibatch.append(replay_buffer[i])
	return minibatch

# Learns from memorized experience
func replay():
	var minibatch = pick_random()
	var states = []
	var targets = []
	for experience in minibatch:
		var previous_state = experience.previous_state
		var actions = experience.action
		var reward = experience.reward
		var new_state = experience.new_state
		var target = to_matrix(fixed_nn.brain(previous_state))
		var output_matrix = to_matrix(fixed_nn.brain(new_state))
		for i in range(OUTPUT_ENTRIES):
			if experience.done:
				target[i][actions[i]] = reward
			else:
				# Fixed Q-Target:
				target[i][actions[i]] = reward + gamma * (output_matrix[i]).max()
			targets.append(to_array(target))
		# Filtering out states for training
		states.append(previous_state)
		
	nn.backpropagation(states, targets)
	#var history = self.model.fit(np.array(states), np.array(targets), epochs=1, verbose=0)
	# Keeping track of loss
	#var loss = history.history['loss'][0]
	pass

# Reward given for each step:
func instantaneous_reward():
	# Punish the ships that got to far from their target 
	return -0.00001 * position.distance_to(get_parent().ring_manager.rings[-2].position)


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
	var matrix : Array[Array] = []
	var matrificator : int = 0
	# Transform output of the NN into a matrix:
	for i in range(OUTPUT_ENTRIES):
		matrix.push_back([])
		for j in range(ACTION_OPTIONS):
			matrix[i].push_back(array[matrificator])
			matrificator += 1
	return matrix
	
func to_array(matrix):
	var array = []
	# Transform output of the NN into a matrix:
	for i in range(OUTPUT_ENTRIES):
		for j in range(ACTION_OPTIONS):
			array.push_back(matrix[i][j])
	return array


func spherical_coordinate(vector:Vector3) -> Vector3:
	var r = vector.length()
	var theta = vector.angle_to(Vector3.FORWARD)
	var phi = atan2(vector.y, vector.x)
	return Vector3(r, theta, phi)
