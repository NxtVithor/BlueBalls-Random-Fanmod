package meta.state;

import meta.data.Conductor.BPMChangeEvent;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxTiledSprite;
import flixel.addons.ui.FlxInputText;
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
import meta.data.Song.SwagSong;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.geom.ColorTransform;
import openfl.net.FileReference;

using StringTools;

#if !html5
import sys.thread.Thread;
#end

/**
	As the name implies, this is the class where all of the charting state stuff happens, so when you press 7 the game
	state switches to this one, where you get to chart songs and such. I'm planning on overhauling this entirely in the future
	and making it both more practical and more user friendly.
**/
class ChartingState extends MusicBeatState
{
	var _file:FileReference;
	var _song:SwagSong;

	var songMusic:FlxSound;
	var vocals:FlxSound;
	private var keysTotal:Int = 8;

	var strumLine:FlxSprite;

	var strumLineCam:FlxObject;

	public static var songPosition:Float = 0;

	/*
	 * WILL BE THE CURRENT / LAST PLACED NOTE
	**/
	var curSelectedNote:Array<Dynamic>;

	var lastSection:Int = 0;

	var curSection:Int = 0;

	public static var selectedNoteAlpha:Float = 0.35;

	public static var gridSize:Int = 50;

	var fullGrid:FlxTiledSprite;

	var coolGrid:FlxBackdrop;
	var coolGradient:FlxSprite;

	private var dummyArrow:FlxSprite;
	private var curRenderedNotes:FlxTypedGroup<Note>;
	private var curRenderedSustains:FlxTypedGroup<FlxSprite>;
	private var curRenderedSections:FlxTypedGroup<FlxBasic>;

	// ui shit
	var uiBox:FlxUITabMenu;

	var typingShit:FlxInputText;

	// secton tab shit
	var stepperLength:FlxUINumericStepper;
	var check_mustHitSection:FlxUICheckBox;
	var check_changeBPM:FlxUICheckBox;
	var stepperSectionBPM:FlxUINumericStepper;
	var check_altAnim:FlxUICheckBox;

	// note tab shit
	var stepperSusLength:FlxUINumericStepper;
	var stepperType:FlxUINumericStepper;

	var infoTxt:FlxText;

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
		fullGrid = new FlxTiledSprite(null, gridSize * keysTotal, gridSize);
		// base graphic change data
		var newAlpha = (26 / 255);
		base.graphic.bitmap.colorTransform(base.graphic.bitmap.rect, new ColorTransform(1, 1, 1, newAlpha));
		fullGrid.loadGraphic(base.graphic);
		fullGrid.screenCenter(X);

		// fullgrid height
		fullGrid.height = (songMusic.length / Conductor.stepCrochet) * gridSize;

		add(fullGrid);

		// cursor
		dummyArrow = new FlxSprite().makeGraphic(gridSize, gridSize);
		add(dummyArrow);

		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedSustains = new FlxTypedGroup<FlxSprite>();
		curRenderedSections = new FlxTypedGroup<FlxBasic>();

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
			var sectionLine:FlxSprite = new FlxSprite(FlxG.width / 2 - (gridSize * (keysTotal / 2)) - (extraSize / 2), placement);
			sectionLine.frames = sectionLineGraphic.imageFrame;
			sectionLine.alpha = alphaShit;

			// section camera
			var sectionExtend:Float = 0;
			if (_song.notes[section].mustHitSection)
				sectionExtend = (gridSize * (keysTotal / 2));

			var sectionCamera:FlxSprite = new FlxSprite(FlxG.width / 2 - (gridSize * (keysTotal / 2)) + (sectionExtend), placement);
			sectionCamera.frames = sectionCameraGraphic.imageFrame;
			sectionCamera.alpha = alphaShit;
			curRenderedSections.add(sectionCamera);

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
				curRenderedSections.add(sectionNumber);
			}

			for (i in 1...Std.int(_song.notes[section].lengthInSteps / 4))
			{
				// create a smaller section stepper
				var sectionStep:FlxSprite = new FlxSprite(FlxG.width / 2 - (gridSize * (keysTotal / 2)) - (extraSize / 2), placement + (i * (gridSize * 4)));
				sectionStep.frames = sectionStepGraphic.imageFrame;
				sectionStep.alpha = sectionLine.alpha;
				curRenderedSections.add(sectionStep);
			}

			curRenderedSections.add(sectionLine);
		}
		updateGrid();

		add(curRenderedSections);
		add(curRenderedSustains);
		add(curRenderedNotes);

		strumLineCam = new FlxObject();
		strumLineCam.screenCenter(X);

		// epic strum line
		strumLine = new FlxSprite().makeGraphic(gridSize * keysTotal, 2);
		strumLine.screenCenter(X);
		add(strumLine);

		FlxG.camera.follow(strumLineCam);

		infoTxt = new FlxText(FlxG.width * 0.775, 50, 0, "", 22);
		infoTxt.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, LEFT);
		infoTxt.scrollFactor.set();
		add(infoTxt);

		// init ui
		uiBox = new FlxUITabMenu(null, [
			{name: "Song", label: "Song"},
			{name: "Section", label: "Section"},
			{name: "Note", label: "Note"}
		], true);
		uiBox.resize(300, 400);
		uiBox.x = 50;
		uiBox.y = 20;
		uiBox.scrollFactor.set();
		add(uiBox);

		// init song tab
		var songTitleInput = new FlxUIInputText(10, 10, 70, _song.song, 8);
		typingShit = songTitleInput;

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
			songMusic.volume = checkMuteInst.checked ? 0 : 1;
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
			PlayState.SONG = Song.parseJSONshit(FlxG.save.data.autosave);
			Main.resetState(this);
		});

		var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, 65, 1, 1, 1, 339, 0);
		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';

		var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(stepperBPM.x + stepperBPM.width + 5, stepperBPM.y, 0.1, 1, 0.1, 10, 1);
		stepperSpeed.value = _song.speed;
		stepperSpeed.name = 'song_speed';

		var characters:Array<String> = CoolUtil.coolTextFile(Paths.txt('characterList'));

		var player1DropDown = new FlxUIDropDownMenu(10, 125, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player1 = characters[Std.parseInt(character)];
		});
		player1DropDown.selectedLabel = _song.player1;

		var player2DropDown = new FlxUIDropDownMenu(140, 125, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player2 = characters[Std.parseInt(character)];
		});

		player2DropDown.selectedLabel = _song.player2;

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
		songTab.add(new FlxText(stepperBPM.x - 2, stepperBPM.y - 15, 0, 'Song BPM'));
		songTab.add(new FlxText(stepperSpeed.x - 2, stepperSpeed.y - 15, 0, 'Song Speed'));
		songTab.add(stepperBPM);
		songTab.add(stepperSpeed);
		songTab.add(new FlxText(player1DropDown.x - 2, player1DropDown.y - 15, 0, 'Player'));
		songTab.add(new FlxText(player2DropDown.x - 2, player2DropDown.y - 15, 0, 'Opponent'));
		songTab.add(player1DropDown);
		songTab.add(player2DropDown);

		uiBox.addGroup(songTab);

		// init section tab
		var sectionTab = new FlxUI(null, uiBox);
		sectionTab.name = 'Section';

		stepperLength = new FlxUINumericStepper(10, 10, 4, 0, 0, 999, 0);
		stepperLength.value = _song.notes[curSection].lengthInSteps;
		stepperLength.name = "section_length";

		stepperSectionBPM = new FlxUINumericStepper(10, 80, 1, Conductor.bpm, 0, 999, 0);
		stepperSectionBPM.value = Conductor.bpm;
		stepperSectionBPM.name = 'section_bpm';

		var stepperCopy:FlxUINumericStepper = new FlxUINumericStepper(110, 130, 1, 1, -999, 999, 0);

		var copyButton:FlxButton = new FlxButton(10, 130, "Copy last section", function()
		{
			copySection(Std.int(stepperCopy.value));
		});

		var clearSectionButton:FlxButton = new FlxButton(10, 150, "Clear", clearSection);

		var swapSection:FlxButton = new FlxButton(10, 170, "Swap section", function()
		{
			for (i in 0..._song.notes[curSection].sectionNotes.length)
			{
				var note = _song.notes[curSection].sectionNotes[i];
				note[1] = (note[1] + 4) % 8;
				_song.notes[curSection].sectionNotes[i] = note;
				updateGrid();
			}
		});

		check_mustHitSection = new FlxUICheckBox(10, 30, null, null, "Must hit section", 100);
		check_mustHitSection.name = 'check_mustHit';
		check_mustHitSection.checked = true;
		// _song.needsVoices = check_mustHit.checked;

		check_changeBPM = new FlxUICheckBox(10, 60, null, null, 'Change BPM', 100);
		check_changeBPM.name = 'check_changeBPM';

		check_altAnim = new FlxUICheckBox(10, 90, null, null, "Alt Animation", 100);
		check_altAnim.name = 'check_altAnim';

		// add section tab
		sectionTab.add(stepperLength);
		sectionTab.add(stepperSectionBPM);
		sectionTab.add(stepperCopy);
		sectionTab.add(check_mustHitSection);
		sectionTab.add(check_altAnim);
		sectionTab.add(check_changeBPM);
		sectionTab.add(copyButton);
		sectionTab.add(clearSectionButton);
		sectionTab.add(swapSection);

		uiBox.addGroup(sectionTab);

		// init note tab
		var noteTab = new FlxUI(null, uiBox);
		noteTab.name = 'Note';

		stepperSusLength = new FlxUINumericStepper(10, 10, Conductor.stepCrochet / 2, 0, 0, Conductor.stepCrochet * 16);
		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';

		var applyLength:FlxButton = new FlxButton(100, 10, 'Apply');

		noteTab.add(stepperSusLength);
		noteTab.add(applyLength);

		// note types
		stepperType = new FlxUINumericStepper(10, 30, Conductor.stepCrochet / 125, 0, 0, (Conductor.stepCrochet / 125) + 10); // 10 is placeholder
		// I have no idea what i'm doing lmfao
		stepperType.value = 0;
		stepperType.name = 'note_type';

		// add note tab
		noteTab.add(stepperType);

		uiBox.addGroup(noteTab);
		// I'm genuinely tempted to go around and remove every instance of the word "sus" it is genuinely killing me inside

		FlxG.mouse.visible = true;
	}

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
			if (songMusic.time > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}
		curStep = lastChange.stepTime + Math.floor((songMusic.time - lastChange.songTime) / Conductor.stepCrochet);
		updateBeat();

		if (FlxG.keys.justPressed.SPACE)
		{
			if (songMusic.playing)
				pauseMusic();
			else
			{
				vocals.play();
				songMusic.play();
				resyncVocals();
			}
		}

		if (FlxG.mouse.wheel != 0)
		{
			pauseMusic();
			songMusic.time = Math.min(Math.max(songMusic.time - (FlxG.mouse.wheel * Conductor.stepCrochet * 0.75), 0), songMusic.length);
		}

		curSection = Std.int(curStep / 16);

		if (lastSection != curSection)
			updateUI();

		lastSection = curSection;

		Conductor.songPosition = songMusic.time;

		_song.song = typingShit.text;

		super.update(elapsed);

		infoTxt.text = "Section: " + curSection + " / " + _song.notes.length + "\nBeat: " + curBeat + "\nStep: " + curStep + "\n";

		// strumline camera stuffs!
		strumLine.y = getYfromStrum(Conductor.songPosition);
		strumLineCam.y = strumLine.y + (FlxG.height / 3);

		coolGradient.y = strumLineCam.y - (FlxG.height / 2);
		coolGrid.y = strumLineCam.y - (FlxG.height / 2);

		if (FlxG.mouse.x > fullGrid.x
			&& FlxG.mouse.x < fullGrid.x + fullGrid.width
			&& FlxG.mouse.y > 0
			&& FlxG.mouse.y < getYfromStrum(songMusic.length))
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

					var noteData = adjustSide(Math.floor((dummyArrow.x - fullGrid.x) / gridSize), _song.notes[curSection].mustHitSection);
					var noteSus = 0; // ninja you will NOT get away with this

					_song.notes[curSection].sectionNotes.push([noteStrum, noteData, noteSus, 0]);

					curSelectedNote = _song.notes[curSection].sectionNotes[_song.notes[curSection].sectionNotes.length - 1];

					curRenderedNotes.forEachAlive(function(note:Note)
					{
						note.alpha = 1;

						if (curSelectedNote[0] == note.strumTime && curSelectedNote[1] % 4 == note.noteData)
							note.alpha = selectedNoteAlpha;
					});

					if (FlxG.keys.pressed.CONTROL)
						_song.notes[curSection].sectionNotes.push([noteStrum, (noteData + 4) % 8, noteSus, 0]);

					FlxG.save.data.autosave = Json.stringify({
						"song": _song
					});
					FlxG.save.flush();
				}
				else
				{
					curRenderedNotes.forEachAlive(function(note:Note)
					{
						note.alpha = 1;

						if (FlxG.mouse.overlaps(note))
						{
							if (FlxG.keys.pressed.CONTROL)
							{
								// select note
								note.alpha = selectedNoteAlpha;

								var swagNum:Int = 0;

								for (i in _song.notes[curSection].sectionNotes)
								{
									if (i.strumTime == note.strumTime && i.noteData % 4 == note.noteData)
										curSelectedNote = _song.notes[curSection].sectionNotes[swagNum];

									swagNum += 1;
								}
							}
							else
							{
								// remove note
								for (i in _song.notes[curSection].sectionNotes)
								{
									if (i[0] == note.strumTime && i[1] % 4 == note.noteData)
										_song.notes[curSection].sectionNotes.remove(i);
								}
								curRenderedNotes.remove(note);
								note.destroy();
							}
						}
					});
				}
				updateGrid();
				updateUI(true);
			}
		}
		else
			dummyArrow.visible = false;

		if (FlxG.keys.justPressed.ENTER)
		{
			songPosition = songMusic.time;

			PlayState.SONG = _song;
			ForeverTools.killMusic([songMusic, vocals]);
			FlxG.mouse.visible = false;
			Main.switchState(this, new PlayState());
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
			stepperSusLength.value = curSelectedNote[2];
	}

	function changeNoteSustain(value:Float)
	{
		if (curSelectedNote != null && curSelectedNote[2] != null)
		{
			curSelectedNote[2] += value;
			curSelectedNote[2] = Math.max(curSelectedNote[2], 0);
			updateGrid();
		}

		updateUI(true);
	}

	function getStrumTime(yPos:Float):Float
	{
		return FlxMath.remapToRange(yPos, 0, (songMusic.length / Conductor.stepCrochet) * gridSize, 0, songMusic.length);
	}

	function getYfromStrum(strumTime:Float):Float
	{
		return FlxMath.remapToRange(strumTime, 0, songMusic.length, 0, (songMusic.length / Conductor.stepCrochet) * gridSize);
	}

	function copySection(?sectionNum:Int = 1)
	{
		var daSec = FlxMath.maxInt(curSection, sectionNum);

		for (note in _song.notes[daSec - sectionNum].sectionNotes)
		{
			var strum = note[0] + Conductor.stepCrochet * (_song.notes[daSec].lengthInSteps * sectionNum);

			var copiedNote:Array<Dynamic> = [strum, note[1], note[2]];
			_song.notes[daSec].sectionNotes.push(copiedNote);
		}

		updateGrid();
	}

	function clearSection()
	{
		_song.notes[curSection].sectionNotes = [];

		updateGrid();
	}

	function loadSong(daSong:String)
	{
		if (songMusic != null)
			songMusic.stop();

		if (vocals != null)
			vocals.stop();

		songMusic = new FlxSound().loadEmbedded(Paths.inst(daSong), false, true);
		if (_song.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(daSong), false, true);
		else
			vocals = new FlxSound();
		FlxG.sound.list.add(songMusic);
		FlxG.sound.list.add(vocals);

		songMusic.play();
		vocals.play();

		songPosition = 0;

		songMusic.time = Math.max(songMusic.time, 0);
		songMusic.time = Math.min(songMusic.time, songMusic.length);

		pauseMusic();

		songMusic.onComplete = function()
		{
			ForeverTools.killMusic([songMusic, vocals]);
			loadSong(daSong);
		};
	}

	function loadJson(song:String)
	{
		var formattedSong:String = CoolUtil.coolFormat(song.toLowerCase());
		PlayState.SONG = Song.loadFromJson(formattedSong, formattedSong);
		Main.resetState(this);
	}

	private function updateGrid()
	{
		curRenderedNotes.clear();
		curRenderedSustains.clear();

		for (section in 0..._song.notes.length)
		{
			for (i in _song.notes[section].sectionNotes)
			{
				// note stuffs
				var daNoteAlt = 0;
				if (i.length > 2)
					daNoteAlt = i[3];
				generateChartNote(i[1], i[0], i[2], daNoteAlt, section);
			}
		}
	}

	private function generateChartNote(daNoteInfo, daStrumTime, daSus, daNoteAlt, noteSection)
	{
		var note:Note = ForeverAssets.generateArrow(PlayState.assetModifier, daStrumTime, daNoteInfo % 4, 0, daNoteAlt);
		// I love how there's 3 different engines that use this exact same variable name lmao
		note.rawNoteData = daNoteInfo;
		note.sustainLength = daSus;
		note.setGraphicSize(gridSize, gridSize);
		note.updateHitbox();

		note.screenCenter(X);
		note.x -= gridSize * keysTotal / 2 - gridSize / 2;
		note.x += Math.floor(adjustSide(daNoteInfo, _song.notes[noteSection].mustHitSection) * gridSize);

		note.y = Math.floor(getYfromStrum(daStrumTime));

		curRenderedNotes.add(note);

		if (daSus > 0)
			curRenderedSustains.add(new FlxSprite(note.x + gridSize / 2.5, note.y + gridSize).makeGraphic(8, Math.floor(getYfromStrum(daSus))));
	}

	function adjustSide(noteData:Int, isDad:Bool)
	{
		return isDad ? (noteData + 4) % 8 : noteData;
	}

	function pauseMusic()
	{
		resyncVocals();
		songMusic.pause();
		vocals.pause();
	}

	function resyncVocals()
	{
		songMusic.pause();
		vocals.pause();
		Conductor.songPosition = songMusic.time;
		vocals.time = Conductor.songPosition;
		songMusic.play();
		vocals.play();
	}

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
