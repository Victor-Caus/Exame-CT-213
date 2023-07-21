extends Node

class_name NN_DQN

@export var networkShape : Array[int]
var layers : Array


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
			layers[i].forward(layers[i - 1].a)
		else:
			layers[i].forward(layers[i - 1].a)
			layers[i].activation()
	
	return layers[layers.size() - 1].z


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
	var z : Array
	var a : Array
	var n_inputs : int
	var n_neurons : int
	
	
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
		n_inputs = _n_inputs
		n_neurons = _n_neurons
		
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
		z = []
		for i in range(n_neurons):
			var node = 0.0
			for j in range(n_inputs):
				node += weightsArray[i][j] * inputsArray[j]
		
			node += biasesArray[i]
			z.append(node)
	
	
	func activation():
		a = []
		for i in range(z.size()):
			a.append(NN_DQN.sigmoid(z[i]))
	
	
	func mutateLayer(deviation : float):
		# Previous parameters are the mean of the new parameters
		for i in range(n_neurons):
			for j in range(n_inputs):
				weightsArray[i][j] = randfn(weightsArray[i][j], deviation)
			biasesArray[i] = randfn(biasesArray[i], deviation)


func mutateNetwork(deviation : float):
	for layer in layers:
		layer.mutateLayer(deviation)


func compute_gradient(states, targets):
	var final_gradient = []
	# Gradient has the same shape as NN
	for l in range(networkShape.size() - 1):
		final_gradient.append(Layer.new(networkShape[l], networkShape[l+1]))
	
	for i in range(states.size()):
		var gradient = []
		# Gradient has the same shape as NN
		for l in range(networkShape.size() - 1):
			gradient.append(Layer.new(networkShape[l], networkShape[l+1]))
		var output = brain(states[i])
		# Output layer
		for j in networkShape[-1]:
			var delta_j = output[j] - targets[i][j]
			gradient[-1].biasesArray[j] = delta_j
			final_gradient[-1].biasesArray[j] += gradient[-1].biasesArray[j]/states.size()
			for k in networkShape[-2]:
				gradient[-1].weightsArray[j][k] = delta_j * layers[-2].a[k]
				final_gradient[-1].weightsArray[j][k] += gradient[-1].weightsArray[j][k]/states.size()
		# Hidden layers
		for l in range(networkShape.size() - 3, -1, -1):
			# l = 0 is the first hidden layer, l = networkShape.size() - 2 is the output layer
			for j in networkShape[l+1]:
				var delta_j = 0
				for p in range(networkShape[l+2]):
					delta_j += gradient[l+1].weightsArray[p][j] * gradient[l+1].biasesArray[p]
				delta_j *= NN_DQN.sigmoid_derivative(layers[l].z[j])
				gradient[l].biasesArray[j] = delta_j
				final_gradient[l].biasesArray[j] += gradient[l].biasesArray[j]/states.size()
				for k in networkShape[l]:
					if l == 0: # First hidden layer
						pass
					else:
						gradient[l].weightsArray[j][k] = delta_j * layers[l-1].a[k]
					final_gradient[l].weightsArray[j][k] += gradient[l].weightsArray[j][k]/states.size()
	
	return final_gradient


func backpropagation(states, targets):
	var gradient = compute_gradient(states, targets)
	for k in layers.size():
		for i in range(layers[k].weightsArray.size()):
			layers[k].biasesArray[i] -= get_parent().learning_rate * gradient[k].biasesArray[i]
			for j in range(layers[k].weightsArray[0].size()):
				layers[k].weightsArray[i][j] -= get_parent().learning_rate * gradient[k].weightsArray[i][j]


static func sigmoid(x):
	return 1.0 / (1.0 + exp(-x))


static func sigmoid_derivative(x):
	return sigmoid(x) * (1.0 - sigmoid(x))
	
