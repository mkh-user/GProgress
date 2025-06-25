@icon("res://addons/GProgress/GPro.svg")
class_name GProgress
extends Node

## GProgress Plugin Documentation[br]
## [color=ffde66]Experimental:[/color] You currently have a version that's in test steps, please 
## report any issue in project repo!
## @experimental: This version is an beta version!
## 
## [b][url=https://github.com/mkh-user/GProgress]Official Repo[/url][/b][br]
## MIT 2025 Mahan Khalili[br]
## [i]Version: 0.2.0-beta-1[/i][br][br]
##
## The GProgress plugin is designed to help developers manage player progress in
## their games. With this plugin, you can easily save, load, and manage multiple 
## players' progress using custom clients, signals, and functions.[br]
## This script added automaticly to your project when GProgress plugin is 
## activated and you can use it with [code]GPro[/code].[br][br]
##
## [b]Note:[/b] If plugin isn't initialized, all function with Error return type 
## returns [code]ERR_CANT_CONNECT[/code] and other functions set last error to 
## this error code. Use [code]GPro.is_initialized(true)[/code] for initializing. Example setup code:
## [codeblock]
## func _ready() -> void:
##     # when plugin wasn't initialized, this function with param true will return false and initialize plugin
##     if not GPro.is_initialized(true):
##         GPro.restart() # after initializing GPro needs restart
## [/codeblock][br]
## [b]Note:[/b] Some signals have [color=lightblue][b]GPClient Signal[/b][/color] badge, this 
## signals designed for create optional GPClient, see tutorials to learn create GPClient.[br][br]
## [b]Note:[/b] Some functions have [color=dark_turquoise][b]Internal[/b][/color] badge, this
## functions are just for call from plugin and you can see them here just for more explanation about
## plugin logic, please don't use them!
## 
## [br][br][b]Note:[/b] Documentation in [b]Alpha[/b] & [b]Beta[/b] [color=ffde66]is not 
## updated[/color]; Please report any bug in project repo![br]
## 
## @tutorial(GProgress Demos: Official demos and tutorials):	https://mkh-user.github.io/GProgress-Demos
## @tutorial(،	├ Initial tour):								https://mkh-user.github.io/GProgress-Demos/Initial%20tour/Step%201
## @tutorial(،	└ Default Setup Method - Recommended):			https://mkh-user.github.io/GProgress-Demos/Default%20Setup%20Method/Installing

## [color=lightblue][b]GPClient Signal[/b][/color][br]
signal autosave_request(uuid: String, last_save: String)
## [color=lightblue][b]GPClient Signal[/b][/color][br] 
signal backup_successful(uuid: String) 
## [color=lightblue][b]GPClient Signal[/b][/color][br] 
signal backup_failed(uuid: String, error_code: Error) 
## [color=lightblue][b]GPClient Signal[/b][/color][br]
## Emit when an error happend in plugin withuot error handling system (All functions with 
## [method get_last_error] for debugging system), other functions will return an [enum Error] code.
signal error_occurred(error_code: Error)

# File path for configuration file
const _CONFIG_FILE: String = "res://GProgressConfig.txt"
# File path for save users file
const _USERS_FILE: String = "user://GProgress/Users.file"

# Store config dictionary
var _config: Dictionary
# Store temprory string from config file
var _config_text: String
# Store users dictionary in UUID (String): parameters (Dictionary)
var _users: Dictionary
# Store user pfile keys
var _user_profile: Array
# Store error in functions
var _err: Error:
	set(value):
		# Call error_occurred signal when new value isn't OK
		if value != OK:
			error_occurred.emit(value)
# Store user parameters for logined user
var _logined_user: Dictionary
# Store crash status
var _killed: bool = false:
	set(value):
		# Push error at crash time
		if value:
			push_error("[GProgress] [Montoring] [GPro] [ERROR] Plugin crashed, all its services were stopped until the next run of the game or restart the plugin!")
		# Push message at restore time
		elif not _killed:
			push_warning("[GProgress] [Montoring] [GPro] [MESSAGE] Plugin restore has been successful, all its services are available again!")
	get():
		# Push error when try using plugin if plugin is crashed
		if _killed:
			push_error("[GProgress] [Montoring] [GPro] [ERROR] Try to use Plugin services, all its services not available now!")
			return true
		return false
# Use a variable for all save temprory data
# NOTE: Use _clear_memory() every time
var _memory_space: Array

#region Base

## [color=dark_turquoise][b]Internal[/b][/color][br]
## Activates the plugin before running the projects.
func _init() -> void:
	print_rich("[color=83878c]--- Start GProgress Serivces ---[/color]")
	_err = _open_config() # get error message for load config
	if _err:
		printerr("[GProgress] [Config] [GPro] [FATAL] An error occurred while load configurations; Error code: " + str(_err))
		_killed = true
		return
	if not is_initialized():
		push_error("[GProgress] [Initialize] [GPro] [WARNING] GProgress is not initialized; Please use GPro.initilize() one time.")
		_killed = true
		return
	_memory_space[0] = _config_text.split("\n", false)
	for configure: String in _memory_space[0]:
		_memory_space[1] = configure.split(":", false, 1) # Use split limitation for file path
		_config[_memory_space[1][0]] = _memory_space[1][1]
	_clear_memory()
	_config.progress_parameters = _remove_white_spaces(_config.progress_parameters)
	_config.profile_parameters = _remove_white_spaces(_config.profile_parameters)


## Restarts the plugin. Will call [method _init] and check its effect.
## When [param reset_when_failed] is [code]true[/code] will reset config file data to default value.
## (needs Admin access)
func restart(reset_when_failed: bool = false) -> void:
	if _killed:
		printerr("[GProgress] [Main] [GPro] [MESSAGE] Trying to restart and fix bugs.")
	_init() # Restart
	await get_tree().create_timer(0.5).timeout # Delay
	if _killed:
		printerr("[GProgress] [Main] [GPro] [ERROR] Restart had no effect!")
		if reset_when_failed:
			GProgressPanel.new().reset_config.emit()
			printerr("[GProgress] [Config] [GPro] [MESSAGE] Config was reset!")
			restart()


## Checks plugin initialization, will return [code]true[/code] if plugin is initialized.
## When plugin isn't initialized and [param initialize_if_not] is [code]true[/code] will call 
## [method _initialize].
func is_initialized(initialize_if_not: bool = false) -> bool:
	if GPFile.file_exists(_USERS_FILE):
		return true
	else:
		if initialize_if_not: _initialize()
		return false


## [color=dark_turquoise][b]Internal[/b][/color][br]
## Initializes the plugin with create a file for users' data.
func _initialize() -> Error:
	return _save_file(_USERS_FILE, {})


func _open_config() -> Error:
	if not GPFile.file_exists(_CONFIG_FILE):
		return ERR_DOES_NOT_EXIST
	var file: FileAccess = GPFile.open(_CONFIG_FILE, FileAccess.READ)
	_config_text = file.get_as_text()
	file.close()
	return GPFile.get_error()

#endregion


#region Tools

func _clear_memory() -> void:
	_memory_space.clear()


func _save_file(path: String, value: Variant) -> Error:
	# Make directory if does not exists
	if not GPFile.dir_exists(path.get_base_dir()):
		GPFile.make_dir(path.get_base_dir())
	var file: FileAccess = GPFile.open(path, FileAccess.WRITE)
	var _error: Error = GPFile.get_error()
	file.store_var(value)
	file.close()
	return _error


func _load_file(path: String, defalut_value: Variant = null) -> Variant:
	if not GPFile.file_exists(path):
		printerr("[GProgress] [File Manager] [GPro] File does not exist!")
		return defalut_value
	var file: FileAccess = GPFile.open(path, FileAccess.READ)
	var value: Variant = file.get_var()
	file.close()
	return value


# Remove all spaces from text string
func _remove_white_spaces(text: String) -> String:
	while text.find(" ") != -1:
		text = text.erase(text.find(" "))
	return text


## Returns true if all slots are full.
func slots_are_full() -> bool:
	return _users.keys().size() >= int(_config.user_slots)


# Returns days from YYYY-MM-DD format
func _get_days(date: String) -> int:
	var days: int = int(date.get_slice("-", 2))
	days += int(date.get_slice("-", 1)) * 30
	days += int(date.get_slice("-", 0)) * 365
	return days


# Returns true if UUID exists in current UUIDs
func _invalid_uuid(uuid: String) -> bool:
	return not uuid in _users.keys()


# Returns false if parameter key exists in user profile
func _invalid_profile_parameter(key: String) -> bool:
	if not _auth(): return true
	return not key in _users[_logined_user.uuid].keys()


# Returns true if a user is logined
func _auth() -> bool:
	if _logined_user != {}:
		return not _invalid_uuid(_logined_user.uuid)
	else: return false


# Returns false if parameter key exists in progress parameters
func _invalid_progress_parameter(key: String) -> bool:
	return not key in _config.progress_parameters.split(",", false)


# Returns date time string from system in YYYY-MM-DD HH:MM:SS format
func _get_datetime() -> String:
	return Time.get_datetime_string_from_system(false, true)


# Load users file
func _load_users() -> Error:
	_users = _load_file(_USERS_FILE, {})
	return GPFile.get_error()


# Save users file
func _save_users() -> Error:
	return _save_file(_USERS_FILE, _users)

#endregion


#region User Manager

## Adds a new user, will return [constant ERR_UNAVAILABLE] if all slots are full.
func create_user(profile: Dictionary) -> Error:
	if _killed: return ERR_CANT_CONNECT
	if _load_users(): return _load_users()
	if slots_are_full(): return ERR_UNAVAILABLE
	if _auth(): _logined_user = {}
	profile.uuid = _get_valid_uuid()
	_clear_memory()
	_user_profile = _config.profile_parameters.split(",", false)
	var _new_user: Dictionary
	for profile_key: String in _user_profile:
		if (not profile.has(profile_key)) or _invalid_profile_parameter(profile_key): continue
		_new_user[profile_key] = profile[profile_key]
	_users[profile.uuid] = _new_user
	return _save_users()


## Returns count of users, you can use it for UI setup. (see also [method slots_are_full])
func get_users_count() -> int:
	return get_user_uuids().size()


# Returns a new UUID
func _get_valid_uuid() -> String:
	_memory_space[0] = false
	_memory_space[1] = ""
	while not _memory_space[0]:
		_memory_space[1] = ""
		for i: int in range(8):
			_memory_space[1] += str(randi_range(0, 9))
		_memory_space[0] = get_user_uuids().find(_memory_space[1]) == -1
	if _memory_space[1] == "": get_tree().quit(1)
	return _memory_space[1]


## Deletes currently logined user.
func remove_user() -> Error:
	if _killed: return ERR_CANT_CONNECT
	if _load_users(): return _load_users()
	if not _auth(): return ERR_UNAUTHORIZED
	_users.erase(_logined_user.uuid)
	var user_saves: String = GPFile.globalize_path(str(_config.save_path.join_path(_logined_user.uuid)))
	if GPFile.dir_exists(user_saves):
		var _error: Error = GPFile.remove_dir(user_saves)
		if _error: return _error
	return _save_users()


## Returns an array from any users' uuid.
func get_user_uuids() -> Array:
	_err = OK
	if _killed:
		_err = ERR_CANT_CONNECT
		return []
	if _load_users():
		_err = GPFile.get_error()
		return []
	return _users.keys()

#endregion


#region User Profile

## Returns a dictionary from all users with their profiles based on uuids.
func get_all_profiles() -> Dictionary:
	_err = OK
	if _killed:
		_err = ERR_CANT_CONNECT
		return {}
	if _load_users():
		_err = _load_users()
		return {}
	return _users


## Returns a dictionary from specified profile parameter in all user configs by users' uuid.
## Useful for sort and search actions.
func get_parameter_in_all_profiles(key: String) -> Dictionary:
	_err = OK
	if _killed:
		_err = ERR_CANT_CONNECT
		return {}
	if _load_users():
		_err = _load_users()
		return {}
	var parameters: Dictionary = {}
	for id: String in _users.keys():
		parameters[id] = _users[id][key]
	return parameters


## Returns a dictionary from profile for user with [param uuid].
func get_profile(uuid: String) -> Dictionary:
	_err = OK
	if _killed:
		_err = ERR_CANT_CONNECT
		return {}
	if _load_users():
		_err = _load_users()
		return {}
	if _invalid_uuid(uuid):
		_err = ERR_DOES_NOT_EXIST
		return {}
	return _users[uuid]


## Updates profile for user with [param uuid] from a dictionary, will keep [code]"id", "last_open", "last_save"[/code]
## values.
func update_profile(uuid: String, parameters: Dictionary) -> Error:
	if _killed: return ERR_CANT_CONNECT
	if _load_users(): return _load_users()
	if _invalid_uuid(uuid): return ERR_DOES_NOT_EXIST
	for key: String in parameters.keys():
		if key in ["uuid", "last_open", "last_save"]:
			continue
		if _invalid_profile_parameter(key): return ERR_INVALID_PARAMETER
		_users[uuid][key] = parameters[key]
	return _save_users()

#endregion


#region Authentication

## Modify [code]last_open[/code] parameter in target user's profile and emit autosave signal & 
## backup function if need.
func login_user(uuid: String) -> Error:
	if _killed: return ERR_CANT_CONNECT
	if _load_users(): return _load_users()
	if _invalid_uuid(uuid): return ERR_DOES_NOT_EXIST
	if _users[uuid].has("last_open"):
		_users[uuid].last_open = _get_datetime()
	if check_autosave_time() and _invalid_profile_parameter("last_save"):
		autosave_request.emit(uuid, _users[uuid].last_save)
	if check_backup_time(uuid):
		backup_progress()
	_logined_user = _users[uuid]
	_logined_user.uuid = uuid
	return _save_users()


## Check for autosave and backup and logout currently logined user.
func logout_user() -> Error:
	if _killed: return ERR_CANT_CONNECT
	if _load_users(): return _load_users()
	if not _auth(): return ERR_UNAUTHORIZED
	if check_autosave_time() and _invalid_profile_parameter("last_save"):
		autosave_request.emit(_logined_user.uuid, _users[_logined_user.uuid].last_save)
		return ERR_ALREADY_IN_USE
	if check_backup_time(_logined_user.uuid):
		backup_progress()
		return ERR_ALREADY_IN_USE
	_logined_user = {}
	return OK


## Returns uuid for currently logined user or [code]""[/code].
func get_logined_user_uuid() -> String:
	if _killed:
		_err = ERR_CANT_CONNECT
		return ""
	if _load_users():
		_err = _load_users()
		return ""
	return _logined_user.uuid

#endregion


#region Progress Manager

## Saves new progress for currently logined user.
func save_progress(parameters: Dictionary, auto_datetime: bool = true) -> Error:
	if _killed: return ERR_CANT_CONNECT
	if _load_users(): return _load_users()
	if not _auth(): return ERR_UNAUTHORIZED
	if _invalid_uuid(_logined_user.uuid): return ERR_DOES_NOT_EXIST
	var progress: Dictionary = {}
	for key: String in parameters.keys():
		if _invalid_progress_parameter(key): continue
		progress[key] = parameters[key]
	progress.upid = get_last_upid() + 1
	if auto_datetime:
		if not _invalid_progress_parameter("date"):
			progress.date = Time.get_date_string_from_system()
		if not _invalid_progress_parameter("time"):
			progress.time = Time.get_time_string_from_system()
	_err = _save_progress(progress)
	if not _err:
		var progresses_count: int = GPFile.get_files(GPFile.globalize_path(str(_config.save_path).get_base_dir().path_join(_logined_user.uuid))).size()
		if progresses_count > _config.limit_per_user and _config.limit_per_user != 0:
			var folder: String = GPFile.globalize_path(str(_config.save_path)).get_base_dir().path_join(_logined_user.uuid)
			var older_file: String = GPFile.get_files(folder)[0]
			_err = GPFile.remove_dir(older_file)
		_users[_logined_user.uuid].last_save = _get_datetime()
		return _save_users()
	return _err


## Load specified progress from currently logined user.
func load_progress(upid: int) -> Dictionary:
	_err = OK
	if _killed:
		_err = ERR_CANT_CONNECT
		return {}
	if _load_users():
		_err = _load_users()
		return {}
	if not _auth():
		_err = ERR_UNAUTHORIZED
		return {}
	if _invalid_uuid(_logined_user.uuid):
		_err = ERR_DOES_NOT_EXIST
		return {}
	var save_dir: String = GPFile.globalize_path(str(_config.save_path).get_base_dir()).path_join(_logined_user.uuid)
	if not GPFile.dir_exists(save_dir):
		_err = ERR_DOES_NOT_EXIST
		return {}
	var save_path: String = save_dir.path_join("GProgressSave-{upid}.gpro".format({"upid": upid}))
	var file: FileAccess
	if _config.compression:
		file = GPFile.open_compressed(save_path, FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	else:
		file = GPFile.open(save_path, FileAccess.READ)
	if GPFile.get_error():
		_err = GPFile.get_error()
		return {}
	var encyrpted_progress: PackedByteArray = file.get_buffer(file.get_length())
	file.close()
	var json_progress: PackedByteArray = encyrpted_progress
	if _config.encryption:
		if _config.encryption_key.length() != 32:
			_err = ERR_INVALID_PARAMETER
			return {}
		var aes: AESContext = AESContext.new()
		aes.start(AESContext.MODE_CBC_DECRYPT, str(_config.encryption_key).to_utf8_buffer())
		json_progress = aes.update(encyrpted_progress)
		aes.finish()
	var progress: Dictionary = JSON.parse_string(json_progress.get_string_from_utf8())
	return progress

#region Private

func _save_progress(progress: Dictionary, in_costum_dir: bool = false, custom_dir: String = "") -> Error:
	var save_dir: String = GPFile.globalize_path(str(_config.save_path.get_base_dir())).path_join(_logined_user.uuid)
	if in_costum_dir: save_dir = custom_dir
	if not GPFile.dir_exists(save_dir.get_base_dir()):
		if GPFile.make_dir(save_dir):
			return GPFile.make_dir(save_dir)
	var save_path: String = save_dir.path_join("GProgressSave-{upid}.gpro".format({"upid": str(progress.upid)}))
	var file: FileAccess
	if _config.compression:
		file = GPFile.open_compressed(save_path, FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	else:
		file = GPFile.open(save_path, FileAccess.WRITE)
	var json_progress: String = JSON.stringify(progress, "\t", false)
	var encrypted_progress: PackedByteArray = var_to_bytes(json_progress)
	if _config.encryption:
		if _config.encryption_key.length() != 32:
			return ERR_INVALID_PARAMETER
		var aes: AESContext = AESContext.new()
		aes.start(AESContext.MODE_CBC_ENCRYPT, str(_config.encryption_key).to_utf8_buffer())
		encrypted_progress = aes.update(encrypted_progress)
		aes.finish()
	file.store_buffer(encrypted_progress)
	file.close()
	return OK


func _load_progress(path: String) -> Dictionary:
	_err = OK
	if _killed:
		_err = ERR_CANT_CONNECT
		return {}
	if _load_users():
		_err = _load_users()
		return {}
	if not _auth():
		_err = ERR_UNAUTHORIZED
		return {}
	var save_dir: String = GPFile.globalize_path(path.get_base_dir())
	if not GPFile.dir_exists(save_dir):
		_err = ERR_DOES_NOT_EXIST
		return {}
	var save_path: String = path
	var file: FileAccess
	if _config.compression:
		file = GPFile.open_compressed(save_path, FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	else:
		file = GPFile.open(save_path, FileAccess.READ)
	if GPFile.get_error():
		_err = GPFile.get_error()
		return {}
	var encyrpted_progress: PackedByteArray = file.get_buffer(file.get_length())
	file.close()
	var json_progress: PackedByteArray = encyrpted_progress
	if _config.encryption:
		if _config.encryption_key.length() != 32:
			_err = ERR_INVALID_PARAMETER
			return {}
		var aes: AESContext = AESContext.new()
		aes.start(AESContext.MODE_CBC_DECRYPT, str(_config.encryption_key).to_utf8_buffer())
		json_progress = aes.update(encyrpted_progress)
		aes.finish()
	var progress: Dictionary = JSON.parse_string(json_progress.get_string_from_utf8())
	return progress

#endregion

## Removes specified progress from progresses of currently logined user.
func remove_progress(upid: int) -> Error:
	if _killed: return ERR_CANT_CONNECT
	if _load_users(): return _load_users()
	if _invalid_uuid(_logined_user.uuid): return ERR_DOES_NOT_EXIST
	if not _auth(): return ERR_UNAUTHORIZED
	var save_dir: String = GPFile.globalize_path(str(_config.save_path).get_base_dir()).path_join(_logined_user.uuid)
	if not GPFile.dir_exists(save_dir):
		return ERR_DOES_NOT_EXIST
	var save_path: String = save_dir.path_join("GProgressSave-{upid}.gpro".format({"upid": str(upid)}))
	return GPFile.remove_dir(save_path)


## Quickly saves a progress, default parameters are automatically set even if they exist in the 
## dictionary based on configs.
func quick_progress(parameters: Dictionary) -> Error:
	if _killed: return ERR_CANT_CONNECT
	if _load_users(): return _load_users()
	if _invalid_uuid(_logined_user.uuid): return ERR_DOES_NOT_EXIST
	if not _auth(): return ERR_UNAUTHORIZED
	var progress: Dictionary = {}
	for key: String in parameters.keys():
		if _invalid_progress_parameter(key): continue
		progress[key] = parameters[key]
	progress.upid = get_last_upid() + 1
	if not _invalid_progress_parameter("name"): progress["name"] = "Quick Save"
	if not _invalid_progress_parameter("details"): progress["details"] = "There is no details."
	if not _invalid_progress_parameter("date"): progress["date"] = Time.get_date_string_from_system()
	if not _invalid_progress_parameter("time"): progress["time"] = Time.get_time_string_from_system()
	if not _invalid_progress_parameter("tags"): progress["tags"] = ["Quick Save"]
	return _save_progress(progress)

#region Backup System

## Creates a backup in backups folder.
func backup_progress(upid: int = -1) -> Error:
	if _killed:
		backup_failed.emit(_logined_user.uuid, ERR_CANT_CONNECT)
		return ERR_CANT_CONNECT
	if _load_users():
		backup_failed.emit(_logined_user.uuid, _load_users())
		return _load_users()
	if _invalid_uuid(_logined_user.uuid):
		backup_failed.emit(_logined_user.uuid, ERR_DOES_NOT_EXIST)
		return ERR_DOES_NOT_EXIST
	if not _auth():
		backup_failed.emit(_logined_user.uuid, ERR_UNAUTHORIZED)
		return ERR_UNAUTHORIZED
	if upid == -1: upid = get_last_upid()
	var last_save: Dictionary = load_progress(upid)
	var err: Error = _save_progress(last_save, true, str(_config.backup_path.path_join(_logined_user.uuid)))
	if err:
		backup_failed.emit(_logined_user.uuid, err)
		return err
	backup_successful.emit(_logined_user.uuid)
	return OK


## Loads a backup from [param backup_file].
func load_backup_progress(backup_file: String) -> Error:
	if _killed: return ERR_CANT_CONNECT
	if _load_users(): return _load_users()
	if _invalid_uuid(_logined_user.uuid): return ERR_DOES_NOT_EXIST
	if not _auth(): return ERR_UNAUTHORIZED
	var backup: Dictionary = _load_progress(backup_file)
	if backup == {}: return ERR_FILE_CANT_READ
	return save_progress(backup)


## Returns path to backup folder for currently logined user.
func get_backup_folder() -> String:
	if _killed:
		_err = ERR_CANT_CONNECT
		return ""
	if _load_users():
		_err = _load_users()
		return ""
	if not _auth():
		_err = ERR_UNAUTHORIZED
		return ""
	return _config.backup_path.path_join(_logined_user.uuid)


## Returns an array with all saved backup files in backup path in configs.
func get_backups_list() -> Array:
	if _killed:
		_err = ERR_CANT_CONNECT
		return []
	if _load_users():
		_err = _load_users()
		return []
	if not _auth():
		_err = ERR_UNAUTHORIZED
		return []
	return GPFile.get_files(_config.backup_path.path_join(_logined_user.uuid))

## @experimental
func check_backup_time(uuid: String) -> bool:
	_err = OK
	if _killed:
		_err = ERR_CANT_CONNECT
		return false
	if _load_users():
		_err = _load_users()
		return false
	if _invalid_uuid(uuid):
		_err = ERR_DOES_NOT_EXIST
		return false
	var interval: int = _get_days(Time.get_date_string_from_system())
	var correct_interval: int = int(str(_config.backup_interval).erase(str(_config.backup_inteval).length() - 1))
	match _config.backup_inteval[-1]:
		"n":
			return false
		"d":
			correct_interval *= 1
		"w":
			correct_interval *= 7
		"m":
			correct_interval *= 30
		"y":
			correct_interval *= 365
	if interval % correct_interval == 0:
		return true
	return false

#endregion

#region Statistic Manager

## Returns a dictionary from specified parameter in user progresses by date-time, date, time or 
## progress id based on configs.
func get_parameter_statistics(key: String) -> Dictionary:
	_err = OK
	if _killed:
		_err = ERR_CANT_CONNECT
		return {}
	if _load_users():
		_err = _load_users()
		return {}
	if not _auth():
		_err = ERR_UNAUTHORIZED
		return {}
	if _invalid_progress_parameter(key):
		_err = ERR_INVALID_PARAMETER
		return {}
	var use_date: bool = not _invalid_progress_parameter("date")
	var use_time: bool = not _invalid_progress_parameter("time")
	var stats: Dictionary = {}
	var progress: Dictionary
	for save: String in GPFile.get_files(GPFile.globalize_path(str(_config.save_path).get_base_dir()).path_join(_logined_user.uuid)):
		progress = _load_progress(save)
		match use_date:
			true:
				match use_time:
					true:
						stats[progress.date + "-" + progress.time] = progress[key]
					false:
						stats[progress.date] = progress[key]
			false:
				match use_time:
					true:
						stats[progress.time] = progress[key]
					false:
						stats[progress.upid] = progress[key]
	return stats


## Returns an array from all progresses for target user in order by specified key.
func get_progress_upid_by_parameter(key: String) -> Array:
	_err = OK
	if _killed:
		_err = ERR_CANT_CONNECT
		return []
	if _load_users():
		_err = _load_users()
		return []
	if not _auth():
		_err = ERR_UNAUTHORIZED
		return []
	if _invalid_progress_parameter(key):
		_err = ERR_INVALID_PARAMETER
		return []
	var record: Dictionary = {}
	var progress: Dictionary
	for save: String in GPFile.get_files(GPFile.globalize_path(str(_config.save_path).get_base_dir()).path_join(_logined_user.uuid)):
		progress = _load_progress(save)
		record[progress.upid] = progress
	var sorted_keys: Array = record.keys()
	sorted_keys.sort_custom(func sorter(a: Dictionary, b: Dictionary) -> bool: return record[a][key] < record[b][key])
	return sorted_keys


## Returns an array from all progresses for target user in order by specified key.
func get_progress_sorted_by_parameter(key: String) -> Array:
	_err = OK
	if _killed:
		_err = ERR_CANT_CONNECT
		return []
	if _load_users():
		_err = _load_users()
		return []
	if not _auth():
		_err = ERR_UNAUTHORIZED
		return []
	if _invalid_progress_parameter(key):
		_err = ERR_INVALID_PARAMETER
		return []
	var record: Dictionary = {}
	var progress: Dictionary
	for save: String in GPFile.get_files(GPFile.globalize_path(str(_config.save_path).get_base_dir()).path_join(_logined_user.uuid)):
		progress = _load_progress(save)
		record[progress.upid] = progress
	var sorted_keys: Array = record.values()
	sorted_keys.sort_custom(func sorter(a: Dictionary, b: Dictionary) -> bool: return record[a][key] < record[b][key])
	return sorted_keys


## Returns a dictionary from progress in all user progresses, [method get_parameter_statistics] for
## each parameter.
func progress_report() -> Dictionary:
	_err = OK
	if _killed:
		_err = ERR_CANT_CONNECT
		return {}
	if _load_users():
		_err = _load_users()
		return {}
	if not _auth():
		_err = ERR_UNAUTHORIZED
		return {}
	var report: Dictionary = {}
	for parameter: String in get_valid_parameters():
		report[parameter] = get_parameter_statistics(parameter).values()
	return report

#endregion

#region Preview

## Returns a dictionary from specified progress in user progresses include preview parameters.
func get_progress_preview(upid: int) -> Dictionary:
	_err = OK
	if _killed:
		_err = ERR_CANT_CONNECT
		return {}
	if _load_users():
		_err = _load_users()
		return {}
	if _invalid_uuid(_logined_user.uuid):
		_err = ERR_DOES_NOT_EXIST
		return {}
	if not _auth():
		_err = ERR_UNAUTHORIZED
		return {}
	var progress: Dictionary = load_progress(upid)
	var preview: Dictionary = {}
	_config.preview_parameters = _remove_white_spaces(_config.previewparameters)
	var preview_parameters: Array = _config.preview_parameters.split(",", false)
	for key: String in progress:
		if key in preview_parameters:
			preview[key] = progress[key]
	return preview


## Returns an array from progresses with preview parameters.
func get_preview_list(max_size: int = -1) -> Array:
	_err = OK
	if _killed:
		_err = ERR_CANT_CONNECT
		return []
	if _load_users():
		_err = _load_users()
		return []
	if _invalid_uuid(_logined_user.uuid):
		_err = ERR_DOES_NOT_EXIST
		return []
	if not _auth():
		_err = ERR_UNAUTHORIZED
		return []
	var list: Array = []
	var save_dir: String = GPFile.globalize_path(str(_config.save_path).get_base_dir()).path_join(_logined_user.uuid)
	for save: String in GPFile.get_files(save_dir):
		list.append(get_progress_preview(int(save.get_file().get_basename().split("-")[1])))
	if max_size != -1:
		while list.size() > max_size:
			list.pop_front()
	list.reverse()
	return list

#endregion

#region Parameters

## Returns an array from all progress parameters specified in config.
func get_valid_parameters() -> Array:
	_config.progress_parameters = _remove_white_spaces(_config.progress_parameters)
	return _config.progress_parameters.split(",", false)

#endregion

## Returns id of last saved progress, [code]-2[/code] for errors and [code]-1[/code] when user
## havn't saved progress.
func get_last_upid() -> int:
	_err = OK
	if _killed:
		_err = ERR_CANT_CONNECT
		return -2
	if _load_users():
		_err = _load_users()
		return -2
	if not _auth():
		_err = ERR_UNAUTHORIZED
		return -2
	var save_dir: String = GPFile.globalize_path(str(_config.save_path).get_base_dir()).path_join(_logined_user.uuid)
	if not GPFile.dir_exists(save_dir):
		if GPFile.make_dir(save_dir):
			_err = ERR_CANT_CREATE
			return -2
	if GPFile.get_files(save_dir).size() == 0:
		return -1
	else:
		var last_save: String = Array(GPFile.get_files(save_dir))[-1]
		return int(last_save.get_file().get_basename().split("-")[1])

#region Autosave

## @experimental
func check_autosave_time() -> bool:
	_err = OK
	if _killed:
		_err = ERR_CANT_CONNECT
		return false
	if _load_users():
		_err = _load_users()
		return false
	if _invalid_uuid(_logined_user.uuid):
		_err = ERR_DOES_NOT_EXIST
		return false
	if not _auth():
		_err = ERR_UNAUTHORIZED
		return false
	if _invalid_progress_parameter("last_save"):
		_err = ERR_INVALID_PARAMETER
		return false
	var last_save: String = _users[_logined_user.uuid].last_save
	var interval: int = _get_days(Time.get_date_string_from_system()) - _get_days(last_save)
	var correct_interval: int = int(str(_config.autosave_interval).erase(str(_config.autosave_inteval).length() - 1))
	match _config.autosave_inteval[-1]:
		"n":
			return false
		"d":
			correct_interval *= 1
		"w":
			correct_interval *= 7
		"m":
			correct_interval *= 30
		"y":
			correct_interval *= 365
	if interval >= correct_interval:
		return true
	return false

#endregion

#endregion


#region Debugging

## Returns last saved Error in plugin.
func get_last_error() -> Error:
	return _err

#endregion
