class_name instanciar_armas extends Node


var bone_shield: BoneAttachment3D = null
var attach_point: BoneAttachment3D = null
var _shield: Node3D = null
var bow_instance: Node3D = null
var escudo: Node3D
var equiparCosas: bool = false
var bone_scene: Node3D
var anim_tree: AnimationTree
var anim_playback: AnimationNodeStateMachinePlayback
var goblin_instance: Node3D
var bow_equipped: bool = false
var ready_to_shoot: bool = false
var disparar: bool = false
var has_arrow: bool = false
var shoot_arrow: bool = true
var _sword_instance: Node3D
signal shoot(disparar: bool)
var flecha_actual: Node3D = null
var gamer = GameManager.player_instance

var player_camera: Camera3D = null
var camera_pivot: Node3D = null
var camera_offset_active: bool = false
var original_camera_pos: Vector3
var original_pivot_pos: Vector3


var armas: Dictionary = {
	"bow": preload("res://bow.tscn"),
	"arrow": preload("res://arrow.tscn"),
	"escudoW": preload("res://escudo_escena.tscn"),
	"sword": preload("res://sword.tscn")
}


func _escudo_() -> void:
	#is_combact = true
	if Inventario._inventario_.has("_escudo_"):
		_shield = armas["escudoW"].instantiate()
		bone_shield.add_child(_shield)
		_shield.position = Vector3(0.039, 0.013, -0.013)
		_shield.rotation_degrees = Vector3(-3.0, 74.7, 6.1)
		_shield.name = "shieldEquiped"
		
	else:
		_shield.queue_free()
		_shield = null
		#is_combact = false
func set_anim_tree(tree: AnimationTree) -> void:
	anim_tree = tree

func set_playback(pb: AnimationNodeStateMachinePlayback) -> void:
	anim_playback = pb
func set_goblin_instance(goblin: Node3D) -> void:
	goblin_instance = goblin
	bone_shield = goblin.get_node("Skeleton3D/shield") as BoneAttachment3D
	bone_scene = goblin_instance.get_node("Skeleton3D/BoneAttacch2") as BoneAttachment3D
	attach_point = goblin_instance.get_node("Skeleton3D/BoneAttacch3") as BoneAttachment3D


func set_player_camera_reference(camera: Camera3D, pivot: Node3D):
	player_camera = camera
	camera_pivot = pivot
	if player_camera:
		original_camera_pos = player_camera.position
	if camera_pivot:
		original_pivot_pos = camera_pivot.position
	print("✅ Referencia de cámara recibida")


func instaciar_bow() -> void:
	if Inventario._inventario_.has("bow") and not bow_equipped and not Inventario._inventario_.has("escudoW"):
		if not Inventario._inventario_.has("_escudo_"):
			attach_point = goblin_instance.get_node("Skeleton3D/BoneAttacch3")
			bow_instance = armas["bow"].instantiate()
			#bow_instance.position = Vector3(-0.05, 0, -0.126) posicion de la espalda
			#bow_instance.rotation_degrees = Vector3(0, 90.9, 0)
			bow_instance.position = Vector3(-0.037, -0.005, -0.001)
			bow_instance.rotation_degrees = Vector3(49.7, 23.2, 82.8)
			bow_instance.name = "arco"
			attach_point.add_child(bow_instance)
			bow_equipped = true
			

func move_camera_to_shoulder():
	camera_offset_active = true
		
		# Crear tween para movimiento suave
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	
	# Mover la cámara (no el pivote) para efecto de hombro
	var target_position = Vector3(-0.198, -0.05, 0) # Derecha y un poco arriba
	
	tween.tween_property(player_camera, "position",
		target_position,
		0.4 # Duración en segundos
	)

	tween.parallel().tween_property(player_camera, "fov",
		player_camera.fov - 5.0, # Un poco más zoom
		0.3
	)
	

func reset_camera_position():
	camera_offset_active = false
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	
	# Volver a posición original
	tween.tween_property(player_camera, "position",
		original_camera_pos,
		0.4
	)
	
	# Restaurar FOV
	tween.parallel().tween_property(player_camera, "fov",
		player_camera.fov + 5.0,
		0.3
	)
	

func animar_bow_espalda() -> void:
	equiparCosas = true
	print("🛡️ Animando arco a la espalda")
	
	# 1. Obtener el BoneAttachment3D de la espalda
	var bone_espalda = bone_scene
	if not bone_espalda:
		print("❌ No se encontró BoneAttachment3D en la espalda")
		equiparCosas = false
		return
	
	# 2. Guardar posición global actual del escudo
	var posicion_global_actual = bow_instance.global_transform
	
	# 3. Desconectar del bone actual (mano) y mover al jugador temporalmente
	if bow_instance.get_parent() == attach_point:
		attach_point.remove_child(bow_instance)
	add_child(bow_instance)
	bow_instance.global_transform = posicion_global_actual

	var posicion_objetivo_local = Vector3(0.010, 0.031, -0.106) # posicion de la figura
	var rotacion_objetivo = Vector3(0.1, -87.9, 7.4) # se invierte el eje y para que quede del otro lado
	var escala_objetivo = Vector3(0.898, 0.785, 0.845) # un poco mas quequeño
	
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	

	var posicion_global_objetivo = bone_espalda.to_global(posicion_objetivo_local)
	

	tween.tween_property(bow_instance, "global_position",
						 posicion_global_objetivo, 0.5)
	

	tween.parallel().tween_property(bow_instance, "rotation_degrees",
								   rotacion_objetivo, 0.5)
	

	tween.parallel().tween_property(bow_instance, "scale",
								   escala_objetivo, 0.5)
	
	# 7. Esperar a que termine la animación
	await tween.finished

	# 8. Re-parentear al bone de la espalda
	remove_child(bow_instance)
	bone_espalda.add_child(bow_instance)
	
	# Establecer transformación LOCAL al bone (esto es clave)
	bow_instance.position = posicion_objetivo_local # Posición LOCAL al bone
	bow_instance.rotation_degrees = rotacion_objetivo
	bow_instance.scale = escala_objetivo
	
	# 9. Finalizar
	equiparCosas = false

	if anim_playback:
		anim_playback.travel("State")

func animar_bow_a_mano() -> void:
	equiparCosas = true


	# Guardar posición global actual
	var posicion_global_actual = bow_instance.global_transform
	
	# Obtener el bone de espalda actual
	var bone_espalda = bone_scene
	
	# Desconectar de donde esté (espalda)
	if bow_instance.get_parent() == bone_espalda:
		bone_espalda.remove_child(bow_instance)
	add_child(bow_instance)
	bow_instance.global_transform = posicion_global_actual
	
	# Posición objetivo en la mano (valores originales)
	var posicion_mano_local = Vector3(-0.037, -0.005, -0.001)
	var rotacion_mano_local = Vector3(49.7, 23.2, 82.8)
	#var escala_mano_local = Vector3(0.585, 0.293, 0.29)
	
	# Crear tween
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# Calcular posición global objetivo (mano)
	var posicion_global_mano = attach_point.to_global(posicion_mano_local)
	
	# Animar
	tween.tween_property(bow_instance, "global_position",
						 posicion_global_mano, 0.5)
	tween.parallel().tween_property(bow_instance, "rotation_degrees",
								   rotacion_mano_local, 0.5)
	#tween.parallel().tween_property(_shield, "scale",
	#							   escala_mano_local, 0.5)
	
	await tween.finished
	
	# Re-parentear al bone de la mano
	remove_child(bow_instance)
	attach_point.add_child(bow_instance)
	
	# Establecer transformación local
	bow_instance.position = posicion_mano_local
	bow_instance.rotation_degrees = rotacion_mano_local
	#bow_instance.scale = escala_mano_local
	
	equiparCosas = false
	print("animacion del arco a la mano")
	if anim_playback:
		anim_playback.travel("State")
	

func ani_bow() -> void:
	var punto = goblin_instance.get_node("Skeleton3D/finger")
	var diana = Inventario.ui.get_node("Panel/diana")

	if Inventario._inventario_.has("bow"):
		if Input.is_action_just_pressed("block") and flecha_actual == null:
			# hay un bug corregir que solo si se tiene el arco pueda hacer el zoom
			ready_to_shoot = true
			has_arrow = true
			anim_playback.travel("Ani_player_arrow_01")

			flecha_actual = armas["arrow"].instantiate() as Node3D
			flecha_actual.name = "flecha"
			punto.add_child(flecha_actual)
			flecha_actual.visible = false
			await get_tree().create_timer(0.35).timeout
			flecha_actual.visible = true
			flecha_actual.transform = Transform3D.IDENTITY
			flecha_actual.position = Vector3(0.048, -0.229, 0.011)
			flecha_actual.rotation_degrees = Vector3(-15.4, 164.0, 178.6)
			flecha_actual.scale = Vector3(0.172, 0.472, 0.208)
			diana.visible = true
			move_camera_to_shoulder()
			

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
			diana.visible = false
			reset_camera_position()

func _wait_sword() -> Node3D:
	if _sword_instance != null and is_instance_valid(_sword_instance):
		return _sword_instance
	
	bone_scene = goblin_instance.get_node("Skeleton3D/BoneAttachment3D")
	await get_tree().create_timer(0.7).timeout
	_sword_instance = armas["sword"].instantiate() as Node3D
	var attack_area = _sword_instance.get_node("AttackArea")
	attack_area.monitoring = false
	bone_scene.add_child(_sword_instance)
	_sword_instance.position = Vector3(0.296, -0.002, 0.156)
	_sword_instance.rotation_degrees = Vector3(1.7, 63.5, 143.8)
	_sword_instance.name = "SwordEquipped"
	return _sword_instance

func animar_escudo_a_espalda() -> void:
	if equiparCosas or not _shield:
		print("❌ No se puede animar: equiparCosas =", equiparCosas, ", _shield =", _shield)
		return
	
	# Iniciar animación
	equiparCosas = true
	print("🛡️ Animando escudo a la espalda")
	
	# 1. Obtener el BoneAttachment3D de la espalda
	var bone_espalda = bone_scene
	if not bone_espalda:
		print("❌ No se encontró BoneAttachment3D en la espalda")
		equiparCosas = false
		return
	
	# 2. Guardar posición global actual del escudo
	var posicion_global_actual = _shield.global_transform
	
	# 3. Desconectar del bone actual (mano) y mover al jugador temporalmente
	if _shield.get_parent() == bone_shield:
		bone_shield.remove_child(_shield)
	add_child(_shield)
	_shield.global_transform = posicion_global_actual

	var posicion_objetivo_local = Vector3(0.010, 0.031, -0.106) # Exactamente como en tu captura
	var rotacion_objetivo = Vector3(0.1, 87.9, 7.4) # Rotación de tu captura
	var escala_objetivo = Vector3(0.585, 0.293, 0.29) # Escala de tu captura
	
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	

	var posicion_global_objetivo = bone_espalda.to_global(posicion_objetivo_local)
	

	tween.tween_property(_shield, "global_position",
						 posicion_global_objetivo, 0.5)
	

	tween.parallel().tween_property(_shield, "rotation_degrees",
								   rotacion_objetivo, 0.5)
	

	tween.parallel().tween_property(_shield, "scale",
								   escala_objetivo, 0.5)
	
	# 7. Esperar a que termine la animación
	await tween.finished

	# 8. Re-parentear al bone de la espalda
	remove_child(_shield)
	bone_espalda.add_child(_shield)
	
	# Establecer transformación LOCAL al bone (esto es clave)
	_shield.position = posicion_objetivo_local # Posición LOCAL al bone
	_shield.rotation_degrees = rotacion_objetivo
	_shield.scale = escala_objetivo
	
	# 9. Finalizar
	equiparCosas = false

	if anim_playback:
		anim_playback.travel("State")

func animar_escudo_a_mano() -> void:
	if equiparCosas or not _shield:
		return
	
	equiparCosas = true


	# Guardar posición global actual
	var posicion_global_actual = _shield.global_transform
	
	# Obtener el bone de espalda actual
	var bone_espalda = bone_scene
	
	# Desconectar de donde esté (espalda)
	if _shield.get_parent() == bone_espalda:
		bone_espalda.remove_child(_shield)
	add_child(_shield)
	_shield.global_transform = posicion_global_actual
	
	# Posición objetivo en la mano (valores originales)
	var posicion_mano_local = Vector3(0.039, 0.013, -0.013)
	var rotacion_mano_local = Vector3(-3.0, 74.7, 6.1)
	var escala_mano_local = Vector3(0.585, 0.293, 0.29)
	
	# Crear tween
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# Calcular posición global objetivo (mano)
	var posicion_global_mano = bone_shield.to_global(posicion_mano_local)
	
	# Animar
	tween.tween_property(_shield, "global_position",
						 posicion_global_mano, 0.5)
	tween.parallel().tween_property(_shield, "rotation_degrees",
								   rotacion_mano_local, 0.5)
	tween.parallel().tween_property(_shield, "scale",
								   escala_mano_local, 0.5)
	
	await tween.finished
	
	# Re-parentear al bone de la mano
	remove_child(_shield)
	bone_shield.add_child(_shield)
	
	# Establecer transformación local
	_shield.position = posicion_mano_local
	_shield.rotation_degrees = rotacion_mano_local
	_shield.scale = escala_mano_local
	
	equiparCosas = false
	print("✅ Escudo animado a la mano")
	if anim_playback:
		anim_playback.travel("State")

func equipar_escudo() -> void:
	if gamer and gamer.has_method("set_combat_mode"):
		gamer.set_combat_mode(true)

	if gamer and "is_combact" in gamer:
		gamer.is_combact = true

	if equiparCosas:
		return

	var bone_espalda = bone_scene

	var shield_parent = _shield.get_parent() if _shield else null
	var bow_parent = bow_instance.get_parent() if bow_instance else null

	match [shield_parent, bow_parent]:
		[bone_shield, _]:
			animar_escudo_a_espalda()
			print("llamando al escudo")
		[bone_espalda, _]:
			animar_escudo_a_mano()
		[_, attach_point]:
			animar_bow_espalda()
			print("llamando al arco")
		[_, bone_espalda]:
			animar_bow_a_mano()
			print("arco ya en espalda")

		_:
			print("no se encontro los nodos:",
				  "shield:", shield_parent,
				  "bow:", bow_parent)
			print("bow parent path:", bow_parent.get_path())
