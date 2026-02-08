extends Personaje

class_name player

@export var speed: float = 5.0
@export var acceleration: float = 75.0
@export var fuerza_salto: float = 4.5
@export var _goblin_fbx: PackedScene
const Agregar = preload("res://dialogues_pruebas/Agregar.dialogue")

var _goblin_instance: Node3D
var anim_tree: AnimationTree
var _dialogue_balloon = null
var is_combact: bool = false
var _dialogue_active = false
var tengo_escudo: bool = false

enum SwordState {NONE, DRAWING, DRAWN, SHEATHING, ATTACKING}
var sword_state: SwordState = SwordState.NONE


@onready var pivote: Node3D = $Pivote
@onready var _camara: Camera3D = $Pivote/Camera3D
@onready var ray_suelo: RayCast3D = $RayCast3D
@onready var _salud: ProgressBar = $CanvasLayer/healt
@onready var _stamina: ProgressBar = $CanvasLayer/healt/Stamina
@onready var death_sound: AudioStreamPlayer = $Control/dead_sonido
@onready var desvainar_soni: AudioStreamPlayer = $Control/desvainar


#signal dead_signal(is_dead: bool)
var is_dead: bool = false

var health: float = 100.0
var rotacion_horizontal: float = 0.0
var rotacion_vertical: float = 0.0
var anim_playback: AnimationNodeStateMachinePlayback
var _camera_can_move: bool = true
var is_first_spawn: bool = true

var parry_on: bool = false

var _vector2: Vector2 = Vector2.ZERO
var is_movieng: bool = false
var Jumping: bool = false
var can_jump: bool = true
var __rolling: bool = false
var attack_radio: float = 1.0
var _damage_: bool
var _desvainar: bool = false
var _desvainar_with: bool = false

var is_attacking: bool = false
var ready_to_shoot: bool = false
var equiparCosas: bool = false
var wait_star: float = 2.8
var wait_to_star: bool = false
var _blocking: bool
var _state: String = "idle"
var sensibilidad_camara: float = 0.5
#var inventario_instancia: _inventario = _inventario.new()
signal recoger_objeto(area: Area3D)
var objeto_cercano: Area3D = null
var souls: int = 0
@onready var Enemy: Node3D = get_tree().get_first_node_in_group("enemy")

@onready var ui = get_tree().get_first_node_in_group("UI")
func _ready() -> void:
	if Enemy:
		Enemy.dead_signal.connect(func(muerto: bool):
			if muerto:
				GameManager.add_souls(1)
				print("Souls:", GameManager.souls)
		)
	
	clase_guerrero()
	GameManager.player_instance = self
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_goblin_instance = _goblin_fbx.instantiate()
	add_child(_goblin_instance)
	Weapons.set_goblin_instance(_goblin_instance)
	anim_tree = _goblin_instance.get_node("anim_tree")
	
	
	if anim_tree:
		anim_playback = anim_tree.get("parameters/playback")
	Weapons.set_anim_tree(anim_tree)
	Weapons.set_playback(anim_playback)
	call_deferred("_deferred_ready")
func _deferred_ready() -> void:
	if is_first_spawn:
		play_get_up_animation()
	
func _physics_process(delta: float) -> void:
	Inventario.contador()
	if not _salud.is_inside_tree():
		print("⚠️ BARRA NO ESTÁ EN EL ÁRBOL")
	if is_dead:
		return
	parry()
	nex_level()
	Weapons.instaciar_bow()
	Weapons.ani_bow()
	Inventario.invetarioPlayer()
	_movimiento_jugador(delta)
	conectar_signal(objeto_cercano, ui)
	_aplicar_gravedad(delta)
	_salto_jugador()
	is_attaacking()
	_bloquear()
	_desvainar_espada()
	_regenerar_stamina()
	move_and_slide()
	equipar()
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.is_action_just_pressed("Dialogue") and objeto_cercano:
		emit_signal("recoger_objeto", objeto_cercano)
		print("✅ Jugador recogió:", objeto_cercano.name)
		objeto_cercano = null
	
	
func conectar_signal(area: Area3D, ui) -> void:
	if Input.is_action_just_pressed("Dialogue") and objeto_cercano:
		Inventario._inventario_.append(String(area.name))
	if Input.is_action_just_pressed("Dialogue") and Inventario._inventario_.has("_escudo_"):
		print("escudo en el inventario")
		Weapons._escudo_()
	Inventario.actualizar_slots(ui)
	if Inventario.open_inventario:
		_camera_can_move = false
	else:
		_camera_can_move = true

			
func _movimiento_jugador(delta: float) -> void:
	if is_dead:
		return
	
	var input_dir = Input.get_vector("derecha", "izquierda", "adelante", "atras")
	var direction = (transform.basis * Vector3(input_dir.x, 0, -input_dir.y)).normalized()
	
	if direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
		_vector2 = Vector2(input_dir.x, -input_dir.y)
		is_movieng = true
	else:
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0, acceleration * delta)
		is_movieng = false
		_vector2 = Vector2.ZERO

	anim_tree.set("parameters/State/blend_position", _vector2)


func _desvainar_espada() -> void:
	if Input.is_action_just_pressed("desvainar") and Inventario._inventario_.has("espada"):
		match sword_state:
			SwordState.NONE:
				# Desvainar
				sword_state = SwordState.DRAWING
				is_combact = true
				anim_playback.travel("Ani_player_Desvainar")
				await Weapons._wait_sword()
				desvainar_soni.play()
				print("Animación desvainar")
				await get_tree().create_timer(0.8).timeout
				sword_state = SwordState.DRAWN
				_desvainar_with = true
				anim_playback.travel("With")
				print("Espada desvainada")
				
			SwordState.DRAWN:
				# Envainar
				sword_state = SwordState.SHEATHING
				is_combact = false
				anim_playback.travel("Ani_player_Envainar")
				print("Animación envainar")
				await get_tree().create_timer(1.1).timeout
				
				# Eliminar espada
				if Weapons.bone_scene != null and Weapons._sword_instance != null:
					Weapons.bone_scene.remove_child(Weapons._sword_instance)
					Weapons._sword_instance.queue_free()
					Weapons._sword_instance = null
				
				sword_state = SwordState.NONE
				_desvainar_with = false
				anim_playback.travel("State")
				print("Espada envainada")
	
	anim_tree.set("parameters/With/blend_position", _vector2)


func equipar() -> void:
	if Input.is_action_just_pressed("equipar") and not Inventario._inventario_.has(Weapons.armas):
		anim_playback.travel("Ani_player_equipar")
		await get_tree().create_timer(0.5).timeout
		Weapons.equipar_escudo()


func _bloquear() -> void:
	if Input.is_action_pressed("block") and not _blocking and Inventario._inventario_.has("_escudo_"):
		_blocking = true
		_set_state("Ani_player_Block")
		is_combact = true
	elif not Input.is_action_pressed("block") and _blocking:
		_blocking = false
		is_combact = false
		_set_state("State")

func _set_state(new_state: String) -> void:
	if _state != new_state:
		_state = new_state
		anim_playback.travel(_state)

func parry() -> void:
	if parry_on:
		return

	if Input.is_action_just_pressed("parry") and Inventario._inventario_.has("_escudo_"):
		print("🛡️ PARRY")
		parry_on = true
		is_combact = true

		_set_state("Ani_player_Parry")

		await get_tree().create_timer(1.11).timeout

		parry_on = false
		is_combact = false
		_set_state("State")

	
func _salto_jugador():
	if Input.is_action_just_pressed("salto") and is_on_floor() and not Input.is_action_pressed("adelante"):
		var can_jump: int = 20
		if self._stamina.value < can_jump:
			print("no hay estamina no se puede saltar")
			return
		self._stamina.value -= can_jump
		self._stamina.max_value = 100
		Jumping = true
		print("salto")
		anim_playback.travel("Ani_player_Jump")
		velocity.y = fuerza_salto
		await get_tree().create_timer(2.0).timeout
		Jumping = false
		anim_playback.travel("State")

func _input(event: InputEvent) -> void:
	var _enemigo_instancia = enemy
	const ZOOM_MIN: float = 0.005
	const ZOOM_MAX: float = -5.0
	
	if is_dead:
		return
	
	# Movimiento de camara
	if event is InputEventMouseMotion and _camera_can_move == true:
		rotate_y(deg_to_rad(-event.relative.x * sensibilidad_camara))
		pivote.rotate_x(deg_to_rad(event.relative.y * sensibilidad_camara))
		pivote.rotation.x = clamp(pivote.rotation.x, deg_to_rad(-70.0), deg_to_rad(70.0))
	
	elif event is InputEventMouseButton:
		_camara.position.z = clamp(_camara.position.z, ZOOM_MAX, ZOOM_MIN)
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_camara.position.z += 0.1
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_camara.position.z -= 0.1
		if _camara.global_position == pivote.global_position:
			_camara.position.z = 0
	if event.is_action_pressed("left"):
		Inventario.cambiar_icono(-1, ui.get_node("Icon2"), ui.get_node("Icon2"))

	if event.is_action_pressed("rigth"):
		Inventario.cambiar_icono(1, ui.get_node("Icon3"), ui.get_node("Icon3"))


	elif Input.is_action_just_pressed("fijar"):
		if Enemy:
			_camara.look_at(Enemy.global_position)


func is_attaacking() -> void:
	if Input.is_action_just_pressed("attack") and sword_state == SwordState.DRAWN:
		is_combact = true
		var can_attack: int = 30
		if _stamina.value < can_attack:
			print("Sin stamina, no puedes atacar")
			return
		
		# Cambiar estado a ATTACKING
		sword_state = SwordState.ATTACKING
		is_attacking = true
		self._stamina.value -= can_attack
		self._stamina.max_value = 100
		anim_playback.travel("Ani_player_Attack")
		
		await get_tree().create_timer(1.6667).timeout
		
		# Regresar a estado DRAWN
		is_attacking = false
		sword_state = SwordState.DRAWN # Solo esto
		if not is_dead:
			anim_playback.travel("With")


func play_get_up_animation() -> void:
	set_physics_process(false)
	anim_playback.travel("Get_up")
	wait_to_star = true
	_camera_can_move = false
	await get_tree().create_timer(2.8).timeout
	
	set_physics_process(true)
	_camera_can_move = true
	anim_playback.travel("State")


func take_damage(damage: float) -> void:
	#print("¿_salud existe?", is_instance_valid(_salud))
	is_combact = true
	self.health -= damage
	_damage_ = true
	if is_dead:
		print("is_dead antes de actualizar vida:", is_dead)
		return
	if _salud:
		self._salud.value = health
		self._salud.max_value = 100.0

	if health <= 0:
		death_sound.play()
		is_dead = true
		dead_signal.emit(is_dead)
		print("Emitir señal \"muerto\"")
		wait_to_star = true
		anim_playback.travel("Ani_player_dead")
		await get_tree().create_timer(2.8).timeout
		get_tree().reload_current_scene()
	

func _regenerar_stamina() -> void:
	var stamina_mas: int = 10
	while _stamina.value < 100 and is_on_floor():
		await get_tree().create_timer(2.8).timeout
		self._stamina.value += stamina_mas
		break


func _on_area_3d_area_entered(area: Area3D) -> void:
	#var armas = get_tree().get_first_node_in_group("Arma")
	#var nombres_armas = armas.map(func(n): return n.name) puede servir en el futuro
	if not _dialogue_active and is_combact == false:
		_dialogue_balloon = DialogueManager.show_dialogue_balloon(Agregar)
		_dialogue_active = true
		print("Jugador dentro del área, mostrando diálogo.")
	
	if Inventario.objetos_iconos.has(area.name) and _dialogue_active:
		objeto_cercano = area
		#print("🧭 Puedes recoger:", area.name)
		emit_signal("recoger_objeto", area)
	
		
func _on_area_3d_area_exited(area: Area3D) -> void:
	if _dialogue_active and _dialogue_balloon:
		_dialogue_balloon.queue_free()
		_dialogue_balloon = null
		_dialogue_active = false

	if objeto_cercano == area:
		objeto_cercano = null
		print("⛔ Te alejaste del objeto")


func nex_level() -> void:
	if souls > 1:
		print("puedes subir nievel")

# En player.gd (el script que tiene la AnimationPlayer)

#func animation_activate_sword():
	# Buscamos cualquier nodo en el grupo "Arma" que sea hijo nuestro
	# y ejecutamos su función de activación
 #   get_tree().call_group("Arma", "activate_sword")

#func animation_off_sword():
 #   get_tree().call_group("Arma", "off_sword")
