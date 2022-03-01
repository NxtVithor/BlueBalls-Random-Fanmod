package;

import meta.CoolUtil;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

class ModManager
{
	public static final modDirectory:String = 'mods';
	public static final ignoredDirectories:Array<String> = [
		'characters', 'custom_events', 'custom_notetypes', 'data', 'songs', 'music', 'sounds', 'shaders', 'videos', 'images', 'stages', 'weeks', 'fonts',
		'scripts'
	];
	public static final modsListPath:String = 'modsList.txt';

	public static var modsDirectories:Array<String> = [];

	public static var currentModDirectory:String = '';

	public static var modsList:Map<String, Bool> = new Map<String, Bool>();

	inline public static function modStr(key:String)
	{
		return '${modDirectory}/$key';
	}

	public static function getModPath(key:String)
	{
		#if MODS_ALLOWED
		if (currentModDirectory != null && currentModDirectory.length > 0)
		{
			var leModDir:String = modStr(currentModDirectory + '/' + key);
			if (modsList.get(currentModDirectory) && FileSystem.exists(leModDir))
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

	// in the psych format so the same code lol
	public static function loadModsList()
	{
		#if MODS_ALLOWED
		if (!FileSystem.exists(modsListPath))
			saveModsList();
		// first read the file
		var leMods:Array<String> = CoolUtil.coolTextFile(modsListPath);
		for (i in 0...leMods.length)
		{
			if (leMods.length > 1 && leMods[0].length > 0)
			{
				var modSplit:Array<String> = leMods[i].split('|');
				if (!ignoredDirectories.contains(modSplit[0].toLowerCase()))
					modsList.set(modSplit[0], modSplit[1] == '1');
			}
		}
		// then add other dirs
		// i like it false by default. -shadowmario
		for (directory in modsDirectories)
			if (!modsList.exists(directory))
				modsList.set(directory, false);
		#end
	}

	public static function saveModsList()
	{
		#if MODS_ALLOWED
		var fileStr:String = '';
		for (mod in modsList.keys())
		{
			if (fileStr.length > 0)
				fileStr += '\n';
			fileStr += mod + '|' + (modsList.get(mod) ? '1' : '0');
		}
		File.saveContent(modsListPath, fileStr);
		#end
	}

	public static function loadModsDirectories()
	{
		#if MODS_ALLOWED
		var directories:Array<String> = FileSystem.readDirectory(modDirectory);
		modsDirectories = [];
		for (directory in directories)
			if (FileSystem.isDirectory(modStr(directory)) && !ignoredDirectories.contains(directory.toLowerCase()))
				modsDirectories.push(directory);
		#end
	}
}
