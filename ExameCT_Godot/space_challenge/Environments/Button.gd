extends Button

var increase 
# Called when the region is pressed
func _on_pressed():
	var ring_manager = $"../../RingManager"
	var pivot = $"../../Pivot"
	var n
	n = ring_manager.rings.size()
	print("entramos")
	if n > 2:
		increase = ring_manager.rings[n-2].position - ring_manager.rings[n-3].position
		pivot.translate(increase)
