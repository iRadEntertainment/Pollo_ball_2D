#=======================#
#      player.gd        #
#=======================#

extends KinematicBody2D


var actual_player = false
export var team_color = Color.lemonchiffon setget _team_color_changed

var sprite_height_offset = -Vector2(20,30)
var height = 0

#movement
var vec_mov = Vector2()
const MAX_SPEED    = 80
var trust          = 25
var trust_lateral  = 15
var rotation_speed = 2.5
var dive_speed     = 3

var air_friction     = 0.985
var ground_friction  = 0.93
var bounce_multiplier = 0.6

var trust_vector = Vector2()

#weapons
onready var laser_preload = preload("res://instances/laser_shot.tscn")
var firing = false
var laser_cooldown = 0.15
var firing_time_left = 0


func _ready():
	$sprites/colors/blur.color = team_color

func _process(d):
	# shadow process
	if not Input.is_action_pressed("game_dive_down") \
	and not Input.is_action_pressed("game_dive_up"):
		if height < 1:
			height += d*dive_speed
		if height > 1:
			height -= d*dive_speed
#		if stepify(height,0.01) == 1.00:
#			height = 1
	height = clamp(height,0,2)
	$sprites.global_position = global_position + sprite_height_offset*height/2
	$shadow.global_position  = global_position - sprite_height_offset*height/2
	
	#---- input
	if actual_player:
		if Input.is_action_pressed("ui_up"):
			trust_vector = Vector2(trust,0).rotated(rotation)
		if Input.is_action_pressed("ui_down"):
			trust_vector += -Vector2(trust,0).rotated(rotation)/2
			
		if Input.is_action_pressed("game_fire"):		fire_laser()
		if Input.is_action_pressed("ui_left"):			rotation -= rotation_speed*d
		if Input.is_action_pressed("ui_right"):			rotation += rotation_speed*d
		if Input.is_action_pressed("game_dive_up"):		height += dive_speed*d
		if Input.is_action_pressed("game_dive_down"):	height -= dive_speed*d
		
		if Input.is_action_pressed("game_slide_left"):
			trust_vector += Vector2(0, -trust_lateral).rotated(rotation)
		if Input.is_action_pressed("game_slide_right"):
			trust_vector += Vector2(0,  trust_lateral).rotated(rotation)
	
	#---- movement
	# dampen the movement adding friction
	vec_mov *= air_friction
	if height < 0.05:
		vec_mov *= ground_friction
	
	vec_mov += trust_vector*d
	vec_mov = vec_mov.clamped(MAX_SPEED)
	var collision = move_and_collide(vec_mov)
	trust_vector = Vector2()
	
	#---- collision
	if collision:
		vec_mov = vec_mov.bounce(collision.normal)*bounce_multiplier
		vec_mov += collision.collider_velocity*d
	
	#---- fire cooldown
	if firing_time_left <= 0:
		firing = false
	if firing_time_left > 0:
		firing_time_left -= d
	
	#---- particle emitters
	if actual_player:
		$sprites/burner.emitting       = Input.is_action_pressed("ui_up")
		$sprites/burner_light.enabled  = Input.is_action_pressed("ui_up")
		$sprites/burner_left.emitting  = Input.is_action_pressed("game_slide_left")
		$sprites/burner_right.emitting = Input.is_action_pressed("game_slide_right")
	
	# sparkles when touching the ground
	var scratching_groud = height < 0.1 and vec_mov.length()>1
	$sprites/sparkles_left.emitting  = scratching_groud
	$sprites/sparkles_right.emitting = scratching_groud
	if scratching_groud:
		if not $sfx_scratch.playing:
			$sfx_scratch.play()
	else:
		$sfx_scratch.stop()
	

var firing_laser_sx = true
func fire_laser():
	#check if is already firing
	if firing: return
	
	firing = true
	firing_time_left = laser_cooldown
	
	var laser = laser_preload.instance()
	laser.player_owner = self
	laser.col = team_color
	laser.spacecraft_velocity = vec_mov
	laser.laser_speed = 50
	laser.scale = Vector2(0.5,0.5)
	laser.height = height
	
	if firing_laser_sx:
		firing_laser_sx = false
		laser.global_position = $sprites/las1_pos.global_position
	else:
		firing_laser_sx = true
		laser.global_position = $sprites/las2_pos.global_position
	laser.global_rotation = $sprites/las1_pos.global_rotation
	get_parent().add_child(laser)


func get_hit_by_laser(laser_velocity):
	vec_mov += laser_velocity*2
	

#---------------------- setter/getter -------------------------
func _team_color_changed(col):
	team_color = col
	$sprites/colors/blur.color = team_color
