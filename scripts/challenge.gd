extends Node
class_name Challenge

@export var index : int
@export var state : Button
@export var color : ColorPickerButton
@export var text : LineEdit
@export var value : LineEdit

@onready var main = $"../../../.."

func _ready():
	index = int(name.replace("Challenge", ""))

func event():
	main.on_challenge_select(index)

func event_value(_v):
	main.on_challenge_select(index)
