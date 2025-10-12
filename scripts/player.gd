extends Personaje

class_name player

@export var speed: float = 5.0
@export var acceleration: float = 75.0
@export var fuerza_salto: float = 4.5
@export var _enemy: PackedScene
@export var _goblin_fbx: PackedScene
@export var _sword: PackedScene

var _sword_instance: Node3D
var _goblin_instance: Node3D 
var anim_tree: AnimationTree  

@onready var pivote: Node3D = $Pivote
@onready var _camara: Camera3D = $Pivote/Camera3D
@onready var ray_suelo: RayCast3D = $RayCast3D
@onready var _salud: ProgressBar = $CanvasLayer/healt
@onready var _stamina: ProgressBar=$CanvasLayer/healt/Stamina
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
var State:bool=false

var sensibilidad_camara: float = 0.5

func _ready() -> void:

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	_goblin_instance = _goblin_fbx.instantiate()
	add_child(_goblin_instance)
	anim_tree = _goblin_instance.get_node("anim_tree")  
	if anim_tree:
		anim_playback = anim_tree.get("parameters/playback")   
	
	call_deferred("_deferred_ready")
func _deferred_ready() -> void:
	if is_first_spawn:
		play_get_up_animation()
		is_first_spawn = false


func _physics_process(delta: float) -> void:
	if is_dead:
		return  
	_movimiento_jugador(delta)
	_aplicar_gravedad(delta)
	_salto_jugador()
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
	if Input.is_action_just_pressed("desvainar"):
			_desvainar = true
			anim_playback.travel("Ani_player_Desvainar")
			print("animacion desvainar")
			await get_tree().create_timer(1.6).timeout
			_desvainar = false
			anim_playback.travel("State") 
func _bloquear()->void:
	while Input.is_action_just_pressed("block"):
		_desvainar=true
		anim_playback.travel("Ani_player_Block")
		print("animacion bloquar")
		await get_tree().create_timer(1.6).timeout
		_blocking = false
		anim_playback.travel("State")
		break
func _salto_jugador() :
	if Input.is_action_just_pressed("salto") and is_on_floor():
		var can_jump:int=20
		if self._stamina.value < can_jump:
			print("no hay estamina no se puede saltar")
			return
		self._stamina.value -=can_jump
		self._stamina.max_value=100
		Jumping = true
		print("salto")
		anim_playback.travel("Ani_player_Jump")
		velocity.y = fuerza_salto
		await get_tree().create_timer(2.0).timeout
		Jumping = false
		anim_playback.travel("State")

func _input(event: InputEvent) -> void:
	var _enemigo_instancia = get_tree().get_first_node_in_group("enemy")
	const ZOOM_MIN: float = -1.0
	const ZOOM_MAX: float = -5.0
	
	if is_dead:
		return
	
	# Movimiento de cámara
	if event is InputEventMouseMotion:
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
	
	if Input.is_action_just_pressed("attack") and _desvainar == true:
		var can_attack: int = 100  
		if _stamina.value < can_attack:
			print("Sin stamina, no puedes atacar")
			return
		is_attacking = true
		_stamina.value -= can_attack
		_stamina.max_value = 100  
		anim_playback.travel("Ani_player_Attack")
		
		await get_tree().create_timer(0.5).timeout
		
		is_attacking = false
		if not is_dead:
			anim_playback.travel("State")

	elif Input.is_action_just_pressed("fijar"):
		if _enemigo_instancia:
			_camara.look_at(_enemigo_instancia.global_position)

	
func play_get_up_animation() -> void:
	set_physics_process(false)
	anim_playback.travel("Get_up")
	wait_to_star = true
	await get_tree().create_timer(2.8).timeout
	
	set_physics_process(true)
	anim_playback.travel("State")


func take_damage(damage: float) -> void:
	self.health -= damage
	_damage_=true
	if _damage_==true and is_on_floor():
		#anim_playback.travel("Ani_player_Damage")
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

func _render_sword()->void:
	pass
