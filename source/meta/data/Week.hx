package meta.data;

import flixel.FlxG;

using StringTools;

#if !html5
import sys.FileSystem;
#end

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
	var difficulties:String;
};

class Week
{
	public static var loadedWeeks:Array<Week> = [];

	public static var completedWeeks:Map<String, Bool> = new Map<String, Bool>();

	// used for menu item
	public static var weekNames:Array<String> = [];

	public var directory:String = '';

	public var songs:Array<Array<Dynamic>> = [['Test', 'bf', [255, 255, 255]]];
	public var weekCharacters:Array<String> = ['', 'gf', 'bf'];
	public var weekBefore:String = 'tutorial';
	public var storyName:String = '';
	public var weekName:String = 'Test';
	public var startUnlocked:Bool = true;
	public var hideStoryMode:Bool = false;
	public var hideFreeplay:Bool = false;
	public var difficulties:String = '';

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
		difficulties = weekFile.difficulties;
	}

	public static function loadFromJson(path:String):WeekFile
	{
		return cast CoolUtil.readJson(path);
	}

	public static function loadWeeks()
	{
		loadedWeeks = [];
		weekNames = [];

		var weekFiles:Array<String> = [];
		var directoriesShit:Array<String> = [];

		// check for hardcoded weeks
		for (week in FileSystem.readDirectory(Paths.getPreloadPath('weeks')))
		{
			if (week.endsWith('.json'))
			{
				weekFiles.push(Paths.getPreloadPath('weeks/$week'));
				weekNames.push(CoolUtil.removeExt(week));
				directoriesShit.push('');
			}
		}

		#if MODS_ALLOWED
		// check for modded weeks
		// for root mods directory
		var path:String = ModManager.modStr('weeks');
		if (FileSystem.isDirectory(path))
		{
			for (week in FileSystem.readDirectory(path))
			{
				if (week.endsWith('.json'))
				{
					var daPath:String = '$path/$week';
					if (!weekFiles.contains(daPath))
					{
						weekFiles.push(daPath);
						weekNames.push(CoolUtil.removeExt(week));
						directoriesShit.push('');
					}
				}
			}
		}
		// for mods folders
		for (folder in ModManager.modsDirectories)
		{
			var path:String = ModManager.modStr(folder + '/weeks');
			if (FileSystem.isDirectory(path))
			{
				for (week in FileSystem.readDirectory(path))
				{
					if (week.endsWith('.json'))
					{
						var daPath:String = '$path/$week';
						if (!weekFiles.contains(daPath))
						{
							weekFiles.push(daPath);
							weekNames.push(CoolUtil.removeExt(week));
							directoriesShit.push(folder);
						}
					}
				}
			}
		}
		#end

		// load the weeks
		for (i in 0...weekFiles.length)
		{
			if (weekFiles[i].endsWith('.json'))
			{
				if (directoriesShit[i] != null)
					ModManager.currentModDirectory = directoriesShit[i];
				loadedWeeks[i] = new Week(Week.loadFromJson(weekFiles[i]));
				if (ModManager.currentModDirectory != null)
					loadedWeeks[i].directory = ModManager.currentModDirectory;
			}
		}
		ModManager.currentModDirectory = '';

		// generate unlocked weeks map
		if (FlxG.save.data.completedWeeks != null)
			completedWeeks = FlxG.save.data.completedWeeks;
		for (week in loadedWeeks)
			if (!completedWeeks.exists(week.weekName))
				completedWeeks.set(week.weekName, week.startUnlocked);

		// add custom difficulties
		CoolUtil.difficulties = CoolUtil.defaultDifficulties;
		var lowerCaseDiffs:Array<String> = [];
		for (diff in CoolUtil.defaultDifficulties)
			lowerCaseDiffs.push(diff.toLowerCase());
		for (week in loadedWeeks)
		{
			var diffStr:String = week.difficulties;

			if (diffStr != null)
				diffStr = diffStr.trim();

			if (diffStr != null && diffStr.length > 0)
			{
				var diffs:Array<String> = diffStr.split(',');
				var i:Int = diffs.length - 1;
				while (i > 0)
				{
					if (diffs[i] != null)
					{
						diffs[i] = diffs[i].trim();
						if (diffs[i].length < 1)
							diffs.remove(diffs[i]);
					}
					--i;
				}

				if (diffs.length > 0 && diffs[0].length > 0)
				{
					for (diff in diffs)
						if (!lowerCaseDiffs.contains(diff.toLowerCase()))
							CoolUtil.difficulties.push(diff);
				}
			}
		}
	}

	public static function setCompletedWeek(week:String, ?completed:Bool = true)
	{
		completedWeeks.set(week, true);
		FlxG.save.data.completedWeeks = completedWeeks;
		FlxG.save.flush();
	}

	public static function setDirectoryFromWeek(?data:Week = null)
	{
		ModManager.currentModDirectory = '';
		if (data != null && data.directory != null && data.directory.length > 0)
			ModManager.currentModDirectory = data.directory;
	}
}
