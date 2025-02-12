extends Control

@onready var NewGameBTN : Button = $Panel/NewGame

func changealpha():
	while (true):
		for i : float in range(1):
			pass
			
func load_player_data(file_path):
	if FileAccess.file_exists(file_path):
		var data_file = (FileAccess.open(file_path,FileAccess.READ)).get_as_text()
		#print(data_file)
		var res = JSON.parse_string(data_file)
		if res is Dictionary:
			return res
		else:
			return;
@onready var save = load_player_data("user://Saves/save.json")
var isnew
@onready var config = load_player_data("user://Saves/config.json")
var DebugModeStatus

var save_template = {"default": true,"playername":"Anonymous", "level": 0, "rotation": 0, "position": { "x": 0, "y": 0 }, "time":0}
var maze_template = {"size":0,"maze":"empty"}
var config_template = {"debug_mode":false}

func save_to_file(content):
	var file = FileAccess.open("user://Saves/config.json", FileAccess.WRITE)
	file.store_string(content)
	
func write_file(content,path):
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(content)

func CheckSaveFiles() -> void:
	# 指定存储目录路径
	var save_path = "user://Saves"
	
	# 检查目录是否存在，如果不存在则创建
	if not DirAccess.dir_exists_absolute(save_path):
		print("文件夹不存在，正在创建...")
		var dir = DirAccess.open("user://")
		if dir and dir.make_dir("Saves") == OK:
			print("文件夹创建成功")
		else:
			print("文件夹创建失败")

	# 依次检查并创建文件
	_check_and_create_file("user://Saves/config.json", config_template)
	_check_and_create_file("user://Saves/maze.json", maze_template)
	_check_and_create_file("user://Saves/save.json", save_template)

func CheckSaveFileInvid() -> bool:
	if not save.level or not save.default or not save.rotation or not save.position or not save.time:
		print("存档文件被修改")
		return false
	return true


func _check_and_create_file(file_path: String, default_content) -> void:
	if not FileAccess.file_exists(file_path):
		print(file_path + " 不存在，正在创建...")
		var file = FileAccess.open(file_path, FileAccess.WRITE)
		if file:
			file.store_string(str(default_content))
			print(file_path + " 创建成功")
		else:
			print(file_path + " 创建失败")
	
func CheckSaveFiles2() -> void:
	var dir = DirAccess.open("user://Saves")
	if not dir:
		print("文件夹不存在")
		dir.make_dir("Saves")
	var file1 = FileAccess.open("user://Saves/config.json",FileAccess.READ)
	if not file1:
		print("config不存在")
		var file11 = FileAccess.open("user://Saves/config.json",FileAccess.WRITE)
		file11.store_string(str(config_template))
	var file2 = FileAccess.open("user://Saves/maze.json",FileAccess.READ)
	if not file2:
		print("maze不存在")
		var file22 = FileAccess.open("user://Saves/maze.json",FileAccess.WRITE)
		file22.store_string(str(maze_template))
	var file3 = FileAccess.open("user://Saves/save.json",FileAccess.READ)
	if not file3:
		print("save不存在")
		var file33 = FileAccess.open("user://Saves/save.json",FileAccess.WRITE)
		file33.store_string(str(save_template))

func file_exists(file_path: String) -> bool:
	return FileAccess.file_exists(file_path)

func _ready() -> void:
	if (!file_exists("user://Saves/config.json")):
		DebugModeStatus = false
	else:
		DebugModeStatus = config.debug_mode
	if (!file_exists("user://Saves/save.json")):
		isnew = true
	else:
		isnew = save.default
	CheckSaveFiles()
	#if not CheckSaveFileInvid():
	#	clean_user_data()
		#get_tree().change_scene_to_file("res://Scenes/titlescreen.tscn")
	if isnew:
		$rotation.visible = false
	print("Debug模式:",DebugModeStatus)
	if DebugModeStatus:
		$DialogWindow/DebugModeBtn.button_pressed = true
	pass


func _on_new_game_pressed() -> void:
	print("是否是新玩家?:",isnew);
	if isnew:
		print("开始播放动画")
		$"渐渐变黑".play("Transfortoblack")
		await $"渐渐变黑".animation_finished
		print("ok,动画播放完毕")
		get_tree().change_scene_to_file("res://Scenes/Story.tscn")
	else: 
		print("开始播放动画")
		$"渐渐变黑".play("Transfortoblack")
		await $"渐渐变黑".animation_finished
		print("ok,动画播放完毕")
		get_tree().change_scene_to_file("res://Scenes/background.tscn")
	pass # Replace with function body.


func _on_exit_btn_pressed() -> void:
	get_tree().quit() # 关闭游戏
	pass # Replace with function body.


func _on_debug_mode_btn_toggled(toggled_on: bool) -> void:
	DebugModeStatus = $DialogWindow/DebugModeBtn.button_pressed
	config.debug_mode = DebugModeStatus
	save_to_file(str(config))
	print("已将debug状态调为:",DebugModeStatus)
	pass # Replace with function body.


func _on_ok_pressed() -> void:
	print("关闭设置")
	$DialogWindow.visible = false
	$DialogWindow/OK.disabled = true
	$DialogWindow/DebugModeBtn.disabled = true
	$DialogWindow/OK2.disabled = true
	$DialogWindow/DebugModeBtn.disabled = true
	pass # Replace with function body.


func _on_open_setthings_pressed() -> void:
	print("开启设置")
	$DialogWindow.visible = true
	$DialogWindow/DebugModeBtn.disabled = false
	$DialogWindow/OK.disabled = false
	$DialogWindow/OK2.disabled = false
	$DialogWindow/DebugModeBtn.disabled = false
	pass # Replace with function body.
	
func open_warn_dialog() -> void:
	$DialogWindow2/OK3.disabled = false
	$DialogWindow2/Cancel3.disabled = false
	$DialogWindow2.visible = true

func close_warn_dialog() -> void:
	$DialogWindow2/OK3.disabled = true
	$DialogWindow2/Cancel3.disabled = true
	$DialogWindow2.visible = false
	
func clean_user_data() -> void:
	write_file(str(save_template),"user://Saves/save.json")
	write_file(str(maze_template),"user://Saves/maze.json")
	print("ok,cleared")

func _on_ok_2_pressed() -> void:
	open_warn_dialog()
	print("弹出警告框")
	pass # Replace with function body.


func _on_ok_3_pressed() -> void:
	close_warn_dialog()
	print("用户确定要清空")
	clean_user_data()
	get_tree().change_scene_to_file("res://Scenes/titlescreen.tscn")
	pass # Replace with function body.


func _on_cancel_3_pressed() -> void:
	print("用户放弃清空")
	close_warn_dialog()
	pass # Replace with function body.
