class_name SaveGame
extends RefCounted
## Simpan dan baca kemajuan pemain dalam fail JSON.
## Di PC/Android fail ni dalam folder data aplikasi. Di browser, Godot simpan
## dalam storan browser (IndexedDB), jadi kekal walaupun tutup tab, kecuali
## guna mod incognito atau padam data laman web.

static var path := "user://simpanan.json"


static func save(data: PlayerData) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("Tak dapat simpan: %s" % error_string(FileAccess.get_open_error()))
		return false
	f.store_string(JSON.stringify(data.to_dict(), "\t"))
	f.close()  # di browser, tutup fail = salin ke storan kekal
	return true


## Baca fail simpanan. Kalau tiada atau rosak, mula baru.
static func load_data() -> PlayerData:
	if not FileAccess.file_exists(path):
		return PlayerData.new()
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return PlayerData.from_dict(parsed)
	push_warning("Fail simpanan rosak, mula baru.")
	return PlayerData.new()


static func erase() -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
