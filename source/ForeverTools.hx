package;

import flixel.FlxG;
import flixel.system.FlxSound;
import meta.data.*;

/**
	This class is used as an extension to many other forever engine stuffs, please don't delete it as it is not only exclusively used in forever engine
	custom stuffs, and is instead used globally.
**/
class ForeverTools
{
	// set up maps and stuffs
	public static function resetMenuMusic(resetVolume:Bool = false, forceMusicToPlay:Bool = false)
	{
		if (forceMusicToPlay || FlxG.sound.music == null)
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'), resetVolume ? 0 : 0.7);
			if (resetVolume)
				FlxG.sound.music.fadeIn(4, 0, 0.7);
			// placeholder bpm
			Conductor.changeBPM(102);
		}
	}

	public static function returnSkinAsset(asset:String, assetModifier:String = 'base', changeableSkin:String = 'default', baseLibrary:String,
			?defaultChangeableSkin:String = 'default', ?defaultBaseAsset:String = 'base'):String
	{
		var realAsset = '$baseLibrary/$changeableSkin/$assetModifier/$asset';
		var failedShit = function()
		{
			return !Paths.exists(Paths.getPath('images/' + realAsset + '.png', IMAGE));
		}

		// awesome tree lmao
		if (failedShit())
		{
			realAsset = '$baseLibrary/$asset-$assetModifier';
			if (failedShit())
			{
				realAsset = '$baseLibrary/$asset';
				if (failedShit())
				{
					realAsset = '$baseLibrary/$defaultChangeableSkin/$assetModifier/$asset';
					if (failedShit())
					{
						realAsset = '$baseLibrary/$defaultChangeableSkin/$defaultBaseAsset/$asset';
						if (failedShit())
							realAsset = asset;
					}
				}
			}
		}

		return realAsset;
	}

	public static function killMusic(songsArray:Array<FlxSound>)
	{
		// neat function thing for songs
		for (i in 0...songsArray.length)
		{
			// stop
			songsArray[i].stop();
			songsArray[i].destroy();
		}
	}
}
