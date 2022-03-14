package meta.state;

import meta.data.Section.SwagSection;
import flixel.util.FlxSort;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxTiledSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import gameObjects.userInterface.notes.*;
import haxe.Json;
import meta.MusicBeat.MusicBeatState;
import meta.data.*;
import meta.data.Conductor.BPMChangeEvent;
import meta.data.Song.SwagSong;
import openfl.Assets;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.geom.ColorTransform;
import openfl.net.FileReference;

using StringTools;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

/**
	As the name implies, this is the class where all of the charting state stuff happens, so when you press 7 the game
	state switches to this one, where you get to chart songs and such. I'm planning on overhauling this entirely in the future
	and making it both more practical and more user friendly.

	based on shubs work :)
**/
class ChartingState extends MusicBeatState
{
	var _file:FileReference;
	var _song:SwagSong;

	var vocals:FlxSound;

	static final keysTotal:Int = 9;

	var eventStuff:Array<Dynamic> = [
		['', "Nothing. Yep, that's right."],
		[
			'Hey!',
			"Plays the \"Hey!\" animation from Bopeebo,\nValue 1: BF = Only Boyfriend, GF = Only Girlfriend,\nSomething else = Both.\nValue 2: Custom animation duration,\nleave it blank for 0.6s"
		],
		[
			'Set GF Speed',
			"Sets GF head bopping speed,\nValue 1: 1 = Normal speed,\n2 = 1/2 speed, 4 = 1/4 speed etc.\nUsed on Fresh during the beatbox parts.\n\nWarning: Value must be integer!"
		],
		[
			'Blammed Lights',
			"Value 1: 0 = Turn off, 1 = Blue, 2 = Green,\n3 = Pink, 4 = Red, 5 = Orange, Anything else = Random.\n\nNote to modders: This effect is starting to get \nREEEEALLY overused, this isn't very creative bro smh."
		],
		['Kill Henchmen', "For Mom's songs, don't use this please, i love them :("],
		[
			'Add Camera Zoom',
			"Used on MILF on that one \"hard\" part\nValue 1: Camera zoom add (Default: 0.015)\nValue 2: UI zoom add (Default: 0.03)\nLeave the values blank if you want to use Default."
		],
		['BG Freaks Expression', "Should be used only in \"school\" Stage!"],
		['Trigger BG Ghouls', "Should be used only in \"schoolEvil\" Stage!"],
		[
			'Play Animation',
			"Plays an animation on a Character,\nonce the animation is completed,\nthe animation changes to Idle\n\nValue 1: Animation to play.\nValue 2: Character (Dad, BF, GF)"
		],
		[
			'Camera Follow Pos',
			"Value 1: X\nValue 2: Y\n\nThe camera won't change the follow point\nafter using this, for getting it back\nto normal, leave both values blank."
		],
		[
			'Alt Idle Animation',
			"Sets a specified suffix after the idle animation name.\nYou can use this to trigger 'idle-alt' if you set\nValue 2 to -alt\n\nValue 1: Character to set (Dad, BF or GF)\nValue 2: New suffix (Leave it blank to disable)"
		],
		[
			'Screen Shake',
			"Value 1: Camera shake\nValue 2: HUD shake\n\nEvery value works as the following example: \"1, 0.05\".\nThe first number (1) is the duration.\nThe second number (0.05) is the intensity."
		],
		[
			'Change Character',
			"Value 1: Character to change (Dad, BF, GF)\nValue 2: New character's name"
		],
		[
			'Change Scroll Speed',
			"Value 1: Scroll Speed Multiplier (1 is default)\nValue 2: Time it takes to change fully in seconds."
		]
	];

	var strumLine:FlxSprite;

	var strumLineCam:FlxObject;

	public static var songPosition:Float = 0;

	/*
	 * WILL BE THE CURRENT / LAST PLACED NOTE
	**/
	var curSelectedNote:Array<Dynamic>;
	var curEventSelected:Int = 0;

	var curNoteType:Int = 0;

	var lastSection:Int = 0;

	var curSection:Int = 0;

	public static var gridSize:Int = 50;

	var fullGrid:FlxTiledSprite;

	var coolGrid:FlxBackdrop;
	var coolGradient:FlxSprite;

	private var dummyArrow:FlxSprite;

	private var curRenderedNotes:FlxTypedGroup<Note>;
	private var curRenderedSustains:FlxTypedGroup<FlxSprite>;
	private var curRenderedNoteType:FlxTypedGroup<AttachedFlxText>;

	// ui shit
	var uiBox:FlxUITabMenu;

	var inputs:Array<FlxUIInputText> = [];
	var steppers:Array<FlxUINumericStepper> = [];
	var dropDowns:Array<FlxUIDropDownMenu> = [];

	// song tab shit
	var songTitleInput:FlxUIInputText;

	// section tab shit
	var stepperLength:FlxUINumericStepper;
	var check_mustHitSection:FlxUICheckBox;
	var check_changeBPM:FlxUICheckBox;
	var stepperSectionBPM:FlxUINumericStepper;
	var check_altAnim:FlxUICheckBox;

	var sectionToCopy:Int = 0;
	var notesCopied:Array<Dynamic>;

	// note tab shit
	var stepperSusLength:FlxUINumericStepper;
	var stepperType:FlxUINumericStepper;

	// events tab shit
	var value1InputText:FlxUIInputText;
	var value2InputText:FlxUIInputText;
	var eventDropDown:FlxUIDropDownMenu;
	var descText:FlxText;
	var selectedEventText:FlxText;

	override public function create()
	{
		super.create();

		// grid
		coolGrid = new FlxBackdrop(null, 1, 1, true, true, 1, 1);
		coolGrid.loadGraphic(Paths.image('UI/forever/base/chart editor/grid'));
		coolGrid.alpha = (32 / 255);
		add(coolGrid);

		// gradient
		coolGradient = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height,
			FlxColor.gradient(FlxColor.fromRGB(188, 158, 255, 200), FlxColor.fromRGB(80, 12, 108, 255), 16));
		coolGradient.alpha = (32 / 255);
		add(coolGradient);

		if (PlayState.SONG != null)
			_song = PlayState.SONG;
		else
			_song = Song.loadFromJson('test', 'test');

		loadSong(_song.song);
		Conductor.changeBPM(_song.bpm);
		Conductor.mapBPMChanges(_song);

		// create new sprite
		var base:FlxSprite = FlxGridOverlay.create(gridSize, gridSize, gridSize * 2, gridSize * 2, true, FlxColor.WHITE, FlxColor.BLACK);
		base.graphic.bitmap.colorTransform(base.graphic.bitmap.rect, new ColorTransform(1, 1, 1, 26 / 255));
		// base graphic change data
		fullGrid = new FlxTiledSprite(null, gridSize * keysTotal, gridSize);
		fullGrid.loadGraphic(base.graphic);
		fullGrid.screenCenter(X);
		fullGrid.height = (FlxG.sound.music.length / Conductor.stepCrochet) * gridSize;
		add(fullGrid);

		// cursor
		dummyArrow = new FlxSprite().makeGraphic(gridSize, gridSize);
		add(dummyArrow);

		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedSustains = new FlxTypedGroup<FlxSprite>();
		curRenderedNoteType = new FlxTypedGroup<AttachedFlxText>();

		// GENERATING THE GRID NOTES!
		// pregenerate assets so it doesnt destroy your ram later
		var extraSize:Int = 6;
		var alphaShit:Float = 88 / 255;
		var sectionLineGraphic:FlxGraphic = FlxG.bitmap.create(gridSize * keysTotal + extraSize, 2, FlxColor.WHITE);
		var sectionCameraGraphic:FlxGraphic = FlxG.bitmap.create(Std.int(gridSize * (keysTotal / 2)), 16 * gridSize, FlxColor.fromRGB(43, 116, 219));
		var sectionStepGraphic:FlxGraphic = FlxG.bitmap.create(gridSize * keysTotal + extraSize, 1, FlxColor.WHITE);

		for (section in 0..._song.notes.length)
		{
			var placement:Float = 16 * gridSize * section;

			// this will be used to regenerate a box that shows what section the camera is focused on
			// oh and section information lol
			var sectionLine:FlxSprite = new FlxSprite(FlxG.width / 2 - gridSize * (keysTotal / 2) - extraSize / 2, placement);
			sectionLine.frames = sectionLineGraphic.imageFrame;
			sectionLine.alpha = alphaShit;

			// section camera
			var sectionExtend:Float = 0;
			if (_song.notes[section].mustHitSection)
				sectionExtend = (gridSize * (keysTotal / 2));

			var sectionCamera:FlxSprite = new FlxSprite(FlxG.width / 2 - gridSize * (keysTotal / 2) + sectionExtend, placement);
			sectionCamera.frames = sectionCameraGraphic.imageFrame;
			sectionCamera.alpha = alphaShit;
			add(sectionCamera);

			// set up section numbers
			for (i in 0...2)
			{
				var sectionNumber:FlxText = new FlxText(0, sectionLine.y - 12, 0, Std.string(section), 20);
				// set the x of the section number
				sectionNumber.x = sectionLine.x - sectionNumber.width - 5;
				if (i == 1)
					sectionNumber.x = sectionLine.x + sectionLine.width + 5;

				sectionNumber.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE);
				sectionNumber.antialiasing = false;
				sectionNumber.alpha = sectionLine.alpha;
				add(sectionNumber);
			}

			for (i in 1...Std.int(_song.notes[section].lengthInSteps / 4))
			{
				// create a smaller section stepper
				var sectionStep:FlxSprite = new FlxSprite(FlxG.width / 2 - gridSize * (keysTotal / 2) - extraSize / 2, placement + (i * (gridSize * 4)));
				sectionStep.frames = sectionStepGraphic.imageFrame;
				sectionStep.alpha = sectionLine.alpha;
				add(sectionStep);
			}

			add(sectionLine);
		}
		updateGrid();

		add(curRenderedSustains);
		add(curRenderedNotes);
		add(curRenderedNoteType);

		strumLineCam = new FlxObject();
		strumLineCam.screenCenter(X);

		// epic strum line
		strumLine = new FlxSprite().makeGraphic(gridSize * keysTotal, 2);
		strumLine.screenCenter(X);
		add(strumLine);

		FlxG.camera.follow(strumLineCam);

		// init ui
		uiBox = new FlxUITabMenu(null, [
			{name: "Song", label: "Song"},
			{name: "Section", label: "Section"},
			{name: "Note", label: "Note"},
			{name: "Events", label: 'Events'}
		], true);
		uiBox.resize(300, 400);
		uiBox.x = 50;
		uiBox.y = 20;
		uiBox.scrollFactor.set();
		add(uiBox);

		// init song tab
		songTitleInput = new FlxUIInputText(10, 10, 70, _song.song, 8);
		inputs.push(songTitleInput);

		var checkVoices = new FlxUICheckBox(10, 30, null, null, "Has voice track", 100);
		checkVoices.checked = _song.needsVoices;
		// _song.needsVoices = checkVoices.checked;
		checkVoices.callback = function()
		{
			_song.needsVoices = checkVoices.checked;
		};

		var checkMuteInst = new FlxUICheckBox(10, 90, null, null, "Mute Instrumental (in editor)", 100);
		checkMuteInst.checked = false;
		checkMuteInst.callback = function()
		{
			FlxG.sound.music.volume = checkMuteInst.checked ? 0 : 1;
		};

		var saveButton:FlxButton = new FlxButton(110, 8, "Save", function()
		{
			save();
		});

		var reloadSong:FlxButton = new FlxButton(saveButton.x + saveButton.width + 10, saveButton.y, "Reload Audio", function()
		{
			loadSong(_song.song);
		});

		var reloadSongJson:FlxButton = new FlxButton(reloadSong.x, saveButton.y + 30, "Reload JSON", function()
		{
			loadJson(_song.song.toLowerCase());
		});

		var loadAutosaveBtn:FlxButton = new FlxButton(reloadSongJson.x, reloadSongJson.y + 30, 'Load Autosave', function()
		{
			PlayState.SONG = Song.loadFromJson(FlxG.save.data.autosave);
			Main.resetState();
		});

		var loadEventBtn:FlxButton = new FlxButton(loadAutosaveBtn.x, loadAutosaveBtn.y + 30, 'Load Events', function()
		{
			var songName:String = CoolUtil.coolFormat(_song.song);
			if (Paths.exists(Paths.json(songName + '/events')))
			{
				// ayo a sussy hack from psych?????
				var events:SwagSong = Song.loadFromJson('events', songName);
				_song.events = events.events;
				updateGrid();
			}
		});

		var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, 65, 1, 1, 1, 339, 0);
		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';

		var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(stepperBPM.x + stepperBPM.width + 5, stepperBPM.y, 0.1, 1, 0.1, 10, 1);
		stepperSpeed.value = _song.speed;
		stepperSpeed.name = 'song_speed';
		steppers.push(stepperSpeed);

		var characters:Array<String> = [];
		var charListPath:String = Paths.getPreloadPath('characterList.txt');
		if (Assets.exists(charListPath))
			characters = CoolUtil.coolTextFile(charListPath);

		#if MODS_ALLOWED
		// check for modded characters
		// for root mods directory
		var path:String = ModManager.modStr('characters');
		if (FileSystem.isDirectory(path))
		{
			for (char in FileSystem.readDirectory(path))
			{
				if (!FileSystem.isDirectory(char) && char.endsWith('.json'))
				{
					var realChar:String = char.substring(0, char.lastIndexOf('.')).substring(char.lastIndexOf('/'), char.length);
					if (!characters.contains(realChar))
						characters.push(realChar);
				}
			}
		}

		// for active mods directory
		if (ModManager.currentModDirectory != null && ModManager.currentModDirectory.length > 0)
		{
			var path:String = ModManager.modStr(ModManager.currentModDirectory + '/characters');
			if (FileSystem.isDirectory(path))
			{
				for (char in FileSystem.readDirectory(path))
				{
					if (!FileSystem.isDirectory(char) && char.endsWith('.json'))
					{
						var realChar:String = char.substring(0, char.lastIndexOf('.')).substring(char.lastIndexOf('/'), char.length);
						if (!characters.contains(realChar))
							characters.push(realChar);
					}
				}
			}
		}
		#end

		if (_song.player1 != null && !characters.contains(_song.player1))
			characters.push(_song.player1);
		var player1DropDown = new FlxUIDropDownMenu(10, 125, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player1 = characters[Std.parseInt(character)];
		});
		if (_song.player1 != null)
			player1DropDown.selectedLabel = _song.player1;
		dropDowns.push(player1DropDown);

		if (_song.player2 != null && !characters.contains(_song.player2))
			characters.push(_song.player2);
		var player2DropDown = new FlxUIDropDownMenu(140, player1DropDown.y, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player2 = characters[Std.parseInt(character)];
		});
		if (_song.player2 != null)
			player2DropDown.selectedLabel = _song.player2;
		dropDowns.push(player2DropDown);

		var realGf:String = _song.gfVersion;
		if (realGf == null)
			realGf = _song.player3;
		if (realGf != null && !characters.contains(realGf))
			characters.push(realGf);
		var gfDropDown = new FlxUIDropDownMenu(player1DropDown.x, 170, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.gfVersion = characters[Std.parseInt(character)];
		});
		if (realGf != null)
			gfDropDown.selectedLabel = realGf;
		dropDowns.push(gfDropDown);

		var stages:Array<String> = [];
		var stageListPath:String = Paths.getPreloadPath('stageList.txt');
		if (Assets.exists(stageListPath))
			stages = CoolUtil.coolTextFile(stageListPath);

		#if MODS_ALLOWED
		// check for modded stages
		// for root mods directory
		var path:String = ModManager.modStr('stages');
		if (FileSystem.isDirectory(path))
		{
			for (stage in FileSystem.readDirectory(path))
			{
				if (!FileSystem.isDirectory(stage) && stage.endsWith('.json'))
				{
					var realStage:String = stage.substring(0, stage.lastIndexOf('.')).substring(stage.lastIndexOf('/'), stage.length);
					if (!stages.contains(realStage))
						stages.push(realStage);
				}
			}
		}

		// for active mods directory
		if (ModManager.currentModDirectory != null && ModManager.currentModDirectory.length > 0)
		{
			var path:String = ModManager.modStr(ModManager.currentModDirectory + '/stages');
			if (FileSystem.isDirectory(path))
			{
				for (stage in FileSystem.readDirectory(path))
				{
					if (!FileSystem.isDirectory(stage) && stage.endsWith('.json'))
					{
						var realStage:String = stage.substring(0, stage.lastIndexOf('.')).substring(stage.lastIndexOf('/'), stage.length);
						if (!stages.contains(realStage))
							stages.push(realStage);
					}
				}
			}
		}
		#end

		if (_song.stage != null && !stages.contains(_song.stage))
			stages.push(_song.stage);
		var stageDropDown = new FlxUIDropDownMenu(player2DropDown.x, gfDropDown.y, FlxUIDropDownMenu.makeStrIdLabelArray(stages, true), function(stage:String)
		{
			_song.stage = stages[Std.parseInt(stage)];
		});
		if (_song.stage != null)
			stageDropDown.selectedLabel = _song.stage;
		dropDowns.push(stageDropDown);

		// add song tab
		var songTab = new FlxUI(null, uiBox);
		songTab.name = "Song";
		songTab.add(songTitleInput);

		songTab.add(checkVoices);
		songTab.add(checkMuteInst);
		songTab.add(saveButton);
		songTab.add(reloadSong);
		songTab.add(reloadSongJson);
		songTab.add(loadAutosaveBtn);
		songTab.add(loadEventBtn);
		songTab.add(new FlxText(stepperBPM.x - 2, stepperBPM.y - 15, 0, 'Song BPM'));
		songTab.add(new FlxText(stepperSpeed.x - 2, stepperSpeed.y - 15, 0, 'Song Speed'));
		songTab.add(stepperBPM);
		songTab.add(stepperSpeed);
		songTab.add(new FlxText(player1DropDown.x - 2, player1DropDown.y - 15, 0, 'Player'));
		songTab.add(new FlxText(player2DropDown.x - 2, player2DropDown.y - 15, 0, 'Opponent'));
		songTab.add(new FlxText(gfDropDown.x - 2, gfDropDown.y - 15, 0, 'Girlfriend'));
		songTab.add(new FlxText(stageDropDown.x - 2, stageDropDown.y - 15, 0, 'Stage'));
		songTab.add(gfDropDown);
		songTab.add(stageDropDown);
		songTab.add(player1DropDown);
		songTab.add(player2DropDown);

		uiBox.addGroup(songTab);

		// init section tab
		var sectionTab = new FlxUI(null, uiBox);
		sectionTab.name = 'Section';

		stepperLength = new FlxUINumericStepper(10, 10, 4, 0, 0, 999, 0);
		stepperLength.value = _song.notes[curSection].lengthInSteps;
		stepperLength.name = 'section_length';
		steppers.push(stepperLength);

		stepperSectionBPM = new FlxUINumericStepper(10, 80, 1, Conductor.bpm, 0, 999, 0);
		stepperSectionBPM.value = Conductor.bpm;
		stepperSectionBPM.name = 'section_bpm';
		steppers.push(stepperSectionBPM);

		var stepperCopy:FlxUINumericStepper = new FlxUINumericStepper(110, 130, 1, 1, -999, 999, 0);
		steppers.push(stepperCopy);

		var copyButton:FlxButton = new FlxButton(10, 150, "Copy Section", function()
		{
			notesCopied = [];
			sectionToCopy = curSection;
			for (i in 0..._song.notes[curSection].sectionNotes.length)
			{
				var note:Array<Dynamic> = _song.notes[curSection].sectionNotes[i];
				notesCopied.push(note);
			}

			var startThing:Float = sectionStartTime();
			var endThing:Float = sectionStartTime(1);
			for (event in _song.events)
			{
				var strumTime:Float = event[0];
				if (endThing > event[0] && event[0] >= startThing)
				{
					var copiedEventArray:Array<Dynamic> = [];
					for (i in 0...event[1].length)
					{
						var eventToPush:Array<Dynamic> = event[1][i];
						copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
					}
					notesCopied.push([strumTime, -1, copiedEventArray]);
				}
			}
		});

		var pasteButton:FlxButton = new FlxButton(10, 200, "Paste Section", function()
		{
			if (notesCopied == null || notesCopied.length < 1)
				return;

			var addToTime:Float = Conductor.stepCrochet * (_song.notes[curSection].lengthInSteps * (curSection - sectionToCopy));

			for (note in notesCopied)
			{
				var copiedNote:Array<Dynamic> = [];
				var newStrumTime:Float = note[0] + addToTime;
				if (note[1] < 0)
				{
					var copiedEventArray:Array<Dynamic> = [];
					for (i in 0...note[2].length)
					{
						var eventToPush:Array<Dynamic> = note[2][i];
						copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
					}
					_song.events.push([newStrumTime, copiedEventArray]);
				}
				else
				{
					if (note[4] != null)
						copiedNote = [newStrumTime, note[1], note[2], note[3], note[4]];
					else
						copiedNote = [newStrumTime, note[1], note[2], note[3]];
					_song.notes[curSection].sectionNotes.push(copiedNote);
				}
			}
			updateGrid();
		});

		var clearSectionButton:FlxButton = new FlxButton(10, 150, "Clear", clearSection);

		var swapSection:FlxButton = new FlxButton(10, 170, "Swap section", function()
		{
			for (i in 0..._song.notes[curSection].sectionNotes.length)
			{
				var note = _song.notes[curSection].sectionNotes[i];
				note[1] = (note[1] + 4) % 8;
				_song.notes[curSection].sectionNotes[i] = note;
			}
			updateGrid();
		});

		check_mustHitSection = new FlxUICheckBox(10, 30, null, null, "Must hit section", 100);
		check_mustHitSection.checked = _song.notes[curSection].mustHitSection;
		check_mustHitSection.callback = function()
		{
			_song.notes[curSection].mustHitSection = check_mustHitSection.checked;
		};

		check_changeBPM = new FlxUICheckBox(10, 60, null, null, "Change BPM", 100);
		check_changeBPM.checked = _song.notes[curSection].changeBPM;
		check_changeBPM.callback = function()
		{
			_song.notes[curSection].changeBPM = check_changeBPM.checked;
		};

		check_altAnim = new FlxUICheckBox(10, 100, null, null, "Alt Animation", 100);
		check_altAnim.checked = _song.notes[curSection].altAnim;
		check_altAnim.callback = function()
		{
			_song.notes[curSection].altAnim = check_altAnim.checked;
		};

		// add section tab
		sectionTab.add(stepperLength);
		sectionTab.add(stepperSectionBPM);
		sectionTab.add(stepperCopy);
		sectionTab.add(check_mustHitSection);
		sectionTab.add(check_altAnim);
		sectionTab.add(check_changeBPM);
		sectionTab.add(copyButton);
		sectionTab.add(pasteButton);
		sectionTab.add(clearSectionButton);
		sectionTab.add(swapSection);

		uiBox.addGroup(sectionTab);

		// init note tab
		var noteTab = new FlxUI(null, uiBox);
		noteTab.name = 'Note';

		stepperSusLength = new FlxUINumericStepper(10, 10, Conductor.stepCrochet / 2, 0, 0, Conductor.stepCrochet * 16);
		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';
		steppers.push(stepperSusLength);

		var applyLength:FlxButton = new FlxButton(100, 10, 'Apply');

		noteTab.add(stepperSusLength);
		noteTab.add(applyLength);

		// note types
		stepperType = new FlxUINumericStepper(10, 30, Conductor.stepCrochet / 125, 0, 0, (Conductor.stepCrochet / 125) + 10); // 10 is placeholder
		stepperType.value = 0;
		stepperType.name = 'note_type';
		steppers.push(stepperType);

		// add note tab
		noteTab.add(stepperType);

		uiBox.addGroup(noteTab);

		// init events tab
		var eventsTab = new FlxUI(null, uiBox);
		eventsTab.name = 'Events';

		#if (LUA_ALLOWED && MODS_ALLOWED)
		// check for custom events
		var leEvents:Array<String> = [];
		// for root mods directory
		var path:String = ModManager.modStr('custom_events');
		if (FileSystem.isDirectory(path))
		{
			for (event in FileSystem.readDirectory(path))
			{
				if (!FileSystem.isDirectory(event) && event != 'readme.txt' && event.endsWith('.txt'))
				{
					var realEvent:String = event.substring(0, event.lastIndexOf('.')).substring(event.lastIndexOf('/'), event.length);
					if (!leEvents.contains(realEvent))
					{
						eventStuff.push([realEvent, File.getContent('$path/$event')]);
						leEvents.push(realEvent);
					}
				}
			}
		}

		// for active mods directory
		if (ModManager.currentModDirectory != null && ModManager.currentModDirectory.length > 0)
		{
			var path:String = ModManager.modStr(ModManager.currentModDirectory + '/custom_events');
			if (FileSystem.isDirectory(path))
			{
				for (event in FileSystem.readDirectory(path))
				{
					if (!FileSystem.isDirectory(event) && event != 'readme.txt' && event.endsWith('.txt'))
					{
						var realEvent:String = event.substring(0, event.lastIndexOf('.')).substring(event.lastIndexOf('/'), event.length);
						if (!leEvents.contains(realEvent))
						{
							eventStuff.push([realEvent, File.getContent('$path/$event')]);
							leEvents.push(realEvent);
						}
					}
				}
			}
		}
		#end

		descText = new FlxText(20, 200, 0, eventStuff[0][0]);

		var leEvents:Array<String> = [];
		for (i in 0...eventStuff.length)
			leEvents.push(eventStuff[i][0]);

		var text:FlxText = new FlxText(20, 30, 0, "Event:");
		eventsTab.add(text);
		eventDropDown = new FlxUIDropDownMenu(20, 50, FlxUIDropDownMenu.makeStrIdLabelArray(leEvents, true), function(pressed:String)
		{
			var selectedEvent:Int = Std.parseInt(pressed);
			descText.text = eventStuff[selectedEvent][1];
			if (curSelectedNote != null && eventStuff != null)
			{
				if (curSelectedNote != null && curSelectedNote[2] == null)
				{
					curSelectedNote[1][curEventSelected][0] = eventStuff[selectedEvent][0];
				}
				updateGrid();
			}
		});
		dropDowns.push(eventDropDown);

		var text:FlxText = new FlxText(20, 90, 0, "Value 1:");
		eventsTab.add(text);
		value1InputText = new FlxUIInputText(20, 110, 100, "");
		inputs.push(value1InputText);

		var text:FlxText = new FlxText(20, 130, 0, "Value 2:");
		eventsTab.add(text);
		value2InputText = new FlxUIInputText(20, 150, 100, "");
		inputs.push(value2InputText);

		// New event buttons
		var removeButton:FlxButton = new FlxButton(eventDropDown.x + eventDropDown.width + 10, eventDropDown.y, '-', function()
		{
			if (curSelectedNote != null && curSelectedNote[2] == null) // Is event note
			{
				if (curSelectedNote[1].length < 2)
				{
					_song.events.remove(curSelectedNote);
					curSelectedNote = null;
				}
				else
					curSelectedNote[1].remove(curSelectedNote[1][curEventSelected]);

				var eventsGroup:Array<Dynamic>;
				--curEventSelected;
				if (curEventSelected < 0)
					curEventSelected = 0;
				else if (curSelectedNote != null && curEventSelected >= (eventsGroup = curSelectedNote[1]).length)
					curEventSelected = eventsGroup.length - 1;

				changeEventSelected();
				updateGrid();
			}
		});
		removeButton.setGraphicSize(Std.int(removeButton.height), Std.int(removeButton.height));
		removeButton.updateHitbox();
		removeButton.color = FlxColor.RED;
		removeButton.label.color = FlxColor.WHITE;
		removeButton.label.size = 12;
		setAllLabelsOffset(removeButton, -30, 0);
		eventsTab.add(removeButton);

		var addButton:FlxButton = new FlxButton(removeButton.x + removeButton.width + 10, removeButton.y, '+', function()
		{
			if (curSelectedNote != null && curSelectedNote[2] == null) // Is event note
			{
				var eventsGroup:Array<Dynamic> = curSelectedNote[1];
				eventsGroup.push(['', '', '']);

				changeEventSelected(1);
				updateGrid();
			}
		});
		addButton.setGraphicSize(Std.int(removeButton.width), Std.int(removeButton.height));
		addButton.updateHitbox();
		addButton.color = FlxColor.GREEN;
		addButton.label.color = FlxColor.WHITE;
		addButton.label.size = 12;
		setAllLabelsOffset(addButton, -30, 0);
		eventsTab.add(addButton);

		var moveLeftButton:FlxButton = new FlxButton(addButton.x + addButton.width + 20, addButton.y, '<', function()
		{
			changeEventSelected(-1);
		});
		moveLeftButton.setGraphicSize(Std.int(addButton.width), Std.int(addButton.height));
		moveLeftButton.updateHitbox();
		moveLeftButton.label.size = 12;
		setAllLabelsOffset(moveLeftButton, -30, 0);
		eventsTab.add(moveLeftButton);

		var moveRightButton:FlxButton = new FlxButton(moveLeftButton.x + moveLeftButton.width + 10, moveLeftButton.y, '>', function()
		{
			changeEventSelected(1);
		});
		moveRightButton.setGraphicSize(Std.int(moveLeftButton.width), Std.int(moveLeftButton.height));
		moveRightButton.updateHitbox();
		moveRightButton.label.size = 12;
		setAllLabelsOffset(moveRightButton, -30, 0);
		eventsTab.add(moveRightButton);

		selectedEventText = new FlxText(addButton.x - 100, addButton.y + addButton.height + 6, (moveRightButton.x - addButton.x) + 186,
			'Selected Event: None');
		selectedEventText.alignment = CENTER;
		eventsTab.add(selectedEventText);

		// add events tab
		eventsTab.add(descText);
		eventsTab.add(value1InputText);
		eventsTab.add(value2InputText);
		eventsTab.add(eventDropDown);

		uiBox.addGroup(eventsTab);

		FlxG.mouse.visible = true;
	}

	var colorSine:Float = 0;

	override public function update(elapsed:Float)
	{
		// recalculate steps
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (FlxG.sound.music.time > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}
		curStep = lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime) / Conductor.stepCrochet);
		updateBeat();

		curSection = Std.int(curStep / 16);

		if (lastSection != curSection)
		{
			updateGrid();
			updateUI();
		}

		lastSection = curSection;

		Conductor.songPosition = FlxG.sound.music.time;

		_song.song = songTitleInput.text;

		super.update(elapsed);

		// strumline camera stuffs!
		strumLine.y = getYfromStrum(Conductor.songPosition);
		strumLineCam.y = strumLine.y + (FlxG.height / 3);

		coolGradient.y = strumLineCam.y - (FlxG.height / 2);
		coolGrid.y = strumLineCam.y - (FlxG.height / 2);

		curRenderedNotes.forEachAlive(function(note:Note)
		{
			note.alpha = 1;
			if (note.strumTime <= Conductor.songPosition)
				note.alpha = 0.4;

			if (curSelectedNote != null)
			{
				var noteData = adjustSide(note.noteData, _song.notes[Math.floor(note.strumTime / (Conductor.stepCrochet * 16))].mustHitSection);

				if (curSelectedNote[0] == note.strumTime
					&& ((curSelectedNote[2] == null && noteData < 0) || (curSelectedNote[2] != null && curSelectedNote[1] == noteData)))
				{
					colorSine += elapsed;
					var colorVal:Float = 0.7 + Math.sin(Math.PI * colorSine) * 0.3;
					note.color = FlxColor.fromRGBFloat(colorVal, colorVal, colorVal, 0.999);
				}
			}
		});

		if (FlxG.mouse.x > fullGrid.x
			&& FlxG.mouse.x < fullGrid.x + fullGrid.width
			&& FlxG.mouse.y > 0
			&& FlxG.mouse.y < getYfromStrum(FlxG.sound.music.length))
		{
			var fakeMouseX = FlxG.mouse.x - fullGrid.x;
			dummyArrow.x = Math.floor(fakeMouseX / gridSize) * gridSize + fullGrid.x;
			if (FlxG.keys.pressed.SHIFT)
				dummyArrow.y = FlxG.mouse.y;
			else
				dummyArrow.y = Math.floor(FlxG.mouse.y / gridSize) * gridSize;
			dummyArrow.visible = true;

			// moved this in here for the sake of not dying
			if (FlxG.mouse.justPressed)
			{
				if (!FlxG.mouse.overlaps(curRenderedNotes))
				{
					// add note funny
					var noteStrum = getStrumTime(dummyArrow.y);

					var notesSection = Math.floor(noteStrum / (Conductor.stepCrochet * 16));
					var noteData = Math.floor((dummyArrow.x - fullGrid.x) / gridSize);
					var leGoodData = adjustSide(noteData, _song.notes[notesSection].mustHitSection);
					var noteType = curNoteType; // define notes as the current type
					var noteSus = 0; // ninja you will NOT get away with this

					if (noteData != keysTotal - 1)
					{
						_song.notes[notesSection].sectionNotes.push([noteStrum, leGoodData, noteSus, noteType]);
						curSelectedNote = _song.notes[notesSection].sectionNotes[_song.notes[notesSection].sectionNotes.length - 1];
						if (FlxG.keys.pressed.CONTROL)
							_song.notes[notesSection].sectionNotes.push([noteStrum, (leGoodData + 4) % 8, noteSus, noteType]);
						generateChartNote(leGoodData, noteStrum, noteSus, 0, notesSection);
					}
					else
					{
						_song.events.push([
							noteStrum,
							[
								[
									eventStuff[Std.parseInt(eventDropDown.selectedId)][0],
									value1InputText.text,
									value2InputText.text
								]
							]
						]);
						curSelectedNote = _song.events[_song.events.length - 1];
						curEventSelected = 0;
						changeEventSelected();
						updateGrid();
					}

					FlxG.save.data.autosave = Json.stringify({
						"song": _song
					});
					FlxG.save.flush();
				}
				else
				{
					curRenderedNotes.forEachAlive(function(note:Note)
					{
						if (FlxG.mouse.overlaps(note))
						{
							var leSection = Math.floor(note.strumTime / (Conductor.stepCrochet * 16));

							if (FlxG.keys.pressed.CONTROL)
							{
								// select note
								if (note.noteData > -1)
								{
									for (i in _song.notes[leSection].sectionNotes)
									{
										if (i.strumTime == note.strumTime && i.noteData % 4 == note.noteData)
										{
											curSelectedNote = i;
											break;
										}
									}
								}
								else
								{
									for (i in _song.events)
									{
										if (i != curSelectedNote && i[0] == note.strumTime)
										{
											curSelectedNote = i;
											curEventSelected = Std.int(curSelectedNote[1].length) - 1;
											changeEventSelected();
											break;
										}
									}
								}
							}
							// remove note
							else
							{
								if (note.noteData > -1)
								{
									for (i in _song.notes[curSection].sectionNotes)
									{
										if (i[0] == note.strumTime && i[1] % 4 == note.noteData)
										{
											if (i == curSelectedNote)
												curSelectedNote = null;
											// trace('FOUND EVIL NOTE!!!');
											_song.notes[curSection].sectionNotes.remove(i);
											break;
										}
									}
								}
								else
								{
									for (i in _song.events)
									{
										if (i[0] == note.strumTime && i == curSelectedNote)
										{
											curSelectedNote = null;
											changeEventSelected();
											break;
										}
									}

									curRenderedNoteType.forEachAlive(function(text:AttachedFlxText)
									{
										if (text.sprTracker == note)
										{
											text.kill();
											curRenderedNoteType.remove(text);
											text.destroy();
										}
									});

									for (i in _song.events)
									{
										if (i[0] == note.strumTime)
										{
											if (i == curSelectedNote)
											{
												curSelectedNote = null;
												changeEventSelected();
											}
											// trace('FOUND EVIL EVENT!!!');
											_song.events.remove(i);
											break;
										}
									}
								}

								note.kill();
								curRenderedNotes.remove(note);
								note.destroy();
							}
						}
					});
				}
				updateUI(true);
			}
		}
		else
			dummyArrow.visible = false;
		var focusBlock:Bool = false;
		for (input in inputs)
		{
			if (input.hasFocus)
			{
				focusBlock = true;
				break;
			}
		}
		if (!focusBlock)
		{
			for (stepper in steppers)
			{
				@:privateAccess
				if (cast(stepper.text_field, FlxUIInputText).hasFocus)
				{
					focusBlock = true;
					break;
				}
			}
		}
		if (!focusBlock)
		{
			for (dropDown in dropDowns)
			{
				if (dropDown.dropPanel.visible)
				{
					focusBlock = true;
					break;
				}
			}
		}
		if (!focusBlock)
		{
			if (FlxG.keys.justPressed.SPACE)
			{
				if (FlxG.sound.music.playing)
					pauseMusic();
				else
				{
					vocals.play();
					FlxG.sound.music.play();
					resyncVocals();
				}
			}
			if (FlxG.mouse.wheel != 0)
			{
				pauseMusic();
				FlxG.sound.music.time = Math.min(Math.max(FlxG.sound.music.time - (FlxG.mouse.wheel * Conductor.stepCrochet * 0.75), 0),
					FlxG.sound.music.length);
			}
			if (FlxG.keys.justPressed.ENTER)
			{
				songPosition = FlxG.sound.music.time;
				PlayState.SONG = _song;
				ForeverTools.killMusic([FlxG.sound.music, vocals]);
				FlxG.mouse.visible = false;
				Main.switchState(new PlayState());
			}
			if (FlxG.keys.justPressed.E)
				changeNoteSustain(Conductor.stepCrochet);
			if (FlxG.keys.justPressed.Q)
				changeNoteSustain(-Conductor.stepCrochet);
			if (FlxG.keys.justPressed.R)
				updateUI();
			if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S)
				save();
		}
	}

	override public function stepHit()
	{
		// call all rendered notes lol
		curRenderedNotes.forEach(function(epicNote:Note)
		{
			if (epicNote.y > strumLineCam.y - FlxG.height / 2 - epicNote.height || epicNote.y < strumLineCam.y + FlxG.height / 2)
			{
				epicNote.alive = true;
				epicNote.visible = true;
			}
			else
			{
				epicNote.alive = false;
				epicNote.visible = false;
			}
		});

		super.stepHit();
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUICheckBox.CLICK_EVENT)
		{
			var check:FlxUICheckBox = cast sender;
			var label = check.getLabel().text;
			switch (label)
			{
				case 'Must hit section':
					_song.notes[curSection].mustHitSection = check.checked;
				case 'Change BPM':
					_song.notes[curSection].changeBPM = check.checked;
				case "Alt Animation":
					_song.notes[curSection].altAnim = check.checked;
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;
			FlxG.log.add(wname);
			// ew what was this before? made it switch cases instead of else if
			switch (wname)
			{
				case 'section_length':
					_song.notes[curSection].lengthInSteps = Std.int(nums.value); // change length
					updateGrid(); // vrrrrmmm
				case 'song_speed':
					_song.speed = nums.value; // change the song speed
				case 'song_bpm':
					var bpm = Std.int(nums.value);
					_song.bpm = bpm;
					Conductor.mapBPMChanges(_song);
					Conductor.changeBPM(bpm);
				case 'note_susLength': // STOP POSTING ABOUT AMONG US
					curSelectedNote[2] = nums.value; // change the currently selected note's length
					updateGrid(); // oh btw I know sus stands for sustain it just bothers me
				case 'note_type':
					curNoteType = Std.int(nums.value); // oh yeah dont forget this has to be an integer
				// set the new note type for when placing notes next!
				case 'section_bpm':
					_song.notes[curSection].bpm = Std.int(nums.value); // redefine the section's bpm
					updateGrid(); // update the note grid
			}
		}
		else if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText))
		{
			if (curSelectedNote != null)
			{
				if (sender == value1InputText)
				{
					curSelectedNote[1][curEventSelected][1] = value1InputText.text;
					updateGrid();
				}
				else if (sender == value2InputText)
				{
					curSelectedNote[1][curEventSelected][2] = value2InputText.text;
					updateGrid();
				}
			}
		}
	}

	function updateUI(?ignoreSectionTab:Bool = false)
	{
		// update section tab
		if (!ignoreSectionTab)
		{
			var sec = _song.notes[curSection];

			stepperLength.value = sec.lengthInSteps;
			check_mustHitSection.checked = sec.mustHitSection;
			check_altAnim.checked = sec.altAnim;
			check_changeBPM.checked = sec.changeBPM;
			stepperSectionBPM.value = sec.bpm;
		}

		// update note tab
		if (curSelectedNote != null)
		{
			if (curSelectedNote[2] != null)
				stepperSusLength.value = curSelectedNote[2];
			else
			{
				eventDropDown.selectedLabel = curSelectedNote[1][curEventSelected][0];
				var selected:Int = Std.parseInt(eventDropDown.selectedId);
				if (selected > 0 && selected < eventStuff.length)
					descText.text = eventStuff[selected][1];
				value1InputText.text = curSelectedNote[1][curEventSelected][1];
				value2InputText.text = curSelectedNote[1][curEventSelected][2];
			}
		}
	}

	function changeNoteSustain(value:Float)
	{
		if (curSelectedNote != null && curSelectedNote[2] != null)
		{
			curSelectedNote[2] += value;
			curSelectedNote[2] = Math.max(curSelectedNote[2], 0);
			updateGrid();
			updateUI(true);
		}
	}

	function getStrumTime(yPos:Float):Float
	{
		return FlxMath.remapToRange(yPos, 0, (FlxG.sound.music.length / Conductor.stepCrochet) * gridSize, 0, FlxG.sound.music.length);
	}

	function getYfromStrum(strumTime:Float):Float
	{
		return FlxMath.remapToRange(strumTime, 0, FlxG.sound.music.length, 0, (FlxG.sound.music.length / Conductor.stepCrochet) * gridSize);
	}

	function sectionStartTime(add:Int = 0):Float
	{
		var daBPM:Float = _song.bpm;
		var daPos:Float = 0;
		for (i in 0...curSection + add)
		{
			if (_song.notes[i] != null)
			{
				if (_song.notes[i].changeBPM)
				{
					daBPM = _song.notes[i].bpm;
				}
				daPos += 4 * (1000 * 60 / daBPM);
			}
		}
		return daPos;
	}

	function clearSection()
	{
		_song.notes[curSection].sectionNotes = [];

		updateGrid();
	}

	function changeEventSelected(change:Int = 0)
	{
		if (curSelectedNote != null && curSelectedNote[2] == null)
		{
			curEventSelected += change;
			if (curEventSelected < 0)
				curEventSelected = Std.int(curSelectedNote[1].length) - 1;
			else if (curEventSelected >= curSelectedNote[1].length)
				curEventSelected = 0;
			selectedEventText.text = 'Selected Event: ' + (curEventSelected + 1) + ' / ' + curSelectedNote[1].length;
		}
		else
		{
			curEventSelected = 0;
			selectedEventText.text = 'Selected Event: None';
		}
		updateUI(true);
	}

	function setAllLabelsOffset(button:FlxButton, x:Float, y:Float)
	{
		for (point in button.labelOffsets)
			point.set(x, y);
	}

	function loadSong(daSong:String)
	{
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		if (vocals != null)
			vocals.stop();

		FlxG.sound.playMusic(Paths.inst(daSong), 1);
		FlxG.sound.music.pause();

		if (_song.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(daSong), true);
		else
			vocals = new FlxSound();
		FlxG.sound.list.add(vocals);

		songPosition = 0;

		pauseMusic();

		Conductor.songPosition = 0;
		FlxG.sound.music.time = Conductor.songPosition;
	}

	function loadJson(song:String)
	{
		var daSong:String = song.toLowerCase();
		PlayState.SONG = Song.loadFromJson(daSong, daSong);
		Main.resetState();
	}

	private function updateGrid()
	{
		while (curRenderedNotes.members.length > 0)
			curRenderedNotes.remove(curRenderedNotes.members[0], true);
		while (curRenderedSustains.members.length > 0)
			curRenderedSustains.remove(curRenderedSustains.members[0], true);
		while (curRenderedNoteType.members.length > 0)
			curRenderedNoteType.remove(curRenderedNoteType.members[0], true);

		// note stuffs
		for (s in 0...3)
		{
			var leSection:Int = curSection + s;
			for (i in _song.notes[leSection].sectionNotes)
			{
				var daNoteAlt = 0;
				if (i.length > 2)
					daNoteAlt = i[3];
				generateChartNote(i[1], i[0], i[2], daNoteAlt, leSection);
			}
		}

		var startThing:Float = sectionStartTime();
		var endThing:Float = sectionStartTime(1);
		curRenderedNoteType.visible = false;
		for (i in _song.events)
		{
			if (endThing > i[0] && i[0] >= startThing)
			{
				var note:Note = generateChartNote(i[1], i[0], i[2], 0, curSection);

				var text:String = 'Event: ' + note.eventName + ' (' + Math.floor(note.strumTime) + ' ms)' + '\nValue 1: ' + note.eventVal1 + '\nValue 2: '
					+ note.eventVal2;
				if (note.eventLength > 1)
					text = note.eventLength + ' Events:\n' + note.eventName;

				var daText:AttachedFlxText = new AttachedFlxText(0, 0, 400, text, 12);
				daText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
				daText.xAdd = -135;
				daText.yAdd = -6;
				daText.borderSize = 1;
				if (note.eventLength > 1)
					daText.yAdd += 8;
				daText.sprTracker = note;
				curRenderedNoteType.add(daText);
			}
		}
		curRenderedNoteType.visible = true;
	}

	private function generateChartNote(daNoteInfo:Dynamic, daStrumTime:Float, ?daSus:Float, daNoteAlt:Float, noteSection:Int)
	{
		var note:Note = ForeverAssets.generateArrow(PlayState.assetModifier, daStrumTime, Std.int(daNoteInfo % 4), 0, daNoteAlt);
		// I love how there's 3 different engines that use this exact same variable name lmao
		note.setGraphicSize(gridSize, gridSize);
		note.updateHitbox();

		note.rawNoteData = daNoteInfo;

		var isEvent:Bool = daSus == null || daSus <= -1;

		if (!isEvent)
			note.sustainLength = daSus;
		else
		{
			note.loadGraphic(Paths.image('eventArrow'));
			note.eventName = getEventName(daNoteInfo);
			note.eventLength = daNoteInfo.length;
			if (daNoteInfo.length < 2)
			{
				note.eventVal1 = daNoteInfo[0][1];
				note.eventVal2 = daNoteInfo[0][2];
			}
			daNoteInfo = keysTotal - 1;
		}

		note.screenCenter(X);
		note.x -= gridSize * keysTotal / 2 - gridSize / 2;
		var xShit:Int = daNoteInfo;
		if (!isEvent)
			xShit = adjustSide(xShit, _song.notes[noteSection].mustHitSection);
		note.x += Math.floor(xShit * gridSize);

		note.y = Math.floor(getYfromStrum(daStrumTime));

		if (isEvent)
		{
			note.x += 53;
			note.y += 16;

			note.noteData = -1;
			daNoteInfo = -1;
		}

		curRenderedNotes.add(note);

		if (daSus > 0)
			curRenderedSustains.add(new FlxSprite(note.x + gridSize / 2.5, note.y + gridSize).makeGraphic(8, Math.floor(getYfromStrum(daSus))));

		return note;
	}

	function getEventName(names:Array<Dynamic>)
	{
		var retStr:String = '';
		var addedOne:Bool = false;
		for (i in 0...names.length)
		{
			if (addedOne)
				retStr += ', ';
			retStr += names[i][0];
			addedOne = true;
		}
		return retStr;
	}

	function adjustSide(noteData:Int, isDad:Bool)
	{
		return isDad ? (noteData + 4) % 8 : noteData;
	}

	function pauseMusic()
	{
		resyncVocals();
		FlxG.sound.music.pause();
		vocals.pause();
	}

	function resyncVocals()
	{
		FlxG.sound.music.pause();
		vocals.pause();
		vocals.time = Conductor.songPosition = FlxG.sound.music.time;
		FlxG.sound.music.play();
		vocals.play();
	}

	function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);

	private function save()
	{
		var json = {
			"song": _song
		};

		var data:String = Json.stringify(json);
		if (data != null && data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), _song.song.toLowerCase() + ".json");
		}
	}

	private function saveEvents()
	{
		var eventsSong:SwagSong = {
			song: _song.song,
			notes: [],
			events: _song.events,
			bpm: _song.bpm,
			needsVoices: _song.needsVoices,
			speed: _song.speed,

			player1: _song.player1,
			player2: _song.player2,
			player3: null,
			gfVersion: _song.gfVersion,
			stage: _song.stage,
			validScore: false
		};

		var json = {
			"song": eventsSong
		}

		var data:String = Json.stringify(json, "\t");
		if (data != null && data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), "events.json");
		}
	}

	function onSaveComplete(_)
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved song data.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_)
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_)
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving song data");
	}
}

class AttachedFlxText extends FlxText
{
	public var sprTracker:FlxSprite;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;

	public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true)
	{
		super(X, Y, FieldWidth, Text, Size, EmbeddedFont);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
		{
			setPosition(sprTracker.x + xAdd, sprTracker.y + yAdd);
			angle = sprTracker.angle;
			alpha = sprTracker.alpha;
		}
	}
}
