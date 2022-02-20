package;

#if !html5
import sys.FileSystem;
#end

class ModManager
{
	public static final modDirectory:String = 'mods';
	public static var modsDirectories:Array<String>;

	public static var currentModDirectory:String = '';

	static final ignoredModsDirectories:Array<String> = [
		'characters',
		'fonts',
		'images',
		'music',
		'scripts',
		'shaders',
		'songs',
		'sounds',
		'videos',
		'weeks'
	];

	inline public static function modStr(key:String)
	{
		#if MODS_ALLOWED
		return '${modDirectory}/$key';
		#else
		return key;
		#end
	}

	public static function getModPath(key:String)
	{
		#if MODS_ALLOWED
		if (currentModDirectory != null && currentModDirectory.length > 0)
		{
			var leModDir:String = modStr(currentModDirectory + '/' + key);
			if (FileSystem.exists(leModDir))
				return leModDir;
		}
		var daPath:String = modStr(key);
		if (FileSystem.exists(daPath))
			return daPath;
		return null;
		#else
		return key;
		#end
	}

	public static function loadModsDirectories()
	{
		#if MODS_ALLOWED
		var directories:Array<String> = FileSystem.readDirectory(modDirectory);
		modsDirectories = [];
		for (directory in directories)
			if (FileSystem.isDirectory(modStr(directory)) && !ignoredModsDirectories.contains(directory))
				modsDirectories.push(directory);
		#end
	}
}
