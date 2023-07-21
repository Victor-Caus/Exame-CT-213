extends Node

class_name NN

@export var networkShape : Array[int]
var layers : Array

# PSO:
const FIRST_MUTATE_CHANCE = 1
const FIRST_MUTATE_AMOUT = 1
const MAX_VEL = 1 * FIRST_MUTATE_AMOUT


func _ready():
	layers = []
	for i in range(networkShape.size() - 1):
		layers.append(Layer.new(networkShape[i], networkShape[i+1]))
	
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
	
	return tmpLayers

# File Save and Load System
func saveNN():
	var file = FileAccess.open("res://Data/bestNN", FileAccess.WRITE)
	if not file:
		return
	var save_dict = {
		networkShape = [],
		layers = [],
	}
	
	for i in range(networkShape.size()):
		save_dict.networkShape.push_back(var_to_str(networkShape[i]))
	
	for layer in layers:
		save_dict.layers.push_back(layer.layer_to_dict())
	
	file.store_line(JSON.stringify(save_dict))
	file.close()


func loadNN():
	var file = FileAccess.open("res://Data/bestNN", FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	json.parse(file.get_line())
	var save_dict := json.get_data() as Dictionary
	
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
	# PSO vars
	var weightsVelocities : Array[Array]
	var biasesVelocities : Array
	var maxVelocity
	
	
	func layer_to_dict():
		var save_dict = {
			weightsArray = [],
			biasesArray = [],
			n_inputs = var_to_str(n_inputs),
			n_neurons = var_to_str(n_neurons),
		}
		
		for bias in biasesArray:
			save_dict.biasesArray.push_back(var_to_str(bias))
		
		for weights in weightsArray:
			var tmp_array : Array = []
			for weight in weights:
				tmp_array.push_back(var_to_str(weight))
			save_dict.weightsArray.push_back(tmp_array)
			
		return save_dict
	
	
	func dict_to_layer(save_dict : Dictionary):
		n_neurons = str_to_var(save_dict.n_neurons)
		n_inputs = str_to_var(save_dict.n_inputs)
		
		biasesArray.clear()
		for bias in save_dict.biasesArray:
			biasesArray.push_back(str_to_var(bias))
		
		weightsArray.clear()
		for weights in save_dict.weightsArray:
			var tmp_array : Array = []
			for weight in weights:
				tmp_array.push_back(str_to_var(weight))
			weightsArray.push_back(tmp_array)
	
	
	func _init(_n_inputs, _n_neurons):
		self.n_inputs = _n_inputs
		self.n_neurons = _n_neurons
		
		weightsArray = []
		biasesArray = []
		for i in range(n_neurons):
			var row = []
			var row_v = []
			for j in range(n_inputs):
				row.append(0.0)
				row_v.append(0.0)
			weightsArray.append(row)
			weightsVelocities.append(row_v)
			biasesArray.append(0.0)
			biasesVelocities.append(0.0)
	
	
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
	
	
	func PSO_InitializeLayer(mutationChance : float, mutationAmount : float, maxVel: float):
		for i in range(n_neurons):
			for j in range(n_inputs):
				weightsArray[i][j] = 0
				if randf() < mutationChance:
					weightsArray[i][j] += randf_range(-1.0, 1.0) * mutationAmount
				weightsVelocities[i][j] = randf_range(-1.0, 1.0) * maxVel
			
			biasesArray[i] = 0
			if randf() < mutationChance:
				biasesArray[i] += randf_range(-1.0, 1.0) * mutationAmount
			biasesVelocities[i] = randf_range(-1.0, 1.0) * maxVel
	
	
	func PSO_MutateLayer(inertia_weight : float, cognitive_p : float, social_p: float,  best_particular : Layer, best_global : Layer):
		for i in range(n_neurons):
			for j in range(n_inputs):
				weightsVelocities[i][j] = inertia_weight * weightsVelocities[i][j] + cognitive_p * randf_range(0, 1.0) * (best_particular.weightsArray[i][j] - weightsArray[i][j]) + social_p * randf_range(0, 1.0) * (best_global.weightsArray[i][j] - weightsArray[i][j]) 
				weightsArray[i][j] += weightsVelocities[i][j]
			
			biasesVelocities[i] = inertia_weight * biasesVelocities[i] + cognitive_p * randf_range(0, 1.0) * (best_particular.biasesArray[i] - biasesArray[i]) + social_p * randf_range(0, 1.0) * (best_global.biasesArray[i] - biasesArray[i]) 
			biasesArray[i] += biasesVelocities[i]


func mutateNetwork(deviation : float):
	for layer in layers:
		layer.mutateLayer(deviation)


func PSO_Initialize():
	for layer in layers:
			layer.PSO_InitializeLayer(FIRST_MUTATE_CHANCE, FIRST_MUTATE_AMOUT, MAX_VEL) # Hyperparameters!


func PSO(inertia_weight : float, cognitive_p : float, social_p: float, best_global : NN):
	for i in range(layers.size()):
		var layer = layers[i]
		var best_particular = get_parent().bestParticular.layers[i]
		var best_global_layer = best_global.layers[i]
		layer.PSO_MutateLayer(inertia_weight, cognitive_p, social_p,  best_particular, best_global_layer)
