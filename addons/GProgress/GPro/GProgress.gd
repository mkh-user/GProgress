class_name GProgress
extends Node

## GProgress Plugin Documentation[br]
## 
## The GProgress plugin is designed to help developers manage player progress in their games. With this plugin, you can easily save, load, and manage multiple players' progress using custom clients, signals, and functions.[br]
## This script added automaticly to your project when GProgress plugin is activated and you can use it with [code]GPro[/code].[br][br]
## [b]Note:[/b] If plugin isn't initialized, all function with Error return type returns [code]ERR_CANT_CONNECT[/code] and other functions set last error to this error code.[br]

const _CONNECTOR_FILE = "res://addons/GProgress/connector.file"
const _USERS_FILE = "user://GProgress/Users.file"

var _config: Dictionary
var _users: Dictionary
var _user_parameters: Array
var _err: Error
var _new_user: Dictionary
var _killed := false 

#region initializing
## [b]SD:[/b] Activates the plugin before running the projects.[br]
## [b]In:[/b][br]
## - NOTHING[br]
## [b]Out:[/b][br]
## - NOTHING[br]
## [b]ERR:[/b][br]
## - [b]Soft Error:[/b] [code][GProgress] [Config] [GPro] [FATAL] Error code: %error_code%[/code][br]
## - [b]Error:[/b] [code][GProgress] [Main] [GPro] [ERROR] Plugin crashed, all its services were stopped until the next run of the game or restart the plugin![/code][br]
## - [b]Error:[/b] [code][GProgress] [Config] [GPro] [WARNING] GProgress is not initialized; Please use GPro.initilize() one time.[/code][br]
func _ready():
	_err = _open_config()
	if not _err: _err = FileAccess.get_open_error()
	if _err:
		printerr("[GProgress] [Config] [GPro] [FATAL] Error code: " + str(_err))
		_killed = true
		push_error("[GProgress] [Main] [GPro] [ERROR] Plugin crashed, all its services were stopped until the next run of the game or restart the plugin!")
		return
	if not is_initialized():
		push_error("[GProgress] [Config] [GPro] [WARNING] GProgress is not initialized; Please use GPro.initilize() one time.")
#endregion

#region manager
## [b]SD:[/b] Restarts the plugin[br]
## [b]In:[/b][br]
## - [param reset_when_failed]: If the plugin crashes after restarting, the configs will be reset if this parameter is [code]true[/code].[br]
## [b]Out:[/b][br]
## - NOTHING[br]
## [b]ERR:[/b][br]
## - [b]Soft Error:[/b] [code][GProgress] [Main] [GPro] [MESSAGE] Trying to restart and fix bugs.[/code][br]
## - [b]Soft Error:[/b] [code][GProgress] [Main] [GPro] [ERROR] Restart had no effect[/code][br]
## - [b]Soft Error:[/b] [code][GProgress] [Config] [GPro] [MESSAGE] Config was reset![/code][br]
func restart(reset_when_failed: bool = false) -> void:
	if _killed: printerr("[GProgress] [Main] [GPro] [MESSAGE] Trying to restart and fix bugs.")
	_ready()
	if _killed:
		printerr("[GProgress] [Main] [GPro] [ERROR] Restart had no effect")
		if reset_when_failed:
			var panel = GProgressPanel.new()
			panel.reset_config.emit()
			printerr("[GProgress] [Config] [GPro] [MESSAGE] Config was reset!")
			restart()


## [b]SD:[/b] Checks plugin initialization[br]
## [b]In:[/b][br]
## - [param initialize_if_not]: If the plugin is not initilized, initializes it if this parameter is [code]true[/code].[br]
## [b]Out:[/b][br]
## - is_initiailized [bool]:[br]
## - - If the plugin is initialized: [code]true[/code][br]
## - - If the plugin isn't initialized: [code]false[/code][br]
## [b]ERR:[/b][br]
## - NOTHING[br]
func is_initialized(initialize_if_not: bool = false) -> bool:
	if FileAccess.file_exists(_USERS_FILE):
		return true
	else:
		if initialize_if_not: initialize()
		return false


## [b]SD:[/b] Initializes the plugin[br]
## [b]In:[/b][br]
## - NOTHING[br]
## [b]Out:[/b][br]
## - Error [enum @GlobalScope.Error]:[br]
## - - See [method FileAccess.get_open_error][br]
## [b]ERR:[/b][br]
## - NOTHING[br]
func initialize() -> Error:
	return _save_file(_USERS_FILE, {})
#endregion


## [b]SD:[/b] Adds a new user[br]
## [b]In:[/b][br]
## - [param parameters]: must be a [Dictionary] containing exactly the keys specified in the settings in User Parameters section and in the same order.[br]
## [b]Out:[/b][br]
## - Error [enum @GlobalScope.Error]:[br]
## - - If there is a problem loading the users file: See [method FileAccess.get_open_error][br]
## - - If the user [param id] is duplicated: [code]ERR_ALREADY_EXISTS[/code][br]
## - - If all user slots are full: [code]ERR_UNAVAILABLE[/code][br]
## - - If all keys are not the same as the config, have different names, or are not sorted in the config order: [code]ERR_INVALID_PARAMETER[/code][br]
## - - If there is a problem saving the users file: See [method FileAccess.get_open_error][br]
## - - Otherwise: [code]OK[/code][br]
## [b]ERR:[/b][br]
## - NOTHING
func create_user(parameters: Dictionary) -> Error:
	if _killed: return ERR_CANT_CONNECT
	if _load_users(): return _load_users()
	if not _invalid_id(parameters["id"]): return ERR_ALREADY_EXISTS
	if _slots_are_full(): return ERR_UNAVAILABLE
	var keys = parameters.keys()
	while _config["user_parameters"].find(" ") != -1:
		_config["user_parameters"] = _config["user_parameters"].erase(_config["user_parameters"].find(" "))
	_user_parameters = _config["user_parameters"].split(",", false)
	if keys.size() != _user_parameters.size():
		return ERR_INVALID_PARAMETER
	for i in range(keys.size()):
		if keys[i] != _user_parameters[i]:
			return ERR_INVALID_PARAMETER
		_new_user[keys[i]] = parameters[keys[i]]
	_users[parameters["id"]] = _new_user
	if _save_users(): return _save_users()
	return OK


## [b]SD:[/b] Deletes the specified user[br]
## [b]In:[/b][br]
## - [param id]: Unique id for target user.[br]
## [b]Out:[/b][br]
## - Error [enum @GlobalScope.Error]:[br]
## - - If there is a problem loading the users file: See [method FileAccess.get_open_error][br]
## - - If the user [param id] isn't exist: [code]ERR_INVALID_PARAMETER[/code][br]
## - - If there is a problem deleting user's saves: See [method DirAccess.remove_absolute][br]
## - - If there is a problem saving the users file: See [method FileAccess.get_open_error][br]
## - - Otherwise: [code]OK[/code][br]
## [b]ERR:[/b][br]
## - NOTHING
func remove_user(id: String) -> Error:
	if _killed: return ERR_CANT_CONNECT
	if _load_users(): return _load_users()
	if not id in _users.keys(): ERR_INVALID_PARAMETER
	_users.erase(id)
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(_config["save_path"].join_path(id))):
		var error = DirAccess.remove_absolute(ProjectSettings.globalize_path(_config["save_path"].join_path(id)))
		if error: return error
	return _save_users()


## [b]SD:[/b] Returns a dictionary from all users with their configs[br]
## [b]In:[/b][br]
## - NOTHING[br]
## [b]Out:[/b][br]
## - all_users [Dictionary]:[br]
## - - If there is a problem loading the users file: [code]{}[/code][br]
## - - Otherwise: a dictionary in [code]user_id(String): configs(Dictionary)[/code] format.[br]
## [b]ERR:[/b][br]
## - See [method get_last_error].
func get_all_users() -> Dictionary:
	_err = OK
	if _killed:
		_err = ERR_CANT_CONNECT
		return {}
	if _load_users():
		_err = _load_users()
		return {}
	return _users


## [b]SD:[/b] Returns a dictionary from specified parameter in all user configs by user id[br]
## [b]In:[/b][br]
## - [param key] [String]: key of target parameter.[br]
## [b]Out:[/b][br]
## - parameters [Dictionary]:[br]
## - - If there is a problem loading the users file: [code]{}[/code][br]
## - - Otherwise: a dictionary in [code]user_id(String): parameter_value(Variant)[/code] format.[br]
## [b]ERR:[/b][br]
## - See [method get_last_error].
func get_parameter_in_all_users(key: String) -> Dictionary:
	_err = OK
	if _killed:
		_err = ERR_CANT_CONNECT
		return {}
	if _load_users():
		_err = _load_users()
		return {}
	var parameters = {}
	for id in _users.keys():
		parameters[id] = _users[id][key]
	return parameters


## [b]SD:[/b] Returns a dictionary from specified user configs[br]
## [b]In:[/b][br]
## - [param id] [String]: unique user id for target user.[br]
## [b]Out:[/b][br]
## - config [Dictionary]:[br]
## - - If there is a problem loading the users file: [code]{}[/code][br]
## - - Otherwise: a dictionary in [code]config_key(String): config_value(Variant)[/code] format.[br]
## [b]ERR:[/b][br]
## - See [method get_last_error].
func get_all_user_parameters(id: String) -> Dictionary:
	_err = OK
	if _killed:
		_err = ERR_CANT_CONNECT
		return {}
	if _load_users():
		_err = _load_users()
		return {}
	if _invalid_id(id):
		_err = ERR_DOES_NOT_EXIST
		return {}
	return _users[id]


## [b]SD:[/b] Sets specified user configs from a dictionary[br]
## [b]In:[/b][br]
## - [param id] [String]: unique user id for target user.[br]
## - [param parameters] [Dictionary]: config dictionary, see also [method create_user].[br]
## [b]Out:[/b][br]
## - Error [enum @GlobalScope.Error]:[br]
## - - If there is a problem loading the users file: See [method FileAccess.get_open_error][br]
## - - If the user [param id] isn't exist: [code]ERR_DOES_NOT_EXIST[/code][br]
## - - If any key is not in the config or have different names: [code]ERR_INVALID_PARAMETER[/code][br]
## - - If there is a problem saving the users file: See [method FileAccess.get_open_error][br]
## - - Otherwise: [code]OK[/code][br]
## [b]ERR:[/b][br]
## - NOTHING[br]
## [b]Note:[/b] [code]id[/code], [code]last_open[/code] and [code]last_save[/code] keys cannot be changed, if you change them in the [param parameters], it has no effect.
func set_all_user_parameters(id: String, parameters: Dictionary) -> Error:
	if _killed: return ERR_CANT_CONNECT
	if _load_users(): return _load_users()
	if _invalid_id(id): return ERR_DOES_NOT_EXIST
	for key in parameters.keys():
		if key in ["id", "last_open", "last_save"]:
			continue
		if _invalid_parameter(id, key): return ERR_INVALID_PARAMETER
		_users[id][key] = parameters[key]
	return _save_users()


## [b]SD:[/b] Sets specified user config parameter to [param value][br]
## [b]In:[/b][br]
## - [param id] [String]: unique user id for target user.[br]
## - [param key] [String]: key of target config.[br]
## - [param value] [Variant]: value of target key.[br]
## [b]Out:[/b][br]
## - Error [enum @GlobalScope.Error]:[br]
## - - If there is a problem loading the users file: See [method FileAccess.get_open_error][br]
## - - If the user [param id] isn't exist: [code]ERR_DOES_NOT_EXIST[/code][br]
## - - If [param key] is [code]id[/code], [code]last_save[/code] or [code]last_save[/code],: [code]ERR_LOCKED[/code][br]
## - - If there is a problem saving the users file: See [method FileAccess.get_open_error][br]
## - - Otherwise: [code]OK[/code][br]
## [b]ERR:[/b][br]
## - NOTHING[br]
func set_user_parameter(id: String, key: String, value: Variant) -> Error:
	if _killed: return ERR_CANT_CONNECT
	if _load_users(): return _load_users()
	if key in ["id", "last_save", "last_open"]: return ERR_LOCKED
	if _invalid_id(id): return ERR_DOES_NOT_EXIST
	_users[id][key] = value
	return _save_users()


## [b]SD:[/b] Returns an array from any users id[br]
## [b]In:[/b][br]
## - NOTHING[br]
## [b]Out:[/b][br]
## - all_users [Array]:[br]
## - - If there is a problem loading the users file: [code][][/code][br]
## - - Otherwise: an array from [code]user["id"][/code] for all users.[br]
## [b]ERR:[/b][br]
## - See [method get_last_error].
func get_users_list() -> Array:
	_err = OK
	if _killed:
		_err = ERR_CANT_CONNECT
		return []
	if _load_users():
		_err = _load_users()
		return []
	return _users.keys()


## [b]SD:[/b] Returns value saved in target user's configs[br]
## [b]In:[/b][br]
## - [param id] [String]: unique id for target user.[br]
## - [param key] [String]: target key in config.[br]
## [b]Out:[/b][br]
## - value [Variant]:[br]
## - - If there is a problem loading the users file: [code]null[/code][br]
## - - If user [param id] isn't exist: [code]null[/code][br]
## - - If user [param key] is invalid key: [code]null[/code][br]
## - - Otherwise: value saved in target key in target user's config.[br]
## [b]ERR:[/b][br]
## - See [method get_last_error].
func get_user_parameter(id: String, key: String) -> Variant:
	_err = OK
	if _killed:
		_err = ERR_CANT_CONNECT
		return null
	if _load_users():
		_err = ERR_CANT_CONNECT
		return null
	if _invalid_id(id):
		_err = ERR_DOES_NOT_EXIST
		return null
	if _invalid_parameter(id, key):
		_err = ERR_INVALID_PARAMETER
		return null
	return _users[id][key]


## [b]SD:[/b] Modify [code]last_open[/code] parameter in target user's config[br]
## [b]In:[/b][br]
## - [param id] [String]: unique user id for target user.[br]
## [b]Out:[/b][br]
## - Error [enum @GlobalScope.Error]:[br]
## - - If there is a problem loading the users file: See [method FileAccess.get_open_error][br]
## - - If the user [param id] isn't exist: [code]ERR_DOES_NOT_EXIST[/code][br]
## - - If there is a problem saving the users file: See [method FileAccess.get_open_error][br]
## - - Otherwise: [code]OK[/code][br]
## [b]ERR:[/b][br]
## - NOTHING[br]
func record_open_user(id: String) -> Error:
	if _killed: return ERR_CANT_CONNECT
	if _load_users(): return _load_users()
	if _invalid_id(id): return ERR_DOES_NOT_EXIST
	if "last_open" in _users[id].keys():
		_users[id]["last_open"] = _get_datetime()
	return _save_users()


## [b]SD:[/b] Saves new progress for target user[br]
## [b]In:[/b][br]
## - [param id] [String]: unique user id for target user.[br]
## - [param parameters] [Dictionary]: parameters specified in plugin configs.[br]
## - [param auto_datetime] [bool]: use automatic date and time setter for progress.[br]
## [b]Out:[/b][br]
## - Error [enum @GlobalScope.Error]:[br]
## - - If there is a problem loading the users file: See [method FileAccess.get_open_error][br]
## - - If the user [param id] isn't exist: [code]ERR_DOES_NOT_EXIST[/code][br]
## - - If there is a problem saving the progress file: See [method FileAccess.get_open_error][br]
## - - If there is a problem saving the users file: See [method FileAccess.get_open_error][br]
## - - If there is a problem deleting oldest files: See [method DirAccess.remove_absolute][br]
## - - Otherwise: [code]OK[/code][br]
## [b]ERR:[/b][br]
## - NOTHING[br]
func save_progress(id: String, parameters: Dictionary, auto_datetime: bool = true) -> Error:
	if _killed: return ERR_CANT_CONNECT
	if _load_users(): return _load_users()
	if _invalid_id(id): return ERR_DOES_NOT_EXIST
	var progress := {}
	for key in parameters.keys():
		if _invalid_progress_parameter(key): continue
		if auto_datetime and key in ["date", "time"]: continue
		progress[key] = parameters[key]
	progress["id"] = get_last_progress_id(id) + 1
	if auto_datetime:
		if not _invalid_progress_parameter("date"):
			progress["date"] = Time.get_date_string_from_system()
		if not _invalid_progress_parameter("time"):
			progress["time"] = Time.get_time_string_from_system()
	_err = _save_progress(id, progress)
	if not _err:
		if DirAccess.get_files_at(ProjectSettings.globalize_path(_config["save_path"]).get_base_dir().path_join(id)) > _config["limit_per_user"] and _config["limit_per_user"] != 0:
			var folder = ProjectSettings.globalize_path(_config["save_path"]).get_base_dir().path_join(id)
			var older_file = DirAccess.get_files_at(folder)[0]
			_err = DirAccess.remove_absolute(older_file)
		_users[id]["last_save"] = _get_datetime()
		if _save_users(): return _save_users()
	return _err


func _save_progress(id: String, progress: Dictionary, in_costum_path: bool = false, custom_path: String = "") -> Error:
	var save_dir = ProjectSettings.globalize_path(_config["save_path"].get_base_dir()).path_join(id)
	if in_costum_path: save_dir = custom_path
	if not DirAccess.dir_exists_absolute(save_dir):
		if DirAccess.make_dir_recursive_absolute(save_dir):
			return DirAccess.make_dir_recursive_absolute(save_dir)
	var save_path = save_dir.path_join("GProgressSave-" + progress["id"] + ".gpro")
	var file: FileAccess
	if _config["compression"]:
		file = FileAccess.open_compressed(save_path, FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	else:
		file = FileAccess.open(save_path, FileAccess.WRITE)
	var json_progress = JSON.stringify(progress, "\t", false)
	var encrypted_progress = json_progress
	if _config["encryption"]:
		if _config["encryption_key"].length() != 32:
			return ERR_INVALID_PARAMETER
		var aes = AESContext.new()
		aes.start(AESContext.MODE_CBC_ENCRYPT, _config["encryption_key"].to_utf8_buffer())
		encrypted_progress = aes.update(json_progress)
		aes.finish()
	file.store_buffer(encrypted_progress)
	file.close()
	return OK


## [b]SD:[/b] Load specified progress from target user[br]
## [b]In:[/b][br]
## - [param id] [String]: unique user id for target user.[br]
## - [param progress_id] [int]: id of target progress.[br]
## [b]Out:[/b][br]
## - progress [Dictionary]:[br]
## - - If there is a problem loading the users file: [code]{}[/code][br]
## - - If the user [param id] isn't exist: [code]{}[/code][br]
## - - If the progresses directory isn't exist: [code]{}[/code][br]
## - - If there is a problem loading progress file: [code]{}[/code][br]
## - - If encrytion key isn't 32 bytes: [code]{}[/code][br]
## - - Otherwise: a dictiovary in [code]progress_key: progress_value[/code] format.[br]
## [b]ERR:[/b][br]
## - See [method get_last_error][br]
func load_progress(id: String, progress_id: int) -> Dictionary:
	_err = OK
	if _killed:
		_err = ERR_CANT_CONNECT
		return {}
	if _load_users():
		_err = _load_users()
		return {}
	if _invalid_id(id):
		_err = ERR_DOES_NOT_EXIST
		return {}
	var save_dir = ProjectSettings.globalize_path(_config["save_path"].get_base_dir()).path_join(id)
	if not DirAccess.dir_exists_absolute(save_dir):
		_err = ERR_DOES_NOT_EXIST
		return {}
	var path = save_dir.path_join("GProgressSave.gpro")
	var save_path = path.get_base_dir() + "/" + path.get_file().get_basename() + "-" + str(progress_id) + "." + path.get_extension()
	var file: FileAccess
	if _config["compression"]:
		file = FileAccess.open_compressed(save_path, FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	else:
		file = FileAccess.open(save_path, FileAccess.READ)
	if FileAccess.get_open_error():
		_err = FileAccess.get_open_error()
		return {}
	var encyrpted_progress = file.get_buffer(file.get_length())
	file.close()
	var json_progress = encyrpted_progress
	if _config["encryption"]:
		if _config["encryption_key"].length() != 32:
			_err = ERR_INVALID_PARAMETER
			return {}
		var aes = AESContext.new()
		aes.start(AESContext.MODE_CBC_DECRYPT, _config["encryption_key"].to_utf8_buffer())
		json_progress = aes.update(encyrpted_progress)
		aes.finish()
	var progress = JSON.parse_string(json_progress.get_string_from_utf8())
	return progress


func _load_progress(path: String) -> Dictionary:
	_err = OK
	if _killed:
		_err = ERR_CANT_CONNECT
		return {}
	if _load_users():
		_err = _load_users()
		return {}
	var save_dir = ProjectSettings.globalize_path(path.get_base_dir())
	if not DirAccess.dir_exists_absolute(save_dir):
		_err = ERR_DOES_NOT_EXIST
		return {}
	var save_path = path
	var file: FileAccess
	if _config["compression"]:
		file = FileAccess.open_compressed(save_path, FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	else:
		file = FileAccess.open(save_path, FileAccess.READ)
	if FileAccess.get_open_error():
		_err = FileAccess.get_open_error()
		return {}
	var encyrpted_progress = file.get_buffer(file.get_length())
	file.close()
	var json_progress = encyrpted_progress
	if _config["encryption"]:
		if _config["encryption_key"].length() != 32:
			_err = ERR_INVALID_PARAMETER
			return {}
		var aes = AESContext.new()
		aes.start(AESContext.MODE_CBC_DECRYPT, _config["encryption_key"].to_utf8_buffer())
		json_progress = aes.update(encyrpted_progress)
		aes.finish()
	var progress = JSON.parse_string(json_progress.get_string_from_utf8())
	return progress


func remove_progress(id: String, progress_id: int) -> Error:
	if _killed: return ERR_CANT_CONNECT
	if _load_users(): return _load_users()
	if _invalid_id(id): return ERR_INVALID_PARAMETER
	var save_dir = ProjectSettings.globalize_path(_config["save_path"].get_base_dir()).path_join(id)
	if not DirAccess.dir_exists_absolute(save_dir):
		return ERR_DOES_NOT_EXIST
	var save_path = save_dir.get_base_dir() + "/GProgressSave-" + str(progress_id) + ".gpro"
	return DirAccess.remove_absolute(save_path)


func quick_progress(id: String, parameters: Dictionary) -> Error:
	if _killed: return ERR_CANT_CONNECT
	if _load_users(): return _load_users()
	if _invalid_id(id): return ERR_INVALID_PARAMETER
	var progress := {}
	for key in parameters.keys():
		if _invalid_progress_parameter(key): continue
		if key in ["id", "name", "details", "date", "time", "tags"]: continue
		progress[key] = parameters[key]
	progress["id"] = get_last_progress_id(id) + 1
	if not _invalid_progress_parameter("name"): progress["name"] = "Quick Save"
	if not _invalid_progress_parameter("details"): progress["details"] = "There are no details."
	if not _invalid_progress_parameter("date"): progress["date"] = Time.get_date_string_from_system()
	if not _invalid_progress_parameter("time"): progress["time"] = Time.get_time_string_from_system()
	if not _invalid_progress_parameter("tags"): progress["tags"] = ["Quick Save"]
	return _save_progress(id, progress)


## [b]SD:[/b] Create a backup in backup path[br]
func backup_progress(id: String, progress_id: int = -1) -> Error:
	if _killed: return ERR_CANT_CONNECT
	if _load_users(): return _load_users()
	if _invalid_id(id): return ERR_INVALID_PARAMETER
	if progress_id == -1: progress_id = get_last_progress_id(id)
	var last_save = load_progress(id, progress_id)
	_save_progress(id, last_save, true, _config["backup_path"])
	return OK


func load_backup_progress(id: String, backup_path: String) -> Error:
	if _killed: return ERR_CANT_CONNECT
	if _load_users(): return _load_users()
	if _invalid_id(id): return ERR_INVALID_PARAMETER
	var backup = _load_progress(backup_path)
	if backup == {}:
		return ERR_FILE_CANT_READ
	return save_progress(id, backup)


## [b]SD:[/b] Returns a dictionary from specified parameter in user progresses by date-time, date, time or progress id[br]
func get_parameter_stats(id: String, key: String) -> Dictionary:
	if _killed: return {}
	if _load_users(): return {}
	if _invalid_id(id): return {}
	if _invalid_progress_parameter(key): return {}
	var use_date = not _invalid_progress_parameter("date")
	var use_time = not _invalid_progress_parameter("time")
	var stats = {}
	var progress
	for save in DirAccess.get_files_at(ProjectSettings.globalize_path(_config["save_path"].get_base_dir()).path_join(id)):
		progress = _load_progress(save)
		match use_date:
			true:
				match use_time:
					true:
						stats[progress["date"] + "-" + progress["time"]] = progress[key]
					false:
						stats[progress["date"]] = progress[key]
			false:
				match use_time:
					true:
						stats[progress["time"]] = progress[key]
					false:
						stats[progress["id"]] = progress[key]
	return stats


func get_progress_preview(id: String, progress_id: int) -> Dictionary:
	if _killed: return {}
	if _load_users(): return {}
	if _invalid_id(id): return {}
	var progress = load_progress(id, progress_id)
	var preview := {}
	while _config["preview_parameters"].find(" ") != -1:
		_config["preview_parameters"] = _config["preview_parameters"].erase(_config["preview_parameters"].find(" "))
	var preview_parameters = _config["preview_parameters"].split(",", false)
	for key in progress:
		if key in preview_parameters:
			preview[key] = progress[key]
	return preview


func order_by_parameter_in_array(id: String, key: String) -> Array:
	if _killed: return []
	if _load_users(): return []
	if _invalid_id(id): return []
	if _invalid_progress_parameter(key): return []
	var record := {}
	var progress
	for save in DirAccess.get_files_at(ProjectSettings.globalize_path(_config["save_path"].get_base_dir()).path_join(id)):
		progress = _load_progress(save)
		record[progress["id"]] = progress[key]
	var sorted_keys = record.keys()
	sorted_keys.sort_custom(func(a, b): return record[a] < record[b])
	return sorted_keys


func order_by_parameter_in_dictionary(id: String, key: String) -> Dictionary:
	if _killed: return {}
	if _load_users(): return {}
	if _invalid_id(id): return {}
	if _invalid_progress_parameter(key): return {}
	var record := {}
	var progress
	for save in DirAccess.get_files_at(ProjectSettings.globalize_path(_config["save_path"].get_base_dir()).path_join(id)):
		progress = _load_progress(save)
		record[progress["id"]] = progress[key]
	var sorted_keys = record.keys()
	sorted_keys.sort_custom(func(a, b): return record[a] < record[b])
	var sorted_dictionary = {}
	for index in sorted_keys:
		sorted_dictionary[index] = record[index]
	return sorted_dictionary


func progress_report(id: String) -> Dictionary:
	var report = {}
	for parameter in get_valid_parameters():
		report[parameter] = get_parameter_stats(id, parameter).values()
	return report


func get_preview_list(id: String, max_size: int) -> Array:
	var list = []
	var save_dir = ProjectSettings.globalize_path(_config["save_path"].get_base_dir()).path_join(id)
	for save in DirAccess.get_files_at(save_dir):
		list.append(get_progress_preview(id, int(save.get_file().get_basename().split("-")[1])))
	while list.size() > max_size:
		list.pop_front()
	list.reverse()
	return list


func get_valid_parameters() -> Array:
	while _config["progress_parameters"].find(" ") != -1:
		_config["progress_parameters"] = _config["progress_parameters"].erase(_config["progress_parameters"].find(" "))
	return _config["progress_parameters"].split(",", false)


## [b]SD:[/b] Returns id of last saved progress[br]
func get_last_progress_id(id: String) -> int:
	if _killed: return -1 * ERR_CANT_CONNECT
	if _load_users(): return -1 * ERR_FILE_CANT_READ
	if _invalid_id(id): return -1 * ERR_INVALID_PARAMETER
	var save_dir = ProjectSettings.globalize_path(_config["save_path"].get_base_dir()).path_join(id)
	if not DirAccess.dir_exists_absolute(save_dir):
		if DirAccess.make_dir_recursive_absolute(save_dir):
			return -1 * ERR_FILE_BAD_PATH
	if DirAccess.get_files_at(save_dir).size() == 0:
		return -1
	else:
		var last_save = Array(DirAccess.get_files_at(save_dir))[-1]
		return int(last_save.get_file().get_basename().split("-")[1])



## [b]SD:[/b] Returns last saved Error in plugin[br]
func get_last_error() -> Error:
	return _err


func _get_datetime() -> String:
	return Time.get_datetime_string_from_system(false, true)


func _load_users() -> Error:
	_users = _load_file(_USERS_FILE, {})
	return FileAccess.get_open_error()


func _save_users() -> Error:
	return _save_file(_USERS_FILE, _users)


func _invalid_id(id: String) -> bool:
	return not id in _users.keys()


func _invalid_parameter(id: String, key: String) -> bool:
	return not key in _users[id].keys()


func _invalid_progress_parameter(key: String) -> bool:
	while _config["progress_parameters"].find(" ") != -1:
		_config["progress_parameters"] = _config["progress_parameters"].erase(_config["progress_parameters"].find(" "))
	return not key in _config["progress_parameters"].split(",", false)


func _slots_are_full() -> bool:
	return _users.keys().size() == int(_config["user_slots"])


func _save_file(path: String, value: Variant) -> Error:
	var file = FileAccess.open(path, FileAccess.WRITE)
	var error = FileAccess.get_open_error()
	file.store_var(value)
	file.close()
	return error


func _load_file(path: String, defalut_value: Variant = null) -> Variant:
	if not FileAccess.file_exists(path):
		printerr("[GProgress] [File Manager] [GPro] File does not exist!")
		return defalut_value
	var file = FileAccess.open(path, FileAccess.READ)
	var value = file.get_var()
	file.close()
	return value


func _open_config() -> Error:
	if not FileAccess.file_exists(_CONNECTOR_FILE):
		return ERR_DOES_NOT_EXIST
	_config = _load_file(_CONNECTOR_FILE)
	if not "id" in _config["user_parameters"].split(","):
		return ERR_INVALID_PARAMETER
	return OK
