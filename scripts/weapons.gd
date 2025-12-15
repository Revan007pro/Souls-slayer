class_name instanciar_armas extends Node

var arrow: bool = false
var anim_tree: AnimationTree
var anim_playback: AnimationNodeStateMachinePlayback
var goblin_instance: Node3D
var bow_equipped: bool = false
var ready_to_shoot: bool = false
var disparar: bool = false
var has_arrow: bool = false
var shoot_arrow: bool = true
signal shoot(disparar: bool)
var flecha_actual: Node3D = null # <- ESTA ES LA CLAVE
var armas: Dictionary = {
	"bow": preload("res://bow.tscn"),
	"arrow": preload("res://arrow.tscn")
}
func set_anim_tree(tree: AnimationTree) -> void:
	anim_tree = tree

func set_playback(pb: AnimationNodeStateMachinePlayback) -> void:
	anim_playback = pb
func set_goblin_instance(goblin: Node3D) -> void:
	goblin_instance = goblin
func instaciar_bow() -> void:
	if Inventario._inventario_.has("bow") and not bow_equipped:
		var attach_point = goblin_instance.get_node("Skeleton3D/BoneAttacch2")
		var bow_instance = armas["bow"].instantiate()
		bow_instance.position = Vector3(-0.05, 0, -0.126)
		bow_instance.rotation_degrees = Vector3(0, 90.9, 0)
		bow_instance.name = "arco"
		attach_point.add_child(bow_instance)
		bow_equipped = true


func ani_bow() -> void:
	var punto = goblin_instance.get_node("Skeleton3D/finger")

	if Inventario._inventario_.has("bow"):
		# SOLO UNA VEZ
		if Input.is_action_just_pressed("block") and flecha_actual == null:
			ready_to_shoot = true
			has_arrow = true
			anim_playback.travel("Ani_player_arrow_01")

			flecha_actual = armas["arrow"].instantiate() as Node3D
			flecha_actual.name = "flecha"
			punto.add_child(flecha_actual)

			flecha_actual.transform = Transform3D.IDENTITY
			flecha_actual.position = Vector3(0.048, -0.229, 0.011)
			flecha_actual.rotation_degrees = Vector3(-15.4, 164.0, 178.6)
			flecha_actual.scale = Vector3(0.172, 0.472, 0.208)

		elif Input.is_action_just_released("block") and flecha_actual != null:
			# guardar transform global
			var global_transform = flecha_actual.global_transform

			punto.remove_child(flecha_actual)
			get_tree().current_scene.add_child(flecha_actual)
			flecha_actual.global_transform = global_transform

			anim_playback.travel("Ani_player_arrow_disparo")

			emit_signal("shoot") # solo dispara la señal

			flecha_actual = null
			has_arrow = false


#func instanciar_arrow() -> void:
#	
#	if Input.is_action_just_pressed("block"):
#		
#	elif Input.is_action_just_released("block") and GameManager.player_instance.shoot_arrow:
#		var global = flecha_actual.global_transform
#		punto.remove_child(flecha_actual)
#		#get_tree().current_scene.add_child(flecha_actual)
#		flecha_actual.global_transform = global
