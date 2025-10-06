extends Personaje

class_name player

@export var speed: float = 5.0
@export var acceleration: float = 75.0
@export var fuerza_salto: float = 4.5
@export var _enemy: PackedScene
@export var _goblin_fbx: PackedScene
@export var _sword: PackedScene

var _sword_instance: Node3D
var _goblin_instance: Node3D  # Guardamos la instancia del goblin
var anim_tree: AnimationTree  # Declaramos anim_tree a nivel global

@onready var pivote: Node3D = $Pivote
@onready var _camara: Camera3D = $Pivote/Camera3D
@onready var ray_suelo: RayCast3D = $RayCast3D
@onready var _salud: ProgressBar = $CanvasLayer/healt
@onready var death_sound: AudioStreamPlayer = $dead_sonido

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
var _damage_: bool
var _desvainar: bool
var is_dead: bool = false
var is_attacking: bool = false
var wait_star: float = 2.8
var wait_to_star: bool = false
var _blocking: bool

var sensibilidad_camara: float = 0.5

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	_goblin_instance = _goblin_fbx.instantiate()
	add_child(_goblin_instance)
	_sword_instance = _sword.instantiate()
	_sword_instance.visible = false
	anim_tree = _goblin_instance.get_node("anim_tree")  
	if anim_tree:
		anim_playback = anim_tree.get("parameters/playback")   
	
	call_deferred("_deferred_ready")

func _deferred_ready() -> void:
	if is_first_spawn:
		play_get_up_animation()
		is_first_spawn = false
	else:
		# Si no es la primera vez, ir directamente al estado normal
		anim_playback.travel("State")  # Asegúrate de que "State" sea un estado válido


func _physics_process(delta: float) -> void:
	if is_dead:
		return  
	_movimiento_jugador(delta)
	_aplicar_gravedad(delta)
	_salto_jugador()
	_detectar_suelo_raycast()
	_desvainar_espada()
	_bloquear()
	move_and_slide()
	
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

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
func _desvainar_espada()->void:
	if Input.is_action_just_pressed("desvainar")and is_on_floor():
		_desvainar=true
		anim_playback.travel("Ani_player_Desvainar")
		await get_tree().create_timer(1.5).timeout
		print("animacion desvainar")
		_blocking = false
func _bloquear()->void:
	if Input.is_action_just_pressed("block") and is_on_floor():
		_desvainar=true
		anim_playback.travel("Ani_player_Block")
		print("animacion bloquar")
		_blocking = false
func _salto_jugador():
	if Input.is_action_just_pressed("salto") and is_on_floor_only():
		#await get_tree().create_timer(1.4).timeout
		Jumping = true
		print("salto")
		anim_playback.travel("Ani_player_Jump")
		velocity.y = fuerza_salto
		#Jumping = false
		

func _detectar_suelo_raycast():
	if is_dead:
		return
	
	ray_suelo.force_raycast_update()

	if is_on_floor_only() and ray_suelo.is_colliding():
		Jumping = false
		if not is_attacking and not __rolling:
			anim_playback.travel("State")

func _input(event: InputEvent) -> void:
	const ZOOM_MIN: float = -1.0
	const ZOOM_MAX: float = -5.0
	if is_dead:
		return
	
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * sensibilidad_camara))
		pivote.rotate_x(deg_to_rad(event.relative.y * sensibilidad_camara)) #para invertir el eje -
		
		pivote.rotation.x = clamp(pivote.rotation.x, deg_to_rad(-70.0), deg_to_rad(70.0))
		#pivote.rotation.z = clamp(pivote.rotation.z, deg_to_rad(-90), deg_to_rad(0))

	elif event is InputEventMouseButton:
		_camara.position.z = clamp(_camara.position.z, ZOOM_MAX, ZOOM_MIN)
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_camara.position.z += 0.1 
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_camara.position.z -= 0.1 
		if _camara.global_position==pivote.global_position:
			_camara.position.z=0
	
	if Input.is_action_just_pressed("attack") and not is_attacking and not is_dead:
		is_attacking = true
		anim_playback.travel("Ani_player_Attack")
		await get_tree().create_timer(0.5).timeout  # Ajusta este tiempo según tu animación
		is_attacking = false
		if not is_dead:
			anim_playback.travel("State")
	elif Input.is_action_just_pressed("fijar"):
		_camara.look_at(_enemy.global_position)
	
func play_get_up_animation() -> void:
	set_physics_process(false)
	anim_playback.travel("Get_up")
	await get_tree().create_timer(2.8).timeout
	
	set_physics_process(true)
	anim_playback.travel("State")


func take_damage(damage: float) -> void:
	self.health -= damage
	_damage_=true
	if _damage_==true and is_on_floor():
		anim_playback.travel("Ani_player_Damage")
		print("animacion de daño")
	
	
	#if _sword:
	#	_sword_instance=_sword.instantiate()
	#	add_child(_sword_instance)
	#	if _sword_instance.has_signal("conectar_golpe"):
	#		print("Señal de espada conectada \"error")
	#		_sword_instance.conectar_golpe.connect() 
	#if _sword_instance.has_method("activate_sword"):
	#	print("ponete a estudiar mejor")
		
	
	if is_dead: 
		return

	if health <= 0:
		death_sound.play()
		is_dead = true
		dead_signal.emit(is_dead)
		print("Emitir señal \"muerto\"")
		wait_to_star = true
		anim_playback.travel("Ani_player_dead")
		await get_tree().create_timer(2.8).timeout
		get_tree().reload_current_scene()
	if _salud:
		self._salud.value = health
		self._salud.max_value = 100.0
