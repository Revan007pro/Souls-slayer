extends Node3D

@export var _player_instance: PackedScene
var goblin_instance:Node
@onready var _spanw: Marker3D = $RespawnPoint 

func _ready():
	goblin_instance=_player_instance.instantiate()
	_spanw.add_child(goblin_instance)
	goblin_instance.global_transform = _spanw.global_transform
