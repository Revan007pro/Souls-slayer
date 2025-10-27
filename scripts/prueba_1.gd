# NewWorld.gd (El script en el nodo raíz de la escena de destino)
extends Node3D

@onready var respawn_point: Marker3D = $RespawnPoint 

func _ready():
	await get_tree().process_frame 
	var player_node = GameManager.player_instance 
	get_tree().get_root().add_child(player_node)
	player_node.global_transform = respawn_point.global_transform
	print("Mundo Nuevo: Jugador reubicado.")
	if player_node.has_method("_deferred_ready"):
		player_node.anim_playback.travel("State")
		print("Segundo spawn")