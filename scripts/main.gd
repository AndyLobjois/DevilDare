extends Node
class_name Main

var exePath : String = OS.get_executable_path().get_base_dir()
var savePath : String
var isLock : bool = true
var isEnd : bool = false
var isBindAdd : bool = false
var isBindSub : bool = false

@export_range(0, 5) var index : int = 0
@export var challenges : Array[Challenge]
@export var sounds : Array[SoundPack] = []

# UI
@onready var text = $ChallengeText
@onready var bar = $ChallengeBar
@onready var label = $ChallengeBar/Label
@onready var lock = $LockButton
@onready var settings = $Settings
@onready var readtype = $Settings/ReadType
@onready var audiotype = $Settings/AudioType
@onready var bindWindow = $Settings/BindWindow
# ANIMATIONS
@onready var anim = $AnimationPlayer
@onready var barAnim = $ChallengeBar/AnimationPlayer
# AUDIO
@onready var volume = $Settings/AudioVolume/Slider
@onready var audioAdd = $Audio/AudioAdd
@onready var audioSub = $Audio/AudioSub
@onready var audioEnd = $Audio/AudioEnd
# BINDS
var addKeycode = 4194437
var subKeycode = 4194435
@onready var bindAdd = $Settings/BindWindow/AddButton
@onready var bindSub = $Settings/BindWindow/SubButton

func _ready():
	# Save Name Version
	savePath = "user://save v" + str(ProjectSettings.get_setting("application/config/version")).replace(".", "_")
	
	# Window Check
	if not FileAccess.file_exists(savePath):
		var screen = DisplayServer.screen_get_size(DisplayServer.MAIN_WINDOW_ID)
		var window = get_viewport().get_visible_rect().size
		get_window().position = Vector2((screen.x/2-window.x/2),(screen.y-window.y) - 20)
		
	# Save
	load_data()
	refresh()
	
	# Keybinds
	create_input_map()
	
	# Changes
	change_challenge()
	change_sounds(audiotype.selected)
	
	# Hide Settings
	settings.visible = false

func _process(_delta):
	# Shortcuts
	if GlobalInput.is_action_just_pressed("add") and isLock:
		bar.value += 1
		anim.stop()
		anim.play("add")
		refresh()
		
		if bar.value < bar.max_value:
			audioAdd.volume_db = lerp(0, 10, float(bar.value) / float(bar.max_value)) - 10 - (volume.max_value - volume.value)
			audioAdd.play()
		
	if GlobalInput.is_action_just_pressed("sub") and isLock:
		bar.value -= 1
		audioSub.play()
		refresh()
		
	# Check if Challenge is MAX
	if bar.value == bar.max_value:
		if !isEnd:
			isEnd = true
			audioEnd.play()
			barAnim.play("BarShine")
	else:
		isEnd = false

func _input(event : InputEvent):
	if event is InputEventKey:
		if isBindAdd:
			addKeycode = event.keycode
			isBindAdd = false
		
		if isBindSub:
			subKeycode = event.keycode
			isBindSub = false
		
		create_input_map()


# SAVE/LOAD ---------------------------------------------------
func save_data():
	print("Saved !")
	var file = FileAccess.open(savePath, FileAccess.WRITE)
	file.store_var(get_window().position)
	file.store_var(get_window().size)
	file.store_var(index)
	file.store_var(readtype.selected)
	file.store_var(audiotype.selected)
	file.store_var(volume.value)
	for i in 6:
		file.store_var(challenges[i].state.button_pressed)
		file.store_var(challenges[i].color.color)
		file.store_var(challenges[i].text.text)
		file.store_var(challenges[i].value.text)
	file.store_var(text.text)
	file.store_var(bar.value)
	file.store_var(bar.max_value)
	file.store_var(addKeycode)
	file.store_var(subKeycode)

func load_data():
	if FileAccess.file_exists(savePath):
		var file = FileAccess.open(savePath, FileAccess.READ)
		get_window().position = file.get_var()
		get_window().size = file.get_var()
		index = file.get_var()
		readtype.selected = file.get_var()
		audiotype.selected = file.get_var()
		volume.value = float(file.get_var())
		for i in 6:
			challenges[i].state.button_pressed = file.get_var()
			challenges[i].color.color = file.get_var()
			challenges[i].text.text = file.get_var()
			challenges[i].value.text = file.get_var()
		text.text = file.get_var()
		bar.value = file.get_var()
		bar.max_value = file.get_var()
		addKeycode = file.get_var()
		subKeycode = file.get_var()


# TOOLS -------------------------------------------------------
func refresh():
	label.text = str(bar.value) + " / " + str(bar.max_value)

func load_mp3(path):
	var file = FileAccess.open(path, FileAccess.READ)
	var sound = AudioStreamMP3.new()
	sound.data = file.get_buffer(file.get_length())
	return sound

var isStartUp = true
func change_sounds(value):
	if value < sounds.size():
		audioAdd.stream = sounds[value].add
		audioSub.stream = sounds[value].sub
		audioEnd.stream = sounds[value].end
	else:
		# Open Custom Sounds Folder
		if isStartUp:
			isStartUp = false
		else:
			OS.shell_open(exePath + "/custom_sounds")
			
		# Get Custom Sounds
		if FileAccess.file_exists(exePath + "/custom_sounds/sfx_add.mp3"):
				audioAdd.stream = load_mp3(exePath + "/custom_sounds/sfx_add.mp3")
		if FileAccess.file_exists(exePath + "/custom_sounds/sfx_sub.mp3"):
				audioSub.stream = load_mp3(exePath + "/custom_sounds/sfx_sub.mp3")
		if FileAccess.file_exists(exePath + "/custom_sounds/sfx_end.mp3"):
				audioEnd.stream = load_mp3(exePath + "/custom_sounds/sfx_end.mp3")
	# Save
	save_data()

func change_challenge():
	# Challenge Text
	text.text = challenges[index].text.text.replace("@", challenges[index].value.text)
	
	# Challenge Label
	bar.value = 0
	bar.max_value = int(challenges[index].value.text)
	refresh()
	
	# Challenge Color
	var color = challenges[index].color.color
	var newTheme = bar.get_theme_stylebox("fill").duplicate()
	newTheme.bg_color = color
	newTheme.border_color = color + Color(0.2, 0.2, 0.2)
	newTheme.shadow_color = color - Color(0, 0, 0, 0.5)
	bar.add_theme_stylebox_override("fill", newTheme)
	
	# Save
	save_data()

func create_input_map():
	# Clean
	InputMap.erase_action("add")
	InputMap.erase_action("sub")
	
	# Add New Inputs
	var keyAdd = InputEventKey.new()
	var keySub = InputEventKey.new()
	keyAdd.physical_keycode = addKeycode
	keySub.physical_keycode = subKeycode
	InputMap.add_action("add", 0.5)
	InputMap.action_add_event("add", keyAdd)
	InputMap.add_action("sub", 0.5)
	InputMap.action_add_event("sub", keySub)
	
	# Labels & Unfocus
	bindAdd.text = OS.get_keycode_string(addKeycode)
	bindSub.text = OS.get_keycode_string(subKeycode)
	bindAdd.release_focus()
	bindSub.release_focus()
	
	# Restart Global Input
	GlobalInput._initialize_global_input_c_sharp()
	
	# Save
	save_data()


# BUTTONS / EVENTS ---------------------------------------------
func on_lock_pressed():
	# Lock / Unlock
	isLock = !isLock
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, isLock)
	settings.visible = !isLock
	if isLock:
		get_window().position = Vector2(get_window().position.x + 8, get_window().position.y + 31)
		get_window().size = Vector2(get_window().size.x - 16, 268)
		save_data()
	else:
		get_window().position = Vector2(get_window().position.x - 8, get_window().position.y - 31)
		get_window().size = Vector2(get_window().size.x + 16, 268)

func on_challenge_select(i):
	index = i
	change_challenge()
	anim.stop()
	anim.play("add")

func on_volume(value):
	var db = value - volume.max_value
	audioAdd.volume_db = db
	audioSub.volume_db = db
	audioEnd.volume_db = db
	save_data()

func on_audio_end():
	## STAY -----------------------------------
	if readtype.selected == 0:
		pass
		
	## LOOP -----------------------------------
	elif readtype.selected == 1:
		# Create List of Enable Challenges (including current)
		var list : Array[Challenge] = []
		for item in challenges:
			if item.state.button_pressed == true:
				list.append(item)
		# Next Challenge
		for i in range(0, list.size()):
			if list[i].index == index:
				if i == list.size() - 1: # Back to zero
					index = list[0].index
				else:
					index = list[i + 1].index
				break
	
	## RANDOM ----------------------------------- 
	elif readtype.selected == 2:
		# Create List of Enable Challenges (excluding current)
		var list : Array[Challenge] = []
		for item in challenges:
			if item.state.button_pressed == true and item != challenges[index]:
				list.append(item)
		# Random  
		if list.size() > 1:
			index = list[randi_range(0, list.size() - 1)].index
		elif list.size() == 1:
			index = list[0].index
	
	# Get New Challenge
	change_challenge()

func on_bindbutton():
	bindWindow.visible = !bindWindow.visible

func on_bind_add():
	isBindAdd = true
	isBindSub = false
	bindAdd.text = "Press Any Key"

func on_bind_sub():
	isBindAdd = false
	isBindSub = true
	bindSub.text = "Press Any Key"

func on_selected(_value):
	save_data()
