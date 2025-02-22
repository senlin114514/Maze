extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func test() -> void:
	print("OK dialog is already running")

func init(title: String,subtitle: String) -> void:
	print("Title:",title)
	$Background/Title.text = title
	$Background/Subtitle.text = subtitle

func clear() -> void:
	self.queue_free()

func _on_ok_pressed() -> void:
	Dialog.OK_BTN_reback()
	
	pass # Replace with function body.
