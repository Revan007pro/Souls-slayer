extends Node3D

class_name events

var goblin_instance: Node3D
var spina_1: Marker3D = null
var boneControl: FABRIK3D


func setgoblinInstance(goblin: Node3D) -> void:
	#primero se creo creo un nodo inversive kinematic nodo llamado fabrik3d
	#se selecciona el nodo target que lo controla, en este caso un un nodo mark3d
	#desoues en settins se selecciona los huesos que se quiere controlar 
	#despues se controla por codigo su comportamiento en el scrip del player
	goblin_instance = goblin
	spina_1 = goblin.get_node("Skeleton3D/marcaPosicion") as Marker3D
	boneControl = goblin.get_node("Skeleton3D/boneControl") as FABRIK3D
