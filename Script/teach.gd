extends ColorRect

var isok = false;

func load_player_data(file_path):
	if FileAccess.file_exists(file_path):
		var data_file = (FileAccess.open(file_path,FileAccess.READ)).get_as_text()
		#print(data_file)
		var res = JSON.parse_string(data_file)
		if res is Dictionary:
			return res
		else:
			return;

func save_to_file(content):
	var file = FileAccess.open("user://Saves/save.json", FileAccess.WRITE)
	file.store_string(content)

@onready var save = load_player_data("user://Saves/save.json")
@onready var level : int = save.level
@onready var isnew : bool = save.default

func guide_rotation_maze_w():
	$"../Pressright".visible = true
	$"../Acontroler".play("Transfortoblack")
	await  $"../Acontroler".animation_finished
	$"../Acontroler".play("DisplayText1")
	await  $"../Acontroler".animation_finished
	$"../right".visible = true
	while (true):
		if Input.is_action_pressed("right"):
			break;
		await get_tree().create_timer(0.05).timeout
	print("ok,user pressed right")
	$"../right".visible = false
	for i in range(7):
		$"../Pressright".visible_characters -= 1;
		await get_tree().create_timer(0.03).timeout
	$"../Pressright".visible = false
	$"../Pressleft".visible = true
	await get_tree().create_timer(1).timeout
	$"../Acontroler".play("DisplayText2")
	await  $"../Acontroler".animation_finished
	$"../left".visible = true
	while (true):
		if Input.is_action_pressed("left"):
			break;
		await get_tree().create_timer(0.05).timeout
	print("ok,user pressed left")
	for i in range(7):
		$"../Pressleft".visible_characters -= 1;
		await get_tree().create_timer(0.03).timeout
	$"../left".visible = false
	self.visible = false
	$"../Reminder".visible = false
	print("新手教程完成")
	isok = true;
	save.default = false;
	save.level += 1;
	save.level = int(save.level)
	
	#str(save)
	print("目前的存档:",str(save));
	save_to_file(str(save))

func _ready() -> void:
	await get_tree().create_timer(0.1).timeout
	guide_rotation_maze_w()
	pass
