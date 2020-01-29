#=======================#
#       AUTOLOAD        #
#    network CLIENT     #
#        ntw.gd         #
#=======================#
extends Node

#--- version control
var version = "0.1"
var last_update = "17/01/2020"

#--- network infos
var   host        = NetworkedMultiplayerENet.new()
const PORT        = 5020           # open port on the server
const ADDRESS     = "81.4.107.146" # IP server Godot Italia

signal network_status_changed

#--- timer reconnect
const CONNECTION_ATTEMPTS_STEPS = 5
const TMR_WAIT           = 2 #seconds
const TMR_WAIT_MAX       = 2 #seconds
var   reconnect_timer    = Timer.new()
var   connection_attempt = 0

#--- flags
var fl_connected_to_server = false
var established            = false setget _set_established, _get_established
var connecting             = false

#--- authentication
puppet var fl_auth_succeded = false setget _auth_updated
signal auth_updated
var net_id           = -1
var developer_name   = "" setget _set_developer_name

#--- server datas
# on connection succeded the server will update
# the following variables with a rset_id(this_peer_id,var)
puppet var existing_developers = [] setget _set_existing_developers
puppet var server_log          = [] setget _set_server_log

puppet var developers_info     = {} setget _set_developers_info
signal developers_info_updated
puppet var tasks               = {} setget _set_tasks
signal tasks_updated
puppet var announcements       = [] setget _set_announcements
signal announcements_updated

#--- active request to server
signal test_updated
puppet var test = "boh" setget _test_updated

signal ntw_content_updated
signal data_content_updated
signal dd_content_updated
signal server_log_updated
signal server_log_last_entry_updated



#===============================================================================
#==================================== INIT =====================================

func _ready():
	#connect network signals
	get_tree().multiplayer.connect("network_peer_packet",self,"_on_packets_received")
	get_tree().connect("connected_to_server",self,"_on_connection_succeeded")
	get_tree().connect("connection_failed",self,"_on_connection_failed")
	
	get_tree().connect("network_peer_connected", self, "_on_user_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_user_disconnected")
	get_tree().connect("server_disconnected", self, "_on_server_disconnected")
	#create timer for reconnetcion attempts
	set_timer_for_reconnect()
	add_child(reconnect_timer)
	reconnect_timer.connect("timeout",self,"_attempt_reconnection")
	#set server as network master
	set_network_master(1)
	connect_to_server()


#--------------------------- connection to server ------------------------------

func connect_to_server():
	var res = host.create_client(ADDRESS,PORT)
	
	if res != OK:
		print ("NETWORK: Impossible to create client")
		return
	else:
		if connection_attempt == 0:
			print ("NETWORK: connecting to server...")
		elif connection_attempt%5 == 1:
			print( "NETWORK: retrying... attempt n. %02d - wait time %ss"% [connection_attempt , reconnect_timer.wait_time] )
	
	
	get_tree().set_network_peer(null)
	get_tree().set_network_peer(host)
	
	#start timer for reconnection attempts
	connecting = true
	reconnect_timer.start()

func disconnect_from_server():
	get_tree().set_network_peer(null)
	host.close_connection()
	self.established = false
	connecting       = false
	reconnect_timer.stop()
	connection_attempt = 0
	print("NETWORK: Manual disconnection\n----------------------")

func _attempt_reconnection(): #on reconnect_timer "timeout"
	connection_attempt += 1
	if connection_attempt%CONNECTION_ATTEMPTS_STEPS == 0 and reconnect_timer.wait_time < 300:
		reconnect_timer.wait_time *= 2
	
	if host.get_connection_status() != NetworkedMultiplayerENet.CONNECTION_DISCONNECTED:
		host.close_connection()
	connect_to_server()

func auth_me(val):
	if val:
		if developer_name:
			rpc_id(1,"auth_request",net_id,developer_name)
	else:
		rpc_id(1,"dissociate_user",net_id)
		self.developer_name = ""


#-------------------------- network signal functions ---------------------------

func _on_connection_failed():
#	$scr/bg/lb_print.text = str($scr/bg/lb_print.text,"\n","Connection failed - ","Error: ")
	get_tree().set_network_peer(null)
	self.established = false
	print("NETWORK: connection failed")
	
	if reconnect_timer.is_stopped():
		if not connecting:
			set_timer_for_reconnect()
			connecting = true
		reconnect_timer.start()
	
func _on_connection_succeeded():
#	$scr/bg/lb_print.text = str($scr/bg/lb_print.text,"\n","Connection succeded - ")
	net_id = get_tree().multiplayer.get_network_unique_id()
	print("NETWORK: connection succeeded")
	print("NETWORK: My peer ID: %s | developer_name: %s"%[net_id,developer_name])
	print("NETWORK: Server IP: %s | PORT: %s"%[host.get_peer_address(1),host.get_peer_port(1)])
	
	self.established   = true
	connecting         = false
	connection_attempt = 0
	reconnect_timer.stop()
	set_timer_for_reconnect()
	
	auth_me(true)


#-------------------------- network communications -----------------------------

func _on_user_connected(id):
	if !get_tree().is_network_server(): return
	if id==1: return
	print("NETWORK: user connected %s, IP: %s"%[id2username(id),host.get_peer_address(id)])

func _on_user_disconnected(id):
	print("NETWORK: user disconnected %s"%id2username(id))

func _on_server_disconnected():
	print("NETWORK: server disconnected")
	self.established = false
	connecting       = true
	set_timer_for_reconnect()
	reconnect_timer.start()



#------------------------ network signals and timer ----------------------------

func set_timer_for_reconnect():
	reconnect_timer.wait_time = TMR_WAIT
	reconnect_timer.one_shot = true

func _set_established(val):
	established = val
	emit_signal("network_status_changed",val)
	fl_connected_to_server = val

func _get_established():
	if (get_tree().get_network_peer()):
		if get_tree().get_network_peer().get_connection_status() == 2:
			if !established: established = true
		else:
			if  established: established = false
	else:
		if  established: established = false
	return established

func _set_existing_developers(val):
	existing_developers = val

func _set_server_log(val):
	server_log = val
	emit_signal("server_log_updated")

func _test_updated(val):
	test = val
	emit_signal("test_updated",test)

func _set_developers_info(val):
	developers_info = val
	emit_signal("developers_info_updated",developers_info)

func _set_tasks(val):
	tasks = val
	emit_signal("tasks_updated",tasks)

func _set_announcements(val):
	announcements = val
	emit_signal("announcements_updated",announcements)

func _set_developer_name(val):
	developer_name = val
	mng.save_data()

func _auth_updated(val):
	fl_auth_succeded = val
	emit_signal("auth_updated",fl_auth_succeded)
	if fl_auth_succeded:
		print("NETWORK: connected as | %s |"%developer_name)
	else:
		print("NETWORK: connected as Unknown (%s)"%net_id)

#-------------------------------- Server rpc -----------------------------------

remote func receive_last_server_entry(entry):
	emit_signal("server_log_last_entry_updated",entry)

remote func receive_file_content(args): # args = [which, content]
	var which   = args[0]
	var content = args[1]
	match which:
		"ntw":  emit_signal("ntw_content_updated",content)
		"data": emit_signal("data_content_updated",content)
		"dd":   emit_signal("dd_content_updated",content)


#--------------------------------- Utilities -----------------------------------

func id2username(id):
	var username = "Unknown(%s)"%id
	if id==1:
		username = "Server"
	elif id == 0:
		username = "All"
	else:
		for key in existing_developers.keys():
			if id in existing_developers[key]:
				username = key
				break
	return username










