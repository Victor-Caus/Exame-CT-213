extends SpinBox

func _on_value_changed(value):
	get_parent().get_parent().time_per_ring = value
