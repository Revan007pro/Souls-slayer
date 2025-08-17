# Archivo: Personaje.gd
extends CharacterBody3D

class_name Personaje
var gravedad: float = 9.8

var _atributos: Dictionary = {
    "vitalidad": 10,
    "resistencia": 10,
    "fuerza": 10,
    "destreza": 10,
    "magia": 10,
    "defensa": 10,
    "suerte": 10
}
var _salud_actual: int
var _mana_actual: int
var _nivel: int = 1
var _puntos_de_habilidad: int = 0
var _exp_actual: int = 0
var _exp_proximo_nivel: int = 100

func _ready() -> void:
    _salud_actual = _atributos["vitalidad"] * 10
    _mana_actual = _atributos["magia"] * 10

func recibir_daño(cantidad: int) -> void:
    _salud_actual -= cantidad
    if _salud_actual <= 0:
        _salud_actual = 0
        muerte()

func recuperar_salud(cantidad: int) -> void:
    _salud_actual += cantidad
    if _salud_actual > _atributos["vitalidad"] * 10:
        _salud_actual = _atributos["vitalidad"] * 10

func subir_nivel() -> void:
    _nivel += 1
    _puntos_de_habilidad += 1
    _exp_proximo_nivel = int(_exp_proximo_nivel * 1.5)
    _salud_actual = _atributos["vitalidad"] * 10
    _mana_actual = _atributos["magia"] * 10
    print("¡Subiste al nivel ", _nivel, "!")

func ganar_exp(cantidad: int) -> void:
    _exp_actual += cantidad
    if _exp_actual >= _exp_proximo_nivel:
        _exp_actual -= _exp_proximo_nivel
        subir_nivel()

func clase_guerrero() -> void:
    _atributos["fuerza"] = 14
    _atributos["vitalidad"] = 12
    _atributos["destreza"] = 12

func muerte() -> void:
    print("¡El personaje ha muerto!")

func _aplicar_gravedad(delnta:float) -> void:
    if not is_on_floor():
        velocity.y -=gravedad *delnta
    else:
        velocity.y=0






    
	
		
	