extends Personaje
var cronometro: float
var rutina: int
var angulo_rotacion_aleatorio: Quaternion
var tiempo_maximo_rutina: float = 4.0
var rango_movimiento_aleatorio: float = 5.0
var velocidad_idle: float = 0.0
var velocidad_walk_animacion: float = 0.5
var velocidad_run_animacion: float = 1.0
var _cronometro:float
var _rutina:int


var _atacar_param: bool = false
var is_walking: bool

@export var speed: float = 3.0
@export var detection_range: float = 5.0  # Rango para detectar al jugador
@export var stopping_distance: float = 1.0  # Distancia para detenerse
@export var _player: CharacterBody3D  # Arrastra tu jugador aquí desde el editor

@onready var nav_agent = $NavigationAgent3D

func _ready():
	nav_agent.velocity_computed.connect(_on_velocity_computed)
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = stopping_distance
	_cronometro=tiempo_maximo_rutina
	_rutina=0
	clase_mago()
	
	

func _physics_process(delta):
	comportamiento_enemigo()
	_aplicar_gravedad(delta)
	move_and_slide()

func comportamiento_enemigo() ->void:
	var distance_to_target = global_position.distance_to(_player.global_position)
	if distance_to_target <= detection_range:
		_rutina=1
	else:
		_rutina=0
	match _rutina:
		0:
			velocity = Vector3.ZERO
		1:
			nav_agent.target_position = _player.global_position
			if !nav_agent.is_navigation_finished():
				var next_pos = nav_agent.get_next_path_position()
				var direction = (next_pos - global_position).normalized()
				velocity = direction * speed
				print(_atributos)
			
		
		

func _on_velocity_computed(safe_velocity):
	velocity = safe_velocity
