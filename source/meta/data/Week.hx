package meta.data;

import haxe.Exception;
import haxe.Json;
import sys.FileSystem;
import sys.io.File;

using StringTools;

typedef SwagWeek =
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

	public function new(weekFile:SwagWeek)
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

	public static function loadFromJson(path:String):SwagWeek
	{
		var rawJson:String = CoolUtil.cleanJson(File.getContent(path));
		return cast Json.parse(rawJson);
	}

	public static function loadWeeks()
	{
		var weeksFilesList:Array<String> = FileSystem.readDirectory('assets/weeks');

		#if MODS_ALLOWED
		// check for modded weeks
		var weeksList:Array<String> = [];

		// for root mods folder
		if (FileSystem.isDirectory(ModManager.getModPath('weeks')))
		{
			for (week in FileSystem.readDirectory(ModManager.getModPath('weeks')))
				if (ModManager.isModded('weeks/' + week + '.json'))
					weeksList.push(week);
		}

		// for mods folders
		for (folder in ModManager.modsFolders)
		{
			if (FileSystem.isDirectory(ModManager.getModPath(folder + '/weeks')))
			{
				for (week in FileSystem.readDirectory(ModManager.getModPath(folder + '/weeks')))
					if (ModManager.isModded(folder + '/weeks/' + week + '.json'))
						weeksList.push(week);
			}
		}
		#end

		// load the weeks
		for (i in 0...weeksFilesList.length)
		{
			// ignore other types of files
			if (weeksFilesList[i].endsWith('.json'))
			{
				// remove .json extension
				weeksFilesList[i] = weeksFilesList[i].substring(0, weeksFilesList[i].lastIndexOf('.'));
				// add week name
				weeksNames[i] = weeksFilesList[i].substring(weeksFilesList[i].lastIndexOf('/'), weeksFilesList[i].length);
				// load week from the json
				loadedWeeks[i] = new Week(Week.loadFromJson(Paths.json('weeks/' + weeksFilesList[i])));
			}
		}
	}
}
