extends Node

@onready var _player_recurrente: PackedScene = preload("res://player_escena.tscn")
var player_instance: Node
var cambiar: bool
var escenas_mundo: Dictionary = {
	"_world": "res://world.tscn",
	"next_scene_packed": "res://prueba_1.tscn"
}

func _ready():
	if player_instance == null:
		player_instance = _player_recurrente.instantiate()
		get_tree().root.add_child(player_instance) # IMPORTANTE

func change_scene_via_portal(scene_key: String) -> void:
	if escenas_mundo.has(scene_key):
		var next_scene_path = escenas_mundo[scene_key]
		var next_scene_packed: PackedScene = load(next_scene_path)

		print("GM: Recibida solicitud de cambio a:", scene_key)

		if is_instance_valid(player_instance) and player_instance.has_method("is_first_spawn"):
			player_instance.is_first_spawn = false

		get_tree().change_scene_to_packed(next_scene_packed)
