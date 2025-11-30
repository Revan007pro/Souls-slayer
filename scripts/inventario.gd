class_name _inventario
extends Node
var open_inventario: bool = false

var _inventario_: Array = [

]
var fast_invetory: bool = false
var inven_texture: Texture = preload("res://Imagenes/inventario.png")

var objetos_iconos := {
	"espada": preload("res://Menu/Iconos/espada.png"),
	"_escudo_": preload("res://Menu/Iconos/escudo_ico.png")
}
var ubicacion_objeto := {
	"espada": 2,
	"_escudo_": 1,
}

func invetarioPlayer() -> void:
	var world = get_tree().get_current_scene()
	var escudo = world.find_child("Escudo", true, false)
	var _sword = world.find_child("Sword", true, false)
	if Input.is_action_just_pressed("inventario"):
		print("📦 Abriendo inventario", _inventario_)
	if _inventario_.has("_escudo_") and escudo and escudo.name != "_shield":
		escudo.queue_free()
	if _inventario_.has("espada") and _sword and _sword.name != "SwordEquipped":
		_sword.queue_free()

func actualizar_slots() -> void:
	var ui = get_tree().get_first_node_in_group("UI")
	var inv = ui.get_node("Inventario")

	if Input.is_action_just_pressed("fast_inven"):
		open_inventario = true
		if inv.visible == false:
			print("inventario instanciado")
			inv.visible = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			print("inventario cerrado")
			inv.visible = false
			open_inventario = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


	for i in _inventario_:
		if ubicacion_objeto.has(i):
			var index = ubicacion_objeto[i]
			var icon = ui.get_node("Icon" + (str(index + 1)))
			icon.texture = objetos_iconos[i]
			if Input.is_action_pressed("left"):
				var icon2 = ui.get_node("Icon2")
				icon2.texture = objetos_iconos["espada"]
				
				
			#icon.custom_minimum_size = Vector2(100, 100)
			#icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


#	if not player_node.is_connected("recoger_objeto", Callable(self, "_on_recoger_objeto")):
#		player_node.connect("recoger_objeto", Callable(self, "_on_recoger_objeto"))
#		print("✅ Señal 'recoger_objeto' conectada con el inventario.") forma para conectar señales
