package meta.state.menus;

import meta.data.Week;
import flixel.tweens.FlxTween;
import haxe.Json;
import sys.io.File;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import meta.MusicBeat.MusicBeatState;
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

	static var curDifficulty:Int = 1;

	var activeText:FlxText;
	var darkBG:FlxSprite;

	var infoText:FlxText;

	private var grpModsText:FlxTypedGroup<Alphabet>;

	private var mainColor = FlxColor.WHITE;
	private var bg:FlxSprite;
	private var bgColorTween:FlxTween;

	override function create()
	{
		super.create();

		// load mods list
		ModManager.loadModsDirectories();
		ModManager.loadModsList();

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

		activeText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		activeText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		darkBG = new FlxSprite(activeText.x - activeText.width, 0).makeGraphic(Std.int(FlxG.width * 0.35), 46, 0xFF000000);
		darkBG.alpha = 0.6;
		add(darkBG);

		add(activeText);

		infoText = new FlxText(0, 0, FlxG.width, "", 32);
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
		{
			ModManager.saveModsList();
			Week.loadWeeks();
			Main.switchState(new MainMenuState());
		}

		if (controls.ACCEPT)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			var leDir:String = mods[curSelected].directory;
			ModManager.modsList.set(leDir, !ModManager.modsList.get(leDir));
		}

		// set text shit
		activeText.text = ModManager.modsList.get(mods[curSelected].directory) ? "ACTIVE" : "INACTIVE";
		activeText.x = FlxG.width - activeText.width - 5;
		darkBG.width = activeText.width + 8;
		darkBG.x = FlxG.width - darkBG.width;
		infoText.text = mods[curSelected].description;
		infoText.y = FlxG.height - infoText.height;
	}

	function changeSelection(change:Int = 0)
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = mods.length - 1;
		if (curSelected >= mods.length)
			curSelected = 0;

		// set up color stuffs
		mainColor = mods[curSelected].color;

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
	public var description:String = "No description provided.";
	public var color:FlxColor = 0xFF665AFF;
	public var restart:Bool = false;

	public function new(directory:String)
	{
		this.directory = directory;
		this.name = directory;

		var path = ModManager.modStr(directory + "/pack.json");
		if (Paths.exists(path))
		{
			var rawJson:String = File.getContent(path);
			if (rawJson != null && rawJson.length > 0)
			{
				var data:Dynamic = Json.parse(rawJson);

				if (data.name != null && data.name.length > 0)
					this.name = data.name;
				if (data.description != null && data.description.length > 0)
					this.description = data.description;
				if (data.colors != null && data.colors.length > 2)
					this.color = FlxColor.fromRGB(data.colors[0], data.colors[1], data.colors[2]);

				this.restart = data.restart;
			}
		}
	}
}
