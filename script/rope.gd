extends Node2D

var player_ref : Object = null
var anchor     : Object = null
var hook       : Object = null


const rope_lenght = 6
onready var ik_script = preload("res://script/ik.gd").new()
var points : Array
var line_points  := []

func _ready():
	setup_rope()
	setup_ik()


func _process(delta):
	global_position = anchor.global_position
	ik_script.start_point_given = anchor.global_position
	
	points = ik_script.reach_target(hook.global_position)
	
	line_points = []
	for i in range(points.size()):
		line_points.append(points[i]-global_position)
	
	$line.points = line_points
	$line.global_rotation = 0
	update()

func setup_rope():
	#--- rigid body method
	for i in range(1,rope_lenght):
		var new_seg = $section1.duplicate()
		new_seg.position.x = 64*i
		add_child(new_seg)
	move_child($section_end_pos,rope_lenght+1)
#	move_child($line,rope_lenght+1)
	#--- line2D method
	for i in range(rope_lenght):
		pass

func setup_ik():
	#getting the parts in an arrays to pass to the ik function
	var sections = []
	for section in get_children():
		if "section" in section.name:
			sections.append(section)
		
	ik_script.set_nodes(sections)

#draw points
func _draw():
	
	for point in line_points:
		draw_circle(point, 5, Color.red)
	pass
