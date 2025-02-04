package meta.subState;

import flixel.math.FlxPoint;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import gameObjects.Boyfriend;
import meta.MusicBeat.MusicBeatSubState;
import meta.data.Conductor;
import meta.state.*;
import meta.state.menus.*;

class GameOverSubstate extends MusicBeatSubState
{
	public static var instance:GameOverSubstate;

	public static var bf:Boyfriend;

	var stageSuffix:String = "";

	public static var characterName:String = 'bf';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';

	var camFollow:FlxPoint;
	var camFollowPos:FlxObject;

	var updateCam:Bool = false;

	var isEnding:Bool = false;

	public function new(x:Float, y:Float)
	{
		var daBoyfriendType = PlayState.instance.boyfriend.curCharacter;
		var daBf:String = '';
		switch (daBoyfriendType)
		{
			case 'bf-og':
				daBf = daBoyfriendType;
			case 'bf-pixel':
				daBf = 'bf-pixel-dead';
				stageSuffix = '-pixel';
			default:
				daBf = 'bf-dead';
		}

		super();

		Conductor.songPosition = 0;

		bf = new Boyfriend(x, y, daBf);
		add(bf);

		PlayState.instance.boyfriend.destroy();

		FlxG.sound.play(Paths.sound('fnf_loss_sfx' + stageSuffix));
		Conductor.changeBPM(100);

		camFollow = new FlxPoint(bf.getGraphicMidpoint().x, bf.getGraphicMidpoint().y);

		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2));
		add(camFollowPos);

		bf.playAnim('firstDeath');
	}

	override function create()
	{
		// for lua again man
		instance = this;
		PlayState.instance.callOnLuas('onGameOverStart', []);

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		PlayState.instance.callOnLuas('onUpdate', [elapsed]);

		if (controls.ACCEPT && !isEnding)
		{
			isEnding = true;
			bf.playAnim('deathConfirm', true);
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music('gameOverEnd' + stageSuffix));
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					Main.switchState(new PlayState());
				});
			});
			PlayState.instance.callOnLuas('onGameOverConfirm', [true]);
		}

		if (controls.BACK)
		{
			if (PlayState.isStoryMode)
			{
				ForeverTools.resetMenuMusic(false, true);
				Main.switchState(new StoryMenuState());
			}
			else
			{
				FlxG.sound.music.stop();
				Main.switchState(new FreeplayState());
			}
		}

		if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.curFrame == 12)
		{
			FlxG.camera.follow(camFollowPos, LOCKON, 1);
			updateCam = true;
		}

		if (updateCam)
		{
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 0.6, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		}

		if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.finished)
			FlxG.sound.playMusic(Paths.music('gameOver' + stageSuffix));

		PlayState.instance.callOnLuas('onUpdatePost', [elapsed]);
	}
}
