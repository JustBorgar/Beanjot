class_name UserData
extends Node

##### Variables #####

#Enums/Constants
enum Editor_Mode{Writing, Coding}
enum Editor_Programming_Languages{GDScript, Lua}
enum Editor_Themes{Caffeine, Godette, Bonfire, Paragon, Cosmos, Custom}
enum Editor_Languages{English, Spanish}
const Editor_Layouts = {Classic = "res://Scenes/Classic Theme.tscn", Modern = "res://Scenes/Modern Theme.tscn"}

#Preferences
@export var editor_mode: int = Editor_Mode.Writing
@export var editor_layout: String = Editor_Layouts.Modern
@export var editor_theme: int = Editor_Themes.Caffeine
@export var editor_language: int = Editor_Languages.English
@export var editor_programming_language: int = Editor_Programming_Languages.GDScript
@export var editor_text_wrapped: bool = true
@export var editor_resolution: String = str(ProjectSettings.get_setting("display/window/size/viewport_width")) + "x" + str(ProjectSettings.get_setting("display/window/size/viewport_height"))
@export var editor_bar_folded: bool = false

var _data_manager = DataManager.new()

##### Code #####

#Gets the node's "exported" variables
func get_exports():
	var properties = self.get_property_list()
	var to_return = []
	for index in range(properties.size()):
		if ("editor_" in properties[index].name) and not ("description" in properties[index].name): #Prob shouldn't have used the editor keyword but i'm not changing it by now
			to_return.append(properties[index].name)
	return to_return

#Init
func _init():
	var data = _Load()
	if data:
		var exports = get_exports()
		for value in exports: #For each exported var, set the var to the loaded value or its own value
			self[value] = data[value] if data.has(value) else self[value] #Wasted 30 minutes trying to figure out why var = A or B returned a bool, then I realized this isn't lua (also note to self, find_key doesn't work, it'll always return null)

#Load
func _Load():
	match(_data_manager.data_type): #Returns loaded data
		_data_manager.DATA_TYPES.JSON:
			return _data_manager.LoadData(null)
		_data_manager.DATA_TYPES.Resource:
			return _data_manager.LoadData(self) #Idk, haven't used resources yet

#Save
func Save():
	match(_data_manager.data_type):
		_data_manager.DATA_TYPES.JSON:
			var to_save = {}
			var exports = get_exports()
			for value in exports: #For each exported var
				to_save[value] = self[value] #Store it
			_data_manager.SaveData(to_save) #Saves data as JSON
		_data_manager.DATA_TYPES.Resource:
			_data_manager.SaveData(self) #Passes the script iself to save
