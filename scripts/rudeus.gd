extends Personaje

var _player_instance:Node 
const HUNT = preload("res://dialogues_pruebas/hunt.dialogue")  
var player_clase:bool=false

@onready var dialog_area: Area3D = $Area3D  
func _ready() -> void:
	clase_mago()
	_player_instance = get_tree().get_first_node_in_group("Player")

func _process(delta: float) -> void:
	if player_clase and Input.is_action_just_pressed("Dialogue"):
		DialogueManager.show_dialogue_balloon(HUNT)


func _on_area_3d_area_entered(area: Area3D) -> void:
	if _player_instance:
		player_clase=true
		print("Jugador dentro del área, mostrando")
