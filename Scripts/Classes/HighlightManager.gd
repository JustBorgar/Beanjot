extends Node
class_name HighlightManager

### Vars ###

var Languages = UserData.Editor_Programming_Languages
var Highlighter := CodeHighlighter.new()

### Code ###

## Functions ##

func Highlight_Text(code_edit: CodeEdit, language: Variant = null):
	match(language):
		Languages.GDScript:
			
			#Clear
			Highlighter.clear_color_regions()
			Highlighter.clear_keyword_colors()
			Highlighter.clear_member_keyword_colors()
			Highlighter.clear_highlighting_cache()
			
			#Colors
			const STRING_COLOR = Color(1, 0.92941176891327, 0.63137257099152)
			const COMMENT_COLOR = Color(0.80392158031464, 0.81176471710205, 0.82352942228317, 0.50196081399918)
			const KEYWORD_COLOR = Color(1, 0.43921568989754, 0.52156865596771)
			const MEMBERVAR_COLOR = Color(0.73725491762161, 0.87843137979507, 1)
			const SYMBOL_COLOR = Color(0.67058825492859, 0.78823530673981, 1)
			const NUMBER_COLOR = Color(0.63137257099152, 1, 0.87843137979507)
			const FUNCTION_COLOR = Color(0.34117648005486, 0.70196080207825, 1)
			const ANNOTATION_COLOR = Color(1, 0.70196080207825, 0.45098039507866)
			const BASETYPE_COLOR = Color(0.99999439716339, 0.08191246539354, 0.36862486600876)
			const CLASSTYPE_COLOR = Color(0.258823543787, 1, 0.76078432798386)
			
			#Regions
			Highlighter.add_color_region("'", "'", STRING_COLOR) #String
			Highlighter.add_color_region('"', '"', STRING_COLOR) #String Alt
			Highlighter.add_color_region("'''", "'''", STRING_COLOR) #Long Comment
			Highlighter.add_color_region("#", "", COMMENT_COLOR, true) #Comment
			Highlighter.add_color_region("@", " ", ANNOTATION_COLOR) #Var Keyword
			
			#Words
			const KEYWORDS = ["if", "elif", "else", "for", "while", "match", "break", "continue", "pass", "return", "class", "class_name", "extends", "is", "in", "as", "and", "or", "self", "signal", "func", "super", "static", "const", "enum", "var", "breakpoint", "preload", "await", "yield", "assert", "void", "PI", "TAU", "INF", "NAN", "true", "false"]
			const BASETYPES = ["null", "bool", "int", "float"]
			const CLASSTYPES = ["Variant", "String", "StringName", "NodePath", "Vector2", "Vector2i", "Rect2", "Vector3", "Vector3i", "Transform2D", "Plane", "Quaternion", "AABB", "Basis", "Transform3D", "Color", "RID", "Object", "Array", "Dictionary", "Signal", "Callable", "PackedByteArray", "PackedInt32Array", "PackedInt64Array", "PackedFloat32Array", "PackedFloat64Array", "PackedStringArray", "PackedVector2Array", "PackedVector3Array", "PackedColorArray", "Node", "Node2D", "Node3D", "Control", "Container", "Viewport", "OS", "new"] #Not gonna add everything bc I couldn't find a list for the nodes, just added the basic ones
			
			#Apply Words
			for keyword in KEYWORDS: #Keywords
				Highlighter.add_keyword_color(keyword, KEYWORD_COLOR)
			for base_type in BASETYPES: #Base types
				Highlighter.add_keyword_color(base_type, BASETYPE_COLOR)
			for class_type in CLASSTYPES: #Class types
				Highlighter.add_keyword_color(class_type, CLASSTYPE_COLOR)
				
			Highlighter.symbol_color = SYMBOL_COLOR
			Highlighter.number_color = NUMBER_COLOR
			Highlighter.member_variable_color = MEMBERVAR_COLOR
			Highlighter.function_color = FUNCTION_COLOR
			
			#Apply highlighter
			code_edit.draw_tabs = true
			code_edit.indent_size = 4
			code_edit.syntax_highlighter = Highlighter
			
		Languages.Lua:
			
			#Clear
			Highlighter.clear_color_regions()
			Highlighter.clear_keyword_colors()
			Highlighter.clear_member_keyword_colors()
			Highlighter.clear_highlighting_cache()
			
			#Colors
			const STRING_COLOR = Color8(173, 241, 149)
			const COMMENT_COLOR = Color8(102, 102, 102)
			const KEYWORD_COLOR = Color8(248, 109, 124)
			const SYMBOL_COLOR = Color8(204, 204, 204)
			const NUMBER_COLOR = Color8(255, 198, 0)
			const MEMBERVAR_COLOR = Color8(132, 214, 247)
			const FUNCTION_COLOR = Color8(204, 204, 204)
			const BASETYPE_COLOR = Color8(248, 109, 124)
			const CLASSTYPE_COLOR = Color8(132, 214, 247)
			
			#Regions
			Highlighter.add_color_region("'", "'", STRING_COLOR) #String
			Highlighter.add_color_region('"', '"', STRING_COLOR) #String Alt
			Highlighter.add_color_region("--", "", COMMENT_COLOR, true) #Comment
			Highlighter.add_color_region("--[[", "]]", COMMENT_COLOR) #Long Comment
			
			#Words
			const KEYWORDS = ["if", "else", "elseif", "then", "do", "in", "for", "while", "and", "or", "not", "false", "true", "nil", "local", "function", "break", "return", "continue", "repeat", "until", "end", "goto", "self"]
			const BASETYPES = ["nil", "boolean", "string", "number", "table", "thread", "userdata", "unknown", "never", "any"]
			const CLASSTYPES = ["assert", "pcall", "xpcall", "collectgarbage", "dofile", "_G", "getfenv", "getmetatable", "ipairs", "pairs", "load", "loadfile", "loadstring", "next", "print", "rawequal", "rawget", "rawset", "select", "setfenv", "setmetatable", "tonumber", "tostring", "type", "unpack", "_VERSION", "coroutine.create", "coroutine.resume", "coroutine.running", "coroutine.status", "coroutine.wrap", "coroutine.yield", "spawn", "wait", "delay"]
			const RCLASSES = ["task", "Instance", "workspace", "game", "script", "Vector3", "Vector2", "CFrame", "WaitForChild", "FindFirstChild", "Destroy", "GetChildren", "GetService", "new", "require"]  #Godot doesn't provide a way to highlight member functions, so here's some common ones + a few keywords
				
			#Apply Words
			for keyword in KEYWORDS: #Keywords
				Highlighter.add_keyword_color(keyword, KEYWORD_COLOR)
			for base_type in BASETYPES: #Base types
				Highlighter.add_keyword_color(base_type, BASETYPE_COLOR)
			for class_type in CLASSTYPES: #Class types
				Highlighter.add_keyword_color(class_type, CLASSTYPE_COLOR)
			for rclass in RCLASSES: #R Classes
				Highlighter.add_keyword_color(rclass, CLASSTYPE_COLOR)
				
			Highlighter.symbol_color = SYMBOL_COLOR
			Highlighter.number_color = NUMBER_COLOR
			Highlighter.member_variable_color = MEMBERVAR_COLOR
			Highlighter.function_color = FUNCTION_COLOR
			
			#Apply highlighter
			code_edit.draw_tabs = false
			code_edit.indent_size = 8
			code_edit.syntax_highlighter = Highlighter
		
		_:
			#Remove highlighter
			code_edit.draw_tabs = false
			code_edit.indent_size = 4
			code_edit.syntax_highlighter = null
	
