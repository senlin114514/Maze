extends Node2D

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
func read_maze():
	var file = FileAccess.open("user://Saves/maze.json", FileAccess.READ)
	var content = file.get_as_text()
	return content
func save_maze(content):
	var file = FileAccess.open("user://Saves/maze.json", FileAccess.WRITE)
	file.store_string(content)
#3 + 2 * (level // 3)		
@onready var save = load_player_data("user://Saves/save.json")
@onready var level = save.level

@export var greenwall : PackedScene
@export var bluewall : PackedScene
@export var goldwall : PackedScene
@export var redwall : PackedScene
@export var purplewall : PackedScene
@export var AirBlock : PackedScene
@export var startx = -250;
@export var starty = -250;
var n = 3

@onready var cplabel = $"../CheckPointIDLable"

var iswin = false

# Called when the node enters the scene tree for the first time.

var maze = "";

class edges:
	var u
	var v
	var w
	
	func _init(u, v, w):
		self.u = u
		self.v = v
		self.w = w
		
var edge = []
var f = range(25 * 25 + 10)
var smallest_tree = []

var temp_maze = [];

var r
		
func find(x : int) -> int:
	if (f[x] == x): return x;
	f[x] = find(f[x]);
	return f[x];

func add(u : int, v : int) -> void:
	var x = find(u);var y = find(v);
	f[y] = x;
	return;
	
var cnt : int = 1;

func get_real_posx(id : int) -> int:
	var h : int = ((id - 1) / n + 1) * 2;
	return h;

func get_real_posy(id : int) -> int:
	var l : int = ((id - 1) % n + 1) * 2;
	return l;

func breakblock(u : int,v : int) -> void:
	if u > v:
		var t = v;
		v = u;
		u = t
	var hu : int = ((u - 1) / n + 1) * 2;
	var lu : int = ((u - 1) % n + 1) * 2;
	
	hu -= 1
	lu -=1
	
	var hv : int = ((v - 1) / n + 1) * 2;
	var lv : int = ((v - 1) % n + 1) * 2;
	
	hv -= 1
	lv -= 1
	
	#print(hu," ",lu," ",hv," ",lv);
	
	if u + 1 == v:
		#print("break:",hu,",",lu + 1);
		temp_maze[hu][lu + 1] = 0;
		#print(111);
	else:
		#print("break:",hu + 1,",",lu);
		temp_maze[hu + 1][lu] = 0;

func get_maze() -> void:
	for i in range(n * n - 1):
		if i == 0:
			continue;
		if i % n == 0:
			edge.append(edges.new(i,i + n,randi()))
		elif i > (n - 1) * n:
			edge.append(edges.new(i,i + 1,randi()))
		else:
			edge.append(edges.new(i,i + n,randi()))
			edge.append(edges.new(i,i + 1,randi()))
		pass
	pass
	edge.sort_custom(func(x : edges,y : edges):
		return x.w < y.w
		)
	for i in edge:
		var u = i.u;
		var v = i.v;
		var w = i.w;
		if not find(u) == find(v):
			cnt += 1;
			add(u,v);
			smallest_tree.append(edges.new(u,v,0));
			if cnt == (n * n):
				break;
	var t1 = []
	for i in range(2 * n + 1):
		t1.append(1)
	#print(t1)
	var t2 = []
	for i in range(2 * n + 1):
		if (i + 1) % 2 == 1: t2.append(1);
		else: t2.append(0);
	#print(t2)
	for i in range(2 * n + 1):
		if (i + 1) % 2 == 1:
			#t1.duplicate(true);
			var t = t1.duplicate(true)
			temp_maze.append(t);
		else:
			#t2.duplicate(true);
			var t = t2.duplicate(true)
			temp_maze.append(t);
	temp_maze[2 * n - 1][2 * n] = 0
	for i in smallest_tree:
		breakblock(i.u,i.v);
	for i in temp_maze:
		for j in i:
			if j == 1:
				maze += "1";
			else:
				maze += "0";
		maze += "n"
	r.maze = maze
	r.size = n
	print("保存文件:",r)
	save_maze(str(r))

var threshold = 18
var power = 2

@onready var config = load_player_data("user://Saves/config.json")
@onready var DebugModeStatus = config.debug_mode

func calculate_n(level):
	n = 3 + 12 * (min(level, threshold) / threshold) ** power
	return int(n)

func get_color(level:int) -> int:
	if 1 <= level and level <= 6: return 1
	elif 7 <= level and level <= 12: return 2
	elif 13 <= level and level <= 18: return 3
	elif 19 <= level and level <= 24: return 4
	else: return 5
	
var nextpath = "res://Scenes/background.tscn"
	
func _ready() -> void:
	if current_time <= 60: $"../TimeDisplayer".text = str(current_time)
	else: $"../TimeDisplayer".text = str(snapped(current_time,0.1))
	ispasued = true
	print("关卡:",level)
	if level == 30:
		$"../NextGameReminder".text = "  完成"
		nextpath = "user://Scenes/end.tscn"
	n = calculate_n(level)
	print("难度系数:",n)
	var temp_string = str(int(level))
	cplabel.text = temp_string
	r = load_player_data("user://Saves/maze.json")
	randomize()
	#{"size" : "0","maze" : "empty"}
	if (r.maze == "empty"):
		print("未发现迷宫存档")
		get_maze()
	else: 
		maze = r.maze
		print("读取到迷宫:",maze)
		print("迷宫大小:",r.size,"需求大小:",n)
		if not int(r.size) == n:
			print("迷宫变化有误")
			r.maze = "empty"
			r.size = n
			get_maze()
		
	var pos = Vector2(startx,starty)
	var size = 500 / (2 * n + 1.0);
	var sc = size / 50.0
	var h = 1
	var l = 1#行列
	get_node("../ball").position = Vector2(100 + 1.5 * size,150 + size)
	var dif = 0.25
	if n == 3:
		dif = 0.4
	elif n > 7:
		dif = 0.15
	
	if n <= 5:
		$"../ball".gravity_scale = 2
	
	get_node("../ball/ball").scale = Vector2(sc - dif,sc - dif);
	get_node("../ball/shape").scale = Vector2(sc - dif,sc - dif);
	
	if not int(save.position.x) == 0 or not int(save.position.y) == 0:
		print("读取存档中的小球位置:",save.position.x,",",save.position.y)
		get_node("../ball").position = Vector2(save.position.x,save.position.y)
	if not save.rotation == 0:
		print("读取存档中的迷宫旋转")
		self.rotation += save.rotation
	
	var ab = AirBlock.instantiate()
	ab.position = pos
	self.add_child(ab)
	
	var color = get_color(level)
	print("墙的颜色:",color)
	
	for i in maze:
		if i == "1":
			pos = Vector2(startx + size * l,starty + size * h)
			var wall
			if color == 1:
				wall = greenwall.instantiate()
			elif color == 2:
				wall = bluewall.instantiate()
			elif color == 3:
				wall = goldwall.instantiate()
			elif color == 4:
				wall = redwall.instantiate()
			elif color == 5:
				wall = purplewall.instantiate()
			wall.add_to_group("maze")
			wall.scale = Vector2(sc,sc);
			wall.position = pos
			self.add_child(wall)
		elif i == "n":
			l = 0;
			h += 1;
		elif i == "0":
			pass
		l += 1;
		
	print("迷宫生成完成✅")
	await $"../WinAnimationPlayer".animation_finished
	ispasued = false

func print_maze():
	for row in maze:
		var line = ""
		for cell in row:
			line += str(cell) + " "
		print(line)

var ispasued = false;
var isFirstAction = false;

@onready var current_time : float = save.time;

func pausedgame():
	if ispasued == false: #暂停游戏
		get_tree().paused = true
		ispasued = true
		$"../DialogWindow3".visible = true
		$"../DialogWindow3/OK3".disabled = false
		$"../DialogWindow3/Cancel3".disabled = false
		$"../Clock".paused = true
		print("暂停游戏")
	else:
		get_tree().paused = false
		ispasued = false
		$"../DialogWindow3".visible = false
		$"../DialogWindow3/OK3".disabled = true
		$"../DialogWindow3/Cancel3".disabled = true
		$"../Clock".paused = false
		
		print("继续游戏")

var isalreadypassed : bool = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if Input.is_action_just_released("paused"):
		pausedgame()
	if ispasued:
		return;
	if iswin:
		return;
	if current_time <= 60: $"../TimeDisplayer".text = str(current_time)
	else: $"../TimeDisplayer".text = str(snapped(current_time,0.1))
	if Input.is_action_pressed("left"):
		if not isFirstAction:
			print("键盘操作,启动计时器")
			isFirstAction = true
			$"../Clock".start()
		self.rotation -= 0.015;
		save.rotation -= 0.015;
	if Input.is_action_pressed("right"):
		if not isFirstAction:
			print("键盘操作,启动计时器")
			isFirstAction = true
			$"../Clock".start()
		self.rotation += 0.015;
		save.rotation += 0.015;
	if DebugModeStatus:
		if Input.is_action_just_released("passed"):
			if ispasued:
				print("nonono")
				return
			$"../ball".gravity_scale = 0
			_on_judgeissuccess_body_entered($"../ball")
			ispasued = true
	pass

func _on_judgeissuccess_body_entered(body: Node2D) -> void:
	if body.is_in_group("ball"):
		#get_node("../star").visible = true;
		$"../Reload".disabled = true
		$"../Clock".paused = true
		await get_tree().create_timer(1.5).timeout 
		iswin = true;
		$"../Reload".visible = false
		$"../NextBtn".disabled = false
		$"../NextBtn".visible = true
		$"../SaveGame".disabled = true
		$"../Clock".paused = false
		$"../NextGameReminder".visible = true
		save.level += 1
		save.rotation = 0
		save.position.x = 0
		save.position.y = 0
		save.time = 0
		print("当前存档:",save)
		save_to_file(str(save))
		#清空地图
		r.maze = "empty"
		r.size = 0
		save_maze(str(r))
		$"../WinAnimationPlayer".play("win")
		await  $"../WinAnimationPlayer".animation_finished
		$"../WinAnimationPlayer".play("displaynewbtn")
		var temp_string = "用时:" + str($"../TimeDisplayer".text) + "s"
		$"../TimeUsedDisplayer".text = temp_string
		$"../TimeUsedDisplayer".visible = true
		print("YOU WIN")
	pass # Replace w
#place with function body.


func _on_next_btn_pressed() -> void:
	if isalreadypassed:
		return
	isalreadypassed = true
	print("下一关!")
	#if level == 12:
	#	print("半场")
	#	get_tree().change_scene_to_file("res://Scenes/HalfTime.tscn.tscn")
	#	pass
	if level == 30:
		get_tree().change_scene_to_file("res://Scenes/end.tscn")
		return
	$"../WinAnimationPlayer".play("end")
	await $"../WinAnimationPlayer".animation_finished
	get_tree().change_scene_to_file(nextpath)
	queue_free()
	pass # Replace with function body.


func _on_reload_pressed() -> void:
	print("弹出对话框")
	ispasued = true
	$"../DialogWindow".visible = true
	$"../DialogWindow/OK".disabled = false
	$"../DialogWindow/Cancel".disabled = false
	$"../Clock".paused = true
	pass # Replace with function body.

func _on_ok_pressed() -> void:
	print("重置迷宫")
	maze = ""
	save.position.x = 0
	save.position.y = 0
	save.rotation = 0.0
	save.time = 0
	r.maze = "empty"
	r.size = 0
	save_maze(str(r))
	save_to_file(str(save))
	$"../WinAnimationPlayer".play("end")
	await $"../WinAnimationPlayer".animation_finished
	get_tree().change_scene_to_file("res://Scenes/background.tscn")
	pass # Replace with function body.


func _on_cancel_pressed() -> void:
	ispasued = false
	$"../Clock".paused = false
	$"../Clock".start()
	$"../DialogWindow".visible = false
	$"../DialogWindow/OK".disabled = true
	$"../DialogWindow/Cancel".disabled = true
	pass # Replace with function body.

func save_current_game() -> void:
	print("保存游戏!")
	print("迷宫旋转:",save.rotation)
	save.position.x = $"../ball".position.x
	save.position.y = $"../ball".position.y
	save.time = float($"../TimeDisplayer".text)
	print("小球位置",save.position.x,",",save.position.y)
	print("当前时间:",save.time)
	save_to_file(str(save))

func _on_save_game_pressed() -> void:
	print("用户按下了保存游戏按钮")
	save_current_game()
	pass # Replace with function body.


func _on_timer_timeout() -> void:
	if iswin or ispasued:
		return;
	print("自动保存!")
	save_current_game()
	pass # Replace with function body.

func _on_clock_timeout() -> void:
	current_time += 0.01
	current_time = snapped(current_time,0.01)
	pass # Replace with function body.


func _on_exit_btn_pressed() -> void:
	print("弹出对话框")
	pausedgame()
	pass # Replace with function body.

func _on_ok_2_pressed() -> void:
	#save_current_game()
	pausedgame()
	get_tree().change_scene_to_file("res://Scenes/titlescreen.tscn")
	pass # Replace with function body.


func _on_cancel_2_pressed() -> void:
	pausedgame()
	$"../DialogWindow2".visible = false
	$"../DialogWindow2/OK2".disabled = true
	$"../DialogWindow2/Cancel2".disabled = true
	pass # Replace with function body.


func _on_ok_3_pressed() -> void:
	pausedgame()
	pass # Replace with function body.


func _on_cancel_3_pressed() -> void:
	print("弹出对话框")
	$"../DialogWindow3".visible = false
	$"../DialogWindow3/OK3".disabled = true
	$"../DialogWindow3/Cancel3".disabled = true
	$"../DialogWindow2".visible = true
	$"../DialogWindow2/OK2".disabled = false
	$"../DialogWindow2/Cancel2".disabled = false
	pass # Replace with function body.
