extends Personaje

class_name enemy


@export var rotation_speed: float = 3.0
@export var detection_range: float = 5.0
@export var stopping_distance: float = 1.5
@export var tiempo_maximo_rutina: float = 4.0
@export var rango_movimiento_aleatorio: float = 5.0
@export var _player: PackedScene 
var _player_instance: Node
var attack_timer: float = 0.0
@export var attack_cooldown: float = 1.5

@onready var nav_agent = $NavigationAgent3D
@onready var _salud: ProgressBar = $Sprite3D/SubViewport/healt
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
var _damage_:bool
signal golpe_conectado(damage: float)
signal dead_signal(is_dead:bool)
var health: float = 100


# Variables de estado
var _cronometro: float = 0.0
var _rutina: int = 0
var angulo_rotacion_aleatorio: Quaternion
var speed: float = 5.0
var player_is_dead: bool = false
var distan_heavy:float=4.5


func _ready():
	_player_instance = _player.instantiate()
	_cronometro = tiempo_maximo_rutina
	clase_mago()
	anim_tree.active = true
	anim_playback = anim_tree.get("parameters/playback")
	add_to_group("enemy")

func _physics_process(delta):
	if is_dead:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	if not is_attacking:
		attack_timer -= delta
	comportamiento_enemigo(delta)
	_aplicar_gravedad(delta)
	move_and_slide()

func comportamiento_enemigo(delta) -> void:
	var distance_to_target = 0.0
	if _player_instance:  # Usamos _player_instance en lugar de _player
		distance_to_target = global_position.distance_to(_player_instance.global_position)

	# Lógica de cambio de estado (transiciones)
	if player_is_dead or not _player_instance:  # Cambiar _player a _player_instance
		_rutina = 2
	else:
		if distance_to_target <= stopping_distance:
			_rutina = 3
		elif distance_to_target <= detection_range:
			_rutina = 1
			_cronometro = 0 # Reiniciar el cronómetro cuando el jugador entra en el rango
		else:
			_cronometro += delta
			if _cronometro >= tiempo_maximo_rutina:
				_rutina = 2
				_cronometro = 0
	
	# Lógica de ejecución del estado
	match _rutina:
		0:
			is_moving = false
			anim_playback.travel("State")
			anim_tree.set("parameters/State/blend_position", Vector2.ZERO)
			velocity = Vector3.ZERO
		
		1:
			is_moving = true
			nav_agent.target_position = _player_instance.global_position  # Usamos _player_instance
			var next_pos = nav_agent.get_next_path_position()
			var direction = (next_pos - global_position).normalized()
			velocity = direction * speed
			_rotate_to_target(direction, delta)
			
			anim_playback.travel("State")
			_vector2 = Vector2(0, 1) # Animación de caminar
			anim_tree.set("parameters/State/blend_position", _vector2)
			
		2:
			is_moving = true
			if nav_agent.is_navigation_finished():
				var grado_aleatorio = randf_range(0.0, 360.0)
				angulo_rotacion_aleatorio = Quaternion.from_euler(Vector3(0, deg_to_rad(grado_aleatorio), 0))
				var direccion_aleatoria = angulo_rotacion_aleatorio * Vector3.FORWARD * rango_movimiento_aleatorio
				nav_agent.target_position = global_position + direccion_aleatoria
				
			var next_pos = nav_agent.get_next_path_position()
			var direction = (next_pos - global_position).normalized()
			_rotate_to_target(direction, delta)
			velocity = direction * speed
			
			_vector2 = Vector2(0, 1) # Animación de caminar
			anim_tree.set("parameters/State/blend_position", _vector2) 
			anim_playback.travel("State")

		3:
			is_moving = false
			look_at(_player_instance.global_position, Vector3.UP)  # Usamos _player_instance
			velocity = Vector3.ZERO
			
			if not is_attacking:
				is_attacking = true
				anim_playback.travel("Attack")
				await get_tree().create_timer(1.0).timeout
				is_attacking = false

			if distan_heavy:
				is_moving = false
				look_at(_player_instance.global_position, Vector3.UP)  # Usamos _player_instance
				velocity = Vector3.ZERO
				#anim_playback.travel("Hevy")

				is_attacking = false
				
				# Vuelve a evaluar el estado después de atacar
				var distance_after_attack = global_position.distance_to(_player_instance.global_position)  # Usamos _player_instance
				if distance_after_attack <= stopping_distance:
					_rutina = 3 # Atacar de nuevo
				elif distance_after_attack <= detection_range:
					_rutina = 1
				else:
					_rutina = 0

			
func _rotate_to_target(direction: Vector3, delta: float):
	var target_angle = atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, target_angle, rotation_speed * delta)
		

func _muerte_propia() ->void:
	anim_playback.travel("Dead")
	await get_tree().create_timer(8.2).timeout
	self.queue_free()
	

func take_damage(damage: float) -> void:
	_damage_=true
	anim_playback.travel("Damage")
	if is_dead:
		return
	
	health -= damage
	if _salud:
		self._salud.value = health
		self._salud.max_value = 100.0
		#look_at(_salud.global_transform.origin, Vector3.UP)
	
	print("Vida actual: enemigo ", health)
	
	if health <= 0:
		is_dead = true
		dead_signal.emit(is_dead)
		print("Emitir señal \"muerto\"")
		_muerte_propia()
