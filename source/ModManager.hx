package;

import haxe.Exception;
import sys.io.File;
import meta.CoolUtil;
#if !html5
import sys.FileSystem;
#end

class ModManager
{
	public static final modDirectory:String = 'mods';
	public static final rawModsListPath:String = 'rawModsList.txt';
	public static var modsDirectories:Array<String>;

	public static var currentModDirectory:String = '';

	public static final baseIgnoredDirectories:Array<String> = [
		'characters', 'custom_events', 'custom_notetypes', 'data', 'songs', 'music', 'sounds', 'shaders', 'videos', 'images', 'stages', 'weeks', 'fonts',
		'scripts'
	];
	public static var ignoredDirectories:Array<String> = [];

	public static var modsList:Array<Array<Dynamic>> = [];
	static var rawModsList:Array<String> = [];

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

	// in the psych format so the same code lol
	public static function loadModsList()
	{
		if (!FileSystem.exists(rawModsListPath))
			saveModsList();
		ignoredDirectories = baseIgnoredDirectories;
		modsList = [];
		rawModsList = CoolUtil.coolTextFile(rawModsListPath);
		if (rawModsList.length > 1 && rawModsList[0].length > 0)
		{
			for (i in 0...rawModsList.length)
			{
				var data:Array<String> = parseModFromList(i);
				modsList.push([data[0], data[1] == '1']);
				if (!ignoredDirectories.contains(data[0].toLowerCase()) && data[1] != '1')
					ignoredDirectories.push(data[0]);
			}
		}
	}

	public static function parseModFromList(index:Int)
	{
		if (rawModsList[index] != null && rawModsList[index].length > 0)
			return rawModsList[index].split('|');
		else
			return null;
	}

	public static function saveModsList()
	{
		var fileStr:String = '';
		for (mod in modsList)
		{
			if (fileStr.length > 0)
				fileStr += '\n';
			fileStr += mod[0] + '|' + (mod[1] ? '1' : '0');
		}
		try
		{
			File.saveContent(rawModsListPath, fileStr);
		}
		catch (e:Exception)
		{
			throw new Exception("Can't save mods list.");
		}
	}

	public static function loadModsDirectories()
	{
		#if MODS_ALLOWED
		var directories:Array<String> = FileSystem.readDirectory(modDirectory);
		modsDirectories = [];
		for (directory in directories)
			if (FileSystem.isDirectory(modStr(directory)) && !ignoredDirectories.contains(directory))
				modsDirectories.push(directory);
		#end
	}
}
