extends Control

@export_file("*.tscn") var ES
@export_file("*.tscn") var PSO
@export_file("*.tscn") var DQN
@export_file("*.tscn") var DQN2



func _on_es_pressed():
	get_tree().change_scene_to_file(ES)


func _on_pso_pressed():
	get_tree().change_scene_to_file(PSO)


func _on_dqn_pressed():
	get_tree().change_scene_to_file(DQN)


func _on_dqn_2_pressed():
	get_tree().change_scene_to_file(DQN2)
