extends Node

func _ready():
	var dialog = get_node("Dialog")
	dialog.loadDialog("test.gd")
