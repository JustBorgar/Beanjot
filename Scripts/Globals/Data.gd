class_name UserData
extends Resource

##### Variables #####

#Enums
enum Editor_Mode{Writing, Coding}
enum Editor_Programming_Languages{GDScript, Lua}
enum Editor_Themes{Caffeine, Godette, Bonfire, Boccher, Mortadela, Custom}
enum Editor_Languages{English, Spanish}

#Constants
const Editor_Layouts = {
	Classic = "res://Scenes/Classic Theme.tscn",
	Modern = "res://Scenes/Modern Theme.tscn"
}

#Preferences
@export var editor_mode = Editor_Mode.Writing
@export var editor_layout = Editor_Layouts.Modern
@export var editor_theme = Editor_Themes.Caffeine
@export var editor_language = Editor_Languages.English
@export var editor_programming_language = Editor_Programming_Languages.GDScript
@export var editor_text_wrapped = false

##### Code #####

#Init
var _Data = DataManager.new()
func _init():
	_Data.encrypt_data = true
	_Data.data_type = _Data.DATA_TYPES.json

#Load
func Load():
	_Data.LoadData(self.duplicate(true))

#Save
func Save():
	_Data.SaveData(self)
