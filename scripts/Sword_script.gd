extends Node3D

@onready var attack_area: Area3D = $AttackArea
@export var damage_amount: float = 10


signal conectar_golpe(damage: float)

func _ready():
	attack_area.body_entered.connect(_on_attack_area_body_entered) 	

func _on_attack_area_body_entered(body: Node):
	if body.is_in_group("enemy") or body.is_in_group("Player"):
		print("¡ESPADA: Golpe conectado con " ,body.name)
		conectar_golpe.emit(damage_amount)
		if body.has_method("take_damage"):
			body.take_damage(damage_amount)

	
func activate_sword():
	attack_area.monitoring = true
