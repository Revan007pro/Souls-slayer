# GameManager.gd (Autoload/Singleton)
extends Node

# Asegúrate de que esta ruta sea correcta
@onready var _player_recurrente: PackedScene = preload("res://player_escena.tscn") 

var player_instance: Node 

func _ready() -> void:
	# 1. Verificación e Instanciación inicial
	if player_instance == null and is_instance_valid(_player_recurrente):
		player_instance = _player_recurrente.instantiate()
		#add_child(player_instance)
		player_instance.name = "PersistentPlayer" 
		print("GM: Jugador persistente inicializado.")
		

func change_scene_via_portal(next_scene_path: String) -> void:
	print("GM: Recibida señal de cambio a:", next_scene_path)
	var next_scene_packed = load(next_scene_path)
	if is_instance_valid(player_instance):
		if player_instance.has_method("set_first_spawn"): # Opción 1: Si tienes un setter
			player_instance.set_first_spawn(false)
		elif "is_first_spawn" in player_instance: # Opción 2: Acceso directo a la variable
			player_instance.is_first_spawn = false
			print("GM: Bandera 'is_first_spawn' desactivada en el jugador.")
		else:
			print("GM ADVERTENCIA: La instancia del jugador no tiene la propiedad 'is_first_spawn'.")

	if next_scene_packed is PackedScene:
		var error = get_tree().change_scene_to_packed(next_scene_packed)
		if error != OK:
			print("GM ERROR CRÍTICO: No se pudo cambiar de escena. Código:", error)
		else:
			print("GM: Cambio de escena exitoso.")
	else:
		print("GM ERROR: No se pudo cargar la escena. La ruta o el archivo es inválido:", next_scene_path)
