class_name GProgress
extends Node

## GProgress Plugin Documentation[br]
## 
## The GProgress plugin is designed to help developers manage player progress in their games. With this plugin, you can easily save, load, and manage multiple players' progress using custom clients, signals, and functions.[br]
## This script added automaticly to your project when GProgress plugin is activated and you can use it with [code]GPro[/code].[br][br]
## [b]Note:[/b] If plugin isn't initialized, all function with Error return type returns [code]ERR_CANT_CONNECT[/code] and other functions set last error to this error code.[br]

signal autosave_request(id, last_save)
signal backup_successful(id)
signal backup_faild(id, error_code)
signal error(error_code)

const _CONFIG_FILE = "res://GProgressConfig.txt"
const _USERS_FILE = "user://GProgress/Users.file"

const _CONFIG_PARAMETERS := [
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
	"encryption_key",
]
var _config: Dictionary
var _config_text: String
var _users: Dictionary
var _user_parameters: Array
var _err: Error:
	set(value): if value != OK: error.emit(value)
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
		return
	var config_list = _config_text.split("\n", false)
	for configure in config_list:
		for param in _CONFIG_PARAMETERS:
			if configure.begins_with(param + ":"):
				if configure.count(":") > 1:
					_config[param] = configure.split(":")[1] + ":" + configure.split(":")[2]
					continue
				_config[param] = configure.split(":")[1]
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


## [b]SD:[/b] Modify [code]last_open[/code] parameter in target user's config and emit autosave & backup signals if need[br]
## [b]In:[/b][br]
## - [param id] [String]: unique user id for target user.[br]
## [b]Out:[/b][br]
## - Error [enum @GlobalScope.Error]:[br]
## - - If there is a problem loading the users file: See [method FileAccess.get_open_error][br]
## - - If the user [param id] isn't exist: [code]ERR_DOES_NOT_EXIST[/code][br]
## - - If there is a problem saving the users file: See [method FileAccess.get_open_error][br]
## - - Otherwise: [code]OK[/code][br]
func record_open_user(id: String) -> Error:
	if _killed: return ERR_CANT_CONNECT
	if _load_users(): return _load_users()
	if _invalid_id(id): return ERR_DOES_NOT_EXIST
	if "last_open" in _users[id].keys():
		_users[id]["last_open"] = _get_datetime()
	if check_autosave_time(id) and _invalid_parameter(id, "last_save"):
		autosave_request.emit(id, _users[id]["last_save"])
	if check_backup_time(id):
		backup_progress(id)
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


func _save_progress(id: String, progress: Dictionary, in_costum_dir: bool = false, custom_dir: String = "") -> Error:
	var save_dir = ProjectSettings.globalize_path(_config["save_path"].get_base_dir()).path_join(id)
	if in_costum_dir: save_dir = custom_dir
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


## [b]SD:[/b] Removes specified progress from target user[br]
## [b]In:[/b][br]
## - [param id] [String]: unique user id for target user.[br]
## - [param progress_id] [int]: id of target progress.[br]
## [b]Out:[/b][br]
## - Error [enum @GlobalScope.Error]:[br]
## - - If there is a problem loading the users file: See [method FileAccess.get_open_error][br]
## - - If the user [param id] isn't exist: [code]ERR_DOES_NOT_EXIST[/code][br]
## - - If the saves folder isn't exist: [code]ERR_DOES_NOT_EXIST[/code][br]
## - - If there is a problem deleting file: See [method DirAccess.remove_absolute][br]
## - - Otherwise: [code]OK[/code][br]
func remove_progress(id: String, progress_id: int) -> Error:
	if _killed: return ERR_CANT_CONNECT
	if _load_users(): return _load_users()
	if _invalid_id(id): return ERR_DOES_NOT_EXIST
	var save_dir = ProjectSettings.globalize_path(_config["save_path"].get_base_dir()).path_join(id)
	if not DirAccess.dir_exists_absolute(save_dir):
		return ERR_DOES_NOT_EXIST
	var save_path = save_dir.get_base_dir() + "/GProgressSave-" + str(progress_id) + ".gpro"
	return DirAccess.remove_absolute(save_path)


## [b]SD:[/b] Quickly saves a progress, default parameters are automatically set (even if they exist in the dictionary)[br]
## [b]In:[/b][br]
## - [param id] [String]: unique user id for target user.[br]
## - [param parameters] [Dictionary]: a dictionary from progress parameters (with or withuot "id", "name", "details", "date", "time" and "tag" keys (Automated parameters).[br]
## [b]Out:[/b][br]
## - Error [enum @GlobalScope.Error]:[br]
## - - If there is a problem loading the users file: See [method FileAccess.get_open_error][br]
## - - If the user [param id] isn't exist: [code]ERR_DOES_NOT_EXIST[/code][br]
## - - If there is a problem saving progress: See [method save_progress][br]
## - - Otherwise: [code]OK[/code][br]
func quick_progress(id: String, parameters: Dictionary) -> Error:
	if _killed: return ERR_CANT_CONNECT
	if _load_users(): return _load_users()
	if _invalid_id(id): return ERR_DOES_NOT_EXIST
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


## [b]SD:[/b] Creates a backup in backup path[br]
## [b]In:[/b][br]
## - [param id] [String]: unique user id for target user.[br]
## - [param progress_id] [int]: unique progress id for target progress, if set it to [code]-1[/code] (default value) ctreate backup from last progress.[br]
## [b]Out:[/b][br]
## - Error [enum @GlobalScope.Error]:[br]
## - - If there is a problem loading the users file: See [method FileAccess.get_open_error][br]
## - - If the user [param id] isn't exist: [code]ERR_DOES_NOT_EXIST[/code][br]
## - - If there is a problem saving backup: See [method save_progress][br]
## - - Otherwise: [code]OK[/code][br]
func backup_progress(id: String, progress_id: int = -1) -> Error:
	if _killed:
		backup_faild.emit(id, ERR_CANT_CONNECT)
		return ERR_CANT_CONNECT
	if _load_users():
		backup_faild.emit(id, _load_users())
		return _load_users()
	if _invalid_id(id):
		backup_faild.emit(id, ERR_DOES_NOT_EXIST)
		return ERR_DOES_NOT_EXIST
	if progress_id == -1: progress_id = get_last_progress_id(id)
	var last_save = load_progress(id, progress_id)
	var err = _save_progress(id, last_save, true, _config["backup_path"])
	if err:
		backup_faild.emit(id, err)
		return err
	backup_successful.emit(id)
	return OK


## [b]SD:[/b] Loads a backup from [param backup_path][br]
## [b]In:[/b][br]
## - [param id] [String]: unique user id for target user.[br]
## - [param backup_path] [String]: path for target backup file, see also [method get_backup_list].[br]
## [b]Out:[/b][br]
## - Error [enum @GlobalScope.Error]:[br]
## - - If there is a problem loading the users file: See [method FileAccess.get_open_error][br]
## - - If the user [param id] isn't exist: [code]ERR_DOES_NOT_EXIST[/code][br]
## - - If there is a problem in load, parse, decrypt, decompression: See [method load_progress][br]
## - - If there is a problem saving progress: See [method save_progress][br]
## - - Otherwise: [code]OK[/code][br]
## [b]Note:[/b] This function save a new progress from backup file to target user, after use it you need to use [method load_progress] for apply progress properties.[br]
func load_backup_progress(id: String, backup_path: String) -> Error:
	if _killed: return ERR_CANT_CONNECT
	if _load_users(): return _load_users()
	if _invalid_id(id): return ERR_DOES_NOT_EXIST
	var backup = _load_progress(backup_path)
	if backup == {}: return ERR_FILE_CANT_READ
	return save_progress(id, backup)

## [b]SD:[/b] Returns an array with all saved backup files in backup path in configs[br]
## [b]In:[/b][br]
## - NOTHING[br]
## [b]Out:[/b][br]
## - backups_list [Array]:[br]
## - - An array with path of all files in [code]Backup Path[/code] config.[br]
func get_backups_list() -> Array:
	return DirAccess.get_files_at(_config["backup_path"])


## [b]SD:[/b] Returns a dictionary from specified parameter in user progresses by date-time, date, time or progress id[br]
## [b]In:[/b][br]
## - [param id] [String]: unique user id for target user.[br]
## - [param key] [String]: key in confgis for extract from progresses.[br]
## [b]Out:[/b][br]
## - statistics [Dictionary]:[br]
## - - If there is a problem loading the users file: [code]{}[/code][br]
## - - If the user [param id] isn't exist: [code]{}[/code][br]
## - - If [param key] is invalid parameters: [code]{}[/code][br]
## - - Otherwise: A dictionary from status of target parameter in all progresses, if progresses has "date" and "time" parameter use these for keys in dictionary, if just one of "date" and "time" are valid parameter use that, and otherwise use progress id. All times sort progresses by id (date-time sort).[br]
## [b]ERR:[/b][br]
## - See [method get_last_error].
func get_parameter_stats(id: String, key: String) -> Dictionary:
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
	if _invalid_progress_parameter(key):
		_err = ERR_INVALID_PARAMETER
		return {}
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


## [b]SD:[/b] Returns a dictionary from specified progress in user progresses include preview parameters.[br]
## [b]In:[/b][br]
## - [param id] [String]: unique user id for target user.[br]
## - [param progress_id] [int]: unique progress id for target progress.[br]
## [b]Out:[/b][br]
## - statistics [Dictionary]:[br]
## - - If there is a problem loading the users file: [code]{}[/code][br]
## - - If the user [param id] isn't exist: [code]{}[/code][br]
## - - If there is a problem in load, parse, decrypt, decompression: [code]{}[/code][br]
## - - Otherwise: See [method load_progress].[br]
## [b]ERR:[/b][br]
## - See [method get_last_error].
func get_progress_preview(id: String, progress_id: int) -> Dictionary:
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
	var progress = load_progress(id, progress_id)
	var preview := {}
	while _config["preview_parameters"].find(" ") != -1:
		_config["preview_parameters"] = _config["preview_parameters"].erase(_config["preview_parameters"].find(" "))
	var preview_parameters = _config["preview_parameters"].split(",", false)
	for key in progress:
		if key in preview_parameters:
			preview[key] = progress[key]
	return preview


## [b]SD:[/b] Returns an array from all progresses for target use in order by specified key.[br]
## [b]In:[/b][br]
## - [param id] [String]: unique user id for target user.[br]
## - [param key] [String]: progress parameter key for order.[br]
## [b]Out:[/b][br]
## - progresses [Array]:[br]
## - - If there is a problem loading the users file: [code][][/code][br]
## - - If the user [param id] isn't exist: [code][][/code][br]
## - - If [param key] is invalid: [code][][/code][br]
## - - If there is a problem in load, parse, decrypt, decompression: Skip that progress[br]
## - - Otherwise: A dictionary from all progresses with [code]progress_id: progress_values[/code] format in order by [param key]. See also [method load_progress].[br]
## [b]ERR:[/b][br]
## - See [method get_last_error].
func order_by_parameter_in_array(id: String, key: String) -> Array:
	_err = OK
	if _killed:
		_err = ERR_CANT_CONNECT
		return []
	if _load_users():
		_err = _load_users()
		return []
	if _invalid_id(id):
		_err = ERR_DOES_NOT_EXIST
		return []
	if _invalid_progress_parameter(key):
		_err = ERR_INVALID_PARAMETER
		return []
	var record := {}
	var progress
	for save in DirAccess.get_files_at(ProjectSettings.globalize_path(_config["save_path"].get_base_dir()).path_join(id)):
		progress = _load_progress(save)
		record[progress["id"]] = progress
	var sorted_keys = record.keys()
	sorted_keys.sort_custom(func(a, b): return record[a][key] < record[b][key])
	return sorted_keys

## @experimental
## [color=Yellow]Experimental:[/color] Sort system in this function is experimental, recommended use [method order_by_parameter_in_array] instead.[br]
## [b]SD:[/b] Returns a dictionary from all progresses for target use in order by specified key.[br]
## [b]In:[/b][br]
## - [param id] [String]: unique user id for target user.[br]
## - [param key] [String]: progress parameter key for order.[br]
## [b]Out:[/b][br]
## - progresses [Dictionary]:[br]
## - - If there is a problem loading the users file: [code]{}[/code][br]
## - - If the user [param id] isn't exist: [code]{}[/code][br]
## - - If [param key] is invalid: [code]{}[/code][br]
## - - If there is a problem in load, parse, decrypt, decompression: Skip that progress[br]
## - - Otherwise: A dictionary from all progresses with [code]progress_id: progress_values[/code] format in order by [param key]. See also [method load_progress].[br]
## [b]ERR:[/b][br]
## - See [method get_last_error].
func order_by_parameter_in_dictionary(id: String, key: String) -> Dictionary:
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
	if _invalid_progress_parameter(key):
		_err = ERR_INVALID_PARAMETER
		return {}
	var record := {}
	var progress
	for save in DirAccess.get_files_at(ProjectSettings.globalize_path(_config["save_path"].get_base_dir()).path_join(id)):
		progress = _load_progress(save)
		record[progress["id"]] = progress
	var sorted_keys = record.keys()
	sorted_keys.sort_custom(func(a, b): return record[a][key] < record[b][key])
	var sorted_dictionary = {}
	for index in sorted_keys:
		sorted_dictionary[index] = record[index]
	return sorted_dictionary


## [b]SD:[/b] Returns a dictionary from progress in all user progresses, similar to [method get_parameter_stats][br]
## [b]In:[/b][br]
## - [param id] [String]: unique user id for target user.[br]
## [b]Out:[/b][br]
## - report [Dictionary]:[br]
## - - If there is a problem loading the users file: [code]{}[/code][br]
## - - If the user [param id] isn't exist: [code]{}[/code][br]
## - - If there is a problem in load, parse, decrypt, decompression: See [method get_parameter_stats][br]
## - - Otherwise: A dictionary with [code]progress_parameter: [parameter_values][/code] format for all parameters (include "id", "index", "name", "last_open" and "last_save").[br]
## [b]ERR:[/b][br]
## - See [method get_last_error].
func progress_report(id: String) -> Dictionary:
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
	var report = {}
	for parameter in get_valid_parameters():
		report[parameter] = get_parameter_stats(id, parameter).values()
	return report


## [b]SD:[/b] Returns an array from progresses with preview parameters[br]
## [b]In:[/b][br]
## - [param id] [String]: unique user id for target user.[br]
## - [param max_size] [int]: max progresses array size ([code]-1[/code] is unlimited), if number of progresses greater than this parameter, removes older progresses while size is big than this.[br]
## [b]Out:[/b][br]
## - preview_list [Array]:[br]
## - - If there is a problem loading the users file: See [code]{}[/code][br]
## - - If the user [param id] isn't exist: [code]{}[/code][br]
## - - If there is a problem in load, parse, decrypt, decompression: See [method get_progress_preview][br]
## - - Otherwise: An array from all progresses just with preview parameters[br]
## [b]ERR:[/b][br]
## - See [method get_last_error].
func get_preview_list(id: String, max_size: int = -1) -> Array:
	_err = OK
	if _killed:
		_err = ERR_CANT_CONNECT
		return []
	if _load_users():
		_err = _load_users()
		return []
	if _invalid_id(id):
		_err = ERR_DOES_NOT_EXIST
		return []
	var list = []
	var save_dir = ProjectSettings.globalize_path(_config["save_path"].get_base_dir()).path_join(id)
	for save in DirAccess.get_files_at(save_dir):
		list.append(get_progress_preview(id, int(save.get_file().get_basename().split("-")[1])))
	if max_size != -1:
		while list.size() > max_size:
			list.pop_front()
	list.reverse()
	return list


## [b]SD:[/b] Returns an array from all progress parameters specified in config[br]
## [b]In:[/b][br]
## - NOTHING[br]
## [b]Out:[/b][br]
## - progress_parameters [Array]:[br]
## - - An array from all parameters ([String]s)[br]
func get_valid_parameters() -> Array:
	while _config["progress_parameters"].find(" ") != -1:
		_config["progress_parameters"] = _config["progress_parameters"].erase(_config["progress_parameters"].find(" "))
	return _config["progress_parameters"].split(",", false)


## [b]SD:[/b] Returns id of last saved progress[br]
## [b]In:[/b][br]
## - [param id] [String]: unique user id for target user.[br]
## [b]Out:[/b][br]
## - progress_id [int]:[br]
## - - If there is a problem loading the users file: [code]-2[/code][br]
## - - If the user [param id] isn't exist: [code]-2[/code][br]
## - - If progress folder isn't exist and can't create it: [code]-2[/code][br]
## - - If there is no saved progress for target user: [code]-1[/code][br]
## - - Otherwise: unique id for last saved progress[br]
## [b]ERR:[/b][br]
## - See [method get_last_error].
func get_last_progress_id(id: String) -> int:
	_err = OK
	if _killed:
		_err = ERR_CANT_CONNECT
		return -2
	if _load_users():
		_err = _load_users()
		return -2
	if _invalid_id(id):
		_err = ERR_DOES_NOT_EXIST
		return -2
	var save_dir = ProjectSettings.globalize_path(_config["save_path"].get_base_dir()).path_join(id)
	if not DirAccess.dir_exists_absolute(save_dir):
		if DirAccess.make_dir_recursive_absolute(save_dir):
			_err = ERR_CANT_CREATE
			return -2
	if DirAccess.get_files_at(save_dir).size() == 0:
		return -1
	else:
		var last_save = Array(DirAccess.get_files_at(save_dir))[-1]
		return int(last_save.get_file().get_basename().split("-")[1])


## @experimental
func check_autosave_time(id: String) -> bool:
	_err = OK
	if _killed:
		_err = ERR_CANT_CONNECT
		return false
	if _load_users():
		_err = _load_users()
		return false
	if _invalid_id(id):
		_err = ERR_DOES_NOT_EXIST
		return false
	if _invalid_progress_parameter("last_save"):
		_err = ERR_INVALID_PARAMETER
		return false
	var last_save = _users[id]["last_save"]
	var interval = _get_days(Time.get_date_string_from_system()) - _get_days(last_save)
	var correct_interval = int(_config["autosave_interval"].erase(_config["autosave_inteval"].lenght() - 1))
	match _config["autosave_inteval"][-1]:
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


## @experimental
func check_backup_time(id: String) -> bool:
	_err = OK
	if _killed:
		_err = ERR_CANT_CONNECT
		return false
	if _load_users():
		_err = _load_users()
		return false
	if _invalid_id(id):
		_err = ERR_DOES_NOT_EXIST
		return false
	var interval = _get_days(Time.get_date_string_from_system())
	var correct_interval = int(_config["backup_interval"].erase(_config["backup_inteval"].lenght() - 1))
	match _config["backup_inteval"][-1]:
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


## [b]SD:[/b] Returns last saved Error in plugin[br]
## [b]In:[/b][br]
## - NOTHING[br]
## [b]Out:[/b][br]
## - Error [enum @GlobalScope.Error]:[br]
## - - If [method is_initialized] returns [code]false[/code]: [code]ERR_CANT_CONNECT[/code][br]
## - - If the user [param id] isn't exist: [code]ERR_DOES_NOT_FOUND[/code][br]
func get_last_error() -> Error:
	return _err


func _get_days(date: String) -> int:
	var days = int(date.split("-", false)[2])
	days += int(date.split("-", false)[1]) * 30
	days += int(date.split("-", false)[0]) * 365
	return days


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
	if not FileAccess.file_exists(_CONFIG_FILE):
		return ERR_DOES_NOT_EXIST
	_config_text = _load_file(_CONFIG_FILE)
	return FileAccess.get_open_error()
