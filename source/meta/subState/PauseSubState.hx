package meta.subState;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import meta.MusicBeat.MusicBeatSubState;
import meta.data.Alphabet;
import meta.state.*;
import meta.state.menus.*;

class PauseSubState extends MusicBeatSubState
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;

	var menuItems:Array<String> = ['Resume', 'Restart Song', 'Toggle Botplay', 'Exit to menu'];
	var curSelected:Int = 0;

	var pauseMusic:FlxSound;

	var levelInfo:FlxText;
	var levelDifficulty:FlxText;
	var levelBotplay:FlxText;

	public function new(x:Float, y:Float)
	{
		super();

		pauseMusic = new FlxSound().loadEmbedded(Paths.music('breakfast'), true, true);
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		FlxG.sound.list.add(pauseMusic);

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		levelInfo = new FlxText(20, 15, 0, CoolUtil.dashToSpace(PlayState.SONG.song), 32);
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.font("vcr.ttf"), 32);
		levelInfo.updateHitbox();
		add(levelInfo);

		levelDifficulty = new FlxText(20, 15 + 32, 0, CoolUtil.difficultyFromNumber(PlayState.storyDifficulty), 32);
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(Paths.font('vcr.ttf'), 32);
		levelDifficulty.updateHitbox();
		add(levelDifficulty);

		levelBotplay = new FlxText(20, 15 + 64, 0, "BOTPLAY", 32);
		levelBotplay.scrollFactor.set();
		levelBotplay.setFormat(Paths.font('vcr.ttf'), 32);
		levelBotplay.updateHitbox();
		levelBotplay.visible = PlayState.cpuControlled;
		add(levelBotplay);

		levelInfo.alpha = 0;
		levelDifficulty.alpha = 0;
		levelBotplay.alpha = 0;

		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);
		levelBotplay.x = FlxG.width - (levelBotplay.width + 20);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});
		FlxTween.tween(levelBotplay, {alpha: 1, y: levelBotplay.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.7});

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		for (i in 0...menuItems.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, menuItems[i], true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpMenuShit.add(songText);
		}

		changeSelection();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.UI_UP_P)
			changeSelection(-1);
		if (controls.UI_DOWN_P)
			changeSelection(1);

		if (controls.ACCEPT)
		{
			var daSelected:String = menuItems[curSelected];

			switch (daSelected)
			{
				case "Resume":
					close();
				case "Restart Song":
					Main.switchState(this, new PlayState());
				case "Toggle Botplay":
					FlxG.sound.play(Paths.sound('scrollMenu'));
					PlayState.cpuControlled = !PlayState.cpuControlled;
					levelBotplay.visible = PlayState.cpuControlled;
				case "Exit to menu":
					PlayState.cpuControlled = false;
					if (PlayState.isStoryMode)
					{
						ForeverTools.resetMenuMusic(false, true);
						Main.switchState(this, new StoryMenuState());
					}
					else
						Main.switchState(this, new FreeplayState());
			}
		}

		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;
	}

	override function destroy()
	{
		pauseMusic.destroy();

		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		FlxG.sound.play(Paths.sound('scrollMenu'));

		curSelected += change;

		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpMenuShit.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
				item.alpha = 1;
		}
	}
}
