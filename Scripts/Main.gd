extends Control

##### Variables #####

#Core
@warning_ignore("get_node_default_without_onready") var text_edit = $TextEdit
@warning_ignore("get_node_default_without_onready") var file_button = $MenuBar/File
@warning_ignore("get_node_default_without_onready") var edit_button = $MenuBar/Edit
@warning_ignore("get_node_default_without_onready") var about_button = $MenuBar/About
@warning_ignore("get_node_default_without_onready") var mode_button = $MenuBar/Mode
@warning_ignore("get_node_default_without_onready") var theme_button = $MenuBar/Theme
@warning_ignore("get_node_default_without_onready") var layout_button = $MenuBar/Layout 

#File
@warning_ignore("get_node_default_without_onready") var import = $MenuBar/File/Import
@warning_ignore("get_node_default_without_onready") var export = $MenuBar/File/Export
@warning_ignore("get_node_default_without_onready") var delete = $MenuBar/File/Delete
@warning_ignore("get_node_default_without_onready") var close = $MenuBar/File/Close
@warning_ignore("get_node_default_without_onready") var rename = $MenuBar/File/Rename
@warning_ignore("get_node_default_without_onready") var create = $MenuBar/File/Create
@warning_ignore("get_node_default_without_onready") var renameinput = $MenuBar/File/Rename/Input

#About
@warning_ignore("get_node_default_without_onready") var about = $MenuBar/About/AboutPopup

#Script
var supported_filetypes := ["txt", "lua", "gd"]
var app_name := "Beanjot"
var file_name := "Untitled Document"
var last_path = null
var data = null

"""
TODO TOMORROW:
_Check if the refactor didn't break anything.
_Implement subcategories.
_Implemented the remaining user preferences (basically subcategories).
_Finish implementing saving.
_Start work on either the themes or the syntax highlighting.

TODO:
_Add search functionality.
_Autocomplete save_as (if possible).
_Implement Themes and custom theme (if possible)
_Add syntax highlighting to code mode.
"""

##### Code #####

### Misc ###

## Update Title ##

func update_title():
	DisplayServer.window_set_title(app_name + " - " + file_name)

## Setup ##

func setup_misc():
	
	#Handle loading preferences
	var data_manager = UserData.new()
	data = data_manager.Load()
	
	#Set preferences (Language/Programming Language sub-categories missing)
	file_button.get_popup().set_item_checked(7, data_manager.editor_text_wrapped)
	mode_button.get_popup().set_item_checked(data_manager.editor_mode, true)
	theme_button.get_popup().set_item_checked(data_manager.editor_theme, true)
	layout_button.get_popup().set_item_checked(0 if data_manager.editor_layout.find("Classic") else 1, true)
	
	#Handle user dropping files
	get_viewport().files_dropped.connect(func(files):
		var path = files[0]
		text_edit.text = FileAccess.get_file_as_string(path)
		last_path = path
		file_name = path
		update_title.call()
		handle_extension(path)
	)
	
	#Handle files opened using Beanjot (will break if any more args are passed)
	var array_to_string = func(arr: Array) -> String: #Converts args array to string
		var s = ""
		for i in arr:
			s += String(i)
		return s
		
	var args = OS.get_cmdline_args() #Gets the first arg and if it's file extension is accepted, loads it.
	if args:
		var ext = array_to_string.call(args).get_extension()
		var find_ext = supported_filetypes.has(ext)
		if find_ext:
			var path = args[0]
			text_edit.text = FileAccess.get_file_as_string(path)
			last_path = path
			file_name = path
			handle_extension(path)
	
	#Diable AutoQuit
	get_tree().set_auto_accept_quit(false)
	
	#Set Initial Title
	update_title.call()
	
	#Fix Rename not closing
	rename.close_requested.connect(func():
		rename.visible = false
		renameinput.clear()
	)
	
	#Hide unwanted right mouse menu tabs
	var context_menu = text_edit.get_menu()
	context_menu.remove_item(10)
	context_menu.remove_item(11)
	context_menu.remove_item(9)
	context_menu.remove_item(10)
	context_menu.remove_item(9)
	
	#Center Popups
	get_tree().get_root().size_changed.connect(func():
		if rename.visible:
			rename.popup_centered()
		if about.visible:
			about.popup_centered()
	)


## Extension Handler ##

func handle_extension(path):
	var extension = path.get_extension()
	if extension != "txt" and supported_filetypes.has(extension):
		if !file_button.get_popup().is_item_checked(7):
			file_pressed("Code Mode", 7)
	elif extension == "txt":
		if file_button.get_popup().is_item_checked(7):
			file_pressed("Code Mode", 7)

## Theme Handler ##

func handle_theme():
	pass

## Popup Handler ##

var last_popup = null
var last_popup_connection = null
var last_popup_callable = null

func handle_popup(popup = null, callable = null):
	
	#Disconnect (this has got to be the most shitty signal disconnect syntax I've ever seen in a game engine, why on earth can't I just store the connection and disconnect that?)
	if last_popup_connection != null:
		if last_popup.visible == true:
			last_popup.hide()
		match (last_popup_connection):
			1:
				last_popup.file_selected.disconnect(last_popup_callable)
			2:
				last_popup.confirmed.disconnect(last_popup_callable)
			3:
				renameinput.text_submitted.disconnect(last_popup_callable)
		last_popup_connection = null
		last_popup_callable = null
		last_popup = null
	
	#Connect
	if popup:
		popup.show()
		last_popup = popup
		last_popup_callable = callable
		if popup.is_class("FileDialog"): #FileDialogs
			popup.file_selected.connect(callable)
			last_popup_connection = 1
			
		elif popup.is_class("ConfirmationDialog"): #ConfirmationDialogs
			popup.confirmed.connect(callable)
			last_popup_connection = 2
			
		elif popup.is_class("Window"): #Custom
			if (popup == rename):
				renameinput.text_submitted.connect(callable)
				last_popup_connection = 3

## Check Handler ##

func handle_check(button, id, callable):
	var popup = button.get_popup()
	callable.call(!popup.is_item_checked(id))
	popup.toggle_item_checked(id)

### Main Functions ###

## File Pressed ##

func file_pressed(item_name, id = null):
	match (item_name):
		
		## Main ##
		
		#Create File
		"New File":
			if text_edit.text != "": #If we wrote something
				handle_popup(create, func():
					file_name = "Untitled Document"
					update_title.call()
					text_edit.text = ""
					last_path = null #Prevents edge case where previous files can be deleted by mistake (otherwise the filename/prev-path would need to constantly be compared)
				)
		
		#Import File
		"Import File":
			handle_popup(import, func(path):
				text_edit.text = FileAccess.get_file_as_string(path)
				last_path = path
				file_name = path
				update_title.call()
				handle_extension(path)
			)
		
		#Export File
		"Export File":
			if last_path: #Update
				var file = FileAccess.open(last_path, FileAccess.WRITE_READ)
				file.store_string(text_edit.text)
				file_name = last_path
				update_title.call()
				file.close()
			else: #Export As
				file_pressed("Export File As")
		
		#Export File as
		"Export File As":
			handle_popup(export, func(path):
				var file = FileAccess.open(path, FileAccess.WRITE_READ) #Write
				#export.set_current_file(file_name) #Default Name == Doc Name
				file.store_string(text_edit.text)
				last_path = path
				file_name = path
				update_title.call()
				file.close()
			)
		
		#Delete File
		"Delete File":
			if last_path or text_edit.text != "": #If there is something to delete
				handle_popup(delete, func():
					if last_path: #Delete if file exists
						OS.move_to_trash(last_path)
					file_pressed("New File") #New file
				)
		
		#Rename File
		"Rename File":
			handle_popup(rename, func(submitted):
				if submitted != "": #If name is valid
					if last_path: #If file was exported
						
						#Rename
						var file = FileAccess.open(last_path, FileAccess.WRITE_READ)
						var path = last_path
						var file_dir = path.get_base_dir()
						var file_ext = path.get_extension()
						var new_path = file_dir + "/" + submitted + "." + file_ext
						file.close()
						DirAccess.rename_absolute(path, new_path)
						last_path = new_path
						file_name = last_path

						#Fix (this rename thing is so amazing it loses all the content in the file)
						file = FileAccess.open(last_path, FileAccess.WRITE_READ)
						file.store_string(text_edit.text)
						file.close()
						
					#If file is new
					else:
						file_name = submitted
					
					#Exported or not, switch tab title and close
					update_title.call()
					rename.visible = false #Close
					renameinput.clear()
			)
		
		#Close Beanjot
		"Close Beanjot":
			if last_path == null: #Unexported file
				if text_edit.text == "": #Nothing written, close
					get_tree().quit()
				else: #Unsaved text, warn
					handle_popup(close, func():
						get_tree().quit()
					)
			else: #Exported file
				var text = FileAccess.get_file_as_string(last_path)
				if text_edit.text == text: #Saved text, quit
					get_tree().quit()
				else: #Unsaved text, warn
					handle_popup(close, func():
						get_tree().quit()
					)
		
		## Misc ##
		
		#Wrap Text
		"Wrap Text":
			handle_check(file_button, id, func(Bool):
				if Bool:
					text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
				else:
					text_edit.wrap_mode = TextEdit.LINE_WRAPPING_NONE
			)

## Edit Pressed ##

func edit_pressed(item_name):
	match(item_name):
	
		#Undo
		"Undo":
			text_edit.undo()
		
		#Redo
		"Redo":
			text_edit.redo()
		
		#Cut
		"Cut":
			text_edit.cut(text_edit.get_caret_wrap_index())
		
		#Copy
		"Copy":
			text_edit.copy(text_edit.get_caret_wrap_index())
		
		#Paste
		"Paste":
			text_edit.paste(text_edit.get_caret_wrap_index())
		
		#Select All
		"Select All":
			text_edit.select_all()
		
		#Deselect
		"Deselect":
			text_edit.deselect()
		
		#Clear
		"Clear":
			text_edit.clear()

## About Pressed ##

func about_pressed(item_name):
	match(item_name):
		
		#About
		"About Beanjot":
			about.popup()
			about.close_requested.connect(func():
				about.visible = false
			)

## Mode Pressed ##

func switch_mode(Bool):
	mode_button.get_popup().set_item_checked(0, !Bool)
	mode_button.get_popup().set_item_checked(1, Bool)
	text_edit.line_folding = Bool
	text_edit.gutters_draw_line_numbers = Bool
	text_edit.indent_automatic = Bool
	text_edit.indent_use_spaces = Bool
	text_edit.code_completion_enabled = Bool
	text_edit.gutters_draw_breakpoints_gutter = Bool
	text_edit.gutters_draw_executing_lines = Bool
	text_edit.gutters_draw_bookmarks = Bool
	text_edit.gutters_zero_pad_line_numbers = Bool
	text_edit.gutters_draw_fold_gutter = Bool

func mode_pressed(item_name, id = null):
	match(item_name):
		
		#Writing
		"Writing":
			switch_mode(false)
			
		#Coding
		"Coding":
			switch_mode(true)

## Theme Pressed ##

func theme_pressed(item_name):
	pass

## Layout Pressed ##

func layout_pressed(item_name):
	pass

### Events ###

## Ready ##

func _init():
	print("A")
	print($TextEdit)
	print(text_edit)
	
	#Setup Miscellaneous
	setup_misc()
	
	#File Pressed
	var file_popup = file_button.get_popup()
	file_popup.id_pressed.connect(func(id):
		file_pressed(file_popup.get_item_text(id), id)
	)
	
	#Edit Pressed
	var edit_popup = edit_button.get_popup()
	edit_popup.id_pressed.connect(func(id):
		edit_pressed(edit_popup.get_item_text(id))
	)
	
	#About Pressed
	var about_popup = about_button.get_popup()
	about_popup.id_pressed.connect(func(id):
		about_pressed(about_popup.get_item_text(id))
	)
	
	var mode_popup = mode_button.get_popup()
	mode_popup.id_pressed.connect(func(id):
		mode_pressed(mode_popup, id)
	)
	
	var theme_popup = theme_button.get_popup()
	theme_popup.id_pressed.connect(func(id):
		theme_pressed(theme_popup)
	)
	
	var layout_popup = layout_button.get_popup()
	layout_popup.id_pressed.connect(func(id):
		layout_pressed(layout_popup)
	)

## Custom Quit ##

func _notification(notif):
	if notif == NOTIFICATION_WM_CLOSE_REQUEST:
		file_pressed("Close Beanjot")
