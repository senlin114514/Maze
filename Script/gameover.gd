extends Control

var save_template = {"default": true,"playername":"Anonymous", "level": 0, "rotation": 0, "position": { "x": 0, "y": 0 } }
var maze_template = {"size":0,"maze":"empty"}

func write_file(content,path):
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(content)

func clean_user_data() -> void:
	write_file(str(save_template),"user://Saves/save.json")
	write_file(str(maze_template),"user://Saves/maze.json")

func _on_ok_pressed() -> void:
	clean_user_data()
	get_tree().change_scene_to_file("res://Scenes/titlescreen.tscn")
	pass # Replace with function body.


func _on_ok_2_pressed() -> void:
	clean_user_data()
	get_tree().quit()
	pass # Replace with function body.
