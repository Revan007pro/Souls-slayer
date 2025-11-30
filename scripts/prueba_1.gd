# prueba_1.gd
extends Node3D
@onready var respawn_point: Marker3D = $RespawnPoint

func _ready():
	call_deferred("move_player")

func move_player():
	await get_tree().process_frame
	var player = GameManager.player_instance
	if is_instance_valid(player):
		player.global_transform = respawn_point.global_transform
		print("Player movido a la posición de spawn.")
