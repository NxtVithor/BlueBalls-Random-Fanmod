package meta.state;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.FlxVideo;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import gameObjects.*;
import gameObjects.userInterface.*;
import gameObjects.userInterface.notes.*;
import gameObjects.userInterface.notes.Strumline.UIStaticArrow;
import meta.*;
import meta.MusicBeat.MusicBeatState;
import meta.data.*;
import meta.data.Script.DebugLuaText;
import meta.data.Script.ModchartSprite;
import meta.data.Script.ModchartText;
import meta.data.Section.SwagSection;
import meta.data.Song.SwagSong;
import meta.data.shaders.Shaders;
import meta.state.menus.*;
import meta.subState.*;
import openfl.events.KeyboardEvent;
import openfl.filters.BitmapFilter;
import openfl.filters.ShaderFilter;
import openfl.media.Sound;

using StringTools;

#if sys
import sys.FileSystem;
#end
#if sys
import meta.data.dependency.Discord;
#end

class PlayState extends MusicBeatState
{
	public static var instance:PlayState;

	public static var startTimer:FlxTimer;

	public static var curStage:String = '';
	public static var SONG:SwagSong;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 2;

	// lazy moment
	private var isTutorial:Bool = false;

	public static var inst:Sound;

	public static var vocals:FlxSound;

	public static var campaignScore:Int = 0;

	public var isDead:Bool = false;

	public var dadOpponent:Character;
	public var gf:Character;
	public var boyfriend:Boyfriend;

	public static var BF_X:Float = 770;
	public static var BF_Y:Float = 100;
	public static var DAD_X:Float = 100;
	public static var DAD_Y:Float = 100;
	public static var GF_X:Float = 400;
	public static var GF_Y:Float = 130;

	public static var assetModifier:String = 'base';
	public static var changeableSkin:String = 'default';

	public var unspawnNotes:Array<Note> = [];

	private var ratingArray:Array<String> = [];
	private var allSicks:Bool = true;

	// if you ever wanna add more keys
	private var numberOfKeys:Int = 4;

	// get it cus release
	// I'm funny just trust me
	private var curSection:Int = 0;

	private var camFollow:FlxPoint;
	private var camFollowPos:FlxObject;

	private static var prevCamFollow:FlxPoint;

	// Discord RPC variables
	public static var songDetails:String = "";
	public static var detailsSub:String = "";
	public static var detailsPausedText:String = "";

	private var curSong:String = "";
	private var gfSpeed:Int = 1;

	public static var health:Float = 1; // mario
	public static var combo:Int = 0;

	public static var misses:Int = 0;

	public var generatedMusic:Bool = false;

	public static var seenCutscene:Bool = false;

	private var startingSong:Bool = false;

	public var paused:Bool = false;

	var startedCountdown:Bool = false;
	var inCutscene:Bool = false;
	var camZooming:Bool = false;

	var video:FlxVideo;

	var canPause:Bool = true;

	var previousFrameTime:Int = 0;
	var songTime:Float = 0;

	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var dialogueHUD:FlxCamera;

	// used by tutorial
	var cameraTwn:FlxTween;

	public static var animatedShaders:Map<String, DynamicShaderHandler> = new Map<String, DynamicShaderHandler>();

	public var shaderUpdates:Array<Float->Void> = [];

	public var shader_chromatic_abberation:ChromaticAberrationEffect;

	// lua shit
	public static var luaArray:Array<Script> = [];

	public var luaShaders:Map<String, DynamicShaderHandler> = new Map<String, DynamicShaderHandler>();
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
	public var camGameShaders:Array<ShaderEffect> = [];
	public var camHUDShaders:Array<ShaderEffect> = [];
	public var camOtherShaders:Array<ShaderEffect> = [];

	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;

	var camDisplaceX:Float = 0;
	var camDisplaceY:Float = 0; // might not use depending on result

	public static var cameraSpeed:Float = 1;

	public static var defaultCamZoom:Float = 1.05;

	public var forceZoom:Array<Float> = [0, 0, 0, 0];

	public static var songScore:Int = 0;

	public static var songHits:Int = 0;

	var storyDifficultyText:String = "";

	public static var iconRPC:String = "";

	public static var songLength:Float = 0;

	public var endingSong:Bool = false;

	public var stageBuild:Stage;

	public var uiHUD:ClassHUD;

	public static var daPixelZoom:Float = 6;
	public static var determinedChartType:String = "";

	// strumlines
	public var cpuStrums:Strumline;
	public var playerStrums:Strumline;

	public var strumLineNotes:FlxTypedGroup<UIStaticArrow>;
	public var strumLines:FlxTypedGroup<Strumline>;

	private var allUIs:Array<FlxCamera> = [];

	// stores the last judgement object
	public static var lastRating:FlxSprite;
	// stores the last combo objects in an array
	public static var lastCombo:Array<FlxSprite>;

	// botplay i think
	public static var cpuControlled:Bool = false;

	// no cheaters lol
	public static var usedGameplayFeature:Bool = false;

	private var keyPressByController:Bool = false;

	// at the beginning of the playstate
	override public function create()
	{
		super.create();

		instance = this;

		// reset any variables that are static
		songScore = 0;
		combo = 0;
		health = 1;
		misses = 0;
		songHits = 0;
		// sets up the combo object array
		lastCombo = [];

		Timings.callAccuracy();

		assetModifier = 'base';
		changeableSkin = 'default';

		// stop any existing music tracks playing
		resetMusic();

		// create the game camera
		camGame = new FlxCamera();

		// create the hud camera (separate so the hud stays on screen)
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		// create the camera for other things
		camOther = new FlxCamera();
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxCamera.defaultCameras = [camGame];
		FlxG.cameras.add(camHUD);
		allUIs.push(camHUD);

		persistentUpdate = true;
		persistentDraw = true;

		// default song
		if (SONG == null)
			SONG = Song.loadFromJson('test', 'test');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		/// here we determine the chart type!
		// determine the chart type here
		determinedChartType = "FNF";

		// set up a class for the stage type in here afterwards
		curStage = "";
		// call the song's stage if it exists
		if (SONG.stage != null)
			curStage = SONG.stage;

		// cache shit
		displayRating('sick', 'early', true);
		popUpCombo(true);

		stageBuild = new Stage(curStage);
		add(stageBuild);

		/*
			Everything related to the stages aside from things done after are set in the stage class!
			this means that the girlfriend's type, boyfriend's position, dad's position, are all there

			It serves to clear clutter and can easily be destroyed later. The problem is,
			I don't actually know if this is optimised, I just kinda roll with things and hope
			they work. I'm not actually really experienced compared to a lot of other developers in the scene,
			so I don't really know what I'm doing, I'm just hoping I can make a better and more optimised
			engine for both myself and other modders to use!
		 */

		// set up characters here too
		var gfChar:String = SONG.gfVersion;
		if (gfChar == null)
		{
			if (SONG.player3 != null)
				gfChar = SONG.player3;
			else
				gfChar = stageBuild.returnGFtype(curStage);
			SONG.gfVersion = gfChar;
		}
		gf = new Character(GF_X, GF_Y, gfChar);
		gf.scrollFactor.set(0.95, 0.95);

		dadOpponent = new Character(DAD_X, DAD_Y, SONG.player2);
		boyfriend = new Boyfriend(BF_X, BF_Y, SONG.player1);

		var camPos:FlxPoint = new FlxPoint(gf.getGraphicMidpoint().x, gf.getGraphicMidpoint().y);
		camPos.x += gf.cameraPosition[0];
		camPos.y += gf.cameraPosition[1];

		stageBuild.repositionPlayers(curStage, boyfriend, dadOpponent, gf);
		stageBuild.dadPosition(curStage, boyfriend, dadOpponent, gf, camPos);

		GF_X = gf.x;
		GF_Y = gf.y;
		DAD_X = dadOpponent.x;
		DAD_Y = dadOpponent.y;
		BF_X = boyfriend.x;
		BF_Y = boyfriend.y;

		changeableSkin = Init.trueSettings.get("UI Skin");
		if (curStage.startsWith("school") && (determinedChartType == "FNF"))
			assetModifier = 'pixel';

		// add characters
		add(gf);

		// add limo cus dumb layering
		if (curStage == 'limo')
			add(stageBuild.limo);

		add(dadOpponent);
		add(boyfriend);

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		setOnLuas('boyfriendName', boyfriend.curCharacter);
		setOnLuas('dadName', dadOpponent.curCharacter);
		setOnLuas('gfName', gf.curCharacter);

		add(stageBuild.foreground);

		// force them to dance
		dadOpponent.dance();
		gf.dance();
		boyfriend.dance();

		// set song position before beginning
		Conductor.songPosition = -(Conductor.crochet * 4);

		// EVERYTHING SHOULD GO UNDER THIS, IF YOU PLAN ON SPAWNING SOMETHING LATER ADD IT TO STAGEBUILD OR FOREGROUND
		// darken everything but the arrows and ui via a flxsprite
		if (Init.trueSettings.get('Stage Opacity') != 100)
		{
			var darknessBG:FlxSprite = new FlxSprite(FlxG.width * -0.5, FlxG.height * -0.5).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
			darknessBG.alpha = (100 - Init.trueSettings.get('Stage Opacity')) / 100;
			darknessBG.scrollFactor.set(0, 0);
			add(darknessBG);
		}

		// generate the song
		generateSong();

		// set the camera position to the center of the stage
		camPos.set(gf.x + (gf.frameWidth / 2), gf.y + (gf.frameHeight / 2));

		// create the game camera
		camFollow = new FlxPoint(camPos.x, camPos.y);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(camPos.x, camPos.y);
		// check if the camera was following someone previously
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}

		add(camFollowPos);

		// actually set the camera up
		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		moveCamera(!SONG.notes[0].mustHitSection);

		// initialize ui elements
		startingSong = true;

		// strums setup
		strumLines = new FlxTypedGroup<Strumline>();
		strumLines.cameras = [camHUD];

		var placement = 20 + FlxG.width / 2;
		cpuStrums = new Strumline(placement - FlxG.width / 4, this, dadOpponent, false, true, false, 4, Init.trueSettings.get('Downscroll'));
		cpuStrums.visible = !Init.trueSettings.get('Centered Notefield');
		playerStrums = new Strumline(placement + (!Init.trueSettings.get('Centered Notefield') ? FlxG.width / 4 : 0), this, boyfriend, true, false, true, 4,
			Init.trueSettings.get('Downscroll'));

		strumLines.add(cpuStrums);
		strumLines.add(playerStrums);

		for (i in 0...playerStrums.receptors.length)
		{
			setOnLuas('defaultPlayerStrumX' + i, playerStrums.receptors.members[i].x);
			setOnLuas('defaultPlayerStrumY' + i, playerStrums.receptors.members[i].y);
		}
		for (i in 0...cpuStrums.receptors.length)
		{
			setOnLuas('defaultOpponentStrumX' + i, cpuStrums.receptors.members[i].x);
			setOnLuas('defaultOpponentStrumY' + i, cpuStrums.receptors.members[i].y);
		}

		add(strumLines);

		strumLineNotes = new FlxTypedGroup<UIStaticArrow>();
		for (strumline in strumLines)
			strumline.receptors.forEachAlive(function(arrow:UIStaticArrow)
			{
				strumLineNotes.add(arrow);
			});

		uiHUD = new ClassHUD();
		add(uiHUD);
		uiHUD.cameras = [camHUD];

		// create a hud over the hud camera for dialogue
		dialogueHUD = new FlxCamera();
		dialogueHUD.bgColor.alpha = 0;
		FlxG.cameras.add(dialogueHUD);

		#if LUA_ALLOWED
		// lua shit
		var path:String = Paths.getPreloadPath('scripts');
		// for global scripts
		var scripts:Array<String> = FileSystem.readDirectory(path);
		for (script in FileSystem.readDirectory(path))
			if (script.endsWith('.lua'))
				scripts.push('$path/$script');
		#if MODS_ALLOWED
		// for root mods directory
		path = ModManager.modStr('scripts');
		if (FileSystem.isDirectory(path))
		{
			for (script in FileSystem.readDirectory(path))
				if (script.endsWith('.lua'))
					scripts.push('$path/$script');
		}
		// for active mods directory
		if (ModManager.currentModDirectory != null && ModManager.currentModDirectory.length > 0)
		{
			path = ModManager.modStr(ModManager.currentModDirectory + '/scripts');
			if (FileSystem.isDirectory(path))
			{
				for (script in FileSystem.readDirectory(path))
					if (script.endsWith('.lua'))
						scripts.push('$path/$script');
			}
		}
		#end
		for (script in scripts)
			// bitch why
			if (script.endsWith('.lua'))
				luaArray.push(new Script(script));

		// for the stage script
		path = '';
		path = Paths.script('stages/$curStage');
		if (Paths.exists(path))
			luaArray.push(new Script(path));

		// for the characters scripts
		var charBase:String = 'characters';
		var charScripts:Array<String> = [
			Paths.script('$charBase/${boyfriend.curCharacter}'),
			Paths.script('$charBase/${dadOpponent.curCharacter}'),
			Paths.script('$charBase/${gf.curCharacter}')
		];
		for (script in charScripts)
			if (Paths.exists(script))
				luaArray.push(new Script(script));

		// for the song script
		path = Paths.script('data/${curSong.toLowerCase()}/script');
		if (Paths.exists(path))
			luaArray.push(new Script(path));
		#end

		keysArray = [
			copyKey(Init.gameControls.get('LEFT')[0]),
			copyKey(Init.gameControls.get('DOWN')[0]),
			copyKey(Init.gameControls.get('UP')[0]),
			copyKey(Init.gameControls.get('RIGHT')[0])
		];

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		usedGameplayFeature = cpuControlled;

		Paths.clearUnusedMemory();

		// call the funny intro cutscene depending on the song
		if (!skipCutscenes())
			songIntroCutscene();
		else
			startCountdown();

		/**
		 * SHADERS
		 *
		 * This is a highly experimental code by gedehari to support runtime shader parsing.
		 * Usually, to add a shader, you would make it a class, but now, I modified it so
		 * you can parse it from a file.
		 *
		 * This feature is planned to be used for modcharts
		 * (at this time of writing, it's not available yet).
		 *
		 * This example below shows that you can apply shaders as a FlxCamera filter.
		 * the GraphicsShader class accepts two arguments, one is for vertex shader, and
		 * the second is for fragment shader.
		 * Pass in an empty string to use the default vertex/fragment shader.
		 *
		 * Next, the Shader is passed to a new instance of ShaderFilter, neccesary to make
		 * the filter work. And that's it!
		 *
		 * To access shader uniforms, just reference the `data` property of the GraphicsShader
		 * instance.
		 *
		 * Thank you for reading! -gedehari
		 */

		// Uncomment the code below to apply the effect

		// var shader:GraphicsShader = new GraphicsShader("", Paths.readFile(Paths.shaderFrag("vhs")));

		// FlxG.camera.setFilters([new ShaderFilter(shader)]);

		callOnLuas('onCreatePost', []);
	}

	public var closeLuas:Array<Script> = [];

	public function callOnLuas(event:String, args:Array<Dynamic>):Dynamic
	{
		var returnVal:Dynamic = Script.Function_Continue;
		#if LUA_ALLOWED
		for (i in 0...luaArray.length)
		{
			var ret:Dynamic = luaArray[i].call(event, args);
			if (ret != Script.Function_Continue)
				returnVal = ret;
		}

		for (i in 0...closeLuas.length)
		{
			luaArray.remove(closeLuas[i]);
			closeLuas[i].stop();
		}
		#end
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic)
	{
		#if LUA_ALLOWED
		for (i in 0...luaArray.length)
		{
			luaArray[i].set(variable, arg);
		}
		#end
	}

	public static function copyKey(arrayToCopy:Array<FlxKey>):Array<FlxKey>
	{
		var copiedArray:Array<FlxKey> = arrayToCopy.copy();
		var i:Int = 0;
		var len:Int = copiedArray.length;

		while (i < len)
		{
			if (copiedArray[i] == NONE)
			{
				copiedArray.remove(NONE);
				--i;
			}
			i++;
			len = copiedArray.length;
		}
		return copiedArray;
	}

	public function addTextToDebug(text:String)
	{
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText)
		{
			spr.y += 20;
		});

		if (luaDebugGroup.members.length > 34)
		{
			var blah = luaDebugGroup.members[34];
			blah.destroy();
			luaDebugGroup.remove(blah);
		}
		luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup));
		#end
	}

	private function gamepadKeyShit()
	{
		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
		keyPressByController = !FlxG.keys.justReleased.ANY
			&& !FlxG.keys.pressed.ANY
			&& gamepad != null
			&& (!gamepad.justReleased.ANY || gamepad.pressed.ANY);

		if (keyPressByController)
		{
			var controlArray:Array<Bool> = [controls.LEFT_P, controls.DOWN_P, controls.UP_P, controls.RIGHT_P];
			for (i in 0...controlArray.length)
			{
				if (controlArray[i])
					onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
			}

			var controlReleaseArray:Array<Bool> = [controls.LEFT_R, controls.DOWN_R, controls.UP_R, controls.RIGHT_R];
			for (i in 0...controlArray.length)
			{
				if (controlReleaseArray[i])
					onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
			}
		}
	}

	var keysArray:Array<Dynamic>;

	public function onKeyPress(event:KeyboardEvent)
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);

		if (key >= 0
			&& !playerStrums.autoplay
			&& (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || keyPressByController)
			&& (FlxG.keys.enabled && !paused && (FlxG.state.active || FlxG.state.persistentUpdate)))
		{
			if (generatedMusic)
			{
				var previousTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;
				// improved this a little bit, maybe its a lil
				var possibleNoteList:Array<Note> = [];
				var pressedNotes:Array<Note> = [];
				var notesStopped:Bool = false;

				playerStrums.allNotes.forEachAlive(function(daNote:Note)
				{
					if (daNote.noteData == key && daNote.canBeHit && !daNote.isSustainNote && !daNote.tooLate && !daNote.wasGoodHit)
						possibleNoteList.push(daNote);
				});
				possibleNoteList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

				// if there is a list of notes that exists for that control
				if (possibleNoteList.length > 0)
				{
					for (epicNote in possibleNoteList)
					{
						for (doubleNote in pressedNotes)
						{
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1)
								destroyNote(playerStrums, doubleNote);
							else
								notesStopped = true;
						}

						// eee jack detection before was not super good
						if (!notesStopped)
						{
							goodNoteHit(epicNote, boyfriend, playerStrums);
							pressedNotes.push(epicNote);
						}
					}
				}
				else // else just call bad notes
					if (!Init.trueSettings.get('Ghost Tapping'))
					{
						vocals.volume = 0;
						missNoteCheck(true, true, key, boyfriend, true);
						// painful if statement
						if (combo > 5 && gf.animOffsets.exists('sad'))
							gf.playAnim('sad');
						callOnLuas('noteMissPress', [key]);
					}
				Conductor.songPosition = previousTime;
			}

			if (playerStrums.receptors.members[key] != null && playerStrums.receptors.members[key].animation.curAnim.name != 'confirm')
				playerStrums.receptors.members[key].playAnim('pressed');

			callOnLuas('onKeyPress', [key]);
		}
	}

	public function onKeyRelease(event:KeyboardEvent)
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);

		if (FlxG.keys.enabled && !paused && (FlxG.state.active || FlxG.state.persistentUpdate) && key >= 0)
		{
			// receptor reset
			if (playerStrums.receptors.members[key] != null)
				playerStrums.receptors.members[key].playAnim('static');

			callOnLuas('onKeyRelease', [key]);
		}
	}

	inline public function getControl(key:String)
	{
		return Reflect.getProperty(controls, key);
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if (key == keysArray[i][j])
						return i;
				}
			}
		}
		return -1;
	}

	private var preventLuaRemove:Bool = false;

	override public function destroy()
	{
		#if LUA_ALLOWED
		preventLuaRemove = true;
		for (i in 0...luaArray.length)
		{
			luaArray[i].call('onDestroy', []);
			luaArray[i].stop();
		}
		luaArray = [];
		#end

		usedGameplayFeature = false;

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		super.destroy();
	}

	public function addShaderToCamera(cam:String, effect:Dynamic)
	{ // STOLE FROM ANDROMEDA

		switch (cam.toLowerCase())
		{
			case 'camhud' | 'hud':
				camHUDShaders.push(effect);
				var newCamEffects:Array<BitmapFilter> = []; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
				for (i in camHUDShaders)
				{
					newCamEffects.push(new ShaderFilter(i.shader));
				}
				camHUD.setFilters(newCamEffects);
			case 'camother' | 'other':
				camOtherShaders.push(effect);
				var newCamEffects:Array<BitmapFilter> = []; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
				for (i in camOtherShaders)
				{
					newCamEffects.push(new ShaderFilter(i.shader));
				}
				camOther.setFilters(newCamEffects);
			case 'camgame' | 'game':
				camGameShaders.push(effect);
				var newCamEffects:Array<BitmapFilter> = []; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
				for (i in camGameShaders)
				{
					newCamEffects.push(new ShaderFilter(i.shader));
				}
				camGame.setFilters(newCamEffects);
			default:
				if (modchartSprites.exists(cam))
				{
					Reflect.setProperty(modchartSprites.get(cam), "shader", effect.shader);
				}
				else if (modchartTexts.exists(cam))
				{
					Reflect.setProperty(modchartTexts.get(cam), "shader", effect.shader);
				}
				else
				{
					var OBJ = Reflect.getProperty(PlayState.instance, cam);
					Reflect.setProperty(OBJ, "shader", effect.shader);
				}
		}
	}

	public function removeShaderFromCamera(cam:String, effect:ShaderEffect)
	{
		switch (cam.toLowerCase())
		{
			case 'camhud' | 'hud':
				camHUDShaders.remove(effect);
				var newCamEffects:Array<BitmapFilter> = [];
				for (i in camHUDShaders)
				{
					newCamEffects.push(new ShaderFilter(i.shader));
				}
				camHUD.setFilters(newCamEffects);
			case 'camother' | 'other':
				camOtherShaders.remove(effect);
				var newCamEffects:Array<BitmapFilter> = [];
				for (i in camOtherShaders)
				{
					newCamEffects.push(new ShaderFilter(i.shader));
				}
				camOther.setFilters(newCamEffects);
			default:
				if (modchartSprites.exists(cam))
				{
					Reflect.setProperty(modchartSprites.get(cam), "shader", null);
				}
				else if (modchartTexts.exists(cam))
				{
					Reflect.setProperty(modchartTexts.get(cam), "shader", null);
				}
				else
				{
					var OBJ = Reflect.getProperty(PlayState.instance, cam);
					Reflect.setProperty(OBJ, "shader", null);
				}
		}
	}

	public function clearShaderFromCamera(cam:String)
	{
		switch (cam.toLowerCase())
		{
			case 'camhud' | 'hud':
				camHUDShaders = [];
				var newCamEffects:Array<BitmapFilter> = [];
				camHUD.setFilters(newCamEffects);
			case 'camother' | 'other':
				camOtherShaders = [];
				var newCamEffects:Array<BitmapFilter> = [];
				camOther.setFilters(newCamEffects);
			case 'camgame' | 'game':
				camGameShaders = [];
				var newCamEffects:Array<BitmapFilter> = [];
				camGame.setFilters(newCamEffects);
			default:
				camGameShaders = [];
				var newCamEffects:Array<BitmapFilter> = [];
				camGame.setFilters(newCamEffects);
		}
	}

	override public function update(elapsed:Float)
	{
		callOnLuas('onUpdate', [elapsed]);

		stageBuild.stageUpdateConstant(elapsed, boyfriend, gf, dadOpponent);

		super.update(elapsed);

		if (health > 2)
			health = 2;

		// sync botplay to bf strums autoplay
		if (playerStrums.autoplay != cpuControlled)
			playerStrums.autoplay = cpuControlled;

		var curSection = SONG.notes[Std.int(curStep / 16)];
		if (generatedMusic && curSection != null)
			moveCamera(!curSection.mustHitSection);

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		// camera stuffs
		var easeLerp:Float = CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1);
		FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom + forceZoom[0], FlxG.camera.zoom, easeLerp);
		for (hud in allUIs)
			hud.zoom = FlxMath.lerp(1 + forceZoom[1], hud.zoom, easeLerp);

		// not even forcezoom anymore but still
		FlxG.camera.angle = FlxMath.lerp(0 + forceZoom[2], FlxG.camera.angle, easeLerp);
		for (hud in allUIs)
			hud.angle = FlxMath.lerp(0 + forceZoom[3], hud.angle, easeLerp);

		isTutorial = curSong.toLowerCase() == 'tutorial' && dadOpponent.curCharacter == 'gf';

		if (!inCutscene)
		{
			gamepadKeyShit();

			// pause the game if the game is allowed to pause and enter is pressed
			if (controls.PAUSE && startedCountdown && canPause)
			{
				if (callOnLuas('onPause', []) != Script.Function_Stop)
				{
					// update drawing stuffs
					persistentUpdate = false;
					persistentDraw = true;
					paused = true;

					// open pause substate
					openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
					updateRPC(true);
				}
			}

			// charting state (more on that later)
			if (FlxG.keys.justPressed.SEVEN)
			{
				resetMusic();
				persistentUpdate = false;
				Main.switchState(new ChartingState());
			}

			if (startingSong)
			{
				if (startedCountdown)
				{
					Conductor.songPosition += elapsed * 1000;
					if (Conductor.songPosition >= 0)
						startSong();
				}
			}
			else
			{
				Conductor.songPosition += elapsed * 1000;

				if (!paused)
				{
					songTime += FlxG.game.ticks - previousFrameTime;
					previousFrameTime = FlxG.game.ticks;

					// Interpolation type beat
					if (Conductor.lastSongPos != Conductor.songPosition)
					{
						songTime = (songTime + Conductor.songPosition) / 2;
						Conductor.lastSongPos = Conductor.songPosition;
						// Conductor.songPosition += FlxG.elapsed * 1000;
						// trace('MISSED FRAME');
					}
				}
			}

			// boyfriend.playAnim('singLEFT', true);

			if (health <= 0 && startedCountdown)
			{
				if (callOnLuas('onGameOver', []) != Script.Function_Stop)
				{
					persistentUpdate = false;
					persistentDraw = false;
					paused = true;
					isDead = true;

					resetMusic();
					FlxG.sound.destroy();

					openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

					// discord stuffs should go here
				}
			}

			// spawn in the notes from the array
			if (unspawnNotes[0] != null && (unspawnNotes[0].strumTime - Conductor.songPosition) < 3500)
			{
				// push note to its correct strumline
				strumLines.members[
					Math.floor((unspawnNotes[0].noteData + (unspawnNotes[0].mustPress ? 4 : 0)) / numberOfKeys)
				].push(unspawnNotes[0]);
				unspawnNotes.splice(unspawnNotes.indexOf(unspawnNotes[0]), 1);
			}

			noteCalls();
		}

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		setOnLuas('botPlay', cpuControlled);

		#if LUA_ALLOWED
		for (key => value in luaShaders)
			value.update(elapsed);
		#end

		callOnLuas('onUpdatePost', [elapsed]);

		for (i in shaderUpdates)
			i(elapsed);
	}

	public function moveCamera(isDad:Bool)
	{
		var char:Character = dadOpponent;

		if (isDad)
		{
			var getCenterX = char.getMidpoint().x + 100;
			var getCenterY = char.getMidpoint().y - 100;
			switch (curStage)
			{
				case 'philly' | 'school':
					getCenterX = char.getMidpoint().x + 200;
			}

			camFollow.x = getCenterX + camDisplaceX + char.cameraPosition[0];
			camFollow.y = getCenterY + camDisplaceY + char.cameraPosition[1];

			if (isTutorial)
			{
				callOnLuas('onMoveCamera', ['gf']);
				if (cameraTwn == null && FlxG.camera.zoom != 1.3)
					cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {
						ease: FlxEase.elasticInOut,
						onComplete: function(twn:FlxTween)
						{
							cameraTwn = null;
						}
					});
			}
			else
				callOnLuas('onMoveCamera', ['dad']);
		}
		else
		{
			char = boyfriend;

			var getCenterX = char.getMidpoint().x - 100;
			var getCenterY = char.getMidpoint().y - 100;
			switch (curStage)
			{
				case 'limo':
					getCenterX = char.getMidpoint().x - 300;
				case 'mall':
					getCenterY = char.getMidpoint().y - 200;
				case 'school':
					getCenterX = char.getMidpoint().x - 200;
					getCenterY = char.getMidpoint().y - 200;
				case 'schoolEvil':
					getCenterX = char.getMidpoint().x - 200;
					getCenterY = char.getMidpoint().y - 225;
			}

			camFollow.x = getCenterX + camDisplaceX - char.cameraPosition[0];
			camFollow.y = getCenterY + camDisplaceY + char.cameraPosition[1];

			if (isTutorial && cameraTwn == null && FlxG.camera.zoom != defaultCamZoom)
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, (Conductor.stepCrochet * 4 / 1000), {
					ease: FlxEase.elasticInOut,
					onComplete: function(twn:FlxTween)
					{
						cameraTwn = null;
					}
				});

			callOnLuas('onMoveCamera', ['boyfriend']);
		}
	}

	function noteCalls()
	{
		// set note splashes positions
		for (strumline in strumLines)
		{
			if (strumline.splashNotes != null)
				for (i in 0...strumline.splashNotes.length)
				{
					strumline.splashNotes.members[i].x = strumline.receptors.members[i].x - 48;
					strumline.splashNotes.members[i].y = strumline.receptors.members[i].y + (Note.swagWidth / 6) - 56;
				}
		}

		// if the song is generated
		if (generatedMusic && startedCountdown)
		{
			for (strumline in strumLines)
			{
				// set the notes x and y
				var downscrollMultiplier = 1;
				if (strumline.downscroll)
					downscrollMultiplier = -1;

				strumline.allNotes.forEachAlive(function(daNote:Note)
				{
					var roundedSpeed = FlxMath.roundDecimal(daNote.noteSpeed, 2);
					var receptorPosY:Float = strumline.receptors.members[Math.floor(daNote.noteData)].y + Note.swagWidth / 6;
					var psuedoY:Float = downscrollMultiplier * -((Conductor.songPosition - daNote.strumTime) * (0.45 * roundedSpeed));

					daNote.y = receptorPosY
						+ (Math.cos(flixel.math.FlxAngle.asRadians(daNote.noteDirection)) * psuedoY)
						+ (Math.sin(flixel.math.FlxAngle.asRadians(daNote.noteDirection)) * daNote.noteVisualOffset);
					// painful math equation
					daNote.x = strumline.receptors.members[Math.floor(daNote.noteData)].x
						+ (Math.cos(flixel.math.FlxAngle.asRadians(daNote.noteDirection)) * daNote.noteVisualOffset)
						+ (Math.sin(flixel.math.FlxAngle.asRadians(daNote.noteDirection)) * psuedoY);

					// also set note rotation
					daNote.angle = -daNote.noteDirection;

					// shitty note hack I hate it so much
					var center:Float = receptorPosY + Note.swagWidth / 3;
					if (daNote.isSustainNote)
					{
						daNote.y -= (daNote.height / 2) * downscrollMultiplier;
						if (daNote.animation.curAnim.name.endsWith('holdend') && daNote.prevNote != null)
						{
							daNote.y -= (daNote.prevNote.height / 2) * downscrollMultiplier;
							if (strumline.downscroll)
							{
								daNote.y += daNote.height * 2;
								if (daNote.endHoldOffset == Math.NEGATIVE_INFINITY)
									// set the end hold offset yeah I hate that I fix this like this
									daNote.endHoldOffset = daNote.prevNote.y - (daNote.y + daNote.height) + 2;
								else
									daNote.y += daNote.endHoldOffset;
							}
							else // this system is funny like that
								daNote.y += (daNote.height / 2) * downscrollMultiplier;
						}

						if (strumline.downscroll)
						{
							daNote.flipY = true;
							if (daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center
								&& (strumline.autoplay || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
							{
								var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
								swagRect.height = (center - daNote.y) / daNote.scale.y;
								swagRect.y = daNote.frameHeight - swagRect.height;
								daNote.clipRect = swagRect;
							}
						}
						else
						{
							if (daNote.y + daNote.offset.y * daNote.scale.y <= center
								&& (strumline.autoplay || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
							{
								var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
								swagRect.y = (center - daNote.y) / daNote.scale.y;
								swagRect.height -= swagRect.y;
								daNote.clipRect = swagRect;
							}
						}
					}
					// hell breaks loose here, we're using nested scripts!
					mainControls(daNote, strumline.character, strumline, strumline.autoplay);

					// check where the note is and make sure it is either active or inactive
					if (daNote.y > FlxG.height)
					{
						daNote.active = false;
						daNote.visible = false;
					}
					else
					{
						daNote.visible = true;
						daNote.active = true;
					}

					if ((!daNote.isSustainNote || (daNote.parentNote != null && !daNote.parentNote.wasGoodHit))
						&& daNote.mustPress
						&& !daNote.tooLate
						&& !daNote.wasGoodHit
						&& daNote.strumTime < Conductor.songPosition - Timings.msThreshold)
					{
						daNote.tooLate = true;
						vocals.volume = 0;
						missNoteCheck(true, false, daNote.noteData, boyfriend, true);
						// ambiguous name
						Timings.updateAccuracy(0);
						noteMissLua(daNote);
					}

					// if the note is off screen (above)
					if (((!strumline.downscroll && daNote.y < -daNote.height)
						|| (strumline.downscroll && daNote.y > FlxG.height + daNote.height))
						&& (daNote.tooLate || daNote.wasGoodHit))
						destroyNote(strumline, daNote);
				});
			}

			// reset bf's animation
			var holdControls:Array<Bool> = [controls.LEFT, controls.DOWN, controls.UP, controls.RIGHT];
			if ((boyfriend != null && boyfriend.animation != null)
				&& (boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration
					&& (!holdControls.contains(true) || playerStrums.autoplay))
				&& (boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')))
				boyfriend.dance();
		}
	}

	function noteMissLua(daNote:Note)
	{
		callOnLuas('noteMiss', [
			unspawnNotes.indexOf(daNote),
			daNote.noteData,
			daNote.noteType,
			daNote.isSustainNote
		]);
	}

	function destroyNote(strumline:Strumline, daNote:Note)
	{
		daNote.active = false;
		daNote.exists = false;

		var chosenGroup = (daNote.isSustainNote ? strumline.holdsGroup : strumline.notesGroup);
		// note damage here I guess
		daNote.kill();
		if (strumline.allNotes.members.contains(daNote))
			strumline.allNotes.remove(daNote, true);
		if (chosenGroup.members.contains(daNote))
			chosenGroup.remove(daNote, true);
		daNote.destroy();
	}

	function goodNoteHit(coolNote:Note, character:Character, characterStrums:Strumline, ?canDisplayJudgement:Bool = true)
	{
		if (!coolNote.wasGoodHit)
		{
			coolNote.wasGoodHit = true;
			vocals.volume = 1;

			camZooming = !isTutorial || !coolNote.mustPress;

			characterPlayAnimation(coolNote, character);
			var receptor:UIStaticArrow = characterStrums.receptors.members[coolNote.noteData];
			if (receptor != null)
			{
				receptor.playAnim('confirm', true);
				if (characterStrums.autoplay)
				{
					var time:Float = 0.15;
					if (coolNote.isSustainNote && !coolNote.animation.curAnim.name.endsWith('end'))
						time += 0.15;
					receptor.resetAnim = time;
				}
			}

			var callName:String = 'opponentNoteHit';
			if (coolNote.mustPress)
				callName = 'noteHit';
			callOnLuas(callName, [
				unspawnNotes.indexOf(coolNote),
				Math.abs(coolNote.noteData),
				coolNote.noteType,
				coolNote.isSustainNote
			]);

			var daSection:SwagSection = SONG.notes[Math.floor(curStep / 16)];
			if (daSection != null && coolNote.mustPress == daSection.mustHitSection)
				camDisplace(coolNote.noteData);

			// special thanks to sam, they gave me the original system which kinda inspired my idea for this new one
			if (canDisplayJudgement)
			{
				// get the note ms timing
				var noteDiff:Float = Math.abs(coolNote.strumTime - Conductor.songPosition);
				// get the timing
				if (coolNote.strumTime < Conductor.songPosition)
					ratingTiming = "late";
				else
					ratingTiming = "early";

				// loop through all avaliable judgements
				var foundRating:String = 'miss';
				var lowestThreshold:Float = Math.POSITIVE_INFINITY;
				for (myRating in Timings.judgementsMap.keys())
				{
					var myThreshold:Float = Timings.judgementsMap.get(myRating)[1];
					if (noteDiff <= myThreshold && (myThreshold < lowestThreshold))
					{
						foundRating = myRating;
						lowestThreshold = myThreshold;
					}
				}

				if (!coolNote.isSustainNote)
				{
					increaseCombo(foundRating, coolNote, character);
					popUpScore(foundRating, ratingTiming, characterStrums, coolNote);
					if (coolNote.childrenNotes.length > 0)
						Timings.notesHit++;
					healthCall(Timings.judgementsMap.get(foundRating)[3]);

					if (coolNote.mustPress && !cpuControlled)
					{
						// funny score bar bounce on note hit
						if (uiHUD.scoreTxtTween != null)
							uiHUD.scoreTxtTween.cancel();
						uiHUD.scoreTxt.scale.x = 1.1;
						uiHUD.scoreTxtTween = FlxTween.tween(uiHUD.scoreTxt.scale, {x: 1}, 0.3, {
							ease: FlxEase.cubeOut,
							onComplete: function(twn:FlxTween)
							{
								uiHUD.scoreTxtTween = null;
							}
						});
					}
				}
				else if (coolNote.isSustainNote)
				{
					// call updated accuracy stuffs
					if (coolNote.parentNote != null)
					{
						Timings.updateAccuracy(100, true, coolNote.parentNote.childrenNotes.length);
						healthCall(100 / coolNote.parentNote.childrenNotes.length);
					}
				}
			}

			if (!coolNote.isSustainNote)
				destroyNote(characterStrums, coolNote);
		}
	}

	function missNoteCheck(?includeAnimation:Bool = false, ?playSound:Bool = false, direction:Int = 0, character:Character, popMiss:Bool = false,
			lockMiss:Bool = false)
	{
		if (playSound)
			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
		if (includeAnimation)
		{
			camDisplace(direction);
			character.playAnim('sing' + UIStaticArrow.getArrowFromNumber(direction).toUpperCase() + 'miss', lockMiss);
		}
		decreaseCombo(popMiss);
	}

	function characterPlayAnimation(coolNote:Note, character:Character)
	{
		// alright so we determine which animation needs to play
		// get alt strings and stuffs
		var stringArrow:String = '';
		var altString:String = '';

		var baseString = 'sing' + UIStaticArrow.getArrowFromNumber(coolNote.noteData).toUpperCase();

		// I tried doing xor and it didnt work lollll
		if (coolNote.noteAlt > 0)
			altString = '-alt';
		if ((SONG.notes[Math.floor(curStep / 16)] != null && SONG.notes[Math.floor(curStep / 16)].altAnim)
			&& character.animOffsets.exists(baseString + '-alt'))
		{
			if (altString != '-alt')
				altString = '-alt';
			else
				altString = '';
		}

		stringArrow = baseString + altString;
		// if (coolNote.foreverMods.get('string')[0] != "")
		//	stringArrow = coolNote.noteString;

		character.playAnim(stringArrow, true);
		character.holdTimer = 0;
	}

	private function mainControls(daNote:Note, char:Character, strumline:Strumline, autoplay:Bool)
	{
		var notesPressedAutoplay = [];

		// here I'll set up the autoplay functions
		if (autoplay)
		{
			// check if the note was a good hit
			if (daNote.strumTime <= Conductor.songPosition)
			{
				var canDisplayJudgement = false;
				if (strumline.displayJudgements)
				{
					canDisplayJudgement = true;
					for (noteDouble in notesPressedAutoplay)
					{
						if (noteDouble.noteData == daNote.noteData)
							canDisplayJudgement = false;
					}
					notesPressedAutoplay.push(daNote);
				}
				goodNoteHit(daNote, char, strumline, canDisplayJudgement);
			}
		}
		else
		{
			var holdControls:Array<Bool> = [controls.LEFT, controls.DOWN, controls.UP, controls.RIGHT];
			// check if anything is held
			if (holdControls.contains(true))
			{
				// check notes that are alive
				strumline.allNotes.forEachAlive(function(coolNote:Note)
				{
					if (coolNote.canBeHit && coolNote.mustPress && coolNote.isSustainNote && holdControls[coolNote.noteData])
						goodNoteHit(coolNote, char, strumline);
				});
			}
		}
	}

	function camDisplace(direction:Int)
	{
		if (!Init.trueSettings.get('No Camera Note Movement'))
		{
			camDisplaceX = 0;
			camDisplaceY = 0;

			var camDisplaceExtend:Float = 15;
			switch (direction)
			{
				case 0:
					camDisplaceX = -camDisplaceExtend;
				case 1:
					camDisplaceY = camDisplaceExtend;
				case 2:
					camDisplaceY = -camDisplaceExtend;
				case 3:
					camDisplaceX = camDisplaceExtend;
			}
		}
	}

	#if (VIDEOS_ALLOWED && desktop)
	override public function onFocus()
	{
		if (!paused)
			updateRPC(false);
		#if VIDEOS_ALLOWED
		if (video != null)
			video.onFocus();
		#end
		super.onFocus();
	}

	override public function onFocusLost()
	{
		updateRPC(true);
		#if VIDEOS_ALLOWED
		if (video != null)
			video.onFocusLost();
		#end
		super.onFocusLost();
	}
	#end

	public static function updateRPC(pausedRPC:Bool)
	{
		#if sys
		var displayRPC:String = (pausedRPC) ? detailsPausedText : songDetails;

		if (health > 0)
		{
			if (Conductor.songPosition > 0 && !pausedRPC)
				Discord.changePresence(displayRPC, detailsSub, iconRPC, true, songLength - Conductor.songPosition);
			else
				Discord.changePresence(displayRPC, detailsSub, iconRPC);
		}
		#end
	}

	var animationsPlay:Array<Note> = [];
	private var ratingTiming:String = "";

	function popUpScore(baseRating:String, timing:String, strumline:Strumline, coolNote:Note)
	{
		// set up the rating
		var score:Int = 50;

		// notesplashes
		if (baseRating == "sick")
			// create the note splash if you hit a sick
			strumline.createSplash(coolNote);
		else
			// if it isn't a sick, and you had a sick combo, then it becomes not sick :(
			if (allSicks)
				allSicks = false;

		displayRating(baseRating, timing);
		Timings.updateAccuracy(Timings.judgementsMap.get(baseRating)[3]);
		score = Std.int(Timings.judgementsMap.get(baseRating)[2]);

		songScore += score;
		songHits++;

		popUpCombo();
	}

	private var createdColor = FlxColor.fromRGB(204, 66, 66);

	function popUpCombo(?cache:Bool = false)
	{
		var comboString:String = Std.string(combo);
		var negative = false;
		if (comboString.startsWith('-') || (combo == 0))
			negative = true;
		var stringArray:Array<String> = comboString.split("");
		// deletes all combo sprites prior to initalizing new ones
		if (lastCombo != null)
		{
			while (lastCombo.length > 0)
			{
				lastCombo[0].kill();
				lastCombo.remove(lastCombo[0]);
			}
		}

		for (scoreInt in 0...stringArray.length)
		{
			// numScore.loadGraphic(Paths.image('UI/' + pixelModifier + 'num' + stringArray[scoreInt]));
			var numScore = ForeverAssets.generateCombo('combo', stringArray[scoreInt], (!negative ? allSicks : false), assetModifier, changeableSkin,
				assetModifier == 'pixel'
				&& changeableSkin == 'default' ? 'pixelUI' : 'UI', negative, createdColor, scoreInt);
			add(numScore);
			// hardcoded lmao
			if (!Init.trueSettings.get('Simply Judgements'))
			{
				add(numScore);
				FlxTween.tween(numScore, {alpha: 0}, 0.2, {
					onComplete: function(tween:FlxTween)
					{
						numScore.kill();
					},
					startDelay: Conductor.crochet * 0.002
				});
			}
			else
			{
				add(numScore);
				// centers combo
				numScore.y += 10;
				numScore.x -= 95;
				numScore.x -= (comboString.length - 1) * 22;
				lastCombo.push(numScore);
				FlxTween.tween(numScore, {y: numScore.y + 20}, 0.1, {type: FlxTweenType.BACKWARD, ease: FlxEase.circOut});
			}
			// hardcoded lmao
			if (Init.trueSettings.get('Fixed Judgements'))
			{
				if (!cache)
					numScore.cameras = [camHUD];
				numScore.y += 50;
			}
			numScore.x += 100;
		}
	}

	function decreaseCombo(?popMiss:Bool = false)
	{
		if (combo > 0)
			combo = 0; // bitch lmao
		else
			combo--;

		// misses
		songScore -= 10;
		misses++;

		// doesnt matter miss ratings dont have timings
		healthCall(Timings.judgementsMap.get('miss')[3]);

		// display negative combo
		if (popMiss)
		{
			displayRating('miss', 'late');
			popUpCombo();
		}

		// gotta do it manually here lol
		Timings.updateFCDisplay();
	}

	function increaseCombo(?baseRating:String, ?note:Note, ?character:Character)
	{
		// trolled this can actually decrease your combo if you get a bad/shit/miss
		if (baseRating != null)
		{
			if (Timings.judgementsMap.get(baseRating)[3] > 0)
			{
				if (combo < 0)
					combo = 0;
				combo += 1;
			}
			else
			{
				missNoteCheck(true, true, note.noteData, character, false, true);
				noteMissLua(note);
			}
		}
	}

	public function displayRating(daRating:String, ?diff:Float, timing:String, ?cache:Bool = false)
	{
		/* so you might be asking
			"oh but if the rating isn't sick why not just reset it"
			because miss judgements can pop, and they dont mess with your sick combo
		 */
		var rating = ForeverAssets.generateRating('$daRating', (daRating == 'sick' ? allSicks : false), timing, assetModifier, changeableSkin,
			assetModifier == 'pixel'
			&& changeableSkin == 'default' ? 'pixelUI' : 'UI');
		add(rating);

		if (!Init.trueSettings.get('Simply Judgements'))
		{
			add(rating);

			FlxTween.tween(rating, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					rating.kill();
				},
				startDelay: Conductor.crochet * 0.00125
			});
		}
		else
		{
			if (lastRating != null)
				lastRating.kill();
			add(rating);
			lastRating = rating;
			FlxTween.tween(rating, {y: rating.y + 20}, 0.2, {type: FlxTweenType.BACKWARD, ease: FlxEase.circOut});
			FlxTween.tween(rating, {"scale.x": 0, "scale.y": 0}, 0.1, {
				onComplete: function(tween:FlxTween)
				{
					rating.kill();
				},
				startDelay: Conductor.crochet * 0.00125
			});
		}

		if (!cache)
		{
			if (Init.trueSettings.get('Fixed Judgements'))
			{
				// bound to camera
				rating.cameras = [camHUD];
				rating.screenCenter();
			}

			// return the actual rating to the array of judgements
			Timings.gottenJudgements.set(daRating, Timings.gottenJudgements.get(daRating) + 1);

			// set new smallest rating
			if (Timings.smallestRating != daRating)
			{
				if (Timings.judgementsMap.get(Timings.smallestRating)[0] < Timings.judgementsMap.get(daRating)[0])
					Timings.smallestRating = daRating;
			}
		}
	}

	function healthCall(?ratingMultiplier:Float = 0)
	{
		// health += 0.012;
		var healthBase:Float = 0.06;
		health += (healthBase * (ratingMultiplier / 100));
	}

	function startSong()
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;

		if (!paused)
		{
			FlxG.sound.playMusic(inst, 1, false);
			FlxG.sound.music.onComplete = endSong;
			vocals.play();

			resyncVocals();

			#if sys
			// Song duration in a float, useful for the time left feature
			songLength = FlxG.sound.music.length;

			// Updating Discord Rich Presence (with Time Left)
			updateRPC(false);
			#end
		}

		setOnLuas('songLength', songLength);
		callOnLuas('onSongStart', []);
	}

	private function generateSong()
	{
		// FlxG.log.add(ChartParser.parse());

		Conductor.changeBPM(SONG.bpm);

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		songDetails = SONG.song + ' - ' + CoolUtil.difficulties[storyDifficulty];

		// String for when the game is paused
		detailsPausedText = "Paused - " + songDetails;

		// set details for song stuffs
		detailsSub = "";

		// Updating Discord Rich Presence.
		updateRPC(false);

		curSong = SONG.song;

		// cache momento
		inst = Paths.inst(curSong);

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(curSong), false, true);
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);

		// generate the chart
		unspawnNotes = ChartLoader.generateChartType(SONG, determinedChartType);
		// sometime my brain farts dont ask me why these functions were separated before

		// sort through them
		unspawnNotes.sort(sortByShit);
		// give the game the heads up to be able to start
		generatedMusic = true;

		Timings.accuracyMaxCalculation(unspawnNotes);
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	function resyncVocals()
	{
		// trace('resyncing vocal time ${vocals.time}');
		vocals.pause();
		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
		// trace('new vocal time ${Conductor.songPosition}');
	}

	override function stepHit()
	{
		super.stepHit();
		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > 20
			|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > 20))
			resyncVocals();

		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);
	}

	private function charactersDance(curBeat:Int)
	{
		if (!paused)
		{
			if (curBeat % gfSpeed == 0 && gf.animation.curAnim.name != null && !gf.animation.curAnim.name.startsWith("sing"))
				gf.dance();

			if (curBeat % 2 == 0)
			{
				if (boyfriend.animation.curAnim.name != null && !boyfriend.animation.curAnim.name.startsWith("sing"))
					boyfriend.dance();
				if (dadOpponent.animation.curAnim.name != null && !dadOpponent.animation.curAnim.name.startsWith("sing"))
					dadOpponent.dance();
			}
		}
	}

	override function beatHit()
	{
		super.beatHit();

		var daSection:SwagSection = SONG.notes[Math.floor(curStep / 16)];

		if (daSection != null)
		{
			if (daSection.changeBPM)
			{
				Conductor.changeBPM(daSection.bpm);
				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}
			setOnLuas('mustHitSection', daSection.mustHitSection);
			setOnLuas('altAnim', daSection.altAnim);
			setOnLuas('gfSection', dadOpponent.curCharacter.startsWith('gf') && daSection.mustHitSection);

			// reset cam displace
			if (((!boyfriend.animation.curAnim.name.startsWith('sing') || boyfriend.animation.curAnim.name.endsWith('miss'))
				&& daSection.mustHitSection)
				|| ((!dadOpponent.animation.curAnim.name.startsWith('sing') || dadOpponent.animation.curAnim.name.endsWith('miss'))
					&& !daSection.mustHitSection))
			{
				camDisplaceX = 0;
				camDisplaceY = 0;
			}
		}

		if (camZooming && FlxG.camera.zoom < 1.35 && !Init.trueSettings.get('Reduced Movements') && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			for (hud in allUIs)
				hud.zoom += 0.03;
		}

		uiHUD.beatHit();

		if (curBeat % 16 == 15 && isTutorial && dadOpponent.curCharacter.startsWith('gf') && curBeat > 16 && curBeat < 48)
		{
			boyfriend.playAnim('hey', true);
			dadOpponent.playAnim('cheer', true);
		}

		charactersDance(curBeat);

		// stage stuffs
		stageBuild.stageUpdate(curBeat, boyfriend, gf, dadOpponent);

		setOnLuas('curBeat', curBeat);
		callOnLuas('onBeatHit', []);
	}

	static function resetMusic()
	{
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		if (vocals != null)
			vocals.stop();
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			// trace('null song');
			if (FlxG.sound.music != null)
			{
				//	trace('nulled song');
				FlxG.sound.music.pause();
				vocals.pause();
				//	trace('nulled song finished');
			}

			// trace('ui shit break');
			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;
		}

		// trace('open substate');
		super.openSubState(SubState);
		// trace('open substate end ');
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
				resyncVocals();

			if (startTimer != null && !startTimer.finished)
				startTimer.active = true;
			paused = false;

			updateRPC(false);

			callOnLuas('onResume', []);
		}

		super.closeSubState();
	}

	// Extra functions and stuffs
	public function endSong()
	{
		endingSong = true;
		seenCutscene = false;
		canPause = false;

		#if LUA_ALLOWED
		var ret:Dynamic = callOnLuas('onEndSong', []);
		#else
		var ret:Dynamic = Script.Function_Continue;
		#end

		if (ret != Script.Function_Stop)
		{
			FlxG.sound.music.volume = 0;
			vocals.volume = 0;
			if (SONG.validScore)
				Highscore.saveScore(SONG.song, songScore, storyDifficulty);

			if (!isStoryMode)
			{
				cpuControlled = false;
				persistentUpdate = false;
				Main.switchState(new FreeplayState());
			}
			else
			{
				// set the campaign's score higher
				campaignScore += songScore;

				// remove a song from the story playlist
				storyPlaylist.remove(storyPlaylist[0]);

				// check if there aren't any songs left
				if (storyPlaylist.length <= 0)
				{
					// play menu music
					ForeverTools.resetMenuMusic(false, true);

					// set up transitions
					transIn = FlxTransitionableState.defaultTransIn;
					transOut = FlxTransitionableState.defaultTransOut;

					cpuControlled = false;

					persistentUpdate = false;

					// yeah we completed the week!!
					Week.setCompletedWeek(Week.loadedWeeks[storyWeek].weekName, true);

					// change to the menu state
					Main.switchState(new StoryMenuState());

					// save the week's score if the score is valid
					if (SONG.validScore)
						Highscore.saveWeekScore(storyWeek, campaignScore, storyDifficulty);

					// flush the save
					FlxG.save.flush();
				}
				else
				{
					switch (SONG.song.toLowerCase())
					{
						case 'eggnog':
							// make the lights go out
							var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
								-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
							blackShit.scrollFactor.set();
							add(blackShit);
							camHUD.visible = false;

							// oooo spooky
							FlxG.sound.play(Paths.sound('Lights_Shut_off'));

							// call the song end
							new FlxTimer().start(Conductor.crochet / 1000, function(timer:FlxTimer)
							{
								callDefaultSongEnd();
							}, 1);

						default:
							callDefaultSongEnd();
					}
				}
			}
		}
	}

	private function callDefaultSongEnd()
	{
		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;

		prevCamFollow = camFollow;

		PlayState.SONG = Song.loadFromJson(CoolUtil.formatSong(PlayState.storyPlaylist[0].toLowerCase(), storyDifficulty),
			CoolUtil.coolFormat(PlayState.storyPlaylist[0]));
		FlxG.sound.music.stop();
		ForeverTools.killMusic([vocals]);

		persistentUpdate = false;

		// deliberately did not use the main.switchstate as to not unload the assets
		FlxG.switchState(new PlayState());
	}

	var dialogueBox:DialogueBox;

	public function songIntroCutscene()
	{
		switch (curSong.toLowerCase())
		{
			case "winter-horrorland":
				inCutscene = true;
				var blackScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				add(blackScreen);
				blackScreen.scrollFactor.set();
				camHUD.visible = false;

				new FlxTimer().start(0.1, function(tmr:FlxTimer)
				{
					remove(blackScreen);
					FlxG.sound.play(Paths.sound('Lights_Turn_On'));
					camFollow.y = -2050;
					camFollow.x += 200;
					FlxG.camera.focusOn(camFollow);
					FlxG.camera.zoom = 1.5;

					new FlxTimer().start(0.8, function(tmr:FlxTimer)
					{
						camHUD.visible = true;
						remove(blackScreen);
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween)
							{
								startCountdown();
							}
						});
					});
				});
			case 'senpai':
				callTextbox(null, Paths.music('Lunchbox'));
			case 'roses':
				// the same just play angery noise LOL
				FlxG.sound.play(Paths.sound('ANGRY_TEXT_BOX'));
				callTextbox();
			case 'thorns':
				inCutscene = true;
				for (hud in allUIs)
					hud.visible = false;

				var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
				red.scrollFactor.set();

				var senpaiEvil:FlxSprite = new FlxSprite();
				senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
				senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
				senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
				senpaiEvil.scrollFactor.set();
				senpaiEvil.updateHitbox();
				senpaiEvil.screenCenter();

				add(red);
				add(senpaiEvil);
				senpaiEvil.alpha = 0;
				new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
				{
					senpaiEvil.alpha += 0.15;
					if (senpaiEvil.alpha < 1)
						swagTimer.reset();
					else
					{
						senpaiEvil.animation.play('idle');
						FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
						{
							remove(senpaiEvil);
							remove(red);
							FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
							{
								callTextbox(null, Paths.music('LunchboxScary'));
							}, true);
						});
						new FlxTimer().start(3.2, function(deadTime:FlxTimer)
						{
							FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
						});
					}
				});
			default:
				startCountdown();
		}
	}

	public function startVideo(path:String, ?callback)
	{
		#if VIDEOS_ALLOWED
		inCutscene = true;

		var bg:FlxSprite = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
		bg.scrollFactor.set();
		bg.cameras = [camHUD];
		add(bg);

		video = new FlxVideo(path);
		video.finishCallback = function()
		{
			remove(bg);
			video = null;
			if (callback != null)
				callback();
		};
		#else
		callback();
		#end
	}

	public function callTextbox(?dialogPath:String, ?music:Sound)
	{
		if (dialogPath == null)
			dialogPath = Paths.json('songs/' + curSong.toLowerCase() + '/dialogue');
		if (dialogPath != '' && Paths.exists(dialogPath))
		{
			for (hud in allUIs)
				hud.visible = false;

			dialogueBox = new DialogueBox(DialogueBox.loadFromJson(dialogPath), music);
			dialogueBox.cameras = [dialogueHUD];
			dialogueBox.finishThing = function()
			{
				seenCutscene = true;
				for (hud in allUIs)
					hud.visible = true;
				startCountdown();
			};

			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				add(dialogueBox);
			});
		}
		else
			startCountdown();
	}

	public static function skipCutscenes():Bool
	{
		// pretty messy but an if statement is messier
		if (Init.trueSettings.get('Skip Text') != null && Std.isOfType(Init.trueSettings.get('Skip Text'), String))
		{
			switch (cast(Init.trueSettings.get('Skip Text'), String))
			{
				case 'never':
					return false;
				case 'freeplay only':
					if (!isStoryMode)
						return true;
					else
						return false;
				default:
					return true;
			}
		}
		return false;
	}

	public static var swagCounter:Int = 0;

	public function startCountdown()
	{
		if (startedCountdown)
		{
			callOnLuas('onStartCountdown', []);
			return;
		}
		if (callOnLuas('onStartCountdown', []) != Script.Function_Stop)
		{
			startedCountdown = true;
			seenCutscene = true;
			inCutscene = false;
			Conductor.songPosition = -(Conductor.crochet * 5);
			swagCounter = 0;

			setOnLuas('startedCountdown', true);
			callOnLuas('onCountdownStarted', []);

			camHUD.visible = true;

			startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
			{
				charactersDance(curBeat);

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', [
					ForeverTools.returnSkinAsset('ready', assetModifier, changeableSkin, 'UI'),
					ForeverTools.returnSkinAsset('set', assetModifier, changeableSkin, 'UI'),
					ForeverTools.returnSkinAsset('go', assetModifier, changeableSkin, 'UI')
				]);
				introAssets.set('pixel', [
					ForeverTools.returnSkinAsset('ready-pixel', assetModifier, changeableSkin, 'pixelUI'),
					ForeverTools.returnSkinAsset('set-pixel', assetModifier, changeableSkin, 'pixelUI'),
					ForeverTools.returnSkinAsset('go-pixel', assetModifier, changeableSkin, 'pixelUI')
				]);

				var leModifier:String = 'default';
				if (introAssets.exists(assetModifier))
					leModifier = assetModifier;

				var introAlts:Array<String> = introAssets.get(leModifier);
				for (value in introAssets.keys())
				{
					if (value == PlayState.curStage)
						introAlts = introAssets.get(value);
				}

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3-' + assetModifier), 0.6);
						Conductor.songPosition = -(Conductor.crochet * 4);
					case 1:
						var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
						ready.cameras = [camHUD];

						if (assetModifier == 'pixel')
							ready.setGraphicSize(Std.int(ready.width * PlayState.daPixelZoom));

						ready.screenCenter();
						add(ready);
						FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								ready.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro2-' + assetModifier), 0.6);

						Conductor.songPosition = -(Conductor.crochet * 3);
					case 2:
						var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
						set.cameras = [camHUD];

						if (assetModifier == 'pixel')
							set.setGraphicSize(Std.int(set.width * PlayState.daPixelZoom));

						set.screenCenter();
						add(set);
						FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								set.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro1-' + assetModifier), 0.6);

						Conductor.songPosition = -(Conductor.crochet * 2);
					case 3:
						var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
						go.cameras = [camHUD];

						if (assetModifier == 'pixel')
							go.setGraphicSize(Std.int(go.width * PlayState.daPixelZoom));

						go.updateHitbox();

						go.screenCenter();
						add(go);
						FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								go.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('introGo-' + assetModifier), 0.6);

						Conductor.songPosition = -(Conductor.crochet * 1);
				}

				callOnLuas('onCountdownTick', [swagCounter]);

				swagCounter += 1;
			}, 5);
		}
	}

	override function add(Object:FlxBasic):FlxBasic
	{
		if (Init.trueSettings.get('Disable Antialiasing') && Std.isOfType(Object, FlxSprite))
			cast(Object, FlxSprite).antialiasing = false;
		return super.add(Object);
	}
}
