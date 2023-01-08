extends KinematicBody2D
class_name Player

const MAX_SPEED := 160
const ACCELERATION := 20

onready var anim := $Anim
onready var hammer := $Hammer
onready var hammerHitbox := $HammerHitbox
onready var start_hammer_pos : Vector2
var hammer_locked_pos := Vector2.ZERO
var move_direction := Vector2.ZERO
var velocity := Vector2.ZERO
var hammer_pos_radius := Vector2(16.0, 8.0)

func _ready():
	hammer.connect("hit", self, "_on_hit")

func _on_hit():
	for area in hammerHitbox.get_overlapping_areas():
		var slime = area.get_parent()
		if slime is Slime:
			slime.do_squish()

func _input(event):
	if event.is_action_pressed("game_swing") and hammer.visible:
		hammer_locked_pos = hammer.position
		hammer.play_swing()
	if event.is_action_pressed("game_action"):
		if $Pocket.get_child_count() == 0:
			for area in $PickingHitbox.get_overlapping_areas():
				if area is Pickable:
					var obj = area
					if obj.is_pickable():
						obj.pick_by($Pocket)
						obj.position = Vector2.ZERO
						hammer.visible = false
						hammerHitbox.visible = false
						break
	if event.is_action_released("game_action"):
		if $Pocket.get_child_count() > 0:
			var obj = $Pocket.get_child(0)
			obj.drop_on(get_parent())
			if obj is SlimeJar:
				obj.reset_angle_level_with_animation()
			obj.position = position
			hammer.visible = true
			hammerHitbox.visible = true

func _process(_delta):
	var viewing_angle = _get_viewing_angle()
	hammerHitbox.global_position = global_position + hammer.hammer_elipse_vec * 4.0
	
	if $Pocket.get_child_count() > 0:
		var jar = $Pocket.get_child(0)
		if jar is SlimeJar:
			var target_angle_level = -velocity.x / MAX_SPEED
			var next_angle_level = lerp(jar.angle_level, target_angle_level, 0.08)
			jar.change_angle_level(next_angle_level)

func _physics_process(delta):
	move_direction = Input.get_vector("game_left", "game_right", "game_up", "game_down")
	
	var hammer_factor := 0.4 if hammer.is_swinging() else 1.0
	
	velocity = Vector2(
		lerp(velocity.x, move_direction.x * MAX_SPEED * hammer_factor, ACCELERATION * delta),
		lerp(velocity.y, move_direction.y * MAX_SPEED * hammer_factor, ACCELERATION * delta)
	)
	
	_update_animations()
	
	var new_velocity = move_and_slide(velocity, Vector2.ZERO, false, 4, 0.785398, false)
	
	for i in range(get_slide_count()):
		var obj = get_slide_collision(i).collider
		if obj is Slime:
			var push_force_factor = lerp(1.0, 0.2, obj.proper_scale * obj.proper_scale)
			obj.linear_velocity = velocity.normalized() * MAX_SPEED * push_force_factor
	
	velocity = new_velocity

func _update_animations():
	if _is_moving():
		if anim.current_animation != "Walk":
			anim.play("Walk", 0.1, 2.0)
	else:
		if anim.current_animation != "Idle":
			anim.play("Idle")

func _get_distance_to_mouse():
	var diff = get_viewport().get_mouse_position() - get_transform().get_origin()
	return sqrt(pow(diff.x, 2.0) + pow(diff.y, 2.0))

func _get_viewing_angle():
	var diff = get_viewport().get_mouse_position() - get_transform().get_origin()
	return atan2(diff.y, diff.x)

func _is_moving():
	return move_direction != Vector2.ZERO