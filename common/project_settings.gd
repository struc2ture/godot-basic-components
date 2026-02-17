@tool

extends EditorScript

var viewport_width = 640
var viewport_height = 480
var window_width = 1920
var window_height = 1080
var fullscreen: bool = false

var screen_i: int = 1

var override_splash: bool = true
var splash_time = null

func _run() -> void:
	ProjectSettings.set_setting("display/window/size/viewport_width", viewport_width)
	ProjectSettings.set_setting("display/window/size/viewport_height", viewport_height)
	ProjectSettings.set_setting("display/window/size/window_width_override", window_width)
	ProjectSettings.set_setting("display/window/size/window_height_override", window_height)
	
	ProjectSettings.set_setting("display/window/stretch/mode", "viewport")
	
	
	ProjectSettings.set_setting("display/window/size/mode", DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	
	if override_splash:
		ProjectSettings.set_setting("application/boot_splash/image", "res://common/struc_ture.png")
		ProjectSettings.set_setting("application/boot_splash/bg_color", Color(0.196, 0.024, 0.035))
		ProjectSettings.set_setting("application/boot_splash/stretch_mode", "disabled")
		ProjectSettings.set_setting("application/boot_splash/minimum_display_time", splash_time)
	else:
		ProjectSettings.set_setting("application/boot_splash/image", null)
		ProjectSettings.set_setting("application/boot_splash/bg_color", null)
		ProjectSettings.set_setting("application/boot_splash/stretch_mode", null)
		ProjectSettings.set_setting("application/boot_splash/minimum_display_time", null)

		
	ProjectSettings.save()
	
	var settings = EditorInterface.get_editor_settings()
	settings.set_setting("run/window_placement/screen", screen_i)
