package meta.state.menus;

import flixel.tweens.FlxTween;
import haxe.Json;
import sys.io.File;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import meta.MusicBeat.MusicBeatState;
import meta.data.*;
import meta.data.Alphabet;
import meta.data.dependency.Discord;

using StringTools;

#if !html5
import sys.FileSystem;
#end
#if sys
import sys.thread.Mutex;
import sys.thread.Thread;
#end

class ModsMenuState extends MusicBeatState
{
	var mods:Array<ModMetadata> = [];

	static var curSelected:Int = 0;

	var curSongPlaying:Int = -1;

	static var curDifficulty:Int = 1;

	var infoText:FlxText;
	var subInfoText:FlxText;

	private var grpModsText:FlxTypedGroup<Alphabet>;

	private var mainColor = FlxColor.WHITE;
	private var bg:FlxSprite;
	private var scoreBG:FlxSprite;
	private var bgColorTween:FlxTween;

	override function create()
	{
		super.create();

		// load mods metadata
		for (directory in ModManager.modsDirectories)
			mods.push(new ModMetadata(directory));

		#if !html5
		Discord.changePresence('MODS MENU', 'Main Menu');
		#end

		bg = new FlxSprite().loadGraphic(Paths.image('menus/base/menuDesat'));
		add(bg);

		grpModsText = new FlxTypedGroup<Alphabet>();
		add(grpModsText);

		for (i in 0...mods.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, mods[i].name, true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpModsText.add(songText);
		}

		infoText = new FlxText(5, FlxG.height - 24, 0, "", 32);
		infoText.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		infoText.textField.background = true;
		infoText.textField.backgroundColor = FlxColor.BLACK;
		add(infoText);

		changeSelection();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		bgColorTween = FlxTween.color(bg, 0.35, bg.color, mainColor);

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

		if (controls.BACK)
			Main.switchState(new MainMenuState());

		if (controls.ACCEPT)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			trace(mods[curSelected]);
		}
	}

	function changeSelection(change:Int = 0)
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = mods.length - 1;
		if (curSelected >= mods.length)
			curSelected = 0;

		// set text
		infoText.text = mods[curSelected].description;
		infoText.screenCenter(X);

		// set up color stuffs
		mainColor = mods[curSelected].color;

		// song switching stuffs

		var bullShit:Int = 0;

		for (item in grpModsText.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
				item.alpha = 1;
		}
	}
}

class ModMetadata
{
	public var directory:String;
	public var name:String;
	public var description:String;
	public var color:FlxColor;
	public var restart:Bool;
	public var alphabet:Alphabet;

	public function new(directory:String)
	{
		this.directory = directory;
		this.name = directory;
		this.description = "No description provided.";
		this.color = 0xFF665AFF;
		this.restart = false;

		// try loading json
		var path = ModManager.modStr(directory + "/pack.json");
		if (Paths.exists(path))
		{
			var rawJson:String = CoolUtil.cleanJson(File.getContent(path));
			if (rawJson != null && rawJson.length > 0)
			{
				// dogshit convert
				var data:Dynamic = Json.parse(rawJson);
				var name:String = data.name;
				var description:String = data.description;
				var colors:Array<Int> = data.colors;
				var restart:Bool = data.restart;

				if (name != null && name.length > 0)
					this.name = name;
				if (description != null && description.length > 0)
					this.description = description;
				if (colors != null && colors.length > 2)
					this.color = FlxColor.fromRGB(colors[0], colors[1], colors[2]);

				this.restart = restart;
			}
		}
	}
}
