#===============#
#     ik.gd     #
#===============#

extends Node

var nodes_arr  = []
var points_arr = []
var bones_arr  = []
var ang_offset = []
var ang_constr = []

var start : Vector2
var start_point_given : Vector2

var target_treshold = 0.1
var fl_contact      = false


func set_nodes(array, constraint_array = []):
	nodes_arr = array
	
	if constraint_array:
		ang_constr = constraint_array
	
	#calculate points and lenghts
	start = start_point_given if start_point_given else nodes_arr[0].global_position
	
	if array[0] is Vector2:
		points_arr = array.duplicate()
	else:
		for node in nodes_arr:
			points_arr.append(node.global_position)
	
	for i in range (points_arr.size()-1):
		bones_arr.append(points_arr[i+1] - points_arr[i])
		ang_offset.append( bones_arr[i].angle_to(Vector2(1,0)) )



func reach_target(goal, apply_transf := true): # PROCESSED
	# check if goal is reached
	if   ( points_arr[points_arr.size()-1] - goal ).length() < target_treshold:
		if !fl_contact: fl_contact = true
	elif ( points_arr[points_arr.size()-1] - goal ).length() < target_treshold/10:
		return points_arr
	else:
		if fl_contact: fl_contact = false
	
	# follow starting point in process
	start = start_point_given if start_point_given else nodes_arr[0].global_position
	
	
	# apply shift
	var shift = start - points_arr[0]
	var shifted_arr = []
	for p in points_arr:
		shifted_arr.append(p+shift)
	
	# backward
	var sh_size = shifted_arr.size()
	shifted_arr[sh_size-1] = goal
	for i in range (1,sh_size):
		var id = sh_size-1-i
		
		var direct_back = ( shifted_arr[id] - shifted_arr[id+1] ).normalized() * bones_arr[id].length()
		shifted_arr[id] = shifted_arr[id+1] + direct_back
	
	# forward
	shifted_arr[0] = start
	for i in range (1,sh_size):
		var direct_forw = ( shifted_arr[i] - shifted_arr[i-1] ).normalized() * bones_arr[i-1].length()
		shifted_arr[i] = shifted_arr[i-1] + direct_forw
	
	points_arr = shifted_arr
	
	
	# Nodes transformations
	if apply_transf:
		for i in range (nodes_arr.size()):
			# apply translation to nodes
			nodes_arr[i].global_position = points_arr[i]
			
			# apply rotation to nodes
			if i <= nodes_arr.size() - 2:
				var dir = points_arr[i+1] - points_arr[i]
				var rot = Vector2(1,0).angle_to( dir ) + ang_offset[i]
				nodes_arr[i].global_rotation = rot
	
	return points_arr
