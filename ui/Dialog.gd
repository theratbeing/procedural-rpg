extends Panel

onready var container = get_node("ScrollContainer/VBoxContainer")
onready var speaker   = get_node("ScrollContainer/VBoxContainer/Speaker")
onready var message   = get_node("ScrollContainer/VBoxContainer/Message")
onready var sep_line  = get_node("ScrollContainer/VBoxContainer/HSeparator")
onready var tween     = get_node("Tween")

export(float) var char_per_sec = 20.0

var data     : DialogScript
var scenario : Array
var scenario_index := 0
var choice_var   := ""
var button_nodes := Array() 

signal line_ended
signal dialog_ended

func loadDialog(file: String, label: String):
	data = DialogScript.loadDialog(file)
	scenario = data.content

	if label.empty():
		scenario_index = 0
	else:
		scenario_index = data.label[label]
	
	readLine()

func _ready():
	var _connect = tween.connect("tween_all_completed", self, "emit_signal", ["line_ended"])

func _gui_input(event):
	if event.is_action("ui_accept") or event.is_action("left_click"):
		advance()

func advance():
	if tween.is_active():
		endLine()
	elif !choice_var.empty():
		scenario_index += 1
		readLine()

func readLine():
	if scenario_index >= scenario.size():
		close()
	else:
		eval(scenario[scenario_index])

func eval(expression):
	match typeof(expression):
		TYPE_ARRAY:
			return evalArray(expression)
		TYPE_STRING:
			return data.getVar(expression)
		_:
			return expression

func evalArray(array: Array):
	if array.empty():
		return
	
	var head = array.pop_front()
	match head:
		DialogScript.Command.PRINT:
			printMessage(array)
		DialogScript.Command.SAY:
			sayMessage(array.pop_front(), array)
		DialogScript.Command.CHOOSE:
			var variable = array.pop_front()
			var prompt   = array.pop_front()
			choose(variable, prompt, array)
		DialogScript.Command.QUIT:
			close()
		
		DialogScript.Command.LOAD:
			loadDialog(array[0], array[1])
		DialogScript.Command.LABEL:
			advance()
		DialogScript.Command.GOTO:
			scenario_index = data.label[eval(array[0])]
			advance()
		DialogScript.Command.IF:
			if (eval(array[0])):
				eval(array[1])
			elif array.size() == 3:
				eval(array[2])
		
		DialogScript.Command.ARRAY:
			return array
		DialogScript.Command.SET:
			data.setVar(array[0], eval(array[1]))
		
		DialogScript.Command.EQUAL:
			return eval(array[0]) == eval(array[1])
		DialogScript.Command.LESS:
			return eval(array[0]) < eval(array[1])
		DialogScript.Command.MORE:
			return eval(array[0]) > eval(array[1])
		
		DialogScript.Command.ADD:
			return eval(array[0]) + eval(array[1])
		DialogScript.Command.SUB:
			return eval(array[0]) - eval(array[1])
		DialogScript.Command.MUL:
			return eval(array[0]) * eval(array[1])
		DialogScript.Command.DIV:
			return eval(array[0]) / eval(array[1])
		
		_:
			var err_msg = "Parsing error at instruction %d" % scenario_index
			printerr(err_msg)
			message.bbcode_text = err_msg

func close():
	emit_signal("dialog_ended")

func printMessage(args: Array):
	speaker.visible  = false
	sep_line.visible = false
	printText(args)

func sayMessage(chara_name: String, args: Array):
	speaker.visible  = true
	sep_line.visible = true
	speaker.bbcode_text = chara_name
	printText(args)

func printText(args: Array):
	var text := ""
	for arg in args:
		text += str(eval(arg)) + " "

	message.percent_visible = 0.0
	message.bbcode_text = text
	
	var duration = float(text.length()) / char_per_sec
	tween.interpolate_property(message, "percent_visible",
	0.0, 1.0, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()

func choose(var_name: String, prompt: Array, choice: Array):
	choice_var = var_name
	printMessage(prompt)
	yield(self, "line_ended")
	
	for c_arr in choice:
		assert(typeof(c_arr) == TYPE_ARRAY)
		if c_arr.size() == 3:
			var condition = c_arr.pop_back()
			if !eval(condition):
				continue
		addChoice(eval(c_arr[0]), eval(c_arr[1]))

func addChoice(value, text: String):
	var button = Button.new()
	button.text = text
	button_nodes.push_back(button)
	container.add_child(button)
	var _connect = button.connect("button_down", self, "onChoiceMade", [value])

func onChoiceMade(value):
	data.setVar(choice_var, value)
	choice_var = ""
	for button in button_nodes:
		button.queue_free()
	button_nodes.clear()
	advance()

func endLine():
	tween.stop_all()
	message.percent_visible = 1.0
	emit_signal("line_ended")
