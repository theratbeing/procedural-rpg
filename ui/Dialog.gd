extends Panel

onready var container = get_node("ScrollContainer/VBoxContainer")
onready var speaker   = get_node("ScrollContainer/VBoxContainer/Speaker")
onready var message   = get_node("ScrollContainer/VBoxContainer/Message")
onready var sep_line  = get_node("ScrollContainer/VBoxContainer/HSeparator")
onready var animation = get_node("AnimationPlayer")

export(float) var char_per_sec = 20.0

var data     : DialogScript
var scenario : Array
var scenario_index := 0
var choice_var   := ""
var button_nodes := Array()
var done_printing := false

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
	
	animation.connect("animation_finished", self, "onAnimationFinished")

func _gui_input(event):
	if event.is_action("ui_accept") or event.is_action("left_click"):
		advance()

func advance():
	if done_printing and choice_var.empty():
		nextLine()
	else:
		animation.playback_speed *= 2

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
	
	var head = array.front()
	match head:
		DialogScript.DG.PRINT:
			printMessage(eval(array[1]))
		DialogScript.DG.SAY:
			sayMessage(eval(array[1]), eval(array[2]))
		DialogScript.DG.CHOOSE:
			choose(array[1], eval(array[2]), array.slice(3, -1))
		DialogScript.DG.QUIT:
			close()
		
		DialogScript.DG.LOAD:
			loadDialog(eval(array[1]), eval(array[2]))
		DialogScript.DG.LABEL:
			nextLine()
		DialogScript.DG.GOTO:
			scenario_index = data.label[eval(array[1])]
			readLine()
		DialogScript.DG.IF:
			if (eval(array[1])):
				eval(array[2])
			elif array.size() == 4:
				eval(array[3])
		
		DialogScript.DG.ARRAY:
			return array.slice(1, -1)
		DialogScript.DG.SET:
			data.setVar(array[1], eval(array[2]))
		DialogScript.DG.CALL:
			return callFunc(
				eval(array[1]), eval(array[2]), array.slice(3, -1))
		
		DialogScript.DG.EQUAL:
			return eval(array[1]) == eval(array[2])
		DialogScript.DG.LESS:
			return eval(array[1]) < eval(array[2])
		DialogScript.DG.MORE:
			return eval(array[1]) > eval(array[2])
		
		DialogScript.DG.ADD:
			return eval(array[1]) + eval(array[2])
		DialogScript.DG.SUB:
			return eval(array[1]) - eval(array[2])
		DialogScript.DG.MUL:
			return eval(array[1]) * eval(array[2])
		DialogScript.DG.DIV:
			return eval(array[1]) / eval(array[2])
		
		DialogScript.DG.NOT:
			return not eval(array[1])
		DialogScript.DG.AND:
			return eval(array[1]) and eval(array[2])
		DialogScript.DG.OR:
			return eval(array[1]) or eval(array[2])
		
		_:
			var err_msg = "Parsing error at instruction %d" % scenario_index
			printerr(err_msg)
			message.bbcode_text = err_msg

func close():
	emit_signal("dialog_ended")

func callFunc(object, fname: String, args: Array):
	match args.size():
		0:
			return object.call(fname)
		1:
			return object.call(fname, eval(args[0]))
		2:
			return object.call(fname, eval(args[0]), eval(args[1]))
		3:
			return object.call(fname, eval(args[0]), eval(args[1]), eval(args[2]))
		var n:
			printerr("Too many arguments: %d" % n)

func printMessage(text: String):
	printText(text)
	animation.play("Print")

func sayMessage(chara_name: String, text: String):
	speaker.bbcode_text = chara_name
	printText(text)
	animation.play("Say")

func printText(text: String):
	message.percent_visible = 0.0
	message.bbcode_text = text
	animation.playback_speed = char_per_sec / text.length()
	done_printing = false

func choose(var_name: String, prompt: String, choice: Array):
	choice_var = var_name
	printMessage(prompt)
	yield(animation, "animation_finished")
	
	for c_arr in choice:
		var array = eval(c_arr)
		assert(typeof(array) == TYPE_ARRAY)
		if array.size() == 3:
			var condition = array.pop_back()
			if !eval(condition):
				continue
		addChoice(eval(array[0]), eval(array[1]))

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

func onAnimationFinished(_anim):
	done_printing = true
	emit_signal("line_ended")
