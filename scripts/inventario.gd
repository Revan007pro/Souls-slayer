class_name _inventario
extends Node

var _inventario_: Array = [] 
var player_node: Node = null

signal eliminar(area:Area3D)

func _ready() -> void:
	await get_tree().process_frame  
	player_node = GameManager.player_instance

func invetarioPlayer() -> void:
	if Input.is_action_just_pressed("inventario"):
		print("📦 Abriendo inventario")

func agregar_inventario() -> void:
	if not player_node.is_connected("recoger_objeto", Callable(self, "_on_recoger_objeto")):
		player_node.connect("recoger_objeto", Callable(self, "_on_recoger_objeto"))
		print("✅ Señal 'recoger_objeto' conectada con el inventario.")
func _on_recoger_objeto(area: Area3D) -> void:
	_inventario_.append(area.name)
	print("🧭 Objeto añadido al inventario:", area.name)
	emit_signal("eliminar", area)
