package;

import sys.FileSystem;

class ModManager
{
	public static var modFolder:String = "mods";
	public static var modsFolders:Array<String>;

	// public static var currentModsFolder:String = "";
	static var ignoredModsFolders:Array<String> = ["fonts", "images", "music", "shaders", "songs", "sounds", "weeks"];

	public static function loadModsFolders()
	{
		#if MODS_ALLOWED
		var folders:Array<String> = FileSystem.readDirectory(modFolder);

		modsFolders = [];

		for (folder in folders)
			if (FileSystem.isDirectory(Paths.mod(folder)) && !ignoredModsFolders.contains(folder))
				modsFolders.push(folder);
		#end
	}

	public static function isModded(path:String)
	{
		#if MODS_ALLOWED
        // repeat deluxe
		for (folder in ModManager.modsFolders)
		{
			var daPath:String = Paths.mod(folder + '/' + path);
			if (FileSystem.exists(daPath))
				return true;
		}

		return FileSystem.exists(Paths.mod(path));
		#else
		return false;
		#end
	}
}
