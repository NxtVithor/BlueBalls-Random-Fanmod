package gameObjects.userInterface.notes;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import meta.data.Conductor;
import meta.data.Timings;
import meta.state.PlayState;

using StringTools;

/*
	import flixel.FlxG;

	import flixel.animation.FlxBaseAnimation;
	import flixel.graphics.frames.FlxAtlasFrames;
	import flixel.tweens.FlxEase;
	import flixel.tweens.FlxTween; 
 */
class UIStaticArrow extends FlxSprite
{
	/*  Oh hey, just gonna port this code from the previous Skater engine 
		(depending on the release of this you might not have it cus I might rewrite skater to use this engine instead)
		It's basically just code from the game itself but
		it's in a separate class and I also added the ability to set offsets for the arrows.

		uh hey you're cute ;)
	 */
	private var assetModifier:String = '';

	public var initialX:Int;
	public var initialY:Int;

	public var xTo:Float;
	public var yTo:Float;
	public var angleTo:Float;

	public var resetAnim:Float = 0;

	public var setAlpha:Float = (Init.trueSettings.get('Opaque Arrows')) ? 1 : 0.8;

	public function new(x:Float, y:Float, ?assetModifier:String = '')
	{
		// this extension is just going to rely a lot on preexisting code as I wanna try to write an extension before I do options and stuff
		super(x, y);

		this.assetModifier = assetModifier;

		updateHitbox();
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		if (resetAnim > 0)
		{
			resetAnim -= elapsed;
			if (resetAnim <= 0)
			{
				playAnim('static');
				resetAnim = 0;
			}
		}

		super.update(elapsed);
	}

	// literally just character code
	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		if (AnimName == 'confirm')
			alpha = 1;
		else
			alpha = setAlpha;

		animation.play(AnimName, Force, Reversed, Frame);
		centerOffsets();
		centerOrigin();
	}

	public static function getArrowFromNumber(numb:Int)
	{
		// yeah no I'm not writing the same shit 4 times over
		// take it or leave it my guy
		switch (numb)
		{
			case 0:
				return 'left';
			case 1:
				return 'down';
			case 2:
				return 'up';
			case 3:
				return 'right';
			default:
				return '';
		}
	}

	// that last function was so useful I gave it a sequel
	public static function getColorFromNumber(numb:Int)
	{
		switch (numb)
		{
			case 0:
				return 'purple';
			case 1:
				return 'blue';
			case 2:
				return 'green';
			case 3:
				return 'red';
			default:
				return '';
		}
	}
}

class Strumline extends FlxTypedGroup<FlxBasic>
{
	public static var allReceptors:FlxTypedGroup<UIStaticArrow>;

	public var receptors:FlxTypedGroup<UIStaticArrow>;
	public var splashNotes:FlxTypedGroup<NoteSplash>;
	public var notesGroup:FlxTypedGroup<Note>;
	public var holdsGroup:FlxTypedGroup<Note>;
	public var allNotes:FlxTypedGroup<Note>;

	public var autoplay:Bool = true;
	public var downscroll:Bool = false;
	public var character:Character;
	public var playState:PlayState;
	public var displayJudgements:Bool = false;

	public function new(x:Float = 0, playState:PlayState, ?character:Character, ?displayJudgements:Bool = true, ?autoplay:Bool = true,
			?noteSplashes:Bool = false, ?keyAmount:Int = 4, ?downscroll:Bool = false, ?parent:Strumline)
	{
		super();

		if (allReceptors == null)
			allReceptors = new FlxTypedGroup<UIStaticArrow>();

		receptors = new FlxTypedGroup<UIStaticArrow>();
		splashNotes = new FlxTypedGroup<NoteSplash>();
		notesGroup = new FlxTypedGroup<Note>();
		holdsGroup = new FlxTypedGroup<Note>();

		allNotes = new FlxTypedGroup<Note>();

		this.autoplay = autoplay;
		this.downscroll = downscroll;
		this.character = character;
		this.playState = playState;
		this.displayJudgements = displayJudgements;

		for (i in 0...keyAmount)
		{
			var staticArrow:UIStaticArrow = ForeverAssets.generateUIArrows(-25 + x, 25 + (downscroll ? FlxG.height - 200 : 25), i, PlayState.assetModifier);
			staticArrow.ID = i;

			staticArrow.x -= (keyAmount / 2 * Note.swagWidth);
			staticArrow.x += (Note.swagWidth * i);
			receptors.add(staticArrow);
			allReceptors.add(staticArrow);

			staticArrow.initialX = Math.floor(staticArrow.x);
			staticArrow.initialY = Math.floor(staticArrow.y);
			staticArrow.angleTo = 0;
			staticArrow.y -= 10;
			staticArrow.playAnim('static');

			staticArrow.alpha = 0;
			FlxTween.tween(staticArrow, {y: staticArrow.initialY, alpha: staticArrow.setAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});

			if (noteSplashes)
			{
				var noteSplash:NoteSplash = ForeverAssets.generateNoteSplashes('noteSplashes', PlayState.assetModifier, PlayState.changeableSkin, 'UI', i);
				splashNotes.add(noteSplash);
			}
		}

		if (Init.trueSettings.get('Clip Style').toLowerCase() == 'stepmania')
			add(holdsGroup);
		add(receptors);
		if (Init.trueSettings.get('Clip Style').toLowerCase() == 'fnf')
			add(holdsGroup);
		add(notesGroup);
		if (splashNotes != null)
			add(splashNotes);
	}

	public function createSplash(coolNote:Note)
	{
		// play animation in existing notesplashes
		if (splashNotes != null)
			splashNotes.members[coolNote.noteData].playAnim('anim' + Std.string(FlxG.random.int(0, 1) + 1));
	}

	public function push(newNote:Note)
	{
		var chosenGroup = (newNote.isSustainNote ? holdsGroup : notesGroup);
		chosenGroup.add(newNote);
		allNotes.add(newNote);
		chosenGroup.sort(FlxSort.byY, (!Init.trueSettings.get('Downscroll')) ? FlxSort.DESCENDING : FlxSort.ASCENDING);
	}
}
