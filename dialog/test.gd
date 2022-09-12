extends DialogScript

func _init():
	content = [
		[DG.LABEL, "start"],
		[DG.PRINT, "Hello, there!"],
		[DG.PRINT, "This is a test dialog, a dialog for testing dialog-related features."],
		[DG.SAY, "Nicole", "My name is Nicole."],
		[DG.SAY, "Jamie", "My name is Jamie."],
		
		[DG.LABEL, "choice-1"],
		[DG.CHOOSE, "#choice-1", "What do you want to do next?",
			[DG.ARRAY, "start", "Back to beginning."],
			[DG.ARRAY, "next", "Read next line."],
			[DG.ARRAY, "skipped", "Skip some text."],
			[DG.ARRAY, "quit", "Quit."]
		],
		[DG.GOTO, "#choice-1"],
		
		[DG.LABEL, "next"],
		[DG.PRINT, "This is the next line."],
		[DG.GOTO, "choice-1"],
		
		[DG.LABEL, "skipped"],
		[DG.PRINT, "This is the line after the next line."],
		[DG.GOTO, "choice-1"],
	
		[DG.LABEL, "quit"],
		[DG.PRINT, "Quitting..."],
		[DG.QUIT],
	]
