extends Panel

onready var speaker  = get_node("VBoxContainer/Speaker")
onready var message  = get_node("VBoxContainer/Message")
onready var sep_line = get_node("VBoxContainer/HSeparator")
onready var tween    = get_node("Tween")

export(float) var char_per_sec = 20.0

var scenario : Array
var scenario_index := 0

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

func close():
	pass
