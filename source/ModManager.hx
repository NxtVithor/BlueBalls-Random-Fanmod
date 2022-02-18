package;

import sys.FileSystem;

#if MODS_ALLOWED
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

	inline public static function modStr(key:String)
	{
		return '${ModManager.modFolder}/$key';
	}

	public static function getModPath(key:String)
	{
		var daPath:String = null;
		// for root mods folder
		daPath = modStr(key);
		if (FileSystem.exists(daPath))
			return daPath;
		// for mods folders
		for (folder in ModManager.modsFolders)
		{
			daPath = modStr(folder + '/' + key);
			if (FileSystem.exists(daPath))
				return daPath;
		}
		return null;
	}

	public static function loadModsFolders()
	{
		var folders:Array<String> = FileSystem.readDirectory(modFolder);
		modsFolders = [];
		for (folder in folders)
			if (FileSystem.isDirectory(modStr(folder)) && !ignoredModsFolders.contains(folder))
				modsFolders.push(folder);
	}
}
#end
