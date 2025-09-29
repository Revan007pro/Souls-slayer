extends Personaje

class_name player

@export var speed: float = 5.0
@export var acceleration: float = 75.0
@export var fuerza_salto: float = 4.5
@export var _enemy:CharacterBody3D
@export var _sword: PackedScene
var _sword_instance: Node3D

@onready var pivote: Node3D = $Pivote
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var _camara: Camera3D = $Pivote/Camera3D
@onready var ray_suelo: RayCast3D = $RayCast3D
@onready var _salud: ProgressBar = $"../CanvasLayer/healt"


signal golpe_conectado(damage: float)
signal dead_signal(is_dead: bool)


var health: float = 100.0
var rotacion_horizontal: float = 0.0
var rotacion_vertical: float = 0.0
var anim_playback: AnimationNodeStateMachinePlayback
var is_first_spawn: bool = true


var _vector2: Vector2 = Vector2.ZERO
var is_movieng: bool = false
var Jumping: bool = false
var can_jump: bool = true
var __rolling: bool = false
var attack_radio: float = 1.0
var is_dead: bool = false
var is_attacking: bool = false
var wait_star: float = 2.8
var wait_to_star: bool = false

var sensibilidad_camara: float = 0.5

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	anim_tree.active = true
	add_to_group("player")
	anim_playback = anim_tree.get("parameters/playback")
	call_deferred("_deferred_ready")
func _deferred_ready() -> void:
	if is_first_spawn:
		play_get_up_animation()
		is_first_spawn = false
	else:
		# Si no es la primera vez, ir directamente al estado normal
		anim_playback.travel("State")

func _physics_process(delta: float) -> void:
	if is_dead:
		return  
	_movimiento_jugador(delta)
	_aplicar_gravedad(delta)
	_salto_jugador()
	_detectar_suelo_raycast()
	
	move_and_slide()
	
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _movimiento_jugador(delta: float) -> void:
	if is_dead:
		return
	
	var input_dir = Input.get_vector("atras", "adelante", "derecha", "izquierda")
	var direction = (transform.basis * Vector3(input_dir.x, 0, -input_dir.y)).normalized()
	
	if direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
		_vector2 = Vector2(input_dir.x, -input_dir.y)
		is_movieng = true
	elif Input.is_action_just_pressed("rolling") and not __rolling:
		__rolling = true
		anim_playback.travel("Rolling")
		await get_tree().create_timer(1.4).timeout
		__rolling = false
		anim_playback.travel("State")
	else:
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0, acceleration * delta)
		is_movieng = false
		_vector2 = Vector2.ZERO

	anim_tree.set("parameters/State/blend_position", _vector2)

func puede_saltar()->void:
	await get_tree().create_timer(2.5).timeout

func _salto_jugador():
	if Input.is_action_just_pressed("salto") and is_on_floor() and not is_dead:
		puede_saltar()
		Jumping = true
		anim_playback.travel("Jump")
		velocity.y = fuerza_salto
		await get_tree().create_timer(1.4).timeout
		Jumping = false
		anim_playback.travel("State")

func _detectar_suelo_raycast():
	if is_dead:
		return
	
	ray_suelo.force_raycast_update()

	if is_on_floor_only() and ray_suelo.is_colliding():
		Jumping = false
		if not is_attacking and not __rolling:
			anim_playback.travel("State")

func _input(event: InputEvent) -> void:
	if is_dead:
		return
	
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * sensibilidad_camara))
		pivote.rotate_z(deg_to_rad(-event.relative.y * sensibilidad_camara))
		
		pivote.rotation.x = clamp(pivote.rotation.x, deg_to_rad(-70.0), deg_to_rad(70.0))
		pivote.rotation.z = clamp(pivote.rotation.z, deg_to_rad(-49.0), deg_to_rad(50.0))

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_camara.position.x += 0.1 
			_camara.position.x = clamp(_camara.position.x, -0.5, 1.0)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_camara.position.x -= 0.1 
			_camara.position.x = clamp(_camara.position.x, -0.5, 1.0)
	
	if Input.is_action_just_pressed("attack") and not is_attacking and not is_dead:
		is_attacking = true
		anim_playback.travel("Attack")
		await get_tree().create_timer(0.5).timeout  # Ajusta este tiempo según tu animación
		is_attacking = false
		if _sword_instance and _sword_instance.has_method("activate_sword"):
			_sword_instance.activate_sword()
		if not is_dead:
			anim_playback.travel("State")
	elif Input.is_action_just_pressed("fijar"):
		_camara.look_at(_enemy.global_position)
	if _camara.global_position==pivote.global_position:
		_camara.position.x=0
	
func play_get_up_animation() -> void:
	set_physics_process(false)
	anim_playback.travel("Get_up")
	await get_tree().create_timer(2.8).timeout
	
	set_physics_process(true)
	anim_playback.travel("State")


func take_damage(damage: float) -> void:
	# if _sword:
	#     _sword_instance=_sword.instantiate()
	#     add_child(_sword_instance)
	#     if _sword_instance.has_signal("conectar_golpe"):
	#         print("Señal de espada conectada")
	#         _sword_instance.conectar_golpe.connect()
	# if _sword_instance.conectar_golpe.connect: # ESTA LÍNEA ES EL PROBLEMA PRINCIPAL
	#     self.health -=damage
	# --- FIN DEL BLOQUE A CORREGIR ---

	self.health -= damage

	if is_dead: 
		return

	if health <= 0:
		is_dead = true
		dead_signal.emit(is_dead)
		print("Emitir señal \"muerto\"")
		wait_to_star = true
		anim_playback.travel("Dead")
		await get_tree().create_timer(2.8).timeout
		get_tree().reload_current_scene()
		if not is_dead: 
			anim_playback.travel("Get_up")
		return 
	if _salud:
		self._salud.value = health
		self._salud.max_value = 100.0

	wait_to_star = false 
