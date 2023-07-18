extends Node

class_name NN

@export var networkShape := [15, 32, 23]
var layers : Array

# PSO:
var isPSO: bool = true
const FIRST_MUTATE_CHANCE = 1
const FIRST_MUTATE_AMOUT = 1
const MAX_VEL = 1 * FIRST_MUTATE_AMOUT

func _ready():
	layers = []
	for i in range(networkShape.size() - 1):
		layers.append(Layer.new(networkShape[i], networkShape[i+1]))
		
	if isPSO:
		for layer in layers:
			layer.PSO_InitializeLayer(FIRST_MUTATE_CHANCE, FIRST_MUTATE_AMOUT, MAX_VEL) # Hyperparameters!

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

	func mutateLayer(mutationChance : float, mutationAmount : float):
		for i in range(n_neurons):
			for j in range(n_inputs):
				if randf() < mutationChance:
					weightsArray[i][j] += randf_range(-1.0, 1.0) * mutationAmount

			if randf() < mutationChance:
				biasesArray[i] += randf_range(-1.0, 1.0) * mutationAmount
				
				
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

func mutateNetwork(mutationChance : float, mutationAmount : float):
	for layer in layers:
		layer.mutateLayer(mutationChance, mutationAmount)
		
func PSO(inertia_weight : float, cognitive_p : float, social_p: float, best_global : NN):
	for i in range(layers.size()):
		var layer = layers[i]
		var best_particular = get_parent().bestParticular.layers[i]
		var best_global_layer = best_global.layers[i]
		layer.PSO_MutateLayer(inertia_weight, cognitive_p, social_p,  best_particular, best_global_layer)
