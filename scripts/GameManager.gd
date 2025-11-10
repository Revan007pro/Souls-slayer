
extends Node

@onready var _player_recurrente: PackedScene = preload("res://player_escena.tscn") 
@onready var inventario = preload("res://scripts/inventario.gd").new() # Variable que contiene la instancia

var player_instance: Node 
var world_instance: Node
var _Arma_instancia:Node
var arma_fbx:Node



var escenas_mundo: Dictionary = {
	"_world": "res://world.tscn",
	"next_scene_packed": "res://prueba_1.tscn"
}

func _ready():
	if player_instance == null and is_instance_valid(_player_recurrente):
		player_instance = _player_recurrente.instantiate()
		player_instance.connect("recoger_objeto", Callable(self, "_instanciar_objetos"))
	inventario.connect("_on_recoger_objeto", Callable(self, "_on_eliminar_objetos"))
	
	
func change_scene_via_portal(scene_key: String) -> void:
	if escenas_mundo.has(scene_key):
		var next_scene_path = escenas_mundo[scene_key]
		var next_scene_packed = load(next_scene_path)

		print("GM: Recibida solicitud de cambio a:", scene_key, "→", next_scene_path)

		if is_instance_valid(player_instance):
			if "is_first_spawn" in player_instance:
				player_instance.is_first_spawn = false
				print("GM: Bandera 'is_first_spawn' desactivada en el jugador.")

		if next_scene_packed is PackedScene:
			var error = get_tree().change_scene_to_packed(next_scene_packed)
			if error != OK:
				print("GM ERROR CRÍTICO: No se pudo cambiar de escena. Código:", error)
			else:
				print("GM: Cambio de escena exitoso.")
	else:
		push_error("GM ERROR: La clave '%s' no existe en el diccionario 'escenas_mundo'." % scene_key)

func _instanciar_objetos() -> void:
	pass
	#if area.name == "_escudo_":
	#	print("escudo detectado")
	#if escudo and " _dialogue_active" in player_instance: #and player_instance._dialogue_active:
	#	escudo.queue_free()
	#	print("🛡️ GM: Escudo eliminado del mundo actual.")
	#if _sword and " _dialogue_active" in player_instance:
	#	_sword.queue_free()
	#	print("🗡️ Eliminando espada...")
	#else:
	#	print("❌ GM: No se encontró la espada en la escena actual.")
	#print("detectando escudo")
func _on_eliminar_objetos(area:Area3D)->void:
	var world = get_tree().get_current_scene()
	var escudo = world.find_child("Escudo", true, false)
	var _sword = world.find_child("Sword", true, false)
	if escudo and " _dialogue_active" in player_instance: #and player_instance._dialogue_active:
		escudo.queue_free()
		print("🛡️ GM: Escudo eliminado del mundo actual.")
