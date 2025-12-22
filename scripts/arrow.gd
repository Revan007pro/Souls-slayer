class_name arrow
extends Node3D

@export var speed: float = 40.8
@export var gravity: float = 9.8

var velocity: Vector3
var shoot_arrow := false

func _ready():
	Weapons.connect("shoot", Callable(self, "on_shoot"))


func on_shoot() -> void:
	if shoot_arrow:
		return

	shoot_arrow = true
	var forward = global_transform.basis.y.normalized()
	velocity = forward * speed

func _physics_process(delta):
	if not shoot_arrow:
		return

	position += velocity * delta
	velocity.y -= gravity * delta
	look_at(global_position + velocity, Vector3.UP)
