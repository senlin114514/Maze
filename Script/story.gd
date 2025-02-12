extends Control

var IsCanContiue : bool = false

func _ready() -> void:
	await get_tree().create_timer(1.5).timeout 
	$TextContorler.play("TextControl")
	await $TextContorler.animation_finished
	print("ok,动画播放完毕")
	IsCanContiue = true


func _on_over_lay_button_pressed() -> void:
	if not IsCanContiue:
		print("Please wait")
		return;
	get_tree().change_scene_to_file("res://Scenes/GreenHandGuide.tscn")
	pass # Replace with function body.
