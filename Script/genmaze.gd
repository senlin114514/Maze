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

@onready var cplabel = $"../Control/CheckPointIDLable"

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
	$"../ball".gravity_scale = 0
	#print($"../ball".position)
	if current_time <= 60: $"../Control/TimeDisplayer".text = str(current_time)
	else: $"../Control/TimeDisplayer".text = str(snapped(current_time,0.1))
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
	#旋转中心
	print("迷宫大小(像素)",float(125.0 * 2 * n + 1));
	var targetx = 0
	var targety = 0
	var M = Vector2(float(targetx) + (250 * 1.0 * n + 125 * 1.0)/2.0,targety+(250 * 1.0 * n + 125) / 2.0)
	print("旋转中心:",M);
	self.position = M
	startx = targetx - M.x
	starty = targety - M.y
	var screen_sacle : float = float(700.0) / (2 * float(targetx) + 250 * n + 125) - 0.04
	print("缩放:",screen_sacle)
	print("缩放后的屏幕大小:",800.0 / screen_sacle,",",700.0 / screen_sacle)
	$"../Camera2D".zoom = Vector2(screen_sacle,screen_sacle)
	var bottomy = 700.0 / screen_sacle
	print("底部y坐标:",bottomy)
	$"../judgeissuccess".position.y = bottomy
	#{"size" : "0","maze" : "empty"}
	print("相对于旋转中心,将从",startx,",",starty,"绘制")
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
	var size = 125;
	var sc = size / 50.0
	var h = 1
	var l = 1#行列
	var dif = 0.8
	get_node("../ball/ball").scale = Vector2(float(125.0 / 50 - dif),float(125.0 / 50 - dif))
	get_node("../ball/shape").scale = Vector2(float(125.0 / 50 - dif),float(125.0 / 50 - dif))
	get_node("../ball").position = Vector2(targetx / screen_sacle + 125,targety / screen_sacle)
	$"../ball".mass = 10 + (float(1 / screen_sacle) * 8)
	
	if not int(save.position.x) == 0 or not int(save.position.y) == 0:
		print("读取存档中的小球位置:",save.position.x,",",save.position.y)
		get_node("../ball").position = Vector2(save.position.x,save.position.y)
	if not save.rotation == 0:
		print("读取存档中的迷宫旋转")
		self.rotation += save.rotation
	
	var color = get_color(level)
	print("墙的颜色:",color)
	$"../ball".position = Vector2(startx + size * 2,starty + size * 2)
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
	print("重新布局UI")
	$"../Control".scale = Vector2(1.0 / screen_sacle,1.0 / screen_sacle) 
	var deltax = 700.0 / screen_sacle - float(125.0 * 2 * n + 1);
	print("距离边界:",deltax)
	self.position.x += float(deltax) / 2.0
	self.position.y += 50 / screen_sacle
	await $"../WinAnimationPlayer".animation_finished

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
		$"../Control/DialogWindow3".visible = true
		$"../Control/DialogWindow3/OK3".disabled = false
		$"../Control/DialogWindow3/Cancel3".disabled = false
		$"../Clock".paused = true
		print("暂停游戏")
	else:
		get_tree().paused = false
		ispasued = false
		$"../Control/DialogWindow3".visible = false
		$"../Control/DialogWindow3/OK3".disabled = true
		$"../Control/DialogWindow3/Cancel3".disabled = true
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
	if current_time <= 60: $"../Control/TimeDisplayer".text = str(current_time)
	else: $"../Control/TimeDisplayer".text = str(snapped(current_time,0.1))
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
			_on_judgeissuccess_body_entered($"../ball")
			ispasued = true
	pass

func _on_judgeissuccess_body_entered(body: Node2D) -> void:
	if body.is_in_group("ball"):
		#get_node("../star").visible = true;
		$"../Control/Reload".disabled = true
		$"../Clock".paused = true
		await get_tree().create_timer(1.5).timeout 
		iswin = true;
		$"../Control/Reload".visible = false
		$"../NextBtn".disabled = false
		$"../NextBtn".visible = true
		$"../Control/SaveGame".disabled = true
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
		var temp_string = "用时:" + str($"../Control/TimeDisplayer".text) + "s"
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
	$"../Control/DialogWindow".visible = true
	$"../Control/DialogWindow/OK".disabled = false
	$"../Control/DialogWindow/Cancel".disabled = false
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
	$"../Control/DialogWindow".visible = false
	$"../Control/DialogWindow/OK".disabled = true
	$"../Control/DialogWindow/Cancel".disabled = true
	pass # Replace with function body.

func save_current_game() -> void:
	print("保存游戏!")
	print("迷宫旋转:",save.rotation)
	save.position.x = $"../ball".position.x
	save.position.y = $"../ball".position.y
	save.time = float($"../Control/TimeDisplayer".text)
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
	$"../Control/DialogWindow2".visible = false
	$"../Control/DialogWindow2/OK2".disabled = true
	$"../Control/DialogWindow2/Cancel2".disabled = true
	pass # Replace with function body.


func _on_ok_3_pressed() -> void:
	pausedgame()
	pass # Replace with function body.


func _on_cancel_3_pressed() -> void:
	print("弹出对话框")
	$"../Control/DialogWindow3".visible = false
	$"../Control/DialogWindow3/OK3".disabled = true
	$"../Control/DialogWindow3/Cancel3".disabled = true
	$"../Control/DialogWindow2".visible = true
	$"../Control/DialogWindow2/OK2".disabled = false
	$"../Control/DialogWindow2/Cancel2".disabled = false
	pass # Replace with function body.
