package meta.subState;

import flixel.math.FlxMath;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import gameObjects.Boyfriend;
import meta.MusicBeat.MusicBeatSubState;
import meta.data.Conductor;
import meta.state.*;
import meta.state.menus.*;

class GameOverSubstate extends MusicBeatSubState
{
	var bf:Boyfriend;
	var stageSuffix:String = "";

	var camFollow:FlxObject;
	var camFollowPos:FlxObject;

	var updateCam:Bool = false;

	var isEnding:Bool = false;

	public function new(x:Float, y:Float)
	{
		var daBoyfriendType = PlayState.boyfriend.curCharacter;
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

		PlayState.boyfriend.destroy();

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(bf.getGraphicMidpoint().x, bf.getGraphicMidpoint().y);
		add(camFollow);

		FlxG.sound.play(Paths.sound('fnf_loss_sfx' + stageSuffix));
		Conductor.changeBPM(100);

		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2));
		add(camFollowPos);

		bf.playAnim('firstDeath');
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

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
					Main.switchState(this, new PlayState());
				});
			});
		}

		if (controls.BACK)
		{
			if (PlayState.isStoryMode)
			{
				ForeverTools.resetMenuMusic(false, true);
				Main.switchState(this, new StoryMenuState());
			}
			else
			{
				FlxG.sound.music.stop();
				Main.switchState(this, new FreeplayState());
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
	}
}
