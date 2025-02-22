extends Node

@export var overlay : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func test() -> void:
	print("Dialog script is running")
	
	
func dialog_OK(title : String, subtitle : String) -> void:
	var dialog = preload("res://Scenes/Dialog_OKBTN.tscn").instantiate()
	dialog.test()
	dialog.init(title,subtitle)
	dialog.z_index = 1
	add_child(dialog)
	
func OK_BTN_reback() -> void:
	print("OK")
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
