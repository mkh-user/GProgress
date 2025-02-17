class_name GPFile
extends Node

static func globalize_path(path: String) -> String:
	return ProjectSettings.globalize_path(path)

static func dir_exists(path: String) -> bool:
	return DirAccess.dir_exists_absolute(globalize_path(path))

static func make_dir(path: String) -> Error:
	return DirAccess.make_dir_recursive_absolute(globalize_path(path))

static func file_exists(path: String) -> bool:
	return FileAccess.file_exists(globalize_path(path))

static func remove_dir(path: String) -> Error:
	if not dir_exists(path): return ERR_FILE_NOT_FOUND
	return DirAccess.remove_absolute(globalize_path(path))

static func open(path: String, flag: FileAccess.ModeFlags) -> FileAccess:
	return FileAccess.open(path, flag)

static func open_compressed(path: String, flag: FileAccess.ModeFlags, mode: FileAccess.CompressionMode) -> FileAccess:
	return FileAccess.open_compressed(path, flag, mode)

static func get_error() -> Error:
	return FileAccess.get_open_error()

static func get_files(at_path: String) -> Array:
	return DirAccess.get_files_at(at_path)
