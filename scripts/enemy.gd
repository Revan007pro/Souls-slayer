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
var attack_count:int=2
var _hevy:bool=false
var _ataque_fuerte:float=7.5
var is_dead:bool
var State:bool
signal golpe_conectado(damage: float)
signal dead_signal(is_dead:bool)
var health: float = 100.0
@onready var attack_area: Area3D = $AttackArea
@export var damage_amount: float = 10.0

# Variables de estado
var _cronometro: float = 0.0
var _rutina: int = 0
var angulo_rotacion_aleatorio: Quaternion
var speed: float = 5.0
var player_is_dead: bool = false  # ← NUEVA VARIABLE PARA SABER SI EL JUGADOR ESTÁ MUERTO

func _ready():
	_cronometro = tiempo_maximo_rutina
	clase_mago()
	anim_tree.active = true
	anim_playback = anim_tree.get("parameters/playback")
	add_to_group("enemy")
	$AttackArea.body_entered.connect(_on_attack_area_body_entered)
	if _player != null and _player.has_signal("dead_signal"):
		_player.dead_signal.connect(_on_enemy_dead_signal)

func _physics_process(delta):
	comportamiento_enemigo()
	_aplicar_gravedad(delta)
	move_and_slide()

func comportamiento_enemigo() -> void:
	# Verificar si el jugador está muerto
	if player_is_dead:
		_rutina = 2  # Cambiar a rutina de movimiento aleatorio
		is_moving = true
		anim_playback.travel("State")
		
		# Ejecutar rutina 2 (movimiento aleatorio)
		var direccion_aleatoria = angulo_rotacion_aleatorio * Vector3.FORWARD * rango_movimiento_aleatorio
		var destino = global_position + direccion_aleatoria
		nav_agent.target_position = destino
		
		if !nav_agent.is_navigation_finished():
			var next_pos = nav_agent.get_next_path_position()
			var direction = (next_pos - global_position).normalized()
			velocity = direction * speed
			is_moving = true
			_vector2 = Vector2(1, 0)
			anim_tree.set("parameters/State/blend_position", _vector2)
			rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), rotation_speed * get_process_delta_time())
		return
	
	if _player == null:
		_rutina = 2
		is_moving = true
		anim_playback.travel("State")
		return
	
	var distance_to_target = global_position.distance_to(_player.global_position)
	
	while distance_to_target <= detection_range:
		_rutina = 1
		_cronometro = 0
		if distance_to_target <= stopping_distance:
			_rutina = 3
		break
	if distance_to_target <= _ataque_fuerte and distance_to_target > stopping_distance:
		look_at(_player.global_position)
		_hevy = true
		anim_playback.travel("Hevy")
		velocity = Vector3.ZERO
	elif _rutina != 1:
		_cronometro += get_process_delta_time()
		if _cronometro >= tiempo_maximo_rutina:
			_rutina = randi_range(0, 3)
			_cronometro = 0
			if _rutina == 2:  # Solo para rutina 2 generamos rotación aleatoria
				var grado_aleatorio = randf_range(0.0, 360.0)
				angulo_rotacion_aleatorio = Quaternion.from_euler(Vector3(0, deg_to_rad(grado_aleatorio), 0))

	match _rutina:
		0: 
			velocity = Vector3.ZERO
			is_moving = false
			anim_playback.travel("State")
			
		1: 
			nav_agent.target_position = _player.global_position
			if distance_to_target <= detection_range:
				is_moving = true
				_vector2 = Vector2(1, 0)
				anim_tree.set("parameters/State/blend_position", _vector2) 
				var next_pos = nav_agent.get_next_path_position()
				var direction = (next_pos - global_position).normalized()
				velocity = direction * speed
			else:
				nav_agent.target_position = global_position
				_vector2 = Vector2(0, 0)
				is_moving = false
				
		2:  
			var direccion_aleatoria = angulo_rotacion_aleatorio * Vector3.FORWARD * rango_movimiento_aleatorio
			var destino = global_position + direccion_aleatoria
			nav_agent.target_position = destino
			
			if !nav_agent.is_navigation_finished():
				var next_pos = nav_agent.get_next_path_position()
				var direction = (next_pos - global_position).normalized()
				velocity = direction * speed
				is_moving = true
				_vector2 = Vector2(1, 0)
				anim_tree.set("parameters/State/blend_position", _vector2) 
				rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), rotation_speed * get_process_delta_time())

		3:
			if distance_to_target <= stopping_distance:
				velocity = Vector3.ZERO
				is_moving = false
				is_attacking = true
				look_at(_player.global_position)
				anim_playback.travel("Attack")
				if distance_to_target == detection_range:
					is_moving = true
				if distance_to_target>=detection_range:
					anim_playback.travel("State")
					
			
			else:
				is_attacking=false
				anim_playback.travel("State")
				
	anim_tree.set("parameters/State/blend_position", _vector2)

func _on_enemy_dead_signal(is_dead: bool) -> void:
	print("Señal recibida: Jugador está muerto: ", is_dead)
	player_is_dead = is_dead  # ← ESTABLECER LA BANDERA, NO PONER _player = null
	_rutina = 2
	is_attacking = false
	_hevy = false
	is_moving = true
	return

# Resto de tus funciones permanecen igual...
func _on_velocity_computed(safe_velocity):
	velocity = safe_velocity

func deal_damage(damage: float = damage_amount) ->void:
	golpe_conectado.emit(damage_amount)

func _on_attack_area_body_entered(body):
	if body.is_in_group("player"): 
		print("¡GOLPE CONECTADO! Aplicando daño \"enemigo")
		health -= damage_amount
		if health <= 0:
			is_dead = true
			anim_playback.travel("Death")
		print(health)
