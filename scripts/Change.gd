
extends Node3D
var _player_instance:Node
@export_file("*.tscn") var target_scene_path: String 
func _ready() -> void:
	_player_instance = get_tree().get_first_node_in_group("Player")

func _on_area_area_entered(area: Area3D) -> void:
	if _player_instance:
		print("Portal: Jugador detectado. Llamando al GameManager...")
		GameManager.change_scene_via_portal("next_scene_packed")

