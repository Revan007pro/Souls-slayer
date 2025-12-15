class_name _inventario
extends Node
var open_inventario: bool = false

var _inventario_: Array = []

var fast_invetory: bool = false
var inven_texture: Texture = preload("res://Imagenes/Inventario.png")

var objetos_iconos := {
	"espada": preload("res://Menu/Iconos/espada.png"),
	"_escudo_": preload("res://Menu/Iconos/escudo_ico.png"),
	"bow": preload("res://Menu/Iconos/bow-removebg-preview.png"),
}
var ubicacion_objeto := {
	"espada": 2,
	"_escudo_": 1,
	"bow": 1,
}
var mini_inventario: Dictionary = {
	2: [],
	1: [],
	3: [],
	4: []

}
var index_objeto_actual: int = 0
var iconos_posicion_original := {}
@onready var ui = get_tree().get_first_node_in_group("UI")
func _ready():
	iconos_posicion_original["Icon1"] = ui.get_node("Icon1").position
	iconos_posicion_original["Icon2"] = ui.get_node("Icon2").position
	iconos_posicion_original["Icon3"] = ui.get_node("Icon3").position
	iconos_posicion_original["Icon4"] = ui.get_node("Icon4").position

func invetarioPlayer() -> void:
	var world = get_tree().get_current_scene()
	var escudo = world.find_child("Escudo", true, false)
	var _sword = world.find_child("Sword", true, false)
	var _arco = world.find_child("bow", true, false)
	if Input.is_action_just_pressed("inventario"):
		print("📦 Abriendo inventario", _inventario_)
	if _inventario_.has("_escudo_") and escudo and escudo.name != "_shield":
		escudo.queue_free()
	if _inventario_.has("espada") and _sword and _sword.name != "SwordEquipped":
		_sword.queue_free()
	if _inventario_.has("bow") and _arco and _arco.name != "arco":
		_arco.queue_free()


func actualizar_slots(ui) -> void:
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

				
			#icon.custom_minimum_size = Vector2(100, 100)
			#icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


#	if not player_node.is_connected("recoger_objeto", Callable(self, "_on_recoger_objeto")):
#		player_node.connect("recoger_objeto", Callable(self, "_on_recoger_objeto"))
#		print("✅ Señal 'recoger_objeto' conectada con el inventario.") forma para conectar señales
func cambiar_icono(direccion: int, inv, icon) -> void:
	index_objeto_actual = (index_objeto_actual + direccion) % _inventario_.size()

	var nuevo_item: String = _inventario_[index_objeto_actual]
	var nueva_textura: Texture = objetos_iconos[nuevo_item]


	var pos_inicial: Vector2 = iconos_posicion_original[inv.name]

	tween_call_back(inv, nueva_textura, pos_inicial, icon, direccion)

	
func tween_call_back(inv, nueva_textura, pos_inicial, icon, direccion) -> void:
	var desplazamiento := 25.8
	var icon3 = ui.get_node("Icon3")
	var pos_salida: Vector2
	var pos_entrada: Vector2

	if direccion == 1:
		pos_salida = pos_inicial + Vector2(-desplazamiento, 0)
		pos_entrada = pos_inicial + Vector2(desplazamiento, 0)
		if desplazamiento >= 25.8:
			icon.visible = false
			icon3.visible = true
	else:
		pos_salida = pos_inicial + Vector2(desplazamiento, 0)
		pos_entrada = pos_inicial + Vector2(-desplazamiento, 0)

	var t := create_tween()

	t.tween_property(inv, "position", pos_salida, 1.02)

	t.tween_callback(func():
		icon.texture = nueva_textura
		icon.position = pos_entrada
	)

	t.tween_property(inv, "position", pos_inicial, 1.05)
