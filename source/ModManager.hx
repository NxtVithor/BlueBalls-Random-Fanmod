package;

import sys.FileSystem;

class ModManager
{
	public static var modFolder:String = 'mods';
	public static var modsFolders:Array<String>;

	static final ignoredModsFolders:Array<String> = [
		'characters',
		'fonts',
		'images',
		'music',
		'shaders',
		'songs',
		'sounds',
		'videos',
		'weeks'
	];

	inline static public function getModPath(key:String)
	{
		return '${ModManager.modFolder}/$key';
	}

	public static function loadModsFolders()
	{
		#if MODS_ALLOWED
		var folders:Array<String> = FileSystem.readDirectory(modFolder);

		modsFolders = [];

		for (folder in folders)
			if (FileSystem.isDirectory(getModPath(folder)) && !ignoredModsFolders.contains(folder))
				modsFolders.push(folder);
		#end
	}

	public static function checkModPath(path:String)
	{
		// for mods folders
		for (folder in ModManager.modsFolders)
		{
			var daPath:String = getModPath(folder + '/' + path);
			if (FileSystem.exists(daPath))
				return daPath;
		}

		// for root mod folder
		if (isModded(path))
			return getModPath(path);

		return null;
	}

	public static function isModded(path:String)
	{
		#if MODS_ALLOWED
		// repeat deluxe
		for (folder in ModManager.modsFolders)
		{
			var daPath:String = getModPath(folder + '/' + path);
			if (FileSystem.exists(daPath))
				return true;
		}

		return FileSystem.exists(getModPath(path));
		#else
		return false;
		#end
	}
}
