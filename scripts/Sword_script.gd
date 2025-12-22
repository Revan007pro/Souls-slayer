extends Node3D

@onready var attack_area := find_child("AttackArea", true, false) as Area3D


#var sword_scene: PackedScene = preload("res://sword.tscn")
#var sword: Node3D
#var attack_area: Area3D

@export var damage_amount: float = 10

#func _ready():
#	sword = sword_scene.instantiate()
#	attack_area = sword.get_node("AttackArea")


signal conectar_golpe(damage: float)
#	attack_area.body_entered.connect(_on_attack_area_body_entered)

func _on_attack_area_body_entered(body: Node):
	if body.is_in_group("enemy") or body.is_in_group("Player"):
		print("¡ESPADA: Golpe conectado con ", body.name)
		conectar_golpe.emit(damage_amount)
		if body.has_method("take_damage"):
			body.take_damage(damage_amount)

	
func activate_sword():
	attack_area.monitoring = true

func off_sword():
	attack_area.monitoring = false
	print(attack_area.monitoring)
	if attack_area.monitoring == false:
		print("desactivando colader de espada")
