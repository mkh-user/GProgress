@tool
extends EditorPlugin

var panel = preload("res://addons/GProgress/Panels/Button Panel/panel.tscn").instantiate()

func _enter_tree():
	add_control_to_bottom_panel(panel, "GProgress")


func _exit_tree():
	remove_control_from_bottom_panel(panel)
