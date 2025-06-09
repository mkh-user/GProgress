@icon("res://addons/GProgress/GPro.svg")
@tool
class_name GProgressPanel
extends Control

@export var n_tab: TabContainer
@export var n_dialoge_save_path: FileDialog
@export var n_dialoge_backup_path: FileDialog

@export var n_user_slots: SpinBox
@export var n_profile_parameters: LineEdit
@export var n_limit_per_user: SpinBox

@export var n_progress_parameters: LineEdit
@export var n_preview_parameters: LineEdit

@export var n_autosave_interval: SpinBox
@export var n_autosave_interval_mode: OptionButton
@export var n_save_path: Label
@export var n_save_path_action: Button
@export var n_backup_interval: SpinBox
@export var n_backup_interval_mode: OptionButton
@export var n_backup_path: Label
@export var n_backup_path_action: Button
@export var n_compression: CheckBox
@export var n_compression_disable: CheckBox
@export var n_encryption: CheckBox
@export var n_encryption_disable: CheckBox
@export var n_encryption_key: LineEdit

const CONFIG_FILE = "res://GProgressConfig.txt"

var config := """user_slots:3
profile_parameters:id, index, name, last_open, last_save
limit_per_user:50
progress_parameters:id, index, name, details, date, time, tags
preview_parameters:id, index, name, date, time, tags
autosave_interval:30m
save_path:user://GProgress/Saves
backup_interval:1m
backup_path:user://GProgressBackups
compression:1
encryption:1
encryption_key:q3@g.<9gF[JK-%qqAscBcf,>?k*lOpse"""

var config_list: Array

var config_dictionary: Dictionary

const config_parameters := [
	"user_slots",
	"profile_parameters",
	"limit_per_user",
	"progress_parameters",
	"preview_parameters",
	"autosave_interval",
	"save_path",
	"backup_interval",
	"backup_path",
	"compression",
	"encryption",
	"encryption_key",
]

enum {
	AUTOSAVE_NONE,
	AUTOSAVE_SECOND,
	AUTOSAVE_MINUTE,
	AUTOSAVE_HOUR,
}

enum {
	BACKUP_NONE,
	BACKUP_DAY,
	BACKUP_WEEK,
	BACKUP_MONTH,
	BACKUP_YEAR,
}

var autosave_mode = AUTOSAVE_NONE
var backup_mode = BACKUP_NONE

func _ready():
	if FileAccess.file_exists(CONFIG_FILE):
		_load_config()
	else:
		_save_config()
	config_list = config.split("\n", false)
	for configure: String in config_list:
		for param in config_parameters:
			if configure.begins_with(param + ":"):
				config_dictionary[param] = configure.split(":", false, 1)[1]
	if config_parameters.size() != config_dictionary.keys().size():
		printerr("[GProgress] [Config] [GPP] invalid formation in config file export!")
	update_ui()


func update_ui():
	n_user_slots.value = int(config_dictionary.user_slots)
	n_profile_parameters.text = config_dictionary.profile_parameters
	n_limit_per_user.value = int(config_dictionary.limit_per_user)
	n_progress_parameters.text = config_dictionary.progress_parameters
	n_preview_parameters.text = config_dictionary.preview_parameters
	if config_dictionary.autosave_interval.ends_with("n"):
		n_autosave_interval_mode.selected = 0
		autosave_mode = AUTOSAVE_NONE
	elif config_dictionary.autosave_interval.ends_with("s"):
		n_autosave_interval_mode.selected = 2
		autosave_mode = AUTOSAVE_SECOND
	elif config_dictionary.autosave_interval.ends_with("m"):
		n_autosave_interval_mode.selected = 3
		autosave_mode = AUTOSAVE_MINUTE
	elif config_dictionary.autosave_interval.ends_with("h"):
		n_autosave_interval_mode.selected = 4
		autosave_mode = AUTOSAVE_HOUR
	else:
		printerr("[GProgress] [Config] [GPP] invalid mode for auto-save interval!")
	n_autosave_interval.value = int(config_dictionary.autosave_interval.erase(config_dictionary.autosave_interval.length() - 1))
	n_save_path.text = config_dictionary.save_path
	if config_dictionary.backup_interval.ends_with("n"):
		n_backup_interval_mode.selected = 0
		backup_mode = BACKUP_NONE
	elif config_dictionary.backup_interval.ends_with("d"):
		n_backup_interval_mode.selected = 2
		backup_mode = BACKUP_DAY
	elif config_dictionary.backup_interval.ends_with("w"):
		n_backup_interval_mode.selected = 3
		backup_mode = BACKUP_WEEK
	elif config_dictionary.backup_interval.ends_with("m"):
		n_backup_interval_mode.selected = 4
		backup_mode = BACKUP_MONTH
	elif config_dictionary.backup_interval.ends_with("y"):
		n_backup_interval_mode.selected = 5
		backup_mode = BACKUP_YEAR
	else:
		printerr("[GProgress] [Config] [GPP] invalid mode for backup interval!")
	n_backup_interval.value = int(config_dictionary.backup_interval.erase(config_dictionary.backup_interval.length() - 1))
	n_backup_path.text = config_dictionary.backup_path
	if bool(int(config_dictionary.compression)):
		n_compression.button_pressed = true
	else:
		n_compression_disable.button_pressed = true
	if bool(int(config_dictionary.encryption)):
		n_encryption.button_pressed = true
	else:
		n_encryption_disable.button_pressed = true
	n_encryption_key.text = config_dictionary.encryption_key

func update_dict():
	config_dictionary.user_slots = str(n_user_slots.value)
	config_dictionary.profile_parameters = n_profile_parameters.text
	config_dictionary.limit_per_user = str(n_limit_per_user.value)
	config_dictionary.progress_parameters = n_progress_parameters.text
	config_dictionary.preview_parameters = n_preview_parameters.text
	config_dictionary.autosave_interval = str(n_autosave_interval.value)
	var append = ""
	match n_autosave_interval_mode.selected:
		0:
			append = "n"
		2:
			append = "s"
		3:
			append = "m"
		4:
			append = "h"
		_:
			printerr("[GProgress] [Config] [GPP] invalid mode for autosave interval!")
	config_dictionary.autosave_interval += append
	config_dictionary.save_path = n_save_path.text
	config_dictionary.backup_interval = str(n_backup_interval.value)
	append = ""
	match n_backup_interval_mode.selected:
		0:
			append = "n"
		2:
			append = "d"
		3:
			append = "w"
		4:
			append = "m"
		5:
			append = "y"
		_:
			printerr("[GProgress] [Config] [GPP] invalid mode for backup interval!")
	config_dictionary.backup_interval += append
	config_dictionary.backup_path = n_backup_path.text
	match n_compression.button_pressed:
		true:
			config_dictionary.compression = "1"
		false:
			config_dictionary.compression = "0"
	match n_encryption.button_pressed:
		true:
			config_dictionary.encryption = "1"
		false:
			config_dictionary.encryption = "0"
	config_dictionary.encryption_key = n_encryption_key.text
	while config_dictionary.encryption_key.length() < 32:
		config_dictionary.encryption_key += "?"


func _on_save_changes(value):
	await update_dict()
	config = ""
	for configure in config_parameters:
		config += configure + ":" + config_dictionary[configure] + "\n"
	_save_config()


func _on_save_changes_2():
	await update_dict()
	config = ""
	for configure in config_parameters:
		config += configure + ":" + config_dictionary[configure] + "\n"
	_save_config()


func _on_open_file_pressed():
	OS.shell_open(ProjectSettings.globalize_path(CONFIG_FILE))


func _on_reset_to_defaults_pressed():
	config = """user_slots:3
profile_parameters:id, index, name, last_open, last_save
limit_per_user:50
progress_parameters:id, index, name, details, date, time, tags
preview_parameters:id, index, name, date, time, tags
autosave_interval:30m
save_path:user://GProgress/Saves
backup_interval:1m
backup_path:user://GProgressBackups
compression:1
encryption:1
encryption_key:q3@g.<9gF[JK-%qqAscBcf,>?k*lOpse"""
	_save_config()
	_ready()


func _on_reload_from_file_pressed():
	_ready()


func _on_save_path_pressed():
	n_dialoge_save_path.show()


func _on_backup_path_pressed():
	n_dialoge_backup_path.show()


func _on_save_path_dir_selected(dir):
	n_save_path.text = dir


func _on_backup_path_dir_selected(dir):
	n_backup_path.text = dir

func _load_config():
	var file = FileAccess.open(CONFIG_FILE, FileAccess.READ)
	config = file.get_as_text()
	file.close()

func _save_config():
	var file = FileAccess.open(CONFIG_FILE, FileAccess.WRITE)
	file.store_string(config)
	file.close()
