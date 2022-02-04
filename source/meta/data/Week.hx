package meta.data;

import haxe.Exception;
import sys.FileSystem;
import haxe.Json;
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
		var rawJson:String = CoolUtil.formatJson(File.getContent(path).trim());
		return cast Json.parse(rawJson);
	}

	public static function loadWeeks()
	{
		var weeksFilesList:Array<String> = FileSystem.readDirectory('assets/weeks');

		#if MODS_ALLOWED
		// check for modded weeks
		weeksFilesList = weeksFilesList.concat(scanModsWeeks(Paths.modFolder));
		// lol we should have that for mod folders too
		for (folder in Paths.modsFolders)
			weeksFilesList = weeksFilesList.concat(scanModsWeeks(Paths.mod(folder)));
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

	/**
	 * YOU SHOULD FILTER YOUSELF THE LIST!!!
	 */
	private static function scanModsWeeks(path:String = '.')
	{
		var weeksFiles:Array<String> = FileSystem.readDirectory(path + '/weeks');
		var weeksList:Array<String> = [];

		for (i in 0...weeksFiles.length)
		{
			var daPath:String = path + '/weeks/' + weeksFiles[i];

			if (Paths.isModded(daPath))
				weeksList.push(weeksFiles[i]);
		}

		return weeksList;
	}
}
