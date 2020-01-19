#=======================#
#        menu.gd        #
#=======================#

extends Control

# version control
var version = "0.1"
var last_update = "17/01/2020"

# start game
var selected_arena = ""

func _ready():
	#--- version control
	#--- version control
	$version.text = "ver %s"%[version]
	
	#--- initialize audio
	audio_server.play_menu_audio_background()
	for button in $box_main/cnt_title2/btn_cont.get_children():
		if button is Button:
			button.connect("mouse_entered",audio_server,"play_hover_button")
			button.connect("pressed",audio_server,"play_press_button")


func start_new_game():
	if selected_arena:
#		get_tree().change_scene(selected_arena)
		print(selected_arena)
		audio_server.stop_all_menu_audio()
	else:
		print("Please select an arena")
