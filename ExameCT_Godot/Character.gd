extends Area2D

var nn : NN
var time = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	nn = $NN
	nn.mutateNetwork(0.5,0.5)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time += delta
	var output = nn.brain([time, pingpong(time,2),  pingpong(time,3), pingpong(time,4), pingpong(time,5)])
	position = (Vector2(output[0], output[1]) + Vector2.ONE*2)*100

