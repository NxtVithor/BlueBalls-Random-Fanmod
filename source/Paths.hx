package;

/*
	Aw hell yeah! something I can actually work on!
 */
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import lime.utils.Assets;
import meta.CoolUtil;
import openfl.display.BitmapData;
import openfl.display3D.textures.Texture;
import openfl.media.Sound;
import openfl.system.System;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import sys.FileSystem;
import sys.io.File;

class Paths
{
	// Here we set up the paths class. This will be used to
	// Return the paths of assets and call on those assets as well.
	inline public static var SOUND_EXT = "ogg";

	// level we're loading
	static var currentLevel:String;

	// set the current level top the condition of this function if called
	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	// set up mod variables
	public static var modFolder:String = "mods";
	// public static var currentModsFolder:String = "";
	public static var modsFolders:Array<String>;

	static var ignoredModsFolders:Array<String> = ["fonts", "images", "music", "shaders", "songs", "sounds", "weeks"];

	// stealing my own code from psych engine
	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static var currentTrackedTextures:Map<String, Texture> = [];
	public static var currentTrackedSounds:Map<String, Sound> = [];

	public static function excludeAsset(key:String)
	{
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> = [];

	/// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory()
	{
		// clear non local assets in the tracked assets list
		var counter:Int = 0;
		for (key in currentTrackedAssets.keys())
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
			{
				var obj = currentTrackedAssets.get(key);
				if (obj != null)
				{
					var isTexture:Bool = currentTrackedTextures.exists(key);
					if (isTexture)
					{
						var texture = currentTrackedTextures.get(key);
						texture.dispose();
						texture = null;
						currentTrackedTextures.remove(key);
					}
					@:privateAccess
					if (openfl.Assets.cache.hasBitmapData(key))
					{
						openfl.Assets.cache.removeBitmapData(key);
						FlxG.bitmap._cache.remove(key);
					}
					// trace('removed $key, ' + (isTexture ? 'is a texture' : 'is not a texture'));
					obj.destroy();
					currentTrackedAssets.remove(key);
					counter++;
				}
			}
		}
		// trace('removed $counter assets');
		// run the garbage collector for good measure lmfao
		System.gc();
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];

	public static function clearStoredMemory()
	{
		// clear anything not in the tracked assets and sounds lists
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			if (obj != null && !currentTrackedAssets.exists(key))
			{
				openfl.Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
			}
			localTrackedAssets.remove(key);
		}

		// clear all sounds that are cached
		for (key in currentTrackedSounds.keys())
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && key != null)
			{
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
				localTrackedAssets.remove(key);
			}
		}

		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
	}

	public static function returnGraphic(key:String, ?library:String, ?textureCompression:Bool = false)
	{
		var path = getPath('images/$key.png', IMAGE, library);
		if (FileSystem.exists(path))
		{
			if (!currentTrackedAssets.exists(key))
			{
				var bitmap = BitmapData.fromFile(path);
				var newGraphic:FlxGraphic;
				if (textureCompression)
				{
					var texture = FlxG.stage.context3D.createTexture(bitmap.width, bitmap.height, BGRA, true, 0);
					texture.uploadFromBitmapData(bitmap);
					currentTrackedTextures.set(key, texture);
					bitmap.dispose();
					bitmap.disposeImage();
					bitmap = null;
					// trace('new texture $key, bitmap is $bitmap');
					newGraphic = FlxGraphic.fromBitmapData(BitmapData.fromTexture(texture), false, key, false);
				}
				else
				{
					newGraphic = FlxGraphic.fromBitmapData(bitmap, false, key, false);
					// trace('new bitmap $key, not textured');
				}
				currentTrackedAssets.set(key, newGraphic);
			}
			localTrackedAssets.push(key);
			return currentTrackedAssets.get(key);
		}
		// trace('oh no ' + key + ' is returning null NOOOO');
		return null;
	}

	inline public static function soundPath(key:String, path:String, ?library:String)
	{
		var gottenPath:String = getPath('$path/$key.$SOUND_EXT', SOUND, library);
		return gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);
	}

	public static function returnSound(path:String, key:String, ?library:String):Any
	{
		// I hate this so god damn much
		var gottenPath:String = soundPath(key, path, library);
		// trace(gottenPath);
		if (!currentTrackedSounds.exists(gottenPath))
			currentTrackedSounds.set(gottenPath, Sound.fromFile('./' + gottenPath));
		localTrackedAssets.push(key);
		return currentTrackedSounds.get(gottenPath);
	}

	public static function getPath(file:String, type:AssetType, ?library:Null<String>, ?allowModding:Bool = true)
	{
		/*
			Okay so, from what I understand, this loads in the current path based on the level
			we're in (if a library is not specified), say like week 1 or something, 
			then checks if the assets you're looking for are there.
			if not, it checks the shared assets folder.
		 */

		// well I'm rewriting it so that the library is the path and it looks for the file type
		// later lmao I don't really wanna rn

		#if MODS_ALLOWED
		// check if the file is modded
		if (allowModding)
		{
			for (folder in modsFolders)
			{
				var daPath:String = mod(folder + '/' + file);
				if (FileSystem.exists(daPath))
					return daPath;
			}

			if (isModded(file))
				return mod(file);
		}
		#end

		// if a library is specified
		if (library != null)
			return getLibraryPath(file, library);

		// else, return the preload path
		return getPreloadPath(file);
	}

	// files!
	public static function exists(path:String)
	{
		#if MODS_ALLOWED
		// repeat bruh
		for (folder in modsFolders)
		{
			if (FileSystem.exists(mod(folder + '/' + file)))
				return true;
		}

		if (isModded(path))
			return true;
		else
			return OpenFlAssets.exists(path);
		#else
		return OpenFlAssets.exists(path);
		#end
	}

	/*  
		actually I could just combine all of these main functions into one and really call it a day
		it's similar and would use one function with a switch case
		for now I'm more focused on getting this to run than anything and I'll clean out the code later as I do want to organise
		everything later 
	 */
	static public function getLibraryPath(file:String, library = "preload")
	{
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String)
	{
		return '$library/$file';
	}

	inline static function getPreloadPath(file:String)
	{
		var returnPath:String = 'assets/$file';
		if (!FileSystem.exists(returnPath))
			returnPath = CoolUtil.coolFormat(returnPath);
		return returnPath;
	}

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
	{
		return getPath(file, type, library);
	}

	inline static public function txt(key:String, ?library:String)
	{
		return getPath('$key.txt', TEXT, library);
	}

	inline static public function shader(key:String, ?library:String)
	{
		return getPath('shaders/$key.frag', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function offsetTxt(key:String, ?library:String)
	{
		return getPath('images/characters/$key.txt', TEXT, library);
	}

	inline static public function json(key:String, ?library:String)
	{
		return getPath('$key.json', TEXT, library);
	}

	inline static public function songJson(song:String, secondSong:String, ?library:String)
	{
		return json('songs/${CoolUtil.coolFormat(song)}/${CoolUtil.coolFormat(secondSong)}', library);
	}

	static public function sound(key:String, ?library:String):Dynamic
	{
		var sound:Sound = returnSound('sounds', key, library);
		return sound;
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String):Dynamic
	{
		var file:Sound = returnSound('music', key, library);
		return file;
	}

	inline static public function voices(song:String):Any
	{
		var songKey:String = '${CoolUtil.coolFormat(song)}/Voices';
		var voices = returnSound('songs', songKey);
		return voices;
	}

	inline static public function inst(song:String):Any
	{
		var songKey:String = '${CoolUtil.coolFormat(song)}/Inst';
		var inst = returnSound('songs', songKey);
		return inst;
	}

	inline static public function image(key:String, ?library:String, ?textureCompression:Bool = false)
	{
		var returnAsset:FlxGraphic = returnGraphic(key, library, textureCompression);
		return returnAsset;
	}

	inline static public function font(key:String)
	{
		return 'assets/fonts/$key';
	}

	// mods!
	inline static public function mod(key:String)
	{
		return '$modFolder/$key';
	}

	public static function getModsFolders()
	{
		#if MODS_ALLOWED
		// get folders list
		var folders:Array<String> = FileSystem.readDirectory(modFolder);

		// check if folder should be ignored
		var foldersScan = function()
		{
			// i hate this so much
			for (folder in folders)
			{
				if (ignoredModsFolders.contains(folder) || !FileSystem.isDirectory(mod(folder)))
					folders.remove(folder);
			}
		};
		foldersScan();
		// second time because it is buggy bruh
		foldersScan();

		// return da result
		return folders;
		#else
		return [];
		#end
	}

	inline static public function isModded(path:String)
	{
		#if MODS_ALLOWED
		return FileSystem.exists(mod(path));
		#else
		return false;
		#end
	}

	// animated sprites!
	inline static public function getSparrowAtlas(key:String, ?library:String)
	{
		var graphic:FlxGraphic = returnGraphic(key, library);
		return (FlxAtlasFrames.fromSparrow(graphic, File.getContent(file('images/$key.xml', library))));
	}

	inline static public function getPackerAtlas(key:String, ?library:String)
	{
		return (FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library)));
	}
}
