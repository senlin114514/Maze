extends StaticBody2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	disable_btn()
	add_to_group("wall")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	

func disable_btn() -> void:
	$Button.visible = false
	$Button.disabled = true

func enable_btn() -> void:
	$Button.visible = true
	$Button.disabled = false
	

func clear() -> void:
	queue_free()

func _on_button_pressed() -> void:
	print(self,"被点击")
	get_tree().call_group("maze_global","alreadychecked")
	queue_free()
	pass # Replace with function body.
