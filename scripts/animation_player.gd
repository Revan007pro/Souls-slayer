extends AnimationPlayer

var jugador = GameManager.player_instance
var attack_area: Area3D

#@onready var ani_player: AnimationTree = jugador.get_node("anim_tree")
#@onready var anim_playback: AnimationNodeStateMachinePlayback = ani_player.get("parameters/playback")


func aparecer_efecto_poof():
	var efecto = preload("res://shaders/poof_escena.tscn").instantiate()
	jugador.get_parent().add_child(efecto)
	efecto.global_position = jugador.global_position
	efecto.global_position.y += -1.0
	efecto.global_position.x += 1.8
	efecto.scale = Vector3(-1, -1, -1)
	await get_tree().create_timer(1.0).timeout
	efecto.queue_free() # shader del efecto poof

func monitorin_true():
	var sword = await Weapons._wait_sword()
	attack_area = sword.get_node("AttackArea") # Guardar en variable de clase
	attack_area.monitoring = true


func monitorin_false():
	# Usar la variable de clase
	if attack_area != null:
		attack_area.monitoring = false
