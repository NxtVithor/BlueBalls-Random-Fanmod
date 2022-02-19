package meta;

import haxe.Exception;
import haxe.Json;
import lime.app.Application;
import meta.data.PlayerSettings;
import openfl.Lib;
import openfl.utils.Assets;
import sys.io.File;

using StringTools;

#if !html5
import sys.FileSystem;
#end

class CoolUtil
{
	public static var difficultyArray:Array<String> = ['EASY', "NORMAL", "HARD"];
	public static var difficultyLength = difficultyArray.length;

	inline public static function difficultyFromNumber(number:Int):String
	{
		return difficultyArray[number];
	}

	public static function formatSong(song:String, diff:Int):String
	{
		var poop:String = spaceToDash(song);
		if (diff != 1)
			poop += '-' + difficultyFromNumber(diff);
		return poop;
	}

	inline public static function getControls()
	{
		return PlayerSettings.player1.controls;
	}

	inline public static function boundTo(value:Float, min:Float, max:Float):Float
	{
		return Math.max(min, Math.min(max, value));
	}

	inline public static function getFPS():Float
	{
		return Lib.current.stage.frameRate;
	}

	inline public static function dashToSpace(string:String):String
	{
		return string.replace("-", " ");
	}

	inline public static function spaceToDash(string:String):String
	{
		return string.replace(" ", "-");
	}

	inline static public function coolFormat(path:String)
	{
		return path.toLowerCase().replace(' ', '-');
	}

	public static function readJson(path:String)
	{
		var content:String = File.getContent(path);
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

	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = Assets.getText(path).trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function returnAssetsLibrary(library:String, ?subDir:String = 'assets/images'):Array<String>
	{
		var libraryArray:Array<String> = [];
		#if !html5
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

	public static function precacheSound(sound:String, ?library:String = null):Void
	{
		precacheSoundFile(Paths.sound(sound, library));
	}

	public static function precacheMusic(sound:String, ?library:String = null):Void
	{
		precacheSoundFile(Paths.music(sound, library));
	}

	private static function precacheSoundFile(file:Dynamic):Void
	{
		if (Assets.exists(file, SOUND) || Assets.exists(file, MUSIC))
			Assets.getSound(file, true);
	}

	public static function truncateFloat(number:Float, precision:Int):Float
	{
		var num = number;
		num = num * Math.pow(10, precision);
		num = Math.round(num) / Math.pow(10, precision);
		return num;
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
		{
			dumbArray.push(i);
		}
		return dumbArray;
	}
}
