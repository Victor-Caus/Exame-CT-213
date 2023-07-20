extends SpinBox

func _on_value_changed(_value):
	get_parent().get_parent().deviation = _value
