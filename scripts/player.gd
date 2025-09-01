# Archivo: player.gd
extends Personaje

@export var speed: float = 5.0
@export var acceleration: float = 75.0
@export var fuerza_salto: float = 4.5

@onready var pivote: Node3D = $Pivote
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var _camara: Camera3D = $Pivote/Camera3D
@onready var ray_suelo: RayCast3D = $RayCast3D
#@onready var _timer=get_node("Timer")

signal golpe_conectado(damage: float)
var health: float = 100.0

var rotacion_horizontal: float = 0.0
var rotacion_vertical: float = 0.0
var anim_playback: AnimationNodeStateMachinePlayback
var damage_amount:float=10

var _vector2: Vector2 = Vector2.ZERO
var is_movieng: bool = false
var Jumping: bool = false
var can_jump: bool = true
var __rolling: bool
var attack_radio:float=1.0


var sensibilidad_camara: float = 0.5

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	anim_tree.active = true
	anim_playback = anim_tree.get("parameters/playback")
	add_to_group("Player")
	$AttackArea.body_entered.connect(_on_attack_area_body_entered)
	#_timer.wait_time=attack_radio
	#_timer.start()
	

	if ray_suelo:
		ray_suelo.enabled = true


func _physics_process(delta: float) -> void:
	_movimiento_jugador(delta)
	_aplicar_gravedad(delta)
	_salto_jugador()
	_detectar_suelo_raycast()
	muerte()
	#recibir_daño() 
	move_and_slide()

	

	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _movimiento_jugador(delta: float) -> void:
	var input_dir = Input.get_vector("atras", "adelante", "derecha", "izquierda")
	var direction = (transform.basis * Vector3(input_dir.x, 0, -input_dir.y)).normalized()
	
	if direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
		_vector2 = Vector2(input_dir.x, -input_dir.y)
		is_movieng = true
	elif Input.is_action_just_pressed("rolling"):
		__rolling=true
		anim_playback.travel("Rolling")
		await get_tree().create_timer(1.4).timeout
		anim_playback.travel("State")

	else:
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0, acceleration * delta)
		is_movieng = false
		_vector2 = Vector2.ZERO

	anim_tree.set("parameters/State/blend_position", _vector2)


func _salto_jugador():
	if Input.is_action_just_pressed("salto") and is_on_floor():
		Jumping = true
		anim_playback.travel("Jump")
		velocity.y = fuerza_salto
		await get_tree().create_timer(1.4).timeout
		anim_playback.travel("State")
		

func _detectar_suelo_raycast():
	ray_suelo.force_raycast_update()
	#print("piso detectado")

	if is_on_floor_only() and ray_suelo.is_colliding():
		Jumping = false
		anim_playback.travel("State")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * sensibilidad_camara))
		pivote.rotate_z(deg_to_rad(-event.relative.y * sensibilidad_camara))
		
		pivote.rotation.x = clamp(pivote.rotation.x, deg_to_rad(-70.0), deg_to_rad(70.0))
		pivote.rotation.z = clamp(pivote.rotation.z, deg_to_rad(-49.0), deg_to_rad(50.0))

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_camara.position.x += 0.1 
			_camara.position.x = clamp(_camara.position.x, 1.0, 0.9)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_camara.position.x -= 0.1 
			_camara.position.x = clamp(_camara.position.x, 1.0, -0.5)
	elif _camara.global_position==pivote.global_position:
		_camara.position.x=0
		pivote.rotate_z(deg_to_rad(-event.relative.y * sensibilidad_camara))
		
		pivote.rotation.x = clamp(pivote.rotation.x, deg_to_rad(0), deg_to_rad(0))
		pivote.rotation.z = clamp(pivote.rotation.z, deg_to_rad(0), deg_to_rad(0))
		pivote.rotation.y = clamp(pivote.rotation.y, deg_to_rad(0), deg_to_rad(0))

func deal_damage() ->void:
	golpe_conectado.emit(damage_amount)
	


func _on_attack_area_body_entered(body):
	if body.is_in_group("enemy"): 
		print("¡GOLPE CONECTADO! Aplicando daño")
		health -=damage_amount
		print(health)
	if health<=0:
		queue_free()
		get_tree().reload_current_scene()
		if body.has_method("take_damage"):
			body.take_damage(10.0)
			
	
