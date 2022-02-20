package meta.state.menus;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import gameObjects.userInterface.HealthIcon;
import meta.MusicBeat.MusicBeatState;
import meta.data.*;
import meta.data.Alphabet;
import meta.data.dependency.Discord;
import openfl.media.Sound;

using StringTools;

#if !html5
import sys.FileSystem;
#end
#if sys
import sys.thread.Mutex;
import sys.thread.Thread;
#end

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	static var curSelected:Int = 0;

	var curSongPlaying:Int = -1;

	static var curDifficulty:Int = 1;

	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	var songThread:Thread;
	var threadActive:Bool = true;
	var mutex:Mutex;
	var songToPlay:Sound;

	private var grpSongs:FlxTypedGroup<Alphabet>;

	private var iconArray:Array<HealthIcon> = [];

	private var mainColor = FlxColor.WHITE;
	private var bg:FlxSprite;
	private var scoreBG:FlxSprite;
	private var bgColorTween:FlxTween;

	private var existingDifficulties:Array<Array<String>> = [];

	override function create()
	{
		super.create();

		// reload weeks list
		Week.loadWeeks();

		// load songs metadata from week data
		for (i in 0...Week.loadedWeeks.length)
			addWeek(Week.loadedWeeks[i], i);

		mutex = new Mutex();

		#if !html5
		Discord.changePresence('FREEPLAY MENU', 'Main Menu');
		#end

		bg = new FlxSprite().loadGraphic(Paths.image('menus/base/menuDesat'));
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			ModManager.currentModDirectory = songs[i].directory;

			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - scoreText.width, 0).makeGraphic(Std.int(FlxG.width * 0.35), 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.alignment = CENTER;
		diffText.font = scoreText.font;
		diffText.x = scoreBG.getGraphicMidpoint().x;
		add(diffText);

		add(scoreText);

		changeSelection();
		changeDiff();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, songColor:FlxColor)
	{
		Week.setDirectoryFromWeek(Week.loadedWeeks[weekNum]);

		var coolDifficultyArray = [];
		for (i in CoolUtil.difficulties)
		{
			if (FileSystem.exists(Paths.songJson(songName, songName + '-' + i.toLowerCase()))
				|| (FileSystem.exists(Paths.songJson(songName, songName)) && i == "Normal"))
				coolDifficultyArray.push(i);
		}

		if (coolDifficultyArray.length > 0)
		{
			songs.push(new SongMetadata(songName, weekNum, songCharacter, songColor, ModManager.currentModDirectory));
			existingDifficulties.push(coolDifficultyArray);
		}
	}

	public function addWeek(week:Week, weekNum:Int)
	{
		if (!week.hideFreeplay
			&& ((week.weekBefore != null && week.weekBefore.length > 0 && Week.completedWeeks.get(week.weekBefore)) || week.startUnlocked))
		{
			var num:Int = 0;

			for (song in week.songs)
			{
				addSong(song[0], weekNum, song[1], FlxColor.fromRGB(song[2][0], song[2][1], song[2][2]));

				if (week.weekCharacters.length != 1)
					num++;
			}
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		bgColorTween = FlxTween.color(bg, 0.35, bg.color, mainColor);

		var lerpVal = Main.framerateAdjust(0.1);
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, lerpVal));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;

		if (upP || downP)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			if (upP)
				changeSelection(-1);
			else if (downP)
				changeSelection(1);
		}

		if (controls.UI_LEFT_P)
			changeDiff(-1);
		if (controls.UI_RIGHT_P)
			changeDiff(1);

		if (controls.BACK)
		{
			threadActive = false;
			ForeverTools.resetMenuMusic(false, true);
			Main.switchState(new MainMenuState());
		}

		if (controls.ACCEPT)
		{
			Week.setDirectoryFromWeek(Week.loadedWeeks[songs[curSelected].week]);

			var diffNum:Int = CoolUtil.difficulties.indexOf(existingDifficulties[curSelected][curDifficulty]);
			PlayState.SONG = Song.loadFromJson(CoolUtil.formatSong(songs[curSelected].songName, diffNum), songs[curSelected].songName.toLowerCase());
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = diffNum;

			PlayState.storyWeek = songs[curSelected].week;
			// trace('CUR WEEK' + PlayState.storyWeek);

			if (FlxG.sound.music != null)
				FlxG.sound.music.stop();

			threadActive = false;

			Main.switchState(new PlayState());
		}

		// Adhere the position of all the things (I'm sorry it was just so ugly before I had to fix it Shubs)
		scoreText.text = "PERSONAL BEST:" + lerpScore;
		scoreText.x = FlxG.width - scoreText.width - 5;
		scoreBG.width = scoreText.width + 8;
		scoreBG.x = FlxG.width - scoreBG.width;
		diffText.x = scoreBG.x + (scoreBG.width / 2) - (diffText.width / 2);

		if (songToPlay != null)
		{
			FlxG.sound.playMusic(songToPlay);

			if (FlxG.sound.music.fadeTween != null)
				FlxG.sound.music.fadeTween.cancel();

			FlxG.sound.music.volume = 0.0;
			FlxG.sound.music.fadeIn(1.0, 0.0, 1.0);

			songToPlay = null;

			Paths.clearUnusedMemory();
		}
	}

	var lastDifficulty:String;

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;
		if (lastDifficulty != null && change != 0)
			while (existingDifficulties[curSelected][curDifficulty] == lastDifficulty)
				curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = existingDifficulties[curSelected].length - 1;
		if (curDifficulty > existingDifficulties[curSelected].length - 1)
			curDifficulty = 0;

		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);

		diffText.text = '< ' + existingDifficulties[curSelected][curDifficulty].toUpperCase() + ' >';
		lastDifficulty = existingDifficulties[curSelected][curDifficulty].toUpperCase();
	}

	function changeSelection(change:Int = 0)
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		Week.setDirectoryFromWeek(Week.loadedWeeks[songs[curSelected].week]);

		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);

		// set up color stuffs
		mainColor = songs[curSelected].color;

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
				item.alpha = 1;
		}

		changeDiff();

		if (songThread == null)
		{
			songThread = Thread.create(function()
			{
				while (true)
				{
					if (!threadActive)
						return;

					var index:Null<Int> = Thread.readMessage(false);
					if (index != null)
					{
						if (index == curSelected && threadActive)
						{
							mutex.acquire();
							songToPlay = Paths.inst(songs[curSelected].songName);
							mutex.release();

							curSongPlaying = curSelected;
						}
						// else
						// 	trace("Skipping " + index);
					}
				}
			});
		}

		songThread.sendMessage(curSelected);
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var directory:String = "";

	public function new(song:String, week:Int, songCharacter:String, color:Int, ?directory:String)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		if (directory != null)
			this.directory = directory;
	}
}
