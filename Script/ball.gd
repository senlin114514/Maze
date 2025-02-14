extends RigidBody2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	return
	var collision = move_and_collide(Vector2(0,0))
	if collision:
		print("I collided with ", collision.get_collider().name)
	pass

func _physics_process(delta: float) -> void:
	return;
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
