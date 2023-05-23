extends Control

#Load Scene
func _ready():
	var data_manager = UserData.new()
	var script = preload("res://Scripts/Main.gd")
	var scene = load(data_manager.editor_layout).instantiate() #Get picked theme
	add_child(scene) #Add picked theme
	scene.set_script(script) #Attach main script to it
