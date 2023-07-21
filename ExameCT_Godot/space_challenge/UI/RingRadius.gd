extends SpinBox


func _on_value_changed(_value):
	get_parent().get_parent().radius = _value
