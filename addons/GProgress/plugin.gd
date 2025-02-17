@tool
extends EditorPlugin

var panel: Control = preload("res://addons/GProgress/Panels/Button Panel/panel.tscn").instantiate()

func _enter_tree() -> void:
	add_control_to_container(EditorPlugin.CONTAINER_PROJECT_SETTING_TAB_RIGHT, panel)
	add_autoload_singleton("GPro", "res://addons/GProgress/GPro/GProgress.gd")


func _exit_tree()-> void :
	remove_control_from_container(EditorPlugin.CONTAINER_PROJECT_SETTING_TAB_RIGHT, panel)
	remove_autoload_singleton("GPro")

func _get_plugin_name() -> String:
	return "GProgress"

func _get_plugin_icon() -> Texture2D:
	return load("res://addons/GProgress/GPro.svg")
