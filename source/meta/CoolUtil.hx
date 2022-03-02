package meta;

import meta.data.Week;
import lime.app.Application;
import haxe.Exception;
import haxe.Json;
import meta.data.PlayerSettings;
import meta.state.PlayState;
import openfl.Lib;

using StringTools;

#if sys
import sys.FileSystem;
#end

class CoolUtil
{
	public static var defaultDifficulties:Array<String> = ['Easy', 'Normal', 'Hard'];
	// the chart that has no suffix and is the starting difficulty
	public static var defaultDifficulty:String = 'Normal';

	public static var difficulties:Array<String> = [];

	public static function loadDiffs(week:Int)
	{
		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
		var diffStr:String = Week.loadedWeeks[week].difficulties;
		// fuck you html
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
				CoolUtil.difficulties = diffs;
		}
	}

	public static function formatDifficulty(?num:Int)
	{
		if (num == null)
			num = PlayState.storyDifficulty;

		var fileSuffix:String = difficulties[num];
		if (fileSuffix != defaultDifficulty)
			fileSuffix = '-' + fileSuffix;
		else
			fileSuffix = '';
		return spaceToDash(fileSuffix.toLowerCase());
	}

	inline public static function formatSong(song:String, ?diff:Int)
	{
		return spaceToDash(song) + formatDifficulty(diff);
	}

	inline public static function getControls()
	{
		return PlayerSettings.player1.controls;
	}

	inline public static function boundTo(value:Float, min:Float, max:Float)
	{
		return Math.max(min, Math.min(max, value));
	}

	inline public static function getFPS()
	{
		return Lib.current.stage.frameRate;
	}

	inline public static function dashToSpace(string:String)
	{
		return string.replace("-", " ");
	}

	inline public static function spaceToDash(string:String)
	{
		return string.replace(" ", "-");
	}

	inline static public function coolFormat(path:String)
	{
		return spaceToDash(path.toLowerCase());
	}

	inline static public function getContent(path:String)
	{
		#if sys
		return Paths.readFile(path);
		#else
		#end
	}

	public static function readJson(path:String)
	{
		var content:String = null;
		try
		{
			content = Paths.readFile(path);
		}
		catch (e:Exception)
		{
			throw new Exception('The file doesn\'t exist or is unreadable: $path');
		}
		if (content != null && content.length > 0)
			return Json.parse(cleanJson(content));
		else
			throw new Exception('Invalid JSON file: $path');
	}

	public static function cleanJson(rawJson:String)
	{
		while (!rawJson.endsWith("}"))
			rawJson = rawJson.substr(0, rawJson.length - 1);
		return rawJson;
	}

	inline public static function removeExt(str:String)
	{
		return str.substring(0, str.lastIndexOf('.'));
	}

	public static function coolTextFile(path:String)
	{
		var daList:Array<String> = Paths.readFile(path).trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function returnAssetsLibrary(library:String, ?subDir:String = 'assets/images')
	{
		var libraryArray:Array<String> = [];
		#if sys
		var unfilteredLibrary = FileSystem.readDirectory('$subDir/$library');

		for (directory in unfilteredLibrary)
		{
			if (!directory.contains('.'))
				libraryArray.push(directory);
		}
		trace(libraryArray);
		#end

		return libraryArray;
	}

	// win da time
	inline static public function alert(title:String, message:String)
	{
		#if desktop
		Application.current.window.alert(message, title);
		#end
	}

	public static function precacheSound(sound:String, ?library:String = null)
	{
		precacheSoundFile(Paths.sound(sound, library));
	}

	public static function precacheMusic(sound:String, ?library:String = null)
	{
		precacheSoundFile(Paths.music(sound, library));
	}

	private static function precacheSoundFile(file:Dynamic)
	{
		if (Paths.exists(file))
			Paths.returnSound(null, file);
	}

	public static function truncateFloat(number:Float, precision:Int)
	{
		var num = number;
		num = num * Math.pow(10, precision);
		num = Math.round(num) / Math.pow(10, precision);
		return num;
	}

	public static function numberArray(max:Int, ?min = 0)
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
		{
			dumbArray.push(i);
		}
		return dumbArray;
	}
}
