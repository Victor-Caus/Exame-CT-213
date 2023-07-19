extends Node

class_name NN_DQN

@export var networkShape : Array[int]
var layers : Array

# Save and Load System:
var isPSO : bool = false
var autoloadNN : bool = false

func _ready():
	layers = []
	for i in range(networkShape.size() - 1):
		layers.append(Layer.new(networkShape[i], networkShape[i+1]))
	
	if autoloadNN:
		layers = loadNN()
		
	randomize()


func brain(inputs : Array) -> Array:
	for i in range(layers.size()):
		if i == 0:
			layers[i].forward(inputs)
			layers[i].activation()
		elif i == layers.size() - 1:
			layers[i].forward(layers[i - 1].nodeArray)
		else:
			layers[i].forward(layers[i - 1].nodeArray)
			layers[i].activation()
	
	return layers[layers.size() - 1].nodeArray


func copyLayers() -> Array:
	var tmpLayers : Array = []
	for i in range(layers.size()):
		var tmpLayer = Layer.new(networkShape[i], networkShape[i+1])
		tmpLayer.weightsArray = layers[i].weightsArray.duplicate(true)
		tmpLayer.biasesArray = layers[i].biasesArray.duplicate(true)
		tmpLayers.append(tmpLayer)
	print(tmpLayers)
	
	return tmpLayers


# File Save and Load System
func saveNN():
	var file = FileAccess.open("res://Data/bestNN", FileAccess.WRITE)
	var save_dict = {
		networkShape = [],
		layers = [],
		isPSO = var_to_str(isPSO),
	}
	
	for i in range(networkShape.size()):
		save_dict.networkShape.push_back(var_to_str(networkShape[i]))
	
	for layer in layers:
		save_dict.layers.push_back(layer.layer_to_dict())
	
	file.store_line(JSON.stringify(save_dict))
	file.close()

func loadNN():
	var file = FileAccess.open("res://Data/bestNN", FileAccess.READ)
	var json := JSON.new()
	json.parse(file.get_line())
	var save_dict := json.get_data() as Dictionary
	
	isPSO = str_to_var(save_dict.isPSO)
	
	networkShape = []
	for i in range(save_dict.networkShape.size()):
		networkShape.push_back(str_to_var(save_dict.networkShape[i]))
	
	layers = []
	for i in range(networkShape.size() - 1):
		layers.append(Layer.new(networkShape[i], networkShape[i+1]))
		layers[-1].dict_to_layer(save_dict.layers[i])
	
	file.close()

class Layer:
	var weightsArray : Array[Array]
	var biasesArray : Array
	var nodeArray : Array
	var n_inputs : int
	var n_neurons : int
	
	func _init(n_inputs, n_neurons):
		self.n_inputs = n_inputs
		self.n_neurons = n_neurons
		
		weightsArray = []
		biasesArray = []
		for i in range(n_neurons):
			var row = []
			var row_v = []
			for j in range(n_inputs):
				row.append(0.0)
				row_v.append(0.0)
			weightsArray.append(row)
			biasesArray.append(0.0)
	
	func forward(inputsArray : Array):
		nodeArray = []
		for i in range(n_neurons):
			var node = 0.0
			for j in range(n_inputs):
				node += weightsArray[i][j] * inputsArray[j]
		
			node += biasesArray[i]
			nodeArray.append(node)
	
	func activation():
		for i in range(nodeArray.size()):
			nodeArray[i] = tanh(nodeArray[i])
	
	func mutateLayer(deviation : float):
		for i in range(n_neurons):
			for j in range(n_inputs):
				weightsArray[i][j] = randfn(weightsArray[i][j], deviation)
			biasesArray[i] = randfn(biasesArray[i], deviation)

func mutateNetwork(deviation : float):
	for layer in layers:
		layer.mutateLayer(deviation)

# NN Gradient Descend:
func loss(states, targets):
	for i in range(states.size()):
		
	var cost = mean(-(y * log(y_hat) + (1.0 - y) * log(1.0 - y_hat)))
	return cost


# Utils: activation functions:
func relu(x):
	return max(0,x)
	
func sigmoid(x):
	return 1.0 / (1.0 + exp(-x))

