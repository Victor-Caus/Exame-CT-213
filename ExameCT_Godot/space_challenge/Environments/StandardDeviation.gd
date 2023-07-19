extends SpinBox

func _on_value_changed(value):
	get_parent().get_parent().deviation = value
