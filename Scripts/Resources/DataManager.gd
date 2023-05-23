class_name DataManager
extends Resource

##### Variables #####

enum DATA_TYPES{json, tres} #tres is easier to use, but bad actors can inject code to it

const DEFAULT_DIRECTORY = "user://Data/"
const DEFAULT_NAME = "Save"

var default_path = DEFAULT_DIRECTORY + DEFAULT_NAME + "." + str(data_type) #Current Path
var data_type = DATA_TYPES.tres
var encrypt_data = false

##### Resource Functions #####

## Load ##

#Requests to load user's data, returns it's contents, the template, or null.
func LoadData(template = null, path = default_path):
	if data_type == DATA_TYPES.tres: #Resource
		if ResourceLoader.exists(path):
			return load(path)
		return template
	elif data_type == DATA_TYPES.json: #JSON
		if FileAccess.file_exists(path):
			var text_data = FileAccess.get_file_as_string(path)
			var dict_data = JSON.parse_string(text_data)
			if dict_data is Dictionary:
				return JSON.parse_string(text_data)
			else:
				print("Not a dictionary")
				return template
		return template

## Save ##

#Requests to save user's data, if data exists it overwrites it, otherwise it creates it.
func SaveData(data, path = default_path):
	if data_type == DATA_TYPES.tres: #Resource
		ResourceSaver.save(data, path)
	elif data_type == DATA_TYPES.json: #JSON
		var file = FileAccess.open(path, FileAccess.WRITE)
		var text_data = JSON.stringify(data)
		file.store_string(text_data)
		file.close()

## Wipe ##

#Requests to wipe user's data, if data exists it deletes the file, otherwise it does nothing.
func WipeData(path = default_path):
	OS.move_to_trash(path)

##### Internal #####

## Verify Directory ##

#Makes sure the default directory exists
func verify_dir(path: String):
	DirAccess.make_dir_absolute(path)

##### Events #####

## Ready ##

func _init():
	verify_dir(DEFAULT_DIRECTORY) #Ensures dir exists
