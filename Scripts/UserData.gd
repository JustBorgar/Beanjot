class_name UserData
extends Resource

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

var _data_manager = DataManager.new()

##### Code #####

#Init
func _init():
	var data = _Load()
	if data:
		editor_mode = data["editor_mode"]
		editor_layout = data["editor_layout"]
		editor_theme = data["editor_theme"]
		editor_language = data["editor_language"]
		editor_programming_language = data["editor_programming_language"]
		editor_text_wrapped = data["editor_text_wrapped"]

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
			_data_manager.SaveData({ #Saves data as JSON
				"editor_mode" = editor_mode,
				"editor_layout" = editor_layout,
				"editor_theme" = editor_theme,
				"editor_language" = editor_language,
				"editor_programming_language" = editor_programming_language,
				"editor_text_wrapped" = editor_text_wrapped
			})
		_data_manager.DATA_TYPES.Resource:
			_data_manager.SaveData(self) #Passes the script iself to save
