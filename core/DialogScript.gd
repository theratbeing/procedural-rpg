extends Resource
class_name DialogScript

enum Command {
	PRINT,
	SAY,
	CHOOSE,
	QUIT,
	
	LOAD,
	LABEL,
	GOTO,
	IF,
	
	ARRAY,
	SET,
	
	EQUAL,
	LESS,
	MORE,
	
	ADD,
	SUB,
	MUL,
	DIV,
}

const GLOBAL_PREFIX := "$"
const LOCAL_PREFIX  := "#"

const PATH := "res://dialog/"

var label   := Dictionary()
var local   := Dictionary()
var content := Array()

static func loadDialog(file: String) -> Resource:
	var dialog = load(PATH + file).new()
	dialog.indexLabel()
	return dialog

func setVar(variable: String, value):
	if variable.begins_with(LOCAL_PREFIX):
		local[variable.trim_prefix(LOCAL_PREFIX)] = value
	elif variable.begins_with(GLOBAL_PREFIX):
		Global.variables[variable.trim_prefix(GLOBAL_PREFIX)] = value
	else:
		return null
	return value

func getVar(variable: String):
	if variable.begins_with(LOCAL_PREFIX):
		return local[variable.trim_prefix(LOCAL_PREFIX)]
	elif variable.begins_with(GLOBAL_PREFIX):
		return Global.variables[variable.trim_prefix(GLOBAL_PREFIX)]
	else:
		return variable
 
func indexLabel():
	for index in content.size():
		var command = content[index]
		if typeof(command) == TYPE_ARRAY and \
		command.size() == 2 and \
		command[0] == Command.LABEL:
			var label_name = command[1]
			assert(typeof(label_name) == TYPE_STRING)
			label[label_name] = index
