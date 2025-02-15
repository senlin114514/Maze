extends Node2D

@export var wall : PackedScene
@export var AirBlock : PackedScene
@export var startx = -250;
@export var starty = -250;
@export var n = 3;

#@onready var cplabel = $"../CheckPointIDLable"

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
var f = range(n * n + 10)
var smallest_tree = []

var temp_maze = [];
		
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
	
	print(hu," ",lu," ",hv," ",lv);
	
	if u + 1 == v:
		print("break:",hu,",",lu + 1);
		temp_maze[hu][lu + 1] = 0;
		#print(111);
	else:
		print("break:",hu + 1,",",lu);
		temp_maze[hu + 1][lu] = 0;

func get_maze() -> void:
	var temp_string = "关卡: %s" % n
	#cplabel.text = temp_string
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
	#print(temp_maze)
	temp_maze[1][0] = 0
	temp_maze[2 * n - 1][2 * n] = 0
	#print(temp_maze);
	#for i in temp_maze:
	#	print(i)
	#breakblock(1,2);
	#breakblock(1,4);
	for i in smallest_tree:
		print(i.u," ",i.v," ",i.w)
		breakblock(i.u,i.v);
		#print(i.u," ",i.v," ",i.w)
	#print(temp_maze[11][11])
	#print(temp_maze[3])
	for i in temp_maze:
		for j in i:
			if j == 1:
				maze += "1";
			else:
				maze += "0";
		maze += "n"
	#print(temp_maze)
func _ready() -> void:
	#randomize()  # 初始化随机数种子
	#generate_maze()
	#print_maze()
	#randomize()
	#get_maze()
	#return;
	#$"../AnimationPlayer".play("apper")
	#await $"../AnimationPlayer".animation_finished
	maze = "1111111n1000101n1110101n1000001n1111101n1000000n1111111"
	var pos = Vector2(startx,starty)
	#wall.position = Vector2(100,100);
	var size = 500 / (2 * n + 1.0);
	var sc = size / 50.0
	print(size);
	print(size * (2.0 * n + 1))
	print(sc);
	var h = 1
	var l = 1#行列
	#$ball.position = Vector2(150,150)
	get_node("../ball").position = Vector2(100 + 1.5 * size,150 + size)
	get_node("../ball").scale = Vector2(1 / sc,1 / sc)
	#$ball.position = Vector2(150,150);
	
	var dif = 0.25
	if n == 3:
		dif = 0.4
	elif n > 7:
		dif = 0.1
	
	get_node("../ball/ball").scale = Vector2(sc - dif,sc - dif);
	get_node("../ball/shape").scale = Vector2(sc - dif,sc - dif);
	
	var ab = AirBlock.instantiate()
	ab.position = pos
	self.add_child(ab)
	
	for i in maze:
		#print(i)
		if i == "1":
			pos = Vector2(startx + size * l,starty + size * h)
			#print(pos)
			var wall = wall.instantiate()
			wall.add_to_group("maze")
			wall.scale = Vector2(sc,sc);
			wall.position = pos
			self.add_child(wall)
		elif i == "n":
			#pos += Vector2(0,50)
			l = 0;
			h += 1;
		elif i == "0":
			pass
		l += 1;
	pass # Replace with function body.

func print_maze():
	for row in maze:
		var line = ""
		for cell in row:
			line += str(cell) + " "
		print(line)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	#$Maze_wall_group.rotation += 0.1;
	if iswin:
		return
	if not $"../Overlay".isok:
		return
	if Input.is_action_pressed("left"):
		self.rotation += 0.01;
	if Input.is_action_pressed("right"):
		self.rotation -= 0.01;
	pass

func _on_judgeissuccess_body_entered(body: Node2D) -> void:
	if body.is_in_group("ball"):
		#print(body)
		#get_node("../star").visible = true;
		iswin = true;
		$"../NextBtn".disabled = false
		$"../NextBtn".visible = true
		await get_tree().create_timer(1).timeout 
		$"../Overlay".visible = true
		$"../DisplayContinueInfo".play("apppear")
		print("YOU WIN")
	pass # Replace w
#place with function body.


func _on_next_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/background.tscn")
	pass # Replace with function body.
