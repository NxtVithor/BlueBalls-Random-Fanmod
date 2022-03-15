package meta;

import flixel.FlxCamera;
import openfl.display.BlendMode;
import flixel.tweens.FlxEase;
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

	// funni utils used by scripts
	public static function getFlxEaseByString(?ease:String = '')
	{
		switch (ease.toLowerCase().trim())
		{
			case 'backin':
				return FlxEase.backIn;
			case 'backinout':
				return FlxEase.backInOut;
			case 'backout':
				return FlxEase.backOut;
			case 'bouncein':
				return FlxEase.bounceIn;
			case 'bounceinout':
				return FlxEase.bounceInOut;
			case 'bounceout':
				return FlxEase.bounceOut;
			case 'circin':
				return FlxEase.circIn;
			case 'circinout':
				return FlxEase.circInOut;
			case 'circout':
				return FlxEase.circOut;
			case 'cubein':
				return FlxEase.cubeIn;
			case 'cubeinout':
				return FlxEase.cubeInOut;
			case 'cubeout':
				return FlxEase.cubeOut;
			case 'elasticin':
				return FlxEase.elasticIn;
			case 'elasticinout':
				return FlxEase.elasticInOut;
			case 'elasticout':
				return FlxEase.elasticOut;
			case 'expoin':
				return FlxEase.expoIn;
			case 'expoinout':
				return FlxEase.expoInOut;
			case 'expoout':
				return FlxEase.expoOut;
			case 'quadin':
				return FlxEase.quadIn;
			case 'quadinout':
				return FlxEase.quadInOut;
			case 'quadout':
				return FlxEase.quadOut;
			case 'quartin':
				return FlxEase.quartIn;
			case 'quartinout':
				return FlxEase.quartInOut;
			case 'quartout':
				return FlxEase.quartOut;
			case 'quintin':
				return FlxEase.quintIn;
			case 'quintinout':
				return FlxEase.quintInOut;
			case 'quintout':
				return FlxEase.quintOut;
			case 'sinein':
				return FlxEase.sineIn;
			case 'sineinout':
				return FlxEase.sineInOut;
			case 'sineout':
				return FlxEase.sineOut;
			case 'smoothstepin':
				return FlxEase.smoothStepIn;
			case 'smoothstepinout':
				return FlxEase.smoothStepInOut;
			case 'smoothstepout':
				return FlxEase.smoothStepInOut;
			case 'smootherstepin':
				return FlxEase.smootherStepIn;
			case 'smootherstepinout':
				return FlxEase.smootherStepInOut;
			case 'smootherstepout':
				return FlxEase.smootherStepOut;
		}
		return FlxEase.linear;
	}

	public static function blendModeFromString(blend:String):BlendMode
	{
		switch (blend.toLowerCase().trim())
		{
			case 'add':
				return ADD;
			case 'alpha':
				return ALPHA;
			case 'darken':
				return DARKEN;
			case 'difference':
				return DIFFERENCE;
			case 'erase':
				return ERASE;
			case 'hardlight':
				return HARDLIGHT;
			case 'invert':
				return INVERT;
			case 'layer':
				return LAYER;
			case 'lighten':
				return LIGHTEN;
			case 'multiply':
				return MULTIPLY;
			case 'overlay':
				return OVERLAY;
			case 'screen':
				return SCREEN;
			case 'shader':
				return SHADER;
			case 'subtract':
				return SUBTRACT;
		}
		return NORMAL;
	}

	public static function cameraFromString(cam:String):FlxCamera
	{
		switch (cam.toLowerCase())
		{
			case 'camhud' | 'hud':
				return PlayState.instance.camHUD;
			case 'camother' | 'other':
				return PlayState.instance.camOther;
			default:
				return PlayState.instance.camGame;
		}
	}
}
