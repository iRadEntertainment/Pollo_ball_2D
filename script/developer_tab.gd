#=======================#
#   developer_tab.gd    #
#=======================#
extends Control


func _ready():
	hide()
	$vbox/tab_cont.current_tab = 0
#	$vbox/tab_cont.set_tab_disabled(3,true)
