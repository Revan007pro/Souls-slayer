extends Node3D
@onready var respawn_point: Marker3D = $RespawnPoint

func _ready():
	await get_tree().process_frame

	var player = GameManager.player_instance
	player.global_transform = respawn_point.global_transform

	if player.has_method("anim_playback"):
		player.anim_playback.travel("State")
