@tool
extends Control

@onready var n_tab: TabContainer = $Scroll/Tab

@onready var n_user_slots: SpinBox = $"Scroll/Tab/User Settings/user_slots"
@onready var n_user_parameters: LineEdit = $"Scroll/Tab/User Settings/user_parameters"
@onready var n_limit_per_user: SpinBox = $"Scroll/Tab/User Settings/limit_per_user"

@onready var n_progress_parameters: LineEdit = $"Scroll/Tab/Progress Settings/progress_parameters"
@onready var n_preview_parameters: LineEdit = $"Scroll/Tab/Progress Settings/preview_parameters"

@onready var n_autosave_interval: SpinBox = $"Scroll/Tab/Save & Backup/autosave_interval"
@onready var n_autosave_interval_mode: OptionButton = $"Scroll/Tab/Save & Backup/autosave_interval2"
@onready var n_save_path: Label = $"Scroll/Tab/Save & Backup/SavePath2"
@onready var n_save_path_action: Button = $"Scroll/Tab/Save & Backup/save_path"
@onready var n_backup_interval: SpinBox = $"Scroll/Tab/Save & Backup/backup_interval"
@onready var n_backup_interval_mode: OptionButton = $"Scroll/Tab/Save & Backup/backup_interval2"
@onready var n_backup_path: Label = $"Scroll/Tab/Save & Backup/BackupPath2"
@onready var n_backup_path_action: Button = $"Scroll/Tab/Save & Backup/backup_path"
@onready var n_compression: CheckBox = $"Scroll/Tab/Save & Backup/compression"
@onready var n_compression_disable: CheckBox = $"Scroll/Tab/Save & Backup/compression2"
@onready var n_encryption: CheckBox = $"Scroll/Tab/Save & Backup/encryption"
@onready var n_encryption_disable: CheckBox = $"Scroll/Tab/Save & Backup/encryption2"

const CONFIG_FILE = "res://addons/GProgress/config.txt"

var config := """user_slots:3
user_parameters:id, index, name, last_open, last_save
limit_per_user:50
progress_parameters:id, index, name, detailes, date, time, tag
preview_parameters:name, detailes, date, time, tag
autosave_interval:1m
save_path:user://GProgress/Saves/
backup_interval:3m
backup_path:user://GProgress/Backups/
compression:1
encryption:1"""

var config_list: Array

var config_dictionary: Dictionary

const config_parameters := [
	"user_slots",
	"user_parameters",
	"limit_per_user",
	"progress_parameters",
	"preview_parameters",
	"autosave_interval",
	"save_path",
	"backup_interval",
	"backup_path",
	"compression",
	"encryption",
]

enum {
	AUTOSAVE_NONE,
	AUTOSAVE_DAY,
	AUTOSAVE_WEEK,
	AUTOSAVE_MONTH,
	AUTOSAVE_YEAR,
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
		var file = FileAccess.open(CONFIG_FILE, FileAccess.READ)
		config = file.get_as_text()
		file.close()
	else:
		var file = FileAccess.open(CONFIG_FILE, FileAccess.WRITE)
		file.store_string(config)
		file.close()
	config_list = config.split("\n")
	for configure in config_list:
		for param in config_parameters:
			if configure.begins_with(param + ":"):
				if configure.begins_with("save_path:") or configure.begins_with("backup_path:"):
					config_dictionary[param] = configure.split(":")[1] + ":" + configure.split(":")[2]
					continue
				config_dictionary[param] = configure.split(":")[1]
	if config_parameters.size() != config_dictionary.keys().size():
		printerr("[GProgress] [Config] [GPP] invalid formation in config file export!")
	
	update_ui()

func update_ui():
	n_user_slots.value = int(config_dictionary["user_slots"])
	
	n_user_parameters.text = config_dictionary["user_parameters"]
	
	n_limit_per_user.value = int(config_dictionary["limit_per_user"])
	
	n_progress_parameters.text = config_dictionary["progress_parameters"]
	
	n_preview_parameters.text = config_dictionary["preview_parameters"]
	
	if config_dictionary["autosave_interval"].ends_with("n"):
		n_autosave_interval_mode.selected = 0
		autosave_mode = AUTOSAVE_NONE
	elif config_dictionary["autosave_interval"].ends_with("d"):
		n_autosave_interval_mode.selected = 2
		autosave_mode = AUTOSAVE_DAY
	elif config_dictionary["autosave_interval"].ends_with("w"):
		n_autosave_interval_mode.selected = 3
		autosave_mode = AUTOSAVE_WEEK
	elif config_dictionary["autosave_interval"].ends_with("m"):
		n_autosave_interval_mode.selected = 4
		autosave_mode = AUTOSAVE_MONTH
	elif config_dictionary["autosave_interval"].ends_with("y"):
		n_autosave_interval_mode.selected = 5
		autosave_mode = AUTOSAVE_YEAR
	else:
		printerr("[GProgress] [Config] [GPP] invalid mode for auto-save interval!")
	
	n_autosave_interval.value = int(config_dictionary["autosave_interval"].erase(config_dictionary["autosave_interval"].length() - 1))
	
	n_save_path.text = config_dictionary["save_path"]
	
	if config_dictionary["backup_interval"].ends_with("n"):
		n_backup_interval_mode.selected = 0
		backup_mode = BACKUP_NONE
	elif config_dictionary["backup_interval"].ends_with("d"):
		n_backup_interval_mode.selected = 2
		backup_mode = BACKUP_DAY
	elif config_dictionary["backup_interval"].ends_with("w"):
		n_backup_interval_mode.selected = 3
		backup_mode = BACKUP_WEEK
	elif config_dictionary["backup_interval"].ends_with("m"):
		n_backup_interval_mode.selected = 4
		backup_mode = BACKUP_MONTH
	elif config_dictionary["backup_interval"].ends_with("y"):
		n_backup_interval_mode.selected = 5
		backup_mode = BACKUP_YEAR
	else:
		printerr("[GProgress] [Config] [GPP] invalid mode for backup interval!")
	
	n_backup_interval.value = int(config_dictionary["backup_interval"].erase(config_dictionary["backup_interval"].length() - 1))
	
	n_backup_path.text = config_dictionary["backup_path"]
	
	if bool(int(config_dictionary["compression"])):
		n_compression.button_pressed = true
	else:
		n_compression_disable.button_pressed = true
	
	if bool(int(config_dictionary["encryption"])):
		n_encryption.button_pressed = true
	else:
		n_encryption_disable.button_pressed = true
	
