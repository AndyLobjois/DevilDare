extends Node

var exePath = OS.get_executable_path().get_base_dir()
var savePath = "user://save"
var isLock = true
var isEnd = false

@onready var text = $Text
@onready var bar = $Bar
@onready var label = $Bar/Label
@onready var labelButton = $Bar/LabelButton
@onready var labelEdit = $Bar/LabelEdit
@onready var lockButton = $LockButton
@onready var lockOn = $LockButton/LockOn
@onready var lockOff = $LockButton/LockOff
@onready var anim = $AnimationPlayer
@onready var barAnim = $Bar/AnimationPlayer
@onready var audioAdd = $AudioAdd
@onready var audioSub = $AudioSub
@onready var audioEnd = $AudioEnd

func _ready():
    # Save
    if not FileAccess.file_exists(savePath):
        var screen = DisplayServer.screen_get_size(DisplayServer.MAIN_WINDOW_ID)
        var window = get_viewport().get_visible_rect().size
        get_window().position = Vector2((screen.x/2-window.x/2),(screen.y-window.y) - 20)
    load_data()
    refresh()
    
    # Audio
    var addPath = exePath + "/sfx_add.mp3"
    var subPath = exePath + "/sfx_sub.mp3"
    var endPath = exePath + "/sfx_end.mp3"
    if FileAccess.file_exists(addPath):
            audioAdd.stream = load_mp3(addPath)
    if FileAccess.file_exists(subPath):
            audioSub.stream = load_mp3(subPath)
    if FileAccess.file_exists(endPath):
            audioEnd.stream = load_mp3(endPath)
            
    # Color
    set_bar_color(exePath + "/color.txt")
        
    # Keybinds
    create_input_map()

func _process(delta):
    if GlobalInput.is_action_just_pressed("ui_accept"):
        bar.max_value = float(labelEdit.text)
        toggleLabel(false)
        refresh()
    
    if GlobalInput.is_action_just_pressed("add"):
        bar.value += 1
        anim.stop()
        anim.play("add")
        refresh()
        
        if bar.value < bar.max_value:
            audioAdd.volume_db = lerp(0, 10, float(bar.value) / float(bar.max_value)) - 10
            audioAdd.play()
        
    if GlobalInput.is_action_just_pressed("sub"):
        bar.value -= 1
        audioSub.play()
        refresh()
        
    if bar.value == bar.max_value:
        if !isEnd:
            isEnd = true
            audioEnd.play()
            barAnim.play("BarShine")
    else:
        isEnd = false
            
func _notification(what):
    if what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT:
        save_data()
        toggleLabel(false)
        lockButton.visible = false
    elif what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
        lockButton.visible = true


# SAVE/LOAD ---------------------------------------------------
func save_data():
    var file = FileAccess.open(savePath, FileAccess.WRITE)
    file.store_var(get_window().position)
    file.store_var(get_window().size)
    file.store_var(text.text)
    file.store_var(bar.value)
    file.store_var(bar.max_value)

func load_data():
    if FileAccess.file_exists(savePath):
        var file = FileAccess.open(savePath, FileAccess.READ)
        get_window().position = file.get_var()
        get_window().size = file.get_var()
        text.text = file.get_var()
        bar.value = file.get_var()
        bar.max_value = file.get_var()


# TOOLS -------------------------------------------------------
func refresh():
    label.text = str(bar.value) + " / " + str(bar.max_value)
    labelEdit.text = str(bar.max_value)

func load_mp3(soundPath):
    var file = FileAccess.open(soundPath, FileAccess.READ)
    var sound = AudioStreamMP3.new()
    sound.data = file.get_buffer(file.get_length())
    return sound

func toggleLabel(state):
    label.visible = !state
    labelButton.visible = !state
    labelEdit.visible = state
 
func set_bar_color(colorPath):
    if FileAccess.file_exists(colorPath):
        var file = FileAccess.open(colorPath, FileAccess.READ)
        var color = Color("#" + file.get_line() + "ff")
        
        var newTheme = bar.get_theme_stylebox("fill").duplicate()
        newTheme.bg_color = color
        newTheme.border_color = color + Color(0.2, 0.2, 0.2)
        newTheme.shadow_color = color - Color(0, 0, 0, 0.5)
        bar.add_theme_stylebox_override("fill", newTheme) 
    
    
# BUTTONS -----------------------------------------------------
func _on_LabelButton_pressed():
    toggleLabel(true)
    labelEdit.grab_focus()
    labelEdit.select_all()
     
func _on_lock_pressed():
    save_data()
    isLock = !isLock
    if isLock:
        lockOn.visible = true
        lockOff.visible = false
        DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
        get_window().position = Vector2(get_window().position.x + 9, get_window().position.y + 31)
    else:
        lockOn.visible = false
        lockOff.visible = true
        DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
        get_window().position = Vector2(get_window().position.x - 9, get_window().position.y - 31)

func create_input_map():
    # Clean
    InputMap.erase_action("add")
    InputMap.erase_action("sub")
    
    # File
    var keycodeAdd = 4194437
    var keycodeSub = 4194435
    if FileAccess.file_exists(exePath + "/keybinds.txt"):
        var file = FileAccess.open(exePath + "/keybinds.txt", FileAccess.READ)
        keycodeAdd = int(file.get_line())
        keycodeSub = int(file.get_line())
    
    # Add New Inputs
    var keyAdd = InputEventKey.new()
    var keySub = InputEventKey.new()
    keyAdd.physical_keycode = keycodeAdd
    keySub.physical_keycode = keycodeSub
    InputMap.add_action("add", 0.5)
    InputMap.action_add_event("add", keyAdd)
    InputMap.add_action("sub", 0.5)
    InputMap.action_add_event("sub", keySub)
    
    GlobalInput._initialize_global_input_c_sharp()
