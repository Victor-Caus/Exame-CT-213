extends Node

class_name NN

var networkShape := [5, 32, 23, 2]
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
			layers[i].forward(layers[i - 1].nodeArray)
		else:
			layers[i].forward(layers[i - 1].nodeArray)
			layers[i].activation()

	return layers[layers.size() - 1].nodeArray

func copyLayers() -> Array:
	var tmpLayers : Array = []
	for i in range(layers.size()):
		var tmpLayer = Layer.new(networkShape[i], networkShape[i+1])
		tmpLayer.weightsArray = layers[i].weightsArray.duplicate()
		tmpLayer.biasesArray = layers[i].biasesArray.duplicate()
		tmpLayers.append(tmpLayer)

	return tmpLayers

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
			for j in range(n_inputs):
				row.append(0.0)
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

	func mutateLayer(mutationChance : float, mutationAmount : float):
		for i in range(n_neurons):
			for j in range(n_inputs):
				if randf() < mutationChance:
					weightsArray[i][j] += randf_range(-1.0, 1.0) * mutationAmount

			if randf() < mutationChance:
				biasesArray[i] += randf_range(-1.0, 1.0) * mutationAmount

func mutateNetwork(mutationChance : float, mutationAmount : float):
	for layer in layers:
		layer.mutateLayer(mutationChance, mutationAmount)
