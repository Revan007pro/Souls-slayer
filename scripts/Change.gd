extends Node3D

@export var next_scene: PackedScene
var new_world:Node
var _player_instance:Node 


func _ready() -> void:
	_player_instance = get_tree().get_first_node_in_group("Player")

func _on_area_3d_area_entered(area: Area3D) -> void:
	if _player_instance :
		call_deferred("change_scene")

func change_scene() -> void:
	get_tree().change_scene_to_packed(next_scene)
