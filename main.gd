extends Node2D

## Manual bench for the macOS fullscreen cursor bug (godotengine/godot#76038).
## Switch window mode and mouse mode at runtime, so one build covers every case.

var _label: Label

const WINDOW_MODES := {
	KEY_1: [DisplayServer.WINDOW_MODE_WINDOWED, "WINDOWED"],
	KEY_2: [DisplayServer.WINDOW_MODE_FULLSCREEN, "FULLSCREEN"],
	KEY_3: [DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN, "EXCLUSIVE_FULLSCREEN"],
}

const MOUSE_MODES := {
	KEY_V: [Input.MOUSE_MODE_VISIBLE, "VISIBLE"],
	KEY_H: [Input.MOUSE_MODE_HIDDEN, "HIDDEN"],
	KEY_C: [Input.MOUSE_MODE_CAPTURED, "CAPTURED"],
	KEY_N: [Input.MOUSE_MODE_CONFINED, "CONFINED"],
}

const SHAPES := {
	KEY_A: [Input.CURSOR_ARROW, "ARROW (custom magenta)"],
	KEY_S: [Input.CURSOR_IBEAM, "IBEAM (system)"],
	KEY_D: [Input.CURSOR_POINTING_HAND, "POINTING_HAND (system)"],
}


func _ready() -> void:
	Input.set_custom_mouse_cursor(_make_cursor(), Input.CURSOR_ARROW, Vector2(24, 24))

	var layer := CanvasLayer.new()
	add_child(layer)
	_label = Label.new()
	_label.position = Vector2(40, 40)
	_label.add_theme_font_size_override("font_size", 26)
	layer.add_child(_label)
	_refresh()


## Build the cursor in code, so the project needs no imported asset.
func _make_cursor() -> ImageTexture:
	var size := 48
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var radius := size / 2.0 - 2.0
	for y in size:
		for x in size:
			var dx := x - size / 2.0
			var dy := y - size / 2.0
			var inside := dx * dx + dy * dy <= radius * radius
			img.set_pixel(x, y, Color(1, 0, 1, 1) if inside else Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key: int = event.keycode

	if key == KEY_ESCAPE:
		get_tree().quit()
	elif WINDOW_MODES.has(key):
		DisplayServer.window_set_mode(WINDOW_MODES[key][0])
		print("window mode -> ", WINDOW_MODES[key][1])
	elif MOUSE_MODES.has(key):
		Input.mouse_mode = MOUSE_MODES[key][0]
		print("mouse mode -> ", MOUSE_MODES[key][1])
	elif SHAPES.has(key):
		Input.set_default_cursor_shape(SHAPES[key][0])
		print("cursor shape -> ", SHAPES[key][1])
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	var win := "?"
	for k in WINDOW_MODES:
		if WINDOW_MODES[k][0] == DisplayServer.window_get_mode():
			win = WINDOW_MODES[k][1]
	var mouse := "?"
	for k in MOUSE_MODES:
		if MOUSE_MODES[k][0] == Input.mouse_mode:
			mouse = MOUSE_MODES[k][1]
	_label.text = "\n".join([
		"macOS cursor bench  (godot#76038)",
		"",
		"window mode : %s" % win,
		"mouse mode  : %s" % mouse,
		"",
		"1 windowed   2 fullscreen   3 exclusive fullscreen",
		"V visible    H hidden       C captured   N confined",
		"A arrow(magenta)  S ibeam   D pointing hand",
		"ESC quit",
		"",
		"Move the pointer to the top of the screen, then back down.",
	])
