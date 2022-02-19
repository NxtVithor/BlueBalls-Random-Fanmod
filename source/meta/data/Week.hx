package meta.data;

#if !html5
import sys.FileSystem;
#end

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
	public static var weekNames:Array<String> = [];

	public var directory:String;

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
		var weekFiles:Array<String> = [];
		var directoriesShit:Array<String> = [];

		// check for hardcoded weeks
		for (week in FileSystem.readDirectory(Paths.getPreloadPath('weeks')))
		{
			if (week.endsWith('.json'))
			{
				weekFiles.push(Paths.getPreloadPath('weeks/$week'));
				directoriesShit.push(null);
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
						directoriesShit.push(null);
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
				{
					ModManager.currentModDirectory = directoriesShit[i];
					trace(ModManager.currentModDirectory);
				}
				loadedWeeks[i] = new Week(Week.loadFromJson(weekFiles[i]));
				if (directoriesShit[i] != null)
					loadedWeeks[i].directory = directoriesShit[i];
			}
		}
		ModManager.currentModDirectory = '';
	}

	public static function setDirectoryFromWeek(?data:Week = null)
	{
		if (data != null && data.directory != null && data.directory.length > 0)
			ModManager.currentModDirectory = data.directory;
		else
			ModManager.currentModDirectory = '';
	}
}
