extends Node3D

class_name carcajAleatorio


var rangoAleatorio: int = randf_range(1, 10)

func _exit_tree():
    if Weapons.is_connected("flechas", Callable(self , "fechasAleatorias")):
        Weapons.disconnect("flechas", Callable(self , "fechasAleatorias")) # singleton para que solamente lo instancie una vez


func fechasAleatorias(crearFlechas: bool) -> void:
    if rangoAleatorio < 11 and rangoAleatorio > 0:
        print("mis flechas son:", rangoAleatorio)