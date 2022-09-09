extends Panel

onready var speaker  = get_node("VBoxContainer/Speaker")
onready var message  = get_node("VBoxContainer/Message")
onready var sep_line = get_node("VBoxContainer/HSeparator")
onready var tween    = get_node("Tween")

export(float) var char_per_sec = 20.0

var data     : DialogScript
var scenario : Array
var scenario_index := 0

func loadDialog(file: String, label: String):
	data = DialogScript.loadDialog(file)
	scenario = data.content

	if label.empty():
		scenario_index = 0
	else:
		scenario_index = data.label[label]
	
	readLine()

func advance():
	if tween.is_active():
		tween.stop_all()
		message.percent_visible = 1.0
	else:
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
			printMessage(array[0])
		DialogScript.Command.SAY:
			sayMessage(array[0], array[1])
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
	pass

func printMessage(text: String):
	speaker.visible  = false
	sep_line.visible = false
	printText(text)

func sayMessage(chara_name: String, text: String):
	speaker.visible  = true
	sep_line.visible = true
	
	speaker.bbcode_text = chara_name
	printText(text)

func printText(text: String):
	message.percent_visible = 0.0
	message.bbcode_text = text
	
	var duration = float(text.length()) / char_per_sec
	tween.interpolate_property(message, "percent_visible",
	0.0, 1.0, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
