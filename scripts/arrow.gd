class_name arrow
extends Node3D

@export var speed: float = 40.8
@export var gravity: float = 9.8
@export var damage_amount: float = 50
var target


signal conectar_golpe(damage: float)

var velocity: Vector3
var shoot_arrow := false

func _ready():
	Weapons.connect("shoot", Callable(self , "on_shoot"))
	

func on_shoot() -> void:
	if shoot_arrow:
		return

	shoot_arrow = true
	var forward = global_transform.basis.y.normalized() # O este
	forward.y -= 0.1 # pequeño arco hacia abajo
	velocity = forward * speed

func _physics_process(delta):
	if not shoot_arrow:
		return
	position += velocity * delta
	velocity.y -= gravity * delta
	#look_at(global_position)
	look_at(global_position + velocity, Vector3.UP)
	

func _on_attack_area_body_entered(body: Node):
	if body.is_in_group("enemy") or body.is_in_group("Player"):
		print("¡flecha: Golpe conectado con ", body.name, "", body.get_class())
		conectar_golpe.emit(damage_amount)
		if body.has_method("take_damage"):
			body.take_damage(damage_amount)
			#get_parent().remove_child(self)
			#body.get_parent().add_child(self)
			queue_free()
		
	else:
		print("Tipo de objeto: ", body.get_class())
	
	await get_tree().create_timer(4.0).timeout
	queue_free()
