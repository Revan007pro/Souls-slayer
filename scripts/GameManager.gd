extends Node

@onready var _player_recurrente: PackedScene = preload("res://player_escena.tscn")
var player_instance: Node3D
var cambiar: bool
var escenas_mundo: Dictionary = {
	"town": "res://town.tscn",
	"next_scene_packed": "res://prueba_1.tscn"
}


func change_scene_via_portal(scene_key: String) -> void:
	if escenas_mundo.has(scene_key):
		var next_scene_path = escenas_mundo[scene_key]
		var next_scene_packed: PackedScene = load(next_scene_path)

		print("GM: Recibida solicitud de cambio a:", scene_key)
		if is_instance_valid(player_instance) and player_instance.get_parent():
			player_instance.get_parent().remove_child(player_instance)

		get_tree().change_scene_to_packed(next_scene_packed)
		await get_tree().process_frame
		
		get_tree().root.add_child(player_instance)
		call_deferred("configure_new_scene")


func configure_new_scene():
	var new_scene_root = get_tree().current_scene
	
	if is_instance_valid(new_scene_root):
		var terrain_node = new_scene_root.find_node("Terrain3D", true, false)
		
		if terrain_node and is_instance_valid(terrain_node):
			var player_camera = player_instance.find_node("Camera3D", true, false)
			if player_camera and is_instance_valid(player_camera):
				terrain_node.set_camera(player_camera)
				print("GM: Cámara asignada exitosamente al Terrain3D.")
