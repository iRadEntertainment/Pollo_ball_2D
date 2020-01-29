extends Node2D

var player_ref : Object = null
var anchor     : Object = null
var hook       : Object = null

const rope_lenght = 6
onready var ik_script = preload("res://script/ik.gd").new()

func _ready():
	setup_rope()
	setup_ik()


func _process(delta):
	global_position = anchor.global_position
	ik_script.reach_target(hook.global_position)

func setup_rope():
	for i in range(1,rope_lenght):
		var new_seg = $section1.duplicate()
		new_seg.position.x = 64*i
		add_child(new_seg)
	move_child($end_pos,rope_lenght)
	

func setup_ik():
	#getting the parts in an arrays to pass to the ik function
	var sections = []
	for section in get_children():
		sections.append(section)
	ik_script.set_nodes(sections)

