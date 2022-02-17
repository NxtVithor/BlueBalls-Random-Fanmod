package gameObjects;

/**
	The character class initialises any and all characters that exist within gameplay. For now, the character class will
	stay the same as it was in the original source of the game. I'll most likely make some changes afterwards though!
**/
import haxe.Json;
import sys.io.File;
import meta.*;
import meta.data.*;
import meta.data.dependency.FNFSprite;

using StringTools;

// stolen from psych cuz im dumb bruh
typedef CharacterFile =
{
	var animations:Array<Animation>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;
	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
}

typedef Animation =
{
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
}

class Character extends FNFSprite
{
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = 'bf';

	public var holdTimer:Float = 0;

	var danceIdle:Bool = false;

	public var singDuration:Float = 4;

	public var healthIcon:String = 'face';
	public var animationsArray:Array<Animation> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];

	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false)
	{
		super(x, y);
		curCharacter = character;
		this.isPlayer = isPlayer;

		antialiasing = true;

		var path:String = Paths.json('characters/$curCharacter');
		// If a character couldn't be found, change him to BF just to prevent a crash
		if (!Paths.exists(path))
		{
			curCharacter = 'bf';
			path = Paths.json('characters/bf');
		}

		var json:CharacterFile = cast Json.parse(CoolUtil.cleanJson(File.getContent(path)));

		if (Paths.exists(Paths.txt('images/${json.image}')))
			frames = Paths.getPackerAtlas(json.image);
		else
			frames = Paths.getSparrowAtlas(json.image);

		if (json.scale != 1)
		{
			setGraphicSize(Std.int(width * json.scale));
			updateHitbox();
		}

		positionArray = json.position;
		cameraPosition = json.camera_position;

		healthIcon = json.healthicon;
		singDuration = json.sing_duration;
		flipX = !!json.flip_x;
		antialiasing = !json.no_antialiasing;

		animationsArray = json.animations;
		if (animationsArray != null && animationsArray.length > 0)
		{
			for (anim in animationsArray)
			{
				var animAnim:String = '' + anim.anim;
				var animName:String = '' + anim.name;
				var animFps:Int = anim.fps;
				var animLoop:Bool = !!anim.loop; // Bruh
				var animIndices:Array<Int> = anim.indices;
				if (animIndices != null && animIndices.length > 0)
					animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
				else
					animation.addByPrefix(animAnim, animName, animFps, animLoop);

				if (anim.offsets != null && anim.offsets.length > 1)
					addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
			}
		}
		else
			quickAnimAdd('idle', 'BF idle dance');

		danceIdle = animation.getByName('danceLeft') != null && animation.getByName('danceRight') != null;

		dance();

		if (isPlayer) // fuck you ninjamuffin lmao
			flipX = !flipX;

		this.x = x;
		this.y = y;
	}

	override function update(elapsed:Float)
	{
		if (!isPlayer)
		{
			if (animation.curAnim.name.startsWith('sing'))
				holdTimer += elapsed;

			if (holdTimer >= Conductor.stepCrochet * 0.001 * singDuration)
			{
				dance();
				holdTimer = 0;
			}
		}

		if (animation.curAnim.finished && animation.getByName(animation.curAnim.name + '-loop') != null)
			playAnim(animation.curAnim.name + '-loop');

		super.update(elapsed);
	}

	private var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance()
	{
		if (!debugMode)
		{
			if (danceIdle)
			{
				danced = !danced;

				if (danced)
					playAnim('danceRight');
				else
					playAnim('danceLeft');
			}
			else if (animation.getByName('idle') != null)
				playAnim('idle');
		}
	}

	override public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		if (animation.getByName(AnimName) != null)
			super.playAnim(AnimName, Force, Reversed, Frame);

		if (curCharacter.startsWith('gf'))
		{
			if (AnimName == 'singLEFT')
				danced = true;
			else if (AnimName == 'singRIGHT')
				danced = false;

			if (AnimName == 'singUP' || AnimName == 'singDOWN')
				danced = !danced;
		}
	}

	public function quickAnimAdd(name:String, anim:String)
	{
		animation.addByPrefix(name, anim, 24, false);
	}
}
