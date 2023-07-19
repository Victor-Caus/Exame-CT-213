extends SpinBox

func _on_value_changed(_value):
	get_parent().get_parent().time_per_ring = _value
