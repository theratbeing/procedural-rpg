extends Panel

onready var container = get_node("ScrollContainer/VBoxContainer")
onready var speaker   = get_node("ScrollContainer/VBoxContainer/Speaker")
onready var message   = get_node("ScrollContainer/VBoxContainer/Message")
onready var sep_line  = get_node("ScrollContainer/VBoxContainer/HSeparator")

export(float) var char_per_sec = 20.0

var data     : DialogScript
var scenario : Array
var scenario_index := 0
var choice_var   := ""
var button_nodes := Array() 
var printing_done = false
var tween : Tween

signal line_ended
signal dialog_ended

func loadDialog(file: String, label: String = ""):
	data = DialogScript.loadDialog(file)
	scenario = data.content

	if label.empty():
		scenario_index = 0
	else:
		scenario_index = data.label[label]
	
	readLine()

func _ready():
	speaker.visible  = false
	sep_line.visible = false
	message.visible  = false

func _gui_input(event):
	if event.is_action("ui_accept") or event.is_action("left_click"):
		advance()

func advance():
	if !printing_done:
		endLine()
	elif choice_var.empty():
		nextLine()

func nextLine():
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
	
	var copy = array.duplicate()
	var head = copy.pop_front()
	match head:
		DialogScript.DG.PRINT:
			printMessage(copy)
		DialogScript.DG.SAY:
			sayMessage(copy.pop_front(), copy)
		DialogScript.DG.CHOOSE:
			var variable = copy.pop_front()
			var prompt   = copy.pop_front()
			choose(variable, prompt, copy)
		DialogScript.DG.QUIT:
			close()
		
		DialogScript.DG.LOAD:
			loadDialog(copy[0], copy[1])
		DialogScript.DG.LABEL:
			nextLine()
		DialogScript.DG.GOTO:
			scenario_index = data.label[eval(copy[0])]
			nextLine()
		DialogScript.DG.IF:
			if (eval(copy[0])):
				eval(copy[1])
			elif copy.size() == 3:
				eval(copy[2])
		DialogScript.DG.DO:
			for line in copy:
				eval(line)
		
		DialogScript.DG.ARRAY:
			return copy
		DialogScript.DG.SET:
			data.setVar(copy[0], eval(copy[1]))
		
		DialogScript.DG.EQUAL:
			return eval(copy[0]) == eval(copy[1])
		DialogScript.DG.LESS:
			return eval(copy[0]) < eval(copy[1])
		DialogScript.DG.MORE:
			return eval(copy[0]) > eval(copy[1])
		
		DialogScript.DG.ADD:
			return eval(copy[0]) + eval(copy[1])
		DialogScript.DG.SUB:
			return eval(copy[0]) - eval(copy[1])
		DialogScript.DG.MUL:
			return eval(copy[0]) * eval(copy[1])
		DialogScript.DG.DIV:
			return eval(copy[0]) / eval(copy[1])
		
		DialogScript.DG.NOT:
			return not eval(copy[0])
		DialogScript.DG.AND:
			return eval(copy[0]) and eval(copy[1])
		DialogScript.DG.OR:
			return eval(copy[0]) or eval(copy[1])
		
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
	message.visible = true
	printing_done   = false
	
	var duration = float(text.length()) / char_per_sec
	tween = Tween.new()
	add_child(tween)
	var _out = tween.connect("tween_completed", self, "onTweenCompleted") 
	_out = tween.interpolate_property(message, "percent_visible",
	0.0, 1.0, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	_out = tween.start()

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

func onTweenCompleted(_arg1, _arg2):
	endLine()

func endLine():
	var _out = tween.stop_all()
	tween.queue_free()
	
	message.percent_visible = 1.0
	printing_done = true
	emit_signal("line_ended")
