
func actualizar_animacion():
    var velocidad_actual_agente = agente.get_velocity().length()
    var animation_speed_normalized = velocidad_actual_agente / agente.max_speed
    animation_speed_normalized = clampf(animation_speed_normalized, 0.0, 1.0)
    animator.set("parameters/" + str(speed_hash) + "/scale", animation_speed_normalized)

    is_walking = velocidad_actual_agente > 0.1
    animator.set("parameters/" + str(walk_hash) + "/blend_position", is_walking)

func play_footstep_sound():
    if audio_source != null and audio_source.stream != null:
        audio_source.play()

func _hacer_daño():
    _vida -= _contador

func reset_ataque():
    animator.set("parameters/" + str(atacar_param_hash) + "/active", false)

func _atacar():
    agente.target_position = global_position
    _atacar_param = true
    animator.set("parameters/" + str(atacar_param_hash) + "/active", _atacar_param)

func _atacar_distancia():
    pass

func _on_trigger_entered(other: Node3D):
    if other.is_in_group("player"):
        _hacer_daño()
    elif _vida <= 0.0:
        queue_free()


        	var punto_cercano = NavigationServer3D.get_singleton().map_get_closest_point(
				get_world_3d().get_navigation_map(),
				punto_destino_aleatorio
			)
			
			if punto_cercano != Vector3.ZERO:
				agente.target_position = punto_cercano