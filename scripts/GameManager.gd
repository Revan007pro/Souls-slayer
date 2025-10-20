extends Node

var player_instance: Node
var current_player: Node

func register_player(player: Node) -> void:
    player_instance = player
    current_player = player

func get_player() -> Node:
    return player_instance