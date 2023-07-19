extends SpinBox

func _on_value_changed(_value):
	$"../../RingManager".ring_dist = _value
