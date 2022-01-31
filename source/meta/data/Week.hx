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
	public static var weeksList:Array<String> = [];

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

	public static function loadWeeks()
	{
		var weeksFilesList:Array<String> = FileSystem.readDirectory('assets/weeks');

		// custom modded week code because the original one is incomplete for our case
		#if MODS_ALLOWED
		var moddedWeeksFilesList:Array<String> = FileSystem.readDirectory('${Paths.modFolder}/weeks');

		if (moddedWeeksFilesList != null)
		{
			for (i in 0...moddedWeeksFilesList.length)
			{
				var path:String = 'weeks/${moddedWeeksFilesList[i]}';

				// make game crash if the week already exist in game files
				if (weeksFilesList.contains(moddedWeeksFilesList[i]))
					throw new Exception('TRYING TO OVERRIDE A BASE GAME WEEK????');
				// wanna add a custom week with a good name???
				else if (Paths.isModded(path))
					weeksFilesList.push(moddedWeeksFilesList[i]);
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

				// load week from the json
				loadedWeeks[i] = new Week(Week.loadFromJson(Paths.json('weeks/${weeksFilesList[i]}')));
			}
		}
	}

	public static function loadFromJson(path:String):SwagWeek
	{
		var rawJson:String = CoolUtil.formatJson(File.getContent(path).trim());
		return cast Json.parse(rawJson);
	}
}
