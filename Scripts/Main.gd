extends Control

"""
Hey there, thanks for checking out my little text editor. This is basically the first actual
program I make coming from roblox luau, so don't expect the most clean/functional thing ever.

Sorry if the code isn't easy to read, i'm still trying to find a code structure i'm comfortable
with in godot, so i'm not entirely happy with how this turned out myself but eh, at least it
works (might come back to clean it up later if I find a way to split the MenuBar functions
without passing a morbillion parameters or doing something hacky (I'll probably implement
a custom WaitForChild("Path") node or something like that later)).

Credits can be found in the attribution thing, and the page readme probably,
once I set it up. There's also a TODO thing below with stuff I might come back
to add later if there's ever demand for this, and yup, that's pretty much about
it, thanks for reading, feel free to do whatever you want with the source code.
"""

##### Variables #####

#Core
@warning_ignore("get_node_default_without_onready") var text_edit = $TextEdit
@warning_ignore("get_node_default_without_onready") var menu_background = $MenuBackground
@warning_ignore("get_node_default_without_onready") var menu_bar = menu_background.get_node("MenuBar")
@warning_ignore("get_node_default_without_onready") var menu_lowerbar = menu_background.get_node("LowerMenuBar")
@warning_ignore("get_node_default_without_onready") var fold_button = menu_lowerbar.get_node("Fold") if menu_lowerbar else null
@warning_ignore("get_node_default_without_onready") var bj_version = get_parent().get_node("Version")

#MenuBar
@warning_ignore("get_node_default_without_onready") var file_button = menu_bar.get_node("File")
@warning_ignore("get_node_default_without_onready") var edit_button = menu_bar.get_node("Edit")
@warning_ignore("get_node_default_without_onready") var about_button = menu_bar.get_node("About")
@warning_ignore("get_node_default_without_onready") var mode_button = menu_bar.get_node("Mode")
@warning_ignore("get_node_default_without_onready") var theme_button = menu_bar.get_node("Theme")
@warning_ignore("get_node_default_without_onready") var layout_button = menu_bar.get_node("Layout")

#File
@warning_ignore("get_node_default_without_onready") var import = file_button.get_node("Import")
@warning_ignore("get_node_default_without_onready") var export = file_button.get_node("Export")
@warning_ignore("get_node_default_without_onready") var delete = file_button.get_node("Delete")
@warning_ignore("get_node_default_without_onready") var close = file_button.get_node("Close")
@warning_ignore("get_node_default_without_onready") var restart = file_button.get_node("Restart")
@warning_ignore("get_node_default_without_onready") var rename = file_button.get_node("Rename")
@warning_ignore("get_node_default_without_onready") var create = file_button.get_node("Create")
@warning_ignore("get_node_default_without_onready") var renameinput = rename.get_node("Input")

#About
@warning_ignore("get_node_default_without_onready") var about = about_button.get_node("AboutPopup")
@warning_ignore("get_node_default_without_onready") var attribution = about_button.get_node("AttributionPopup")

#Submenus
var lang_submenu: PopupMenu = null
var mode_submenu: PopupMenu = null
var runcode_submenu: PopupMenu = null

#Script
var supported_filetypes := ["txt", "lua", "gd"]
var app_name := "Beanjot"
var file_name := "Untitled Document"
var last_path = null
var data_manager = null
var highlight_manager = null
var last_popup = null
var last_popup_connection = null
var last_popup_callable = null
var folded = false

"""
BUGS:
_TextEdit doesn't scale the text properly sometimes.
_Program name may not show the file name (this is an engine bug I tried to fix with a yield, but without get_title() method for DisplayServer there's no consistent fix).
_ ¯/_(ツ)_/¯ using lambdas seems to make the program crash randomly, with no repro, and no info in the debugger to fix it, so I used them pretty sparingly.

TODO POST RELEASE/MAYBE, IF I FEEL LIKE IT:
_Allow editing multiple files at once like vscode and notepad++ do.
_Add more customization (custom theme, custom font/font sizes, etc).
_Ask the user if they want to save their text or not when closing beanjot.
_Make the MenuBar in the modern layout bigger when the user increases the resolution.
_MenuBar functions make main hard to read, split them in their own sub-scripts (Gave up atm).
_Make the handle_extension func use enums instead of raw numbers, and make the the filetypes variable grab them from the node or the node from the code (all from 1 place).
_Add additional modes (For example a QuickNotes mode (remote trello), a Localizar mode (custom zip with a source text and it's localizations), a DataManager mode (would allow making CSV/JSON files using a higher level interface), etc).
_Add support for CSS, HTML, RES, TSCN, CSV, Java files (if I can, struggled a bit with lua already).
_Add strict typing and make the code more consistent (get rid of all the PascalCase too).
_Make the about/credits section less ugly, I don't like how it looks rn.
_Translate credits/about (Idk how to deal with multi-line text atm).
_The current themes implementation is trash, do it the built in way.
_Add search functionality and borderless/fullscreen mode.
_Store user's popup resolution.
"""

##### Code #####

''' Misc '''

#Handles various miscellaneous when the program starts 
func setup_misc():
	
	#Clamp window size
	DisplayServer.window_set_min_size(Vector2i(355, 300))
	
	#Diable AutoQuit
	get_tree().set_auto_accept_quit(false)
	
	#Set Initial Title/Resolution
	get_tree().create_timer(0.1).timeout.connect(func(): #Without yield it doesn't change at all
		get_tree().create_timer(1).timeout.connect(func():
			DisplayServer.window_set_title(app_name + " - " + file_name)
		)
		DisplayServer.window_set_title(app_name + " - " + file_name)
	)
	var res = data_manager.editor_resolution.split_floats("x")
	DisplayServer.window_set_size(Vector2(res[0], res[1]))
	get_tree().get_root().size_changed.connect(func():
		var new_res = DisplayServer.window_get_size()
		data_manager.editor_resolution = str(new_res[0]) + "x" + str(new_res[1])
	)
	
	#Setup Foldable MenuBar
	if fold_button:
		var fold_pressed = func(skip = false):
			
			#Add bar items
			var buttons = []
			for button in menu_bar.get_children():
				buttons.append(button)
			for button in menu_lowerbar.get_children():
				buttons.append(button)
			
			#Folded
			if (folded == false):
				folded = true
				
				#Fix bar items size
				for button in buttons:
					button.clip_text = true
				
				#Tween
				if not skip: #Play tween
					var fold_tween = create_tween() #Background
					var fold_tween2 = create_tween() #TextEdit
					var fold_tween3 = create_tween() #Version
					fold_tween.tween_property(menu_background, "offset_right", 30, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
					fold_tween2.tween_property(text_edit, "offset_left", 30, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
					fold_tween3.tween_property(bj_version, "visible_ratio", 0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
					fold_tween.play()
					fold_tween2.play()
					fold_tween3.play()
				else: #Set directly
					menu_background.offset_right = 30
					text_edit.offset_left = 30
					bj_version.visible_ratio = 0
				
			#Unfolded
			else:
				
				#Fix bar items size
				for button in buttons:
					button.clip_text = false
				
				#Tween
				if not skip:
					var fold_tween = create_tween() #Background
					var fold_tween2 = create_tween() #TextEdit
					var fold_tween3 = create_tween() #Version
					fold_tween.tween_property(menu_background, "offset_right", 85, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
					fold_tween2.tween_property(text_edit, "offset_left", 85, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
					fold_tween3.tween_property(bj_version, "visible_ratio", 1, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
					fold_tween.play()
					fold_tween2.play()
					fold_tween3.play()
				else:
					menu_background.offset_right = 85
					text_edit.offset_left = 85
					bj_version.visible_ratio = 1
				folded = false
			data_manager.editor_bar_folded = folded #Save
		fold_button.pressed.connect(fold_pressed) #Call
		if folded != data_manager.editor_bar_folded: #Apply saved
			fold_pressed.call(true)
		
	
	#Setup clickable links
	for textlabel in attribution.get_children():
		if textlabel.name == "Text":
			textlabel.meta_clicked.connect(func(meta): #Link clicked
				OS.shell_open(meta) #Open
			)
	
	#Check layout
	layout_button.get_popup().set_item_checked(0 if data_manager.editor_layout == data_manager.Editor_Layouts.Classic else 1, true)
	
	#Handle user dropping files
	get_viewport().files_dropped.connect(func(files):
		var path = files[0]
		text_edit.text = FileAccess.get_file_as_string(path)
		last_path = path
		file_name = path
		DisplayServer.window_set_title(app_name + " - " + file_name) #Update Title
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
	
	#Setup sub-popups
	var lang_menu = file_button.get_popup() #Language
	lang_submenu = PopupMenu.new()
	lang_submenu.name = "lang_submenu"
	lang_submenu.add_check_item("English", 0)
	lang_submenu.add_check_item("Spanish", 1)
	lang_menu.add_child(lang_submenu)
	lang_menu.set_item_submenu(8, "lang_submenu")
	var mode_menu = mode_button.get_popup() #Mode
	mode_submenu = PopupMenu.new()
	mode_submenu.name = "mode_submenu"
	mode_submenu.add_check_item("GDScript", 0)
	mode_submenu.add_check_item("Lua/Luau", 1)
	mode_menu.add_child(mode_submenu)
	mode_menu.hide_on_checkable_item_selection = false
	var runcode_menu = mode_submenu #Mode (Run Code)
	runcode_submenu = PopupMenu.new()
	runcode_submenu.name = "runcode_submenu"
	runcode_submenu.add_item("Run", 0)
	runcode_menu.add_child(runcode_submenu)
	runcode_submenu.id_pressed.connect(func(_id): #Demo popup button pressed
		OS.shell_open(mode_button.get_meta("URL"))
	)
	
	#Center Popups
	get_tree().get_root().size_changed.connect(func():
		if rename.visible:
			rename.popup_centered()
		if about.visible:
			about.popup_centered()
	)

#Handles loading data and classes
func load_data():
	data_manager = UserData.new()
	highlight_manager = HighlightManager.new()

#Handles saving data when the program closes
func save_data():
	data_manager.Save()

## Handles file extensions
func handle_extension(path):
	var extension = path.get_extension()
	if extension == "lua" or extension == "gd": #If filetype isn't txt, enable code mode
		if !mode_button.get_popup().is_item_checked(UserData.Editor_Mode.Coding): #If code mode isn't already enabled, enable
			mode_pressed(UserData.Editor_Mode.Coding)
		if extension == "gd": #Set highlighting to gdscript (I should use enums but I wanna finish this today)
			submode_pressed(0)
		elif extension == "lua": #Set highlighting to lua
			submode_pressed(1)
	elif extension == "txt":
		if !mode_button.get_popup().is_item_checked(UserData.Editor_Mode.Writing): #If writing mode isn't already enabled, enable
			mode_pressed(UserData.Editor_Mode.Writing)

''' Utils '''

#Handles popups
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

#Handles single checks
func handle_check(button, id):
	var popup = button.get_popup()
	popup.toggle_item_checked(id)
	return popup.is_item_checked(id)

''' MenuBar '''

## File ##

func file_pressed(item_name, id = null, apply_loaded = null):
	match (item_name):
		
		## Main ##
		
		#Create File
		"New File":
			if text_edit.text != "": #If we wrote something
				handle_popup(create, func():
					file_name = "Untitled Document"
					DisplayServer.window_set_title(app_name + " - " + file_name) #Update Title
					text_edit.text = ""
					last_path = null #Prevents edge case where previous files can be deleted by mistake (otherwise the filename/prev-path would need to constantly be compared)
				)
		
		#Import File
		"Import File":
			handle_popup(import, func(path):
				text_edit.text = FileAccess.get_file_as_string(path)
				last_path = path
				file_name = path
				DisplayServer.window_set_title(app_name + " - " + file_name) #Update Title
				handle_extension(path)
			)
		
		#Export File
		"Export File":
			if last_path: #Update
				var file = FileAccess.open(last_path, FileAccess.WRITE_READ)
				file.store_string(text_edit.text)
				file_name = last_path
				DisplayServer.window_set_title(app_name + " - " + file_name) #Update Title
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
				DisplayServer.window_set_title(app_name + " - " + file_name) #Update Title
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
					DisplayServer.window_set_title(app_name + " - " + file_name) #Update Title
					rename.visible = false #Close
					renameinput.clear()
			)
		
		#Close Beanjot
		"Close Beanjot":
			save_data() #Saves data before you quit
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
			if apply_loaded != null:
				if apply_loaded == false and file_button.get_popup().is_item_checked(id) == false:
					return
			var Bool = handle_check(file_button, id)
			if Bool:
				text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
			else:
				text_edit.wrap_mode = TextEdit.LINE_WRAPPING_NONE
			data_manager.editor_text_wrapped = text_edit.wrap_mode #Update Wrap

## Edit ##

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

## About ##

func about_pressed(item_name):
	match(item_name):
		
		#About
		"About Beanjot":
			about.popup()
			about.close_requested.connect(func():
				about.visible = false
			)
		
		#Attribution
		"Attribution":
			attribution.popup()
			attribution.close_requested.connect(func():
				attribution.visible = false
			)

## Mode ##

func switch_mode(Bool):
	mode_button.get_popup().set_item_checked(0, !Bool)
	mode_button.get_popup().set_item_checked(1, Bool)
	text_edit.line_folding = Bool
	text_edit.gutters_draw_line_numbers = Bool
	text_edit.indent_automatic = Bool #text_edit.indent_use_spaces = Bool
	text_edit.code_completion_enabled = Bool
	text_edit.gutters_draw_breakpoints_gutter = Bool
	text_edit.gutters_draw_executing_lines = Bool
	text_edit.gutters_draw_bookmarks = Bool
	text_edit.gutters_zero_pad_line_numbers = Bool
	text_edit.gutters_draw_fold_gutter = Bool

func mode_pressed(item_id):
	data_manager.editor_mode = item_id #Update mode
	
	#Apply Mode
	match(item_id):
		
		#Writing
		UserData.Editor_Mode.Writing:
			mode_button.get_popup().set_item_submenu(1, "")
			highlight_manager.Highlight_Text(text_edit, null)
			switch_mode(false)
			
		#Coding
		UserData.Editor_Mode.Coding:
			mode_button.get_popup().set_item_submenu(1, "mode_submenu") #Thank you godot for not letting me check items with submenus, very kind of you
			highlight_manager.Highlight_Text(text_edit, data_manager.editor_programming_language)
			switch_mode(true)

func submode_pressed(item_id):
	data_manager.editor_programming_language = item_id #Update language
	switch_mode(true) #Force the mode to switch
	
	#Apply language
	var url: String = ""
	match(item_id):
		
		#GDScript
		data_manager.Editor_Programming_Languages.GDScript:
			highlight_manager.Highlight_Text(text_edit, item_id)
			url = "https://gdscript-online.github.io/"
		
		#Lua
		data_manager.Editor_Programming_Languages.Lua:
			highlight_manager.Highlight_Text(text_edit, item_id)
			url = "https://luau-lang.org/demo?" #lua is more widely used but the luau highlighting is prob more accurate bc that's the one I use
		
	#Save Last Language
	data_manager.editor_programming_language = item_id
	mode_button.set_meta("URL", url)
	
	#Check selected item
	for item_index in mode_submenu.item_count:
		if item_index == data_manager.editor_programming_language:
			mode_submenu.set_item_checked(item_index, true)
			mode_submenu.set_item_submenu(item_index, "runcode_submenu") #Thank you godot for not letting me check items with submenus, very kind of you
		else:
			mode_submenu.set_item_checked(item_index, false)
			mode_submenu.set_item_submenu(item_index, "")

## Theme ##

func switch_theme(c1, c2, c3, c4):
	$Background.color = c1
	$MenuBackground.color = c2
	text_edit.add_theme_color_override("background_color", c3)
	
	var apply_recursively = func(menu_button, self_func):
		for menu_popup in menu_button.get_children(true): #Get Button Popups
			if menu_popup is PopupMenu:
				for menu_margin in menu_popup.get_children(true): #Get Button Margin Container
					if menu_margin is MarginContainer:
						menu_margin.self_modulate = c4 #Apply theme to it
			self_func.call(menu_popup, self_func) #Have function call itself
	for menu_button in $MenuBackground/MenuBar.get_children(false): #Gets MenuBar buttons
		apply_recursively.call(menu_button, apply_recursively) #Recursively look for popups and apply the theme to them
		
	#Apply themes to ContextMenu
	var context_menu = text_edit.get_menu()
	for context_margin in context_menu.get_children(true): #Get Margin Container
		if context_margin is MarginContainer:
			context_margin.self_modulate = c4

func theme_pressed(item_id):
	data_manager.editor_theme = item_id #Update Theme
	var popup: PopupMenu = theme_button.get_popup()
	var layout_popup: PopupMenu = layout_button.get_popup() #Layout data uses the path, so we check the popup instead
	
	#Apply theme
	match (item_id):
		UserData.Editor_Themes.Caffeine:
			switch_theme(
				Color8(81, 61, 57, 255), #Background color
				Color8(39, 28, 24, 255) if layout_popup.is_item_checked(1) else Color8(81, 61, 57, 255), #Menu background color
				Color8(58, 43, 40, 255), #Text Edit Color
				Color8(125, 76, 61, 255) #Popup Colors
			)
		UserData.Editor_Themes.Godette:
			switch_theme(
				Color8(54, 61, 74, 255), #Background color
				Color8(39, 45, 55, 255) if layout_popup.is_item_checked(1) else Color8(54, 61, 74, 255), #Menu background color
				Color8(29, 34, 41, 255), #Text Edit Color
				Color8(54, 61, 74, 255) #Popup Colors
			)
		UserData.Editor_Themes.Bonfire:
			switch_theme(
				Color8(39, 42, 47, 255), #Background color
				Color8(30, 33, 36, 255) if layout_popup.is_item_checked(1) else Color8(39, 42, 47, 255), #Menu background color
				Color8(49, 49, 49, 255), #Text Edit Color
				Color8(168, 177, 182, 255) #Popup Colors
			)
		UserData.Editor_Themes.Paragon:
			switch_theme(
				Color8(164, 126, 27, 255), #Background color
				Color8(84, 57, 7, 255) if layout_popup.is_item_checked(1) else Color8(164, 126, 27, 255), #Menu background color
				Color8(128, 91, 16, 255), #Text Edit Color
				Color8(255, 214, 10, 255) #Popup Colors
			)
		UserData.Editor_Themes.Cosmos:
			switch_theme(
				Color8(164, 19, 60, 255), #Background color
				Color8(128, 15, 47, 255) if layout_popup.is_item_checked(1) else Color8(164, 19, 60, 255), #Menu background color
				Color8(89, 13, 34, 255), #Text Edit Color
				Color8(164, 19, 60, 255) #Popup Colors
			)
		#UserData.Editor_Themes.Custom:
			#pass
		
	#Check selected item
	data_manager.editor_theme = item_id
	for item_index in popup.item_count:
		if item_index == data_manager.editor_theme:
			popup.set_item_checked(item_index, true)
		else:
			popup.set_item_checked(item_index, false)

## Layout ##

func layout_pressed(item_id):
	var layout_index = UserData.Editor_Layouts.keys().find(data_manager.editor_layout)
	var new_layout_index = UserData.Editor_Layouts.keys().find(layout_button.get_popup().get_item_text(item_id))
	if item_id != layout_index:
		
		#Check selected item
		var popup: PopupMenu = layout_button.get_popup()
		var layout_path = UserData.Editor_Layouts.values()[item_id]
		data_manager.editor_layout = layout_path
		for item_index in popup.item_count:
			if item_index == new_layout_index:
				popup.set_item_checked(item_index, true)
			else:
				popup.set_item_checked(item_index, false)
		
		#Update Layout
		data_manager.editor_layout = layout_path
		
		#Restart Prompt
		handle_popup(restart, func():
			file_pressed("Close Beanjot")
		)

## Language ##

func language_pressed(item_id):
	data_manager.editor_language = item_id #Update Language
	
	#Apply language
	match (item_id):
		UserData.Editor_Languages.English:
			TranslationServer.set_locale("en")
		UserData.Editor_Languages.Spanish:
			TranslationServer.set_locale("es")
	
	#Check selected item
	data_manager.editor_language = item_id
	for item_index in lang_submenu.item_count:
		if item_index == data_manager.editor_language:
			lang_submenu.set_item_checked(item_index, true)
		else:
			lang_submenu.set_item_checked(item_index, false)

''' Signals '''

## Custom Quit ##

func _notification(notif):
	if notif == NOTIFICATION_WM_CLOSE_REQUEST:
		file_pressed("Close Beanjot")

## Ready ##

func _init():
	
	#Setup Miscellaneous/Load Data
	load_data()
	setup_misc()
	
	#File Pressed
	var file_popup = file_button.get_popup()
	file_popup.id_pressed.connect(func(id):
		file_pressed(file_popup.get_item_text(id), id)
	)
	file_pressed("Wrap Text", 7, data_manager.editor_text_wrapped)
	
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
	
	#Mode Pressed
	var mode_popup = mode_button.get_popup()
	mode_popup.id_pressed.connect(func(id):
		mode_pressed(id)
	)
	mode_submenu.id_pressed.connect(func(id):
		submode_pressed(id)
	)
	submode_pressed(data_manager.editor_programming_language)
	mode_pressed(data_manager.editor_mode)
	
	#Theme Pressed
	var theme_popup = theme_button.get_popup()
	theme_popup.id_pressed.connect(func(id):
		theme_pressed(id)
	)
	theme_pressed(data_manager.editor_theme)
	
	#Layout Pressed
	var layout_popup = layout_button.get_popup()
	layout_popup.id_pressed.connect(func(id):
		layout_pressed(id)
	)
	
	#Language Pressed
	lang_submenu.id_pressed.connect(func(id):
		language_pressed(id)
	)
	language_pressed(data_manager.editor_language)
