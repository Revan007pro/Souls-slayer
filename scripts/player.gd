extends Personaje

class_name player

@export var speed: float = 5.0
@export var acceleration: float = 75.0
@export var fuerza_salto: float = 4.5
@export var _enemy: PackedScene
@export var _goblin_fbx: PackedScene
@onready var _sword: PackedScene = preload("res://sword.tscn")

var _sword_instance: Node3D
var _goblin_instance: Node3D 
var _arma_instancia =Node
var anim_tree: AnimationTree  
var bone_scene: BoneAttachment3D
var _dialogue_balloon = null
var is_combact:bool=false
var _dialogue_active = false

const  Agregar = preload("res://dialogues_pruebas/Agregar.dialogue")  

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
var _camera_can_move:bool = true 
var is_first_spawn: bool =true

var _vector2: Vector2 = Vector2.ZERO
var is_movieng: bool = false
var Jumping: bool = false
var can_jump: bool = true
var __rolling: bool = false
var attack_radio: float = 1.0
var _damage_: bool
var _desvainar: bool=false
var _desvainar_with:bool=false
var is_dead: bool = false
var is_attacking: bool = false

var wait_star: float = 2.8
var wait_to_star: bool = false
var _blocking: bool

var sensibilidad_camara: float = 0.5

func _ready() -> void:
	#GameManager._player_recurrente(self)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	_arma_instancia = get_tree().get_first_node_in_group("Arma")
	_goblin_instance = _goblin_fbx.instantiate()
	add_child(_goblin_instance)
	anim_tree = _goblin_instance.get_node("anim_tree")  
	bone_scene = _goblin_instance.get_node("Skeleton3D/BoneAttachment3D")
	if anim_tree:
		anim_playback = anim_tree.get("parameters/playback")   
	call_deferred("_deferred_ready")
func _deferred_ready() -> void:
	if is_first_spawn:
		play_get_up_animation()
	
func _physics_process(delta: float) -> void:
	if is_dead:
		return  
	_movimiento_jugador(delta)
	_aplicar_gravedad(delta)
	_salto_jugador()
	is_attaacking()
	_desvainar_espada()
	_bloquear()
	_regenerar_stamina()
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

func _wait_sword() -> void:
	await get_tree().create_timer(0.7).timeout
	_sword_instance = _sword.instantiate() as Node3D
	bone_scene.add_child(_sword_instance)
	_sword_instance.position = Vector3(0.296, -0.002, 0.156)
	_sword_instance.rotation_degrees = Vector3(1.7, 63.5, 143.8)
func _desvainar_espada() -> void:
	
	if Input.is_action_just_pressed("desvainar"):
		
		if !_desvainar:
			is_combact=true
			_wait_sword()
			_desvainar = true
			anim_playback.travel("Ani_player_Desvainar")
			print("Animación desvainar")
			await get_tree().create_timer(1.6).timeout
			_desvainar_with = true
			anim_playback.travel("With")
			print("Espada desvainada")
		elif _desvainar_with:  
			is_combact=false
			anim_playback.travel("Ani_player_Envainar")
			print("Animación envainar")
			await get_tree().create_timer(1.1).timeout  
			_desvainar = false
			_desvainar_with = false
			bone_scene.remove_child(_sword_instance)
			anim_playback.travel("State")
			print("Espada envainada")
	anim_tree.set("parameters/With/blend_position", _vector2)

func _bloquear()->void:
	while Input.is_action_just_pressed("block"):
		is_combact=true
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
	if event is InputEventMouseMotion and _camera_can_move==true:
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
	

	elif Input.is_action_just_pressed("fijar"):
		if _enemigo_instancia:
			_camara.look_at(_enemigo_instancia.global_position)

func is_attaacking()->void:
	if Input.is_action_just_pressed("attack") and _desvainar == true:
		is_combact=true
		var can_attack: int = 30 
		if _stamina.value < can_attack:
			print("Sin stamina, no puedes atacar")
			return
		is_attacking = true
		self._stamina.value -= can_attack
		self._stamina.max_value = 100  
		anim_playback.travel("Ani_player_Attack")
		
		await get_tree().create_timer(1.6667).timeout
		
		is_attacking = false
		if not is_dead:
			anim_playback.travel("With")


	
func play_get_up_animation() -> void:
	set_physics_process(false)
	anim_playback.travel("Get_up")
	wait_to_star = true
	_camera_can_move=false
	await get_tree().create_timer(2.8).timeout
	
	set_physics_process(true)
	_camera_can_move=true
	anim_playback.travel("State")


func take_damage(damage: float) -> void:
	is_combact=true
	self.health -= damage
	_damage_=true
	#anim_playback.travel("Ani_player_Damage")
	
	
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

func _regenerar_stamina()->void:
	var stamina_mas:int=10
	while _stamina.value < 100 and is_on_floor():
		await get_tree().create_timer(2.8).timeout
		self._stamina.value +=stamina_mas
		break

func _on_area_3d_area_entered(area: Area3D) -> void:
	if not _dialogue_active and is_combact==false:
		_dialogue_balloon = DialogueManager.show_dialogue_balloon(Agregar)
		_dialogue_active = true
		print("Jugador dentro del área, mostrando diálogo.")

func _on_area_3d_area_exited(area: Area3D) -> void:
	if _dialogue_active and _dialogue_balloon:
		_dialogue_balloon.queue_free()
		_dialogue_balloon = null
		_dialogue_active = false
		print("Jugador salió del área, diálogo cerrado.")
