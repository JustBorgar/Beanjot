extends Node
class_name DataManager

##### Variables #####

const DATA_TYPES = {JSON = "json", Resource = "tres"}
const DEFAULT_DIRECTORY = "user://Data/"
const DEFAULT_NAME = "Save"

var data_type = DATA_TYPES.JSON
var encrypt_data = false #JSON only
var decrypt_key = "xJ83Lb3jH"
var default_path = DEFAULT_DIRECTORY + DEFAULT_NAME + "." + str(data_type) #Current Path

##### Resource Functions #####

## Load ##

#Requests to load user's data, returns it's contents, the template, or null.
func LoadData(template = null, path = default_path):
	if data_type == DATA_TYPES.Resource: #Resource
		if ResourceLoader.exists(path):
			return load(path)
		return template
	elif data_type == DATA_TYPES.JSON: #JSON
		if FileAccess.file_exists(path):
			var file = FileAccess.open(path, FileAccess.READ) if not encrypt_data else FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, decrypt_key)
			var text_data = file.get_as_text()
			var dict_data = JSON.parse_string(text_data)
			file.close()
			if dict_data is Dictionary:
				return JSON.parse_string(text_data)
			else:
				push_warning("Loaded data isn't a valid dictionary, cannot return.")
				return template
		return template

## Save ##

#Requests to save user's data, if data exists it overwrites it, otherwise it creates it.
func SaveData(data, path = default_path):
	if data_type == DATA_TYPES.Resource: #Resource
		ResourceSaver.save(data, path)
	elif data_type == DATA_TYPES.JSON: #JSON
		var file = FileAccess.open(path, FileAccess.WRITE) if not encrypt_data else FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, decrypt_key)
		var text_data = JSON.stringify(data)
		file.store_string(text_data)
		file.close()

## Wipe ##

#Requests to wipe user's data, if data exists it deletes the file, otherwise it does nothing.
func WipeData(path = default_path):
	OS.move_to_trash(path)

##### Events #####

## Ready ##

func _init():
	DirAccess.make_dir_absolute(DEFAULT_DIRECTORY) #Ensures dir exists
