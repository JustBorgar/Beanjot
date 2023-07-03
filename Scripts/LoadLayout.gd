extends Control

#Setup Menubar
@onready var menubar_items = $MenuBarItems
func setup_menubar(layout):
	for items in menubar_items.get_children(): #For each menu
		var menubar = layout.get_node("MenuBackground/" + items.name) #Check if the layout has it
		if menubar: #If it does
			for button in items.get_children(): #For each button of said menu
				button.reparent(menubar) #Add it to the appropiate layout menu
		else: #If it doesn't
			items.queue_free() #Destroy

#Load Scene
func _ready():
	var user_data = UserData.new()
	var script = preload("res://Scripts/Main.gd")
	var scene = load(user_data.editor_layout).instantiate() #Get picked layout
	add_child(scene) #Add picked layout
	setup_menubar(scene) #Setup menubar
	scene.set_script(script) #Attach main script to it
