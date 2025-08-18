extends Personaje

# Variables
var cronometro: float
var rutina: int
var angulo_rotacion_aleatorio: Quaternion
var agente: NavigationAgent3D
@export var Player: Node3D
#var animator: AnimationTree
var audio_source: AudioStreamPlayer3D
var _vida: float = 100.0
var _contador: float = 20.0

var animation_speed: float = 3.5
var tiempo_maximo_rutina: float = 4.0
var speed_param: String = "Speed"

var walk_param: String = "Walk"
var atacar_param: String = "Atacar"
var max_animation_speed: float

var rango_detectar_jugador: float = 5.0
var _rango_strop: float = 0.3
var rango_movimiento_aleatorio: float = 5.0
var velocidad_idle: float = 0.0
var velocidad_walk_animacion: float = 0.5
var velocidad_run_animacion: float = 1.0

var _atacar_param: bool = false
var is_walking: bool

func _ready():
	agente = $NavigationAgent3D
	#animator = $AnimationTree
	rutina = 0
	cronometro = tiempo_maximo_rutina
	
	# Esperar un frame para asegurar que estamos en el árbol de escena
	await get_tree().process_frame

func _process(delta):
	#if agente == null or Player == null or animator == null:
		#return

	comportamiento_enemigo()

func comportamiento_enemigo():
	var distancia_al_jugador = global_position.distance_to(Player.global_position)

	if distancia_al_jugador <= rango_detectar_jugador:
		rutina = 2
		cronometro = 0
	elif rutina != 2:
		cronometro += get_process_delta_time()

		if cronometro >= tiempo_maximo_rutina:
			rutina = randi_range(0, 1)
			cronometro = 0
			if rutina == 1:
				var grado_aleatorio = randf_range(0.0, 360.0)
				angulo_rotacion_aleatorio = Quaternion.from_euler(Vector3(0, deg_to_rad(grado_aleatorio), 0))

	match rutina:
		0:
			agente.target_position = global_position
		
		1:
			var direccion_aleatoria = angulo_rotacion_aleatorio * Vector3.FORWARD * rango_movimiento_aleatorio
			var punto_destino_aleatorio = global_position + direccion_aleatoria
			
			# Usar directamente el NavigationAgent3D para establecer el destino
			agente.target_position = punto_destino_aleatorio
			
			# Verificar si el destino es alcanzable
			if not agente.is_target_reachable():
				rutina = 0
				cronometro = 0
		
		2:
			if global_position.distance_to(Player.global_position) <= _rango_strop:
				agente.target_position = global_position
				rutina = 3
			else:
				agente.target_position = Player.global_position
		
		3:
			pass
