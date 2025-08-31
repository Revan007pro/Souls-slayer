extends Personaje

# Configuración

@export var rotation_speed: float = 5.0
@export var detection_range: float = 5.0
@export var stopping_distance: float = 1.5
@export var tiempo_maximo_rutina: float = 4.0
@export var rango_movimiento_aleatorio: float = 5.0
@export var _player: CharacterBody3D 

@onready var nav_agent = $NavigationAgent3D
@onready var anim_tree: AnimationTree = $AnimationTree
var anim_playback:AnimationNodeStateMachinePlayback
var _vector2: Vector2 = Vector2.ZERO
var is_moving: bool = false
var is_attacking:bool=false

# Variables de estado
var _cronometro: float = 0.0
var _rutina: int = 0
var angulo_rotacion_aleatorio: Quaternion
var speed: float = 5.0

func _ready():
	_cronometro = tiempo_maximo_rutina
	clase_mago()
	anim_tree.active = true
	anim_playback = anim_tree.get("parameters/playback")

func _physics_process(delta):
	comportamiento_enemigo()
	_aplicar_gravedad(delta)
	update_animation()
	move_and_slide()

func comportamiento_enemigo() -> void:
	
	var distance_to_target = global_position.distance_to(_player.global_position)
	
	# Lógica de cambio de rutina
	if distance_to_target <= detection_range:
		_rutina = 1  # Perseguir jugador
		_cronometro = 0
		if distance_to_target <= stopping_distance:
			_rutina = 3
	elif _rutina != 1:
		_cronometro += get_process_delta_time()
		if _cronometro >= tiempo_maximo_rutina:
			_rutina = randi_range(0, 2)
			_cronometro = 0
			if _rutina == 2:  # Solo para rutina 2 generamos rotación aleatoria
				var grado_aleatorio = randf_range(0.0, 360.0)
				angulo_rotacion_aleatorio = Quaternion.from_euler(Vector3(0, deg_to_rad(grado_aleatorio), 0))
	elif is_attacking:
		velocity=Vector3.ZERO
		return
	
	# Ejecutar rutina actual
	match _rutina:
		0: 
			velocity = Vector3.ZERO
			is_moving = false
			
		1: 
			nav_agent.target_position = _player.global_position
			if distance_to_target<=detection_range:
				is_moving = true
				var next_pos = nav_agent.get_next_path_position()
				var direction = (next_pos - global_position).normalized()
				velocity = direction * speed

			else:
				nav_agent.target_position =global_position
				is_moving=false
				
				
		2:  
			var direccion_aleatoria = angulo_rotacion_aleatorio * Vector3.FORWARD * rango_movimiento_aleatorio
			var destino = global_position + direccion_aleatoria
			nav_agent.target_position = destino
			
			if !nav_agent.is_navigation_finished():
				var next_pos = nav_agent.get_next_path_position()
				var direction = (next_pos - global_position).normalized()
				velocity = direction * speed
				# Rotación básica
				rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), rotation_speed * get_process_delta_time())
		3:
			if distance_to_target <= stopping_distance:
				velocity = Vector3.ZERO
				is_moving = false
				is_attacking = true
				anim_playback.travel("Attack")
			else:
				is_attacking = false
				anim_playback.travel("State")

	
func _on_velocity_computed(safe_velocity):
	velocity = safe_velocity


func update_animation():
	if is_moving:
		_vector2 = Vector2(1, 0)  
	else:
		_vector2 = Vector2(0, 0)  
	
	anim_tree.set("parameters/State/blend_position", _vector2)
