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

	public static function getModPath(key:String)
	{
		#if MODS_ALLOWED
		var daPath:String = null;
		// for mods folders
		for (folder in ModManager.modsFolders)
		{
			daPath = getModPath(folder + '/' + key);
			if (FileSystem.exists(daPath))
				return daPath;
		}
		// for root mods folder
		daPath = '${ModManager.modFolder}/$key';
		if (FileSystem.exists(daPath))
			return daPath;
		return null;
		#end
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
}
