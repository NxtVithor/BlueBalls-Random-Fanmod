package meta.data;

import haxe.Json;
import sys.FileSystem;
import sys.io.File;

using StringTools;

typedef WeekFile =
{
	var songs:Array<Array<Dynamic>>;
	var weekCharacters:Array<String>;
	var weekBefore:String;
	var storyName:String;
	var weekName:String;
	var freeplayColor:Array<Int>;
	var startUnlocked:Bool;
	var hideStoryMode:Bool;
	var hideFreeplay:Bool;
};

class Week
{
	public static var loadedWeeks:Array<Week> = [];

	// used for menu item
	public static var weeksNames:Array<String> = [];

	public var songs:Array<Array<Dynamic>> = [['Test', 'bf', [255, 255, 255]]];
	public var weekCharacters:Array<String> = ['', 'gf', 'bf'];
	public var weekBefore:String = 'tutorial';
	public var storyName:String = '';
	public var weekName:String = 'Test';
	public var startUnlocked:Bool = true;
	public var hideStoryMode:Bool = false;
	public var hideFreeplay:Bool = false;

	public function new(weekFile:WeekFile)
	{
		songs = weekFile.songs;
		weekCharacters = weekFile.weekCharacters;
		weekBefore = weekFile.weekBefore;
		storyName = weekFile.storyName;
		weekName = weekFile.weekName;
		startUnlocked = weekFile.startUnlocked;
		hideStoryMode = weekFile.hideStoryMode;
		hideFreeplay = weekFile.hideFreeplay;
	}

	public static function loadFromJson(path:String):WeekFile
	{
		return cast CoolUtil.readJson(path);
	}

	public static function loadWeeks()
	{
		var weekFiles:Array<String> = FileSystem.readDirectory(Paths.getPreloadPath('weeks'));

		#if MODS_ALLOWED
		// check for modded weeks
		// for root mods folder
		var path:String = ModManager.getModPath('weeks');
		if (FileSystem.isDirectory(path))
		{
			for (week in FileSystem.readDirectory(path))
				weekFiles.push(week);
		}
		// for mods folders
		for (folder in ModManager.modsFolders)
		{
			var path:String = ModManager.getModPath(folder + '/weeks');
			if (FileSystem.isDirectory(path))
			{
				for (week in FileSystem.readDirectory(path))
					weekFiles.push(week);
			}
		}
		#end

		// load the weeks
		for (i in 0...weekFiles.length)
		{
			// ignore other types of files
			if (weekFiles[i].endsWith('.json'))
			{
				weekFiles[i] = weekFiles[i].substring(0, weekFiles[i].lastIndexOf('.'));
				weeksNames[i] = weekFiles[i].substring(weekFiles[i].lastIndexOf('/'), weekFiles[i].length);
				loadedWeeks[i] = new Week(Week.loadFromJson(Paths.json('weeks/' + weekFiles[i])));
			}
		}
	}
}
