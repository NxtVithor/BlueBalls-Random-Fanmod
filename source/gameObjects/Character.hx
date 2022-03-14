package gameObjects;

/**
	The character class initialises any and all characters that exist within gameplay. For now, the character class will
	stay the same as it was in the original source of the game. I'll most likely make some changes afterwards though!
**/
import flixel.util.FlxColor;
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
	public var heyTimer:Float = 0;

	public var specialAnim:Bool = false;

	public var idleSuffix:String = '';

	var danceIdle:Bool = false;

	public var singDuration:Float = 4;

	public var healthIcon:String = 'face';
	public var animationsArray:Array<Animation> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];

	public var healthBarColor:FlxColor;

	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false)
	{
		super(x, y);
		curCharacter = character;
		this.isPlayer = isPlayer;

		antialiasing = true;

		var path:String = Paths.json('characters/$curCharacter');
		// If a character couldn't be found, change him to BF to prevent a crash
		if (!Paths.exists(path))
		{
			curCharacter = 'bf';
			path = Paths.json('characters/bf');
		}

		var charData:CharacterFile = cast CoolUtil.readJson(path);

		if (Paths.exists(Paths.txt('images/${charData.image}')))
			frames = Paths.getPackerAtlas(charData.image);
		else
			frames = Paths.getSparrowAtlas(charData.image);

		if (charData.scale != 1)
		{
			setGraphicSize(Std.int(width * charData.scale));
			updateHitbox();
		}

		positionArray = charData.position;
		cameraPosition = charData.camera_position;

		healthIcon = charData.healthicon;
		healthBarColor = FlxColor.fromRGB(charData.healthbar_colors[0], charData.healthbar_colors[1], charData.healthbar_colors[2]);

		singDuration = charData.sing_duration;
		flipX = !!charData.flip_x;
		antialiasing = !charData.no_antialiasing;

		animationsArray = charData.animations;
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

		recalculateDanceIdle();
		dance();

		if (isPlayer) // fuck you ninjamuffin lmao
			flipX = !flipX;

		this.x = x;
		this.y = y;
	}

	override function update(elapsed:Float)
	{
		if (heyTimer > 0)
		{
			heyTimer -= elapsed;
			if (heyTimer <= 0)
			{
				if (specialAnim && animation.curAnim.name == 'hey' || animation.curAnim.name == 'cheer')
				{
					specialAnim = false;
					dance();
				}
				heyTimer = 0;
			}
		}
		else if (specialAnim && animation.curAnim.finished)
		{
			specialAnim = false;
			dance();
		}

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
		if (!debugMode && !specialAnim)
		{
			if (danceIdle)
			{
				danced = !danced;

				if (danced)
					playAnim('danceRight' + idleSuffix);
				else
					playAnim('danceLeft' + idleSuffix);
			}
			else if (animation.getByName('idle' + idleSuffix) != null)
				playAnim('idle' + idleSuffix);
		}
	}

	public var danceEveryNumBeats:Int = 2;

	public function recalculateDanceIdle()
	{
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (animation.getByName('danceLeft' + idleSuffix) != null && animation.getByName('danceRight' + idleSuffix) != null);

		if (lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;
			if (danceIdle)
				calc /= 2;
			else
				calc *= 2;
			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}
	}

	override public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		specialAnim = false;

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
