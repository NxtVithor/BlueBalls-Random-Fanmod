package meta;

import lime.app.Application;
import haxe.Json;
import openfl.utils.Assets;
import meta.data.PlayerSettings;
import openfl.Lib;
import sys.io.File;

using StringTools;

#if !html5
import sys.FileSystem;
#end

class CoolUtil
{
	// tymgus45
	public static var difficultyArray:Array<String> = ['EASY', "NORMAL", "HARD"];
	public static var difficultyLength = difficultyArray.length;

	public static function difficultyFromNumber(number:Int):String
	{
		return difficultyArray[number];
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

	inline public static function readJson(path:String)
	{
		return Json.parse(File.getContent(path).trim());
	}

	public static function cleanJson(rawJson:String)
	{
		while (!rawJson.endsWith("}"))
			rawJson = rawJson.substr(0, rawJson.length - 1);
		return rawJson;
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

		for (folder in unfilteredLibrary)
		{
			if (!folder.contains('.'))
				libraryArray.push(folder);
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
