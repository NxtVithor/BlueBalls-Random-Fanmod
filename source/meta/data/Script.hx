package meta.data;

import flixel.util.FlxSave;
import Type.ValueType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import gameObjects.userInterface.notes.Strumline;
import meta.data.dependency.Discord;
import meta.data.shaders.Shaders;
import meta.state.PlayState;
import meta.state.menus.FreeplayState;
import meta.state.menus.StoryMenuState;
import meta.subState.GameOverSubstate;
import meta.subState.PauseSubState;
import openfl.display.BlendMode;
import openfl.filters.BitmapFilter;
import openfl.filters.ShaderFilter;
import openfl.media.Sound;
#if LUA_ALLOWED
import llua.Convert;
import llua.Lua;
import llua.LuaL;
import llua.State;
#end

using StringTools;

// sorry shadowmario if i borrow your code a bit
class Script
{
	public static var Function_Stop = 1;
	public static var Function_Continue = 0;

	var gonnaClose:Bool = false;

	public var scriptPath:String = '';

	#if LUA_ALLOWED
	public var lua:State = null;
	#end

	public function new(script:String)
	{
		#if LUA_ALLOWED
		lua = LuaL.newstate();
		LuaL.openlibs(lua);
		Lua.init_callbacks(lua);

		var result:Dynamic = LuaL.dofile(lua, script);
		var resultStr:String = Lua.tostring(lua, result);
		if (resultStr != null && result != 0)
		{
			CoolUtil.alert('Error on LUA script!', resultStr);
			trace('Error on LUA script! ' + resultStr);
			lua = null;
			return;
		}
		scriptPath = script;
		trace('Lua script loaded: ' + script);

		// Lua shit
		set('Function_Stop', Function_Stop);
		set('Function_Continue', Function_Continue);
		set('luaDebugMode', false);
		set('luaDeprecatedWarnings', true);
		set('inChartEditor', false);

		// Song/Week shit
		set('curBpm', Conductor.bpm);
		set('bpm', PlayState.SONG.bpm);
		set('scrollSpeed', PlayState.SONG.speed);
		set('crochet', Conductor.crochet);
		set('stepCrochet', Conductor.stepCrochet);
		set('songLength', FlxG.sound.music.length);
		set('songName', PlayState.SONG.song);
		set('startedCountdown', false);

		set('isStoryMode', PlayState.isStoryMode);
		set('difficulty', PlayState.storyDifficulty);
		set('weekRaw', PlayState.storyWeek);
		set('week', Week.weekNames[PlayState.storyWeek]);
		set('seenCutscene', PlayState.seenCutscene);

		/*
			Block require and os, Should probably have a proper function but this should be good enough for now,
			until someone smarter comes along and recreates a safe version of the OS library.
		 */
		set('require', false);
		set('os', false);

		// Camera poo
		set('cameraX', 0);
		set('cameraY', 0);

		// Screen stuff
		set('screenWidth', FlxG.width);
		set('screenHeight', FlxG.height);

		// PlayState cringe ass nae nae bullcrap
		set('curBeat', 0);
		set('curStep', 0);

		set('score', 0);
		set('misses', 0);
		set('hits', 0);

		set('rating', 0);
		set('ratingName', '');
		set('ratingFC', '');
		// psych troll
		set('version', '0.5.1');
		// no not really
		set('fmVersion', Main.foreverEngineVersion.trim());

		set('inGameOver', false);
		set('mustHitSection', false);
		set('altAnim', false);
		set('gfSection', false);

		for (i in 0...4)
		{
			set('defaultPlayerStrumX' + i, 0);
			set('defaultPlayerStrumY' + i, 0);
			set('defaultOpponentStrumX' + i, 0);
			set('defaultOpponentStrumY' + i, 0);
		}

		// Default character positions woooo
		set('defaultBoyfriendX', PlayState.BF_X);
		set('defaultBoyfriendY', PlayState.BF_Y);
		set('defaultOpponentX', PlayState.DAD_X);
		set('defaultOpponentY', PlayState.DAD_Y);
		set('defaultGirlfriendX', PlayState.GF_X);
		set('defaultGirlfriendY', PlayState.GF_Y);

		// Character shit
		set('boyfriendName', PlayState.SONG.player1);
		set('dadName', PlayState.SONG.player2);
		set('gfName', PlayState.SONG.player3);

		Lua_helper.add_callback(lua, "addLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false)
		{
			var daPath = Paths.script(luaFile);

			if (Paths.exists(daPath))
			{
				if (!ignoreAlreadyRunning)
				{
					for (luaInstance in PlayState.luaArray)
					{
						if (luaInstance.scriptPath == daPath)
						{
							luaTrace('The script "' + daPath + '" is already running!');
							return;
						}
					}
				}
				PlayState.luaArray.push(new Script(daPath));
				return;
			}
			luaTrace('Script $daPath doesn\'t exist!');
		});
		Lua_helper.add_callback(lua, "removeLuaScript", function(luaFile:String)
		{
			var daPath = Paths.script(luaFile);

			if (Paths.exists(daPath))
			{
				for (luaInstance in PlayState.luaArray)
				{
					if (luaInstance.scriptPath == daPath)
					{
						PlayState.luaArray.remove(luaInstance);
						return;
					}
				}
			}
			luaTrace('Script $daPath doesn\'t exist!');
		});

		// stuff 4 noobz like you B)

		Lua_helper.add_callback(lua, "loadGraphic", function(variable:String, image:String)
		{
			var spr:FlxSprite = getObjectDirectly(variable);
			if (spr != null && image != null && image.length > 0)
			{
				spr.loadGraphic(Paths.image(image));
			}
		});
		Lua_helper.add_callback(lua, "loadFrames", function(variable:String, image:String, spriteType:String = "sparrow")
		{
			var spr:FlxSprite = getObjectDirectly(variable);
			if (spr != null && image != null && image.length > 0)
			{
				loadFrames(spr, image, spriteType);
			}
		});

		Lua_helper.add_callback(lua, "getProperty", function(variable:String)
		{
			var killMe:Array<String> = variable.split('.');
			killMe = compatibilityStuff(killMe, true);
			if (killMe.length > 1)
			{
				return Reflect.getProperty(getPropertyLoopThingWhatever(killMe), killMe[killMe.length - 1]);
			}
			return Reflect.getProperty(getInstance(), variable);
		});
		Lua_helper.add_callback(lua, "setProperty", function(variable:String, value:Dynamic)
		{
			var killMe:Array<String> = variable.split('.');
			killMe = compatibilityStuff(killMe, true);
			if (killMe.length > 1)
			{
				return Reflect.setProperty(getPropertyLoopThingWhatever(killMe), killMe[killMe.length - 1], value);
			}
			return Reflect.setProperty(getInstance(), variable, value);
		});
		Lua_helper.add_callback(lua, "getPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic)
		{
			if (Std.isOfType(Reflect.getProperty(getInstance(), obj), FlxTypedGroup))
			{
				return getGroupStuff(Reflect.getProperty(getInstance(), obj).members[index], variable);
			}

			var leArray:Dynamic = Reflect.getProperty(getInstance(), obj)[index];
			if (leArray != null)
			{
				if (Type.typeof(variable) == ValueType.TInt)
				{
					return leArray[variable];
				}
				return getGroupStuff(leArray, variable);
			}
			luaTrace("Object #" + index + " from group: " + obj + " doesn't exist!");
			return null;
		});
		Lua_helper.add_callback(lua, "setPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, value:Dynamic)
		{
			if (Std.isOfType(Reflect.getProperty(getInstance(), obj), FlxTypedGroup))
			{
				setGroupStuff(Reflect.getProperty(getInstance(), obj).members[index], variable, value);
				return;
			}

			var leArray:Dynamic = Reflect.getProperty(getInstance(), obj)[index];
			if (leArray != null)
			{
				if (Type.typeof(variable) == ValueType.TInt)
				{
					leArray[variable] = value;
					return;
				}
				setGroupStuff(leArray, variable, value);
			}
		});
		Lua_helper.add_callback(lua, "removeFromGroup", function(obj:String, index:Int, dontDestroy:Bool = false)
		{
			if (Std.isOfType(Reflect.getProperty(getInstance(), obj), FlxTypedGroup))
			{
				var sex = Reflect.getProperty(getInstance(), obj).members[index];
				if (!dontDestroy)
					sex.kill();
				Reflect.getProperty(getInstance(), obj).remove(sex, true);
				if (!dontDestroy)
					sex.destroy();
				return;
			}
			Reflect.getProperty(getInstance(), obj).remove(Reflect.getProperty(getInstance(), obj)[index]);
		});

		Lua_helper.add_callback(lua, "getPropertyFromClass", function(classVar:String, variable:String)
		{
			var killMe:Array<String> = variable.split('.');
			killMe = compatibilityStuff(killMe);
			if (killMe.length > 1)
			{
				var coverMeInPiss:Dynamic = Reflect.getProperty(Type.resolveClass(classVar), killMe[0]);
				for (i in 1...killMe.length - 1)
				{
					coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
				}
				return Reflect.getProperty(coverMeInPiss, killMe[killMe.length - 1]);
			}
			return Reflect.getProperty(Type.resolveClass(classVar), variable);
		});
		Lua_helper.add_callback(lua, "setPropertyFromClass", function(classVar:String, variable:String, value:Dynamic)
		{
			var killMe:Array<String> = variable.split('.');
			killMe = compatibilityStuff(killMe);
			if (killMe.length > 1)
			{
				var coverMeInPiss:Dynamic = Reflect.getProperty(Type.resolveClass(classVar), killMe[0]);
				for (i in 1...killMe.length - 1)
				{
					coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
				}
				return Reflect.setProperty(coverMeInPiss, killMe[killMe.length - 1], value);
			}
			return Reflect.setProperty(Type.resolveClass(classVar), variable, value);
		});

		// shitass stuff for epic coders like me B)  *image of obama giving himself a medal*
		Lua_helper.add_callback(lua, "getObjectOrder", function(obj:String)
		{
			if (PlayState.instance.modchartSprites.exists(obj))
			{
				return getInstance().members.indexOf(PlayState.instance.modchartSprites.get(obj));
			}
			else if (PlayState.instance.modchartTexts.exists(obj))
			{
				return getInstance().members.indexOf(PlayState.instance.modchartTexts.get(obj));
			}

			var leObj:FlxBasic = Reflect.getProperty(getInstance(), obj);
			if (leObj != null)
			{
				return getInstance().members.indexOf(leObj);
			}
			luaTrace("Object " + obj + " doesn't exist!");
			return -1;
		});
		Lua_helper.add_callback(lua, "setObjectOrder", function(obj:String, position:Int)
		{
			if (PlayState.instance.modchartSprites.exists(obj))
			{
				var spr:ModchartSprite = PlayState.instance.modchartSprites.get(obj);
				if (spr.wasAdded)
				{
					getInstance().remove(spr, true);
				}
				getInstance().insert(position, spr);
				return;
			}
			if (PlayState.instance.modchartTexts.exists(obj))
			{
				var spr:ModchartText = PlayState.instance.modchartTexts.get(obj);
				if (spr.wasAdded)
				{
					getInstance().remove(spr, true);
				}
				getInstance().insert(position, spr);
				return;
			}

			var leObj:FlxBasic = Reflect.getProperty(getInstance(), obj);
			if (leObj != null)
			{
				getInstance().remove(leObj, true);
				getInstance().insert(position, leObj);
				return;
			}
			luaTrace("Object " + obj + " doesn't exist!");
		});

		// gay ass tweens
		Lua_helper.add_callback(lua, "doTweenX", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)
		{
			var penisExam:Dynamic = tweenShit(tag, vars);
			if (penisExam != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {x: value}, duration, {
					ease: CoolUtil.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
			else
			{
				luaTrace('Couldnt find object: ' + vars);
			}
		});
		Lua_helper.add_callback(lua, "doTweenY", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)
		{
			var penisExam:Dynamic = tweenShit(tag, vars);
			if (penisExam != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {y: value}, duration, {
					ease: CoolUtil.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
			else
			{
				luaTrace('Couldnt find object: ' + vars);
			}
		});
		Lua_helper.add_callback(lua, "doTweenAngle", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)
		{
			var penisExam:Dynamic = tweenShit(tag, vars);
			if (penisExam != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {angle: value}, duration, {
					ease: CoolUtil.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
			else
			{
				luaTrace('Couldnt find object: ' + vars);
			}
		});
		Lua_helper.add_callback(lua, "doTweenAlpha", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)
		{
			var penisExam:Dynamic = tweenShit(tag, vars);
			if (penisExam != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {alpha: value}, duration, {
					ease: CoolUtil.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
			else
			{
				luaTrace('Couldnt find object: ' + vars);
			}
		});
		Lua_helper.add_callback(lua, "doTweenZoom", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String)
		{
			var penisExam:Dynamic = tweenShit(tag, vars);
			if (penisExam != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {zoom: value}, duration, {
					ease: CoolUtil.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
			else
			{
				luaTrace('Couldnt find object: ' + vars);
			}
		});
		Lua_helper.add_callback(lua, "doTweenColor", function(tag:String, vars:String, targetColor:String, duration:Float, ease:String)
		{
			var penisExam:Dynamic = tweenShit(tag, vars);
			if (penisExam != null)
			{
				var color:Int = Std.parseInt(targetColor);
				if (!targetColor.startsWith('0x'))
					color = Std.parseInt('0xff' + targetColor);

				var curColor:FlxColor = penisExam.color;
				curColor.alphaFloat = penisExam.alpha;
				PlayState.instance.modchartTweens.set(tag, FlxTween.color(penisExam, duration, curColor, color, {
					ease: CoolUtil.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						PlayState.instance.modchartTweens.remove(tag);
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
					}
				}));
			}
			else
			{
				luaTrace('Couldnt find object: ' + vars);
			}
		});

		// Tween shit, but for strums
		Lua_helper.add_callback(lua, "noteTweenX", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
		{
			cancelTween(tag);
			if (note < 0)
				note = 0;
			var testicle:UIStaticArrow = Strumline.allReceptors.members[note % Strumline.allReceptors.length];

			if (testicle != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {x: value}, duration, {
					ease: CoolUtil.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});
		Lua_helper.add_callback(lua, "noteTweenY", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
		{
			cancelTween(tag);
			if (note < 0)
				note = 0;
			var testicle:UIStaticArrow = Strumline.allReceptors.members[note % Strumline.allReceptors.length];

			if (testicle != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {y: value}, duration, {
					ease: CoolUtil.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});
		Lua_helper.add_callback(lua, "noteTweenAngle", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
		{
			cancelTween(tag);
			if (note < 0)
				note = 0;
			var testicle:UIStaticArrow = Strumline.allReceptors.members[note % Strumline.allReceptors.length];

			if (testicle != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {angle: value}, duration, {
					ease: CoolUtil.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});
		Lua_helper.add_callback(lua, "noteTweenDirection", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
		{
			cancelTween(tag);
			if (note < 0)
				note = 0;
			var testicle:UIStaticArrow = Strumline.allReceptors.members[note % Strumline.allReceptors.length];

			if (testicle != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {direction: value}, duration, {
					ease: CoolUtil.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});
		Lua_helper.add_callback(lua, "mouseClicked", function(button:String)
		{
			var boobs = FlxG.mouse.justPressed;
			switch (button)
			{
				case 'middle':
					boobs = FlxG.mouse.justPressedMiddle;
				case 'right':
					boobs = FlxG.mouse.justPressedRight;
			}

			return boobs;
		});
		Lua_helper.add_callback(lua, "mousePressed", function(button:String)
		{
			var boobs = FlxG.mouse.pressed;
			switch (button)
			{
				case 'middle':
					boobs = FlxG.mouse.pressedMiddle;
				case 'right':
					boobs = FlxG.mouse.pressedRight;
			}
			return boobs;
		});
		Lua_helper.add_callback(lua, "mouseReleased", function(button:String)
		{
			var boobs = FlxG.mouse.justReleased;
			switch (button)
			{
				case 'middle':
					boobs = FlxG.mouse.justReleasedMiddle;
				case 'right':
					boobs = FlxG.mouse.justReleasedRight;
			}
			return boobs;
		});
		Lua_helper.add_callback(lua, "noteTweenAngle", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
		{
			cancelTween(tag);
			if (note < 0)
				note = 0;
			var testicle:UIStaticArrow = Strumline.allReceptors.members[note % Strumline.allReceptors.length];

			if (testicle != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {angle: value}, duration, {
					ease: CoolUtil.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});
		Lua_helper.add_callback(lua, "noteTweenAlpha", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String)
		{
			cancelTween(tag);
			if (note < 0)
				note = 0;
			var testicle:UIStaticArrow = Strumline.allReceptors.members[note % Strumline.allReceptors.length];

			if (testicle != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {alpha: value}, duration, {
					ease: CoolUtil.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween)
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});

		Lua_helper.add_callback(lua, "cancelTween", function(tag:String)
		{
			cancelTween(tag);
		});

		Lua_helper.add_callback(lua, "runTimer", function(tag:String, time:Float = 1, loops:Int = 1)
		{
			cancelTimer(tag);
			PlayState.instance.modchartTimers.set(tag, new FlxTimer().start(time, function(tmr:FlxTimer)
			{
				if (tmr.finished)
				{
					PlayState.instance.modchartTimers.remove(tag);
				}
				PlayState.instance.callOnLuas('onTimerCompleted', [tag, tmr.loops, tmr.loopsLeft]);
				// trace('Timer Completed: ' + tag);
			}, loops));
		});
		Lua_helper.add_callback(lua, "cancelTimer", function(tag:String)
		{
			cancelTimer(tag);
		});

		// stupid bietch ass functions
		Lua_helper.add_callback(lua, "addScore", function(value:Int = 0)
		{
			PlayState.songScore += value;
			PlayState.instance.uiHUD.updateScoreText();
		});
		Lua_helper.add_callback(lua, "addMisses", function(value:Int = 0)
		{
			PlayState.misses += value;
			PlayState.instance.uiHUD.updateScoreText();
		});
		Lua_helper.add_callback(lua, "addHits", function(value:Int = 0)
		{
			PlayState.songHits += value;
			PlayState.instance.uiHUD.updateScoreText();
		});
		Lua_helper.add_callback(lua, "setScore", function(value:Int = 0)
		{
			PlayState.songScore = value;
			PlayState.instance.uiHUD.updateScoreText();
		});
		Lua_helper.add_callback(lua, "setMisses", function(value:Int = 0)
		{
			PlayState.misses = value;
			PlayState.instance.uiHUD.updateScoreText();
		});
		Lua_helper.add_callback(lua, "setHits", function(value:Int = 0)
		{
			PlayState.songHits = value;
			PlayState.instance.uiHUD.updateScoreText();
		});

		Lua_helper.add_callback(lua, "setHealth", function(value:Float = 0)
		{
			PlayState.health = value;
		});
		Lua_helper.add_callback(lua, "addHealth", function(value:Float = 0)
		{
			PlayState.health += value;
		});
		Lua_helper.add_callback(lua, "getHealth", function()
		{
			return PlayState.health;
		});

		Lua_helper.add_callback(lua, "getColorFromHex", function(color:String)
		{
			if (!color.startsWith('0x'))
				color = '0xff' + color;
			return Std.parseInt(color);
		});
		Lua_helper.add_callback(lua, "keyJustPressed", function(name:String)
		{
			var key:Bool = false;
			switch (name)
			{
				case 'left':
					key = PlayState.instance.getControl('NOTE_LEFT_P');
				case 'down':
					key = PlayState.instance.getControl('NOTE_DOWN_P');
				case 'up':
					key = PlayState.instance.getControl('NOTE_UP_P');
				case 'right':
					key = PlayState.instance.getControl('NOTE_RIGHT_P');
				case 'accept':
					key = PlayState.instance.getControl('ACCEPT');
				case 'back':
					key = PlayState.instance.getControl('BACK');
				case 'pause':
					key = PlayState.instance.getControl('PAUSE');
				case 'reset':
					key = PlayState.instance.getControl('RESET');
				case 'space':
					key = FlxG.keys.justPressed.SPACE; // an extra key for convinience
			}
			return key;
		});
		Lua_helper.add_callback(lua, "keyPressed", function(name:String)
		{
			var key:Bool = false;
			switch (name)
			{
				case 'left':
					key = PlayState.instance.getControl('NOTE_LEFT');
				case 'down':
					key = PlayState.instance.getControl('NOTE_DOWN');
				case 'up':
					key = PlayState.instance.getControl('NOTE_UP');
				case 'right':
					key = PlayState.instance.getControl('NOTE_RIGHT');
				case 'space':
					key = FlxG.keys.pressed.SPACE; // an extra key for convinience
			}
			return key;
		});
		Lua_helper.add_callback(lua, "keyReleased", function(name:String)
		{
			var key:Bool = false;
			switch (name)
			{
				case 'left':
					key = PlayState.instance.getControl('NOTE_LEFT_R');
				case 'down':
					key = PlayState.instance.getControl('NOTE_DOWN_R');
				case 'up':
					key = PlayState.instance.getControl('NOTE_UP_R');
				case 'right':
					key = PlayState.instance.getControl('NOTE_RIGHT_R');
				case 'space':
					key = FlxG.keys.justReleased.SPACE; // an extra key for convinience
			}
			return key;
		});
		Lua_helper.add_callback(lua, "addCharacterToList", function(name:String, type:String)
		{
			var charType:Int = 0;
			switch (type.toLowerCase())
			{
				case 'dad':
					charType = 1;
				case 'gf' | 'girlfriend':
					charType = 2;
			}
			PlayState.instance.addCharacterToList(name, charType);
		});
		Lua_helper.add_callback(lua, "precacheImage", function(name:String)
		{
			Paths.returnGraphic(name);
		});
		Lua_helper.add_callback(lua, "precacheSound", function(name:String)
		{
			CoolUtil.precacheSound(name);
		});
		Lua_helper.add_callback(lua, "precacheMusic", function(name:String)
		{
			CoolUtil.precacheMusic(name);
		});
		Lua_helper.add_callback(lua, "triggerEvent", function(name:String, arg1:Dynamic, arg2:Dynamic)
		{
			var value1:String = arg1;
			var value2:String = arg2;
			PlayState.instance.triggerEventNote(name, value1, value2);
			// trace('Triggered event: ' + name + ', ' + value1 + ', ' + value2);
		});

		Lua_helper.add_callback(lua, "startCountdown", function(variable:String)
		{
			PlayState.instance.startCountdown();
		});
		Lua_helper.add_callback(lua, "endSong", function()
		{
			PlayState.instance.endSong();
		});
		Lua_helper.add_callback(lua, "restartSong", function(skipTransition:Bool)
		{
			PlayState.instance.persistentUpdate = false;
			PauseSubState.restartSong(skipTransition);
		});
		Lua_helper.add_callback(lua, "exitSong", function(skipTransition:Bool)
		{
			if (skipTransition)
			{
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
			}

			if (PlayState.isStoryMode)
				Main.switchState(new StoryMenuState());
			else
				Main.switchState(new FreeplayState());

			FlxG.sound.playMusic(Paths.music('freakyMenu'));
		});
		Lua_helper.add_callback(lua, "getSongPosition", function()
		{
			return Conductor.songPosition;
		});

		Lua_helper.add_callback(lua, "getCharacterX", function(type:String)
		{
			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent':
					return PlayState.instance.dadOpponent.x;
				case 'gf' | 'girlfriend':
					return PlayState.instance.gf.x;
				default:
					return PlayState.instance.boyfriend.x;
			}
		});
		Lua_helper.add_callback(lua, "setCharacterX", function(type:String, value:Float)
		{
			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent':
					PlayState.instance.dadOpponent.x = value;
				case 'gf' | 'girlfriend':
					PlayState.instance.gf.x = value;
				default:
					PlayState.instance.boyfriend.x = value;
			}
		});
		Lua_helper.add_callback(lua, "getCharacterY", function(type:String)
		{
			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent':
					return PlayState.instance.dadOpponent.y;
				case 'gf' | 'girlfriend':
					return PlayState.instance.gf.y;
				default:
					return PlayState.instance.boyfriend.y;
			}
		});
		Lua_helper.add_callback(lua, "setCharacterY", function(type:String, value:Float)
		{
			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent':
					PlayState.instance.dadOpponent.y = value;
				case 'gf' | 'girlfriend':
					PlayState.instance.gf.y = value;
				default:
					PlayState.instance.boyfriend.y = value;
			}
		});
		Lua_helper.add_callback(lua, "cameraSetTarget", function(target:String)
		{
			var isDad:Bool = false;
			if (target == 'dad')
			{
				isDad = true;
			}
			PlayState.instance.moveCamera(isDad);
		});
		Lua_helper.add_callback(lua, "cameraShake", function(camera:String, intensity:Float, duration:Float)
		{
			CoolUtil.cameraFromString(camera).shake(intensity, duration);
		});

		Lua_helper.add_callback(lua, "cameraFlash", function(camera:String, color:String, duration:Float, forced:Bool)
		{
			var colorNum:Int = Std.parseInt(color);
			if (!color.startsWith('0x'))
				colorNum = Std.parseInt('0xff' + color);
			CoolUtil.cameraFromString(camera).flash(colorNum, duration, null, forced);
		});
		Lua_helper.add_callback(lua, "cameraFade", function(camera:String, color:String, duration:Float, forced:Bool)
		{
			var colorNum:Int = Std.parseInt(color);
			if (!color.startsWith('0x'))
				colorNum = Std.parseInt('0xff' + color);
			CoolUtil.cameraFromString(camera).fade(colorNum, duration, false, null, forced);
		});
		Lua_helper.add_callback(lua, "setRatingPercent", function(value:Float)
		{
			Timings.accuracy = value;
		});
		Lua_helper.add_callback(lua, "setRatingName", function(value:String)
		{
			Timings.ratingFinal = value;
		});
		// keep that for compatibility
		Lua_helper.add_callback(lua, "setRatingFC", function(value:String)
		{
			Timings.comboDisplay = value;
		});
		Lua_helper.add_callback(lua, "getMouseX", function(camera:String)
		{
			var cam:FlxCamera = CoolUtil.cameraFromString(camera);
			return FlxG.mouse.getScreenPosition(cam).x;
		});
		Lua_helper.add_callback(lua, "getMouseY", function(camera:String)
		{
			var cam:FlxCamera = CoolUtil.cameraFromString(camera);
			return FlxG.mouse.getScreenPosition(cam).y;
		});
		Lua_helper.add_callback(lua, "getScreenPositionX", function(variable:String)
		{
			var obj:FlxObject = getObjectDirectly(variable);
			if (obj != null)
				return obj.getScreenPosition().x;

			return 0;
		});
		Lua_helper.add_callback(lua, "getScreenPositionY", function(variable:String)
		{
			var obj:FlxObject = getObjectDirectly(variable);
			if (obj != null)
				return obj.getScreenPosition().y;

			return 0;
		});
		Lua_helper.add_callback(lua, "characterPlayAnim", function(character:String, anim:String, ?forced:Bool = false)
		{
			switch (character.toLowerCase())
			{
				case 'dad':
					if (PlayState.instance.dadOpponent.animOffsets.exists(anim))
						PlayState.instance.dadOpponent.playAnim(anim, forced);
				case 'gf' | 'girlfriend':
					if (PlayState.instance.gf.animOffsets.exists(anim))
						PlayState.instance.gf.playAnim(anim, forced);
				default:
					if (PlayState.instance.boyfriend.animOffsets.exists(anim))
						PlayState.instance.boyfriend.playAnim(anim, forced);
			}
		});
		Lua_helper.add_callback(lua, "characterDance", function(character:String)
		{
			switch (character.toLowerCase())
			{
				case 'dad':
					PlayState.instance.dadOpponent.dance();
				case 'gf' | 'girlfriend':
					PlayState.instance.gf.dance();
				default:
					PlayState.instance.boyfriend.dance();
			}
		});

		Lua_helper.add_callback(lua, "makeLuaSprite", function(tag:String, image:String, x:Float, y:Float)
		{
			tag = tag.replace('.', '');
			resetSpriteTag(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			if (image != null && image.length > 0)
			{
				leSprite.loadGraphic(Paths.image(image));
			}
			PlayState.instance.modchartSprites.set(tag, leSprite);
			leSprite.active = true;
		});
		Lua_helper.add_callback(lua, "makeLuaShaderSprite", function(tag:String, shader:String, x:Float, y:Float, optimize:Bool = false)
		{
			tag = tag.replace('.', '');
			resetSpriteTag(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y, true, shader, optimize);

			PlayState.instance.modchartSprites.set(tag, leSprite);
			leSprite.active = true;
		});
		Lua_helper.add_callback(lua, "makeAnimatedLuaSprite", function(tag:String, image:String, x:Float, y:Float, ?spriteType:String = "sparrow")
		{
			tag = tag.replace('.', '');
			resetSpriteTag(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);

			loadFrames(leSprite, image, spriteType);
			PlayState.instance.modchartSprites.set(tag, leSprite);
		});

		Lua_helper.add_callback(lua, "makeGraphic", function(obj:String, width:Int, height:Int, color:String)
		{
			var colorNum:Int = Std.parseInt(color);
			if (!color.startsWith('0x'))
				colorNum = Std.parseInt('0xff' + color);

			if (PlayState.instance.modchartSprites.exists(obj))
			{
				PlayState.instance.modchartSprites.get(obj).makeGraphic(width, height, colorNum);
				return;
			}

			var object:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if (object != null)
			{
				object.makeGraphic(width, height, colorNum);
			}
		});
		Lua_helper.add_callback(lua, "addAnimationByPrefix", function(obj:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true)
		{
			if (PlayState.instance.modchartSprites.exists(obj))
			{
				var cock:ModchartSprite = PlayState.instance.modchartSprites.get(obj);
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if (cock.animation.curAnim == null)
				{
					cock.animation.play(name, true);
				}
				return;
			}

			var cock:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if (cock != null)
			{
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if (cock.animation.curAnim == null)
				{
					cock.animation.play(name, true);
				}
			}
		});
		Lua_helper.add_callback(lua, "addAnimationByIndices", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24)
		{
			var strIndices:Array<String> = indices.trim().split(',');
			var die:Array<Int> = [];
			for (i in 0...strIndices.length)
			{
				die.push(Std.parseInt(strIndices[i]));
			}

			if (PlayState.instance.modchartSprites.exists(obj))
			{
				var pussy:ModchartSprite = PlayState.instance.modchartSprites.get(obj);
				pussy.animation.addByIndices(name, prefix, die, '', framerate, false);
				if (pussy.animation.curAnim == null)
				{
					pussy.animation.play(name, true);
				}
				return;
			}

			var pussy:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if (pussy != null)
			{
				pussy.animation.addByIndices(name, prefix, die, '', framerate, false);
				if (pussy.animation.curAnim == null)
				{
					pussy.animation.play(name, true);
				}
			}
		});
		Lua_helper.add_callback(lua, "objectPlayAnimation", function(obj:String, name:String, forced:Bool = false)
		{
			if (PlayState.instance.modchartSprites.exists(obj))
			{
				PlayState.instance.modchartSprites.get(obj).animation.play(name, forced);
				return;
			}

			var spr:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if (spr != null)
			{
				spr.animation.play(name, forced);
			}
		});

		Lua_helper.add_callback(lua, "setScrollFactor", function(obj:String, scrollX:Float, scrollY:Float)
		{
			if (PlayState.instance.modchartSprites.exists(obj))
			{
				PlayState.instance.modchartSprites.get(obj).scrollFactor.set(scrollX, scrollY);
				return;
			}

			var object:FlxObject = Reflect.getProperty(getInstance(), obj);
			if (object != null)
			{
				object.scrollFactor.set(scrollX, scrollY);
			}
		});
		Lua_helper.add_callback(lua, "addLuaSprite", function(tag:String, front:Bool = false)
		{
			if (PlayState.instance.modchartSprites.exists(tag))
			{
				var shit:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				if (!shit.wasAdded)
				{
					if (front)
					{
						getInstance().add(shit);
					}
					else
					{
						if (PlayState.instance.isDead)
						{
							GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.bf), shit);
						}
						else
						{
							var position:Int = PlayState.instance.members.indexOf(PlayState.instance.gfGroup);
							if (PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup) < position)
							{
								position = PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup);
							}
							else if (PlayState.instance.members.indexOf(PlayState.instance.dadGroup) < position)
							{
								position = PlayState.instance.members.indexOf(PlayState.instance.dadGroup);
							}
							PlayState.instance.insert(position, shit);
						}
					}
					shit.wasAdded = true;
				}
			}
		});
		Lua_helper.add_callback(lua, "setGraphicSize", function(obj:String, x:Int, y:Int = 0)
		{
			if (PlayState.instance.modchartSprites.exists(obj))
			{
				var shit:ModchartSprite = PlayState.instance.modchartSprites.get(obj);
				shit.setGraphicSize(x, y);
				shit.updateHitbox();
				return;
			}

			var poop:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if (poop != null)
			{
				poop.setGraphicSize(x, y);
				poop.updateHitbox();
				return;
			}
			luaTrace('Couldnt find object: ' + obj);
		});
		Lua_helper.add_callback(lua, "scaleObject", function(obj:String, x:Float, y:Float)
		{
			if (PlayState.instance.modchartSprites.exists(obj))
			{
				var shit:ModchartSprite = PlayState.instance.modchartSprites.get(obj);
				shit.scale.set(x, y);
				shit.updateHitbox();
				return;
			}

			var poop:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if (poop != null)
			{
				poop.scale.set(x, y);
				poop.updateHitbox();
				return;
			}
			luaTrace('Couldnt find object: ' + obj);
		});
		Lua_helper.add_callback(lua, "updateHitbox", function(obj:String)
		{
			if (PlayState.instance.modchartSprites.exists(obj))
			{
				var shit:ModchartSprite = PlayState.instance.modchartSprites.get(obj);
				shit.updateHitbox();
				return;
			}

			var poop:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if (poop != null)
			{
				poop.updateHitbox();
				return;
			}
			luaTrace('Couldnt find object: ' + obj);
		});
		Lua_helper.add_callback(lua, "updateHitboxFromGroup", function(group:String, index:Int)
		{
			if (Std.isOfType(Reflect.getProperty(getInstance(), group), FlxTypedGroup))
			{
				Reflect.getProperty(getInstance(), group).members[index].updateHitbox();
				return;
			}
			Reflect.getProperty(getInstance(), group)[index].updateHitbox();
		});
		Lua_helper.add_callback(lua, "removeLuaSprite", function(tag:String, destroy:Bool = true)
		{
			if (!PlayState.instance.modchartSprites.exists(tag))
			{
				return;
			}

			var pee:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
			if (destroy)
			{
				pee.kill();
			}

			if (pee.wasAdded)
			{
				getInstance().remove(pee, true);
				pee.wasAdded = false;
			}

			if (destroy)
			{
				pee.destroy();
				PlayState.instance.modchartSprites.remove(tag);
			}
		});

		Lua_helper.add_callback(lua, "setObjectCamera", function(obj:String, camera:String = '')
		{
			if (PlayState.instance.modchartSprites.exists(obj))
			{
				PlayState.instance.modchartSprites.get(obj).cameras = [CoolUtil.cameraFromString(camera)];
				return true;
			}
			else if (PlayState.instance.modchartTexts.exists(obj))
			{
				PlayState.instance.modchartTexts.get(obj).cameras = [CoolUtil.cameraFromString(camera)];
				return true;
			}

			var object:FlxObject = Reflect.getProperty(getInstance(), obj);
			if (object != null)
			{
				object.cameras = [CoolUtil.cameraFromString(camera)];
				return true;
			}
			luaTrace("Object " + obj + " doesn't exist!");
			return false;
		});
		Lua_helper.add_callback(lua, "setBlendMode", function(obj:String, blend:String = '')
		{
			if (PlayState.instance.modchartSprites.exists(obj))
			{
				PlayState.instance.modchartSprites.get(obj).blend = CoolUtil.blendModeFromString(blend);
				return true;
			}

			var spr:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if (spr != null)
			{
				spr.blend = CoolUtil.blendModeFromString(blend);
				return true;
			}
			luaTrace("Object " + obj + " doesn't exist!");
			return false;
		});
		Lua_helper.add_callback(lua, "screenCenter", function(obj:String, pos:String = 'xy')
		{
			var spr:FlxSprite;
			if (PlayState.instance.modchartSprites.exists(obj))
			{
				spr = PlayState.instance.modchartSprites.get(obj);
			}
			else if (PlayState.instance.modchartTexts.exists(obj))
			{
				spr = PlayState.instance.modchartTexts.get(obj);
			}
			else
			{
				spr = Reflect.getProperty(getInstance(), obj);
			}

			if (spr != null)
			{
				switch (pos.trim().toLowerCase())
				{
					case 'x':
						spr.screenCenter(X);
						return;
					case 'y':
						spr.screenCenter(Y);
						return;
					default:
						spr.screenCenter(XY);
						return;
				}
			}
			luaTrace("Object " + obj + " doesn't exist!");
		});
		Lua_helper.add_callback(lua, "isColliding", function(obj1:String, obj2:String)
		{
			var namesArray:Array<String> = [obj1, obj2];
			var objectsArray:Array<FlxSprite> = [];
			for (i in 0...namesArray.length)
			{
				if (PlayState.instance.modchartSprites.exists(namesArray[i]))
				{
					objectsArray.push(PlayState.instance.modchartSprites.get(namesArray[i]));
				}
				else if (PlayState.instance.modchartTexts.exists(namesArray[i]))
				{
					objectsArray.push(PlayState.instance.modchartTexts.get(namesArray[i]));
				}
				else
				{
					objectsArray.push(Reflect.getProperty(getInstance(), namesArray[i]));
				}
			}

			if (!objectsArray.contains(null) && FlxG.overlap(objectsArray[0], objectsArray[1]))
			{
				return true;
			}
			return false;
		});
		Lua_helper.add_callback(lua, "getPixelColor", function(obj:String, x:Int, y:Int)
		{
			var spr:FlxSprite = null;
			if (PlayState.instance.modchartSprites.exists(obj))
			{
				spr = PlayState.instance.modchartSprites.get(obj);
			}
			else if (PlayState.instance.modchartTexts.exists(obj))
			{
				spr = PlayState.instance.modchartTexts.get(obj);
			}
			else
			{
				spr = Reflect.getProperty(getInstance(), obj);
			}

			if (spr != null)
			{
				if (spr.framePixels != null)
					spr.framePixels.getPixel32(x, y);
				return spr.pixels.getPixel32(x, y);
			}
			return 0;
		});
		Lua_helper.add_callback(lua, "getRandomInt", function(min:Int, max:Int = FlxMath.MAX_VALUE_INT, exclude:String = '')
		{
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Int> = [];
			for (i in 0...excludeArray.length)
			{
				toExclude.push(Std.parseInt(excludeArray[i].trim()));
			}
			return FlxG.random.int(min, max, toExclude);
		});
		Lua_helper.add_callback(lua, "getRandomFloat", function(min:Float, max:Float = 1, exclude:String = '')
		{
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Float> = [];
			for (i in 0...excludeArray.length)
			{
				toExclude.push(Std.parseFloat(excludeArray[i].trim()));
			}
			return FlxG.random.float(min, max, toExclude);
		});
		Lua_helper.add_callback(lua, "getRandomBool", function(chance:Float = 50)
		{
			return FlxG.random.bool(chance);
		});
		Lua_helper.add_callback(lua, "startDialogue", function(dialogueFile:String, music:String = null)
		{
			var daMusic:Sound = null;
			if (music != null && music != '')
				daMusic = Paths.music(music);
			PlayState.instance.callTextbox(Paths.json('songs/${PlayState.curStage.toLowerCase()}/' + dialogueFile), daMusic);
		});
		Lua_helper.add_callback(lua, "startVideo", function(videoFile:String)
		{
			#if VIDEOS_ALLOWED
			if (Paths.exists(Paths.video(videoFile)))
				PlayState.instance.startVideo(videoFile);
			else
				luaTrace('Video file not found: ' + videoFile);
			#else
			if (PlayState.instance.endingSong)
				PlayState.instance.endSong();
			else
				PlayState.instance.startCountdown();
			#end
		});

		Lua_helper.add_callback(lua, "playMusic", function(sound:String, volume:Float = 1, loop:Bool = false)
		{
			FlxG.sound.playMusic(Paths.music(sound), volume, loop);
		});
		Lua_helper.add_callback(lua, "playSound", function(sound:String, volume:Float = 1, ?tag:String = null)
		{
			if (tag != null && tag.length > 0)
			{
				tag = tag.replace('.', '');
				if (PlayState.instance.modchartSounds.exists(tag))
					PlayState.instance.modchartSounds.get(tag).stop();
				PlayState.instance.modchartSounds.set(tag, FlxG.sound.play(Paths.sound(sound), volume, false, function()
				{
					PlayState.instance.modchartSounds.remove(tag);
					PlayState.instance.callOnLuas('onSoundFinished', [tag]);
				}));
				return;
			}
			FlxG.sound.play(Paths.sound(sound), volume);
		});
		Lua_helper.add_callback(lua, "stopSound", function(tag:String)
		{
			if (tag != null && tag.length > 1 && PlayState.instance.modchartSounds.exists(tag))
			{
				PlayState.instance.modchartSounds.get(tag).stop();
				PlayState.instance.modchartSounds.remove(tag);
			}
		});
		Lua_helper.add_callback(lua, "pauseSound", function(tag:String)
		{
			if (tag != null && tag.length > 1 && PlayState.instance.modchartSounds.exists(tag))
			{
				PlayState.instance.modchartSounds.get(tag).pause();
			}
		});
		Lua_helper.add_callback(lua, "resumeSound", function(tag:String)
		{
			if (tag != null && tag.length > 1 && PlayState.instance.modchartSounds.exists(tag))
			{
				PlayState.instance.modchartSounds.get(tag).play();
			}
		});
		Lua_helper.add_callback(lua, "soundFadeIn", function(tag:String, duration:Float, fromValue:Float = 0, toValue:Float = 1)
		{
			if (tag == null || tag.length < 1)
			{
				FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			}
			else if (PlayState.instance.modchartSounds.exists(tag))
			{
				PlayState.instance.modchartSounds.get(tag).fadeIn(duration, fromValue, toValue);
			}
		});
		Lua_helper.add_callback(lua, "soundFadeOut", function(tag:String, duration:Float, toValue:Float = 0)
		{
			if (tag == null || tag.length < 1)
			{
				FlxG.sound.music.fadeOut(duration, toValue);
			}
			else if (PlayState.instance.modchartSounds.exists(tag))
			{
				PlayState.instance.modchartSounds.get(tag).fadeOut(duration, toValue);
			}
		});
		Lua_helper.add_callback(lua, "soundFadeCancel", function(tag:String)
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music.fadeTween != null)
				{
					FlxG.sound.music.fadeTween.cancel();
				}
			}
			else if (PlayState.instance.modchartSounds.exists(tag))
			{
				var theSound:FlxSound = PlayState.instance.modchartSounds.get(tag);
				if (theSound.fadeTween != null)
				{
					theSound.fadeTween.cancel();
					PlayState.instance.modchartSounds.remove(tag);
				}
			}
		});
		Lua_helper.add_callback(lua, "getSoundVolume", function(tag:String)
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music != null)
				{
					return FlxG.sound.music.volume;
				}
			}
			else if (PlayState.instance.modchartSounds.exists(tag))
			{
				return PlayState.instance.modchartSounds.get(tag).volume;
			}
			return 0;
		});
		Lua_helper.add_callback(lua, "setSoundVolume", function(tag:String, value:Float)
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music != null)
				{
					FlxG.sound.music.volume = value;
				}
			}
			else if (PlayState.instance.modchartSounds.exists(tag))
			{
				PlayState.instance.modchartSounds.get(tag).volume = value;
			}
		});
		Lua_helper.add_callback(lua, "getSoundTime", function(tag:String)
		{
			if (tag != null && tag.length > 0 && PlayState.instance.modchartSounds.exists(tag))
			{
				return PlayState.instance.modchartSounds.get(tag).time;
			}
			return 0;
		});
		Lua_helper.add_callback(lua, "setSoundTime", function(tag:String, value:Float)
		{
			if (tag != null && tag.length > 0 && PlayState.instance.modchartSounds.exists(tag))
			{
				var theSound:FlxSound = PlayState.instance.modchartSounds.get(tag);
				if (theSound != null)
				{
					var wasResumed:Bool = theSound.playing;
					theSound.pause();
					theSound.time = value;
					if (wasResumed)
						theSound.play();
				}
			}
		});

		Lua_helper.add_callback(lua, "debugPrint", function(text1:Dynamic = '', text2:Dynamic = '', text3:Dynamic = '', text4:Dynamic = '', text5:Dynamic = '')
		{
			if (text1 == null)
				text1 = '';
			if (text2 == null)
				text2 = '';
			if (text3 == null)
				text3 = '';
			if (text4 == null)
				text4 = '';
			if (text5 == null)
				text5 = '';
			luaTrace('' + text1 + text2 + text3 + text4 + text5, true, false);
		});
		Lua_helper.add_callback(lua, "close", function(printMessage:Bool)
		{
			if (!gonnaClose)
			{
				if (printMessage)
					luaTrace('Stopping lua script: ' + scriptPath);
				PlayState.instance.closeLuas.push(this);
			}
			gonnaClose = true;
		});

		Lua_helper.add_callback(lua, "changePresence",
			function(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float)
			{
				#if desktop
				Discord.changePresence(details, state, smallImageKey, hasStartTimestamp, endTimestamp);
				#end
			});

		// LUA TEXTS
		Lua_helper.add_callback(lua, "makeLuaText", function(tag:String, text:String, width:Int, x:Float, y:Float)
		{
			tag = tag.replace('.', '');
			resetTextTag(tag);
			var leText:ModchartText = new ModchartText(x, y, text, width);
			PlayState.instance.modchartTexts.set(tag, leText);
		});

		Lua_helper.add_callback(lua, "setTextString", function(tag:String, text:String)
		{
			var obj:FlxText = getTextObject(tag);
			if (obj != null)
			{
				obj.text = text;
			}
		});
		Lua_helper.add_callback(lua, "setTextSize", function(tag:String, size:Int)
		{
			var obj:FlxText = getTextObject(tag);
			if (obj != null)
			{
				obj.size = size;
			}
		});
		Lua_helper.add_callback(lua, "setTextWidth", function(tag:String, width:Float)
		{
			var obj:FlxText = getTextObject(tag);
			if (obj != null)
			{
				obj.fieldWidth = width;
			}
		});
		Lua_helper.add_callback(lua, "setTextBorder", function(tag:String, size:Int, color:String)
		{
			var obj:FlxText = getTextObject(tag);
			if (obj != null)
			{
				var colorNum:Int = Std.parseInt(color);
				if (!color.startsWith('0x'))
					colorNum = Std.parseInt('0xff' + color);

				obj.borderSize = size;
				obj.borderColor = colorNum;
			}
		});
		Lua_helper.add_callback(lua, "setTextColor", function(tag:String, color:String)
		{
			var obj:FlxText = getTextObject(tag);
			if (obj != null)
			{
				var colorNum:Int = Std.parseInt(color);
				if (!color.startsWith('0x'))
					colorNum = Std.parseInt('0xff' + color);

				obj.color = colorNum;
			}
		});
		Lua_helper.add_callback(lua, "setTextFont", function(tag:String, newFont:String)
		{
			var obj:FlxText = getTextObject(tag);
			if (obj != null)
			{
				obj.font = Paths.font(newFont);
			}
		});
		Lua_helper.add_callback(lua, "setTextItalic", function(tag:String, italic:Bool)
		{
			var obj:FlxText = getTextObject(tag);
			if (obj != null)
			{
				obj.italic = italic;
			}
		});
		Lua_helper.add_callback(lua, "setTextAlignment", function(tag:String, alignment:String = 'left')
		{
			var obj:FlxText = getTextObject(tag);
			if (obj != null)
			{
				obj.alignment = LEFT;
				switch (alignment.trim().toLowerCase())
				{
					case 'right':
						obj.alignment = RIGHT;
					case 'center':
						obj.alignment = CENTER;
				}
			}
		});

		Lua_helper.add_callback(lua, "getTextString", function(tag:String)
		{
			var obj:FlxText = getTextObject(tag);
			if (obj != null)
			{
				return obj.text;
			}
			return null;
		});
		Lua_helper.add_callback(lua, "getTextSize", function(tag:String)
		{
			var obj:FlxText = getTextObject(tag);
			if (obj != null)
			{
				return obj.size;
			}
			return -1;
		});
		Lua_helper.add_callback(lua, "getTextFont", function(tag:String)
		{
			var obj:FlxText = getTextObject(tag);
			if (obj != null)
			{
				return obj.font;
			}
			return null;
		});
		Lua_helper.add_callback(lua, "getTextWidth", function(tag:String)
		{
			var obj:FlxText = getTextObject(tag);
			if (obj != null)
			{
				return obj.fieldWidth;
			}
			return 0;
		});

		Lua_helper.add_callback(lua, "addLuaText", function(tag:String)
		{
			if (PlayState.instance.modchartTexts.exists(tag))
			{
				var shit:ModchartText = PlayState.instance.modchartTexts.get(tag);
				if (!shit.wasAdded)
				{
					getInstance().add(shit);
					shit.wasAdded = true;
					// trace('added a thing: ' + tag);
				}
			}
		});
		Lua_helper.add_callback(lua, "removeLuaText", function(tag:String, destroy:Bool = true)
		{
			if (!PlayState.instance.modchartTexts.exists(tag))
			{
				return;
			}

			var pee:ModchartText = PlayState.instance.modchartTexts.get(tag);
			if (destroy)
			{
				pee.kill();
			}

			if (pee.wasAdded)
			{
				getInstance().remove(pee, true);
				pee.wasAdded = false;
			}

			if (destroy)
			{
				pee.destroy();
				PlayState.instance.modchartTexts.remove(tag);
			}
		});

		Lua_helper.add_callback(lua, "initSaveData", function(name:String, ?folder:String = 'psychenginemods')
		{
			if (!PlayState.instance.modchartSaves.exists(name))
			{
				var save:FlxSave = new FlxSave();
				save.bind(name, folder);
				PlayState.instance.modchartSaves.set(name, save);
				return;
			}
			luaTrace('Save file already initialized: ' + name);
		});
		Lua_helper.add_callback(lua, "flushSaveData", function(name:String)
		{
			if (PlayState.instance.modchartSaves.exists(name))
			{
				PlayState.instance.modchartSaves.get(name).flush();
				return;
			}
			luaTrace('Save file not initialized: ' + name);
		});
		Lua_helper.add_callback(lua, "getDataFromSave", function(name:String, field:String)
		{
			if (PlayState.instance.modchartSaves.exists(name))
			{
				var retVal:Dynamic = Reflect.field(PlayState.instance.modchartSaves.get(name).data, field);
				return retVal;
			}
			luaTrace('Save file not initialized: ' + name);
			return null;
		});
		Lua_helper.add_callback(lua, "setDataFromSave", function(name:String, field:String, value:Dynamic)
		{
			if (PlayState.instance.modchartSaves.exists(name))
			{
				Reflect.setField(PlayState.instance.modchartSaves.get(name).data, field, value);
				return;
			}
			luaTrace('Save file not initialized: ' + name);
		});

		Lua_helper.add_callback(lua, "getTextFromFile", function(path:String, ?ignoreModFolders:Bool = false)
		{
			return Paths.getTextFromFile(path, ignoreModFolders);
		});

		// DEPRECATED, DONT MESS WITH THESE SHITS, ITS JUST THERE FOR BACKWARD COMPATIBILITY
		Lua_helper.add_callback(lua, "luaSpriteMakeGraphic", function(tag:String, width:Int, height:Int, color:String)
		{
			luaTrace("luaSpriteMakeGraphic is deprecated! Use makeGraphic instead", false, true);
			if (PlayState.instance.modchartSprites.exists(tag))
			{
				var colorNum:Int = Std.parseInt(color);
				if (!color.startsWith('0x'))
					colorNum = Std.parseInt('0xff' + color);

				PlayState.instance.modchartSprites.get(tag).makeGraphic(width, height, colorNum);
			}
		});
		Lua_helper.add_callback(lua, "luaSpriteAddAnimationByPrefix", function(tag:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true)
		{
			luaTrace("luaSpriteAddAnimationByPrefix is deprecated! Use addAnimationByPrefix instead", false, true);
			if (PlayState.instance.modchartSprites.exists(tag))
			{
				var cock:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if (cock.animation.curAnim == null)
				{
					cock.animation.play(name, true);
				}
			}
		});
		Lua_helper.add_callback(lua, "luaSpriteAddAnimationByIndices", function(tag:String, name:String, prefix:String, indices:String, framerate:Int = 24)
		{
			luaTrace("luaSpriteAddAnimationByIndices is deprecated! Use addAnimationByIndices instead", false, true);
			if (PlayState.instance.modchartSprites.exists(tag))
			{
				var strIndices:Array<String> = indices.trim().split(',');
				var die:Array<Int> = [];
				for (i in 0...strIndices.length)
				{
					die.push(Std.parseInt(strIndices[i]));
				}
				var pussy:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				pussy.animation.addByIndices(name, prefix, die, '', framerate, false);
				if (pussy.animation.curAnim == null)
				{
					pussy.animation.play(name, true);
				}
			}
		});
		Lua_helper.add_callback(lua, "luaSpritePlayAnimation", function(tag:String, name:String, forced:Bool = false)
		{
			luaTrace("luaSpritePlayAnimation is deprecated! Use objectPlayAnimation instead", false, true);
			if (PlayState.instance.modchartSprites.exists(tag))
			{
				PlayState.instance.modchartSprites.get(tag).animation.play(name, forced);
			}
		});
		Lua_helper.add_callback(lua, "setLuaSpriteCamera", function(tag:String, camera:String = '')
		{
			luaTrace("setLuaSpriteCamera is deprecated! Use setObjectCamera instead", false, true);
			if (PlayState.instance.modchartSprites.exists(tag))
			{
				PlayState.instance.modchartSprites.get(tag).cameras = [CoolUtil.cameraFromString(camera)];
				return true;
			}
			luaTrace("Lua sprite with tag: " + tag + " doesn't exist!");
			return false;
		});
		Lua_helper.add_callback(lua, "setLuaSpriteScrollFactor", function(tag:String, scrollX:Float, scrollY:Float)
		{
			luaTrace("setLuaSpriteScrollFactor is deprecated! Use setScrollFactor instead", false, true);
			if (PlayState.instance.modchartSprites.exists(tag))
			{
				PlayState.instance.modchartSprites.get(tag).scrollFactor.set(scrollX, scrollY);
			}
		});
		Lua_helper.add_callback(lua, "scaleLuaSprite", function(tag:String, x:Float, y:Float)
		{
			luaTrace("scaleLuaSprite is deprecated! Use scaleObject instead", false, true);
			if (PlayState.instance.modchartSprites.exists(tag))
			{
				var shit:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				shit.scale.set(x, y);
				shit.updateHitbox();
			}
		});
		Lua_helper.add_callback(lua, "getPropertyLuaSprite", function(tag:String, variable:String)
		{
			luaTrace("getPropertyLuaSprite is deprecated! Use getProperty instead", false, true);
			if (PlayState.instance.modchartSprites.exists(tag))
			{
				var killMe:Array<String> = variable.split('.');
				if (killMe.length > 1)
				{
					var coverMeInPiss:Dynamic = Reflect.getProperty(PlayState.instance.modchartSprites.get(tag), killMe[0]);
					for (i in 1...killMe.length - 1)
					{
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					}
					return Reflect.getProperty(coverMeInPiss, killMe[killMe.length - 1]);
				}
				return Reflect.getProperty(PlayState.instance.modchartSprites.get(tag), variable);
			}
			return null;
		});
		Lua_helper.add_callback(lua, "setPropertyLuaSprite", function(tag:String, variable:String, value:Dynamic)
		{
			luaTrace("setPropertyLuaSprite is deprecated! Use setProperty instead", false, true);
			if (PlayState.instance.modchartSprites.exists(tag))
			{
				var killMe:Array<String> = variable.split('.');
				if (killMe.length > 1)
				{
					var coverMeInPiss:Dynamic = Reflect.getProperty(PlayState.instance.modchartSprites.get(tag), killMe[0]);
					for (i in 1...killMe.length - 1)
					{
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					}
					return Reflect.setProperty(coverMeInPiss, killMe[killMe.length - 1], value);
				}
				return Reflect.setProperty(PlayState.instance.modchartSprites.get(tag), variable, value);
			}
			luaTrace("Lua sprite with tag: " + tag + " doesn't exist!");
		});
		Lua_helper.add_callback(lua, "musicFadeIn", function(duration:Float, fromValue:Float = 0, toValue:Float = 1)
		{
			FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			luaTrace('musicFadeIn is deprecated! Use soundFadeIn instead.', false, true);
		});
		Lua_helper.add_callback(lua, "musicFadeOut", function(duration:Float, toValue:Float = 0)
		{
			FlxG.sound.music.fadeOut(duration, toValue);
			luaTrace('musicFadeOut is deprecated! Use soundFadeOut instead.', false, true);
		});

		// SHADER SHIT

		Lua_helper.add_callback(lua, "addChromaticAbberationEffect", function(camera:String, chromeOffset:Float = 0.005)
		{
			PlayState.instance.addShaderToCamera(camera, new ChromaticAberrationEffect(chromeOffset));
		});

		Lua_helper.add_callback(lua, "addScanlineEffect", function(camera:String, lockAlpha:Bool = false)
		{
			PlayState.instance.addShaderToCamera(camera, new ScanlineEffect(lockAlpha));
		});
		Lua_helper.add_callback(lua, "addGrainEffect", function(camera:String, grainSize:Float, lumAmount:Float, lockAlpha:Bool = false)
		{
			PlayState.instance.addShaderToCamera(camera, new GrainEffect(grainSize, lumAmount, lockAlpha));
		});
		Lua_helper.add_callback(lua, "addTiltshiftEffect", function(camera:String, blurAmount:Float, center:Float)
		{
			PlayState.instance.addShaderToCamera(camera, new TiltshiftEffect(blurAmount, center));
		});
		Lua_helper.add_callback(lua, "addVCREffect",
			function(camera:String, glitchFactor:Float = 0.0, distortion:Bool = true, perspectiveOn:Bool = true, vignetteMoving:Bool = true)
			{
				PlayState.instance.addShaderToCamera(camera, new VCRDistortionEffect(glitchFactor, distortion, perspectiveOn, vignetteMoving));
			});

		Lua_helper.add_callback(lua, "createShaders", function(shaderName:String, ?optimize:Bool = false)
		{
			var shader = new DynamicShaderHandler(shaderName, optimize);

			return shaderName;
		});
		/*
			Lua_helper.add_callback(lua, "modifyShaderProperty", function(shaderName:String, propertyName:String, value:Dynamic)
			{
			//var handler:DynamicShaderHandler = PlayState.instance.luaShaders.get(shaderName);
			//trace(Reflect.getProperty(handler.shader.data, propertyName));
			//Reflect.setProperty(Reflect.getProperty(handler.shader.data, propertyName), 'value', value);
			handler.modifyShaderProperty(propertyName, value);
			});
			// shader set
		 */
		Lua_helper.add_callback(lua, "setShadersToCamera", function(shaderName:Array<String>, cameraName:String)
		{
			var shaderArray = new Array<BitmapFilter>();

			for (i in shaderName)
			{
				shaderArray.push(new ShaderFilter(PlayState.instance.luaShaders[i].shader));
			}

			CoolUtil.cameraFromString(cameraName).setFilters(shaderArray);
		});

		// shader clear

		Lua_helper.add_callback(lua, "clearShadersFromCamera", function(cameraName)
		{
			CoolUtil.cameraFromString(cameraName).setFilters([]);
		});

		Lua_helper.add_callback(lua, "addGlitchEffect", function(camera:String, waveSpeed:Float = 0.1, waveFrq:Float = 0.1, waveAmp:Float = 0.1)
		{
			PlayState.instance.addShaderToCamera(camera, new GlitchEffect(waveSpeed, waveFrq, waveAmp));
		});
		Lua_helper.add_callback(lua, "addPulseEffect", function(camera:String, waveSpeed:Float = 0.1, waveFrq:Float = 0.1, waveAmp:Float = 0.1)
		{
			PlayState.instance.addShaderToCamera(camera, new PulseEffect(waveSpeed, waveFrq, waveAmp));
		});
		Lua_helper.add_callback(lua, "addDistortionEffect", function(camera:String, waveSpeed:Float = 0.1, waveFrq:Float = 0.1, waveAmp:Float = 0.1)
		{
			PlayState.instance.addShaderToCamera(camera, new DistortBGEffect(waveSpeed, waveFrq, waveAmp));
		});
		Lua_helper.add_callback(lua, "addInvertEffect", function(camera:String, lockAlpha:Bool = false)
		{
			PlayState.instance.addShaderToCamera(camera, new InvertColorsEffect(lockAlpha));
		});
		Lua_helper.add_callback(lua, "addGreyscaleEffect", function(camera:String)
		{ // for dem funkies

			PlayState.instance.addShaderToCamera(camera, new GreyscaleEffect());
		});
		Lua_helper.add_callback(lua, "addGrayscaleEffect", function(camera:String)
		{ // for dem funkies

			PlayState.instance.addShaderToCamera(camera, new GreyscaleEffect());
		});
		Lua_helper.add_callback(lua, "add3DEffect", function(camera:String, xrotation:Float = 0, yrotation:Float = 0, zrotation:Float = 0, depth:Float = 0)
		{ // for dem funkies

			PlayState.instance.addShaderToCamera(camera, new ThreeDEffect(xrotation, yrotation, zrotation, depth));
		});
		Lua_helper.add_callback(lua, "addBloomEffect", function(camera:String, intensity:Float = 0.35, blurSize:Float = 1.0)
		{
			PlayState.instance.addShaderToCamera(camera, new BloomEffect(blurSize / 512.0, intensity));
		});
		Lua_helper.add_callback(lua, "clearEffects", function(camera:String)
		{
			PlayState.instance.clearShaderFromCamera(camera);
		});
		Discord.addLuaCallbacks(lua);

		call('onCreate', []);
		#end
	}

	public function set(variable:String, data:Dynamic)
	{
		#if LUA_ALLOWED
		if (lua == null)
			return;

		Convert.toLua(lua, data);
		Lua.setglobal(lua, variable);
		#end
	}

	#if LUA_ALLOWED
	public function getBool(variable:String)
	{
		var result:String = null;
		Lua.getglobal(lua, variable);
		result = Convert.fromLua(lua, -1);
		Lua.pop(lua, 1);

		if (result == null)
			return false;

		return result == 'true';
	}
	#end

	public function call(event:String, args:Array<Dynamic>):Dynamic
	{
		#if LUA_ALLOWED
		if (lua == null)
			return Function_Continue;

		Lua.getglobal(lua, event);

		for (arg in args)
			Convert.toLua(lua, arg);

		var result:Null<Int> = Lua.pcall(lua, args.length, 1, 0);
		if (result != null && resultIsAllowed(lua, result))
		{
			if (Lua.type(lua, -1) == Lua.LUA_TSTRING)
			{
				var error:String = Lua.tostring(lua, -1);
				Lua.pop(lua, 1);
				if (error == 'attempt to call a nil value')
					// Makes it ignore warnings and not break stuff if you didn't put the functions on your lua file
					return Function_Continue;
			}

			var conv:Dynamic = Convert.fromLua(lua, result);
			return conv;
		}
		#end
		return Function_Continue;
	}

	#if LUA_ALLOWED
	static function resultIsAllowed(leLua:State, leResult:Null<Int>)
	{
		switch (Lua.type(leLua, leResult))
		{
			case Lua.LUA_TNIL | Lua.LUA_TBOOLEAN | Lua.LUA_TNUMBER | Lua.LUA_TSTRING | Lua.LUA_TTABLE:
				return true;
		}
		return false;
	}
	#end

	public function luaTrace(text:String, ignoreCheck:Bool = false, deprecated:Bool = false)
	{
		#if LUA_ALLOWED
		if (ignoreCheck || getBool('luaDebugMode'))
		{
			if (deprecated && !getBool('luaDeprecatedWarnings'))
				return;
			PlayState.instance.addTextToDebug(text);
			trace(text);
		}
		#end
	}

	inline static function getTextObject(name:String):FlxText
	{
		return PlayState.instance.modchartTexts.exists(name) ? PlayState.instance.modchartTexts.get(name) : Reflect.getProperty(PlayState.instance, name);
	}

	static function getGroupStuff(leArray:Dynamic, variable:String)
	{
		var killMe:Array<String> = variable.split('.');
		if (killMe.length > 1)
		{
			var coverMeInPiss:Dynamic = Reflect.getProperty(leArray, killMe[0]);
			for (i in 1...killMe.length - 1)
			{
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
			}
			return Reflect.getProperty(coverMeInPiss, killMe[killMe.length - 1]);
		}
		return Reflect.getProperty(leArray, variable);
	}

	static function loadFrames(spr:FlxSprite, image:String, spriteType:String)
	{
		switch (spriteType.toLowerCase().trim())
		{
			case "packer" | "packeratlas" | "pac":
				spr.frames = Paths.getPackerAtlas(image);

			default:
				spr.frames = Paths.getSparrowAtlas(image);
		}
	}

	// why im a average psych lua coder sometimes
	static function compatibilityStuff(killMe:Array<String>, ?fixNullShit:Bool = false)
	{
		switch (killMe[0])
		{
			case 'playerStrums' | 'cpuStrums':
				if (killMe[1] == 'members')
				{
					killMe[1] = 'receptors';
					killMe.insert(2, 'members');
				}
		}

		if (fixNullShit && !PlayState.instance.isDead)
		{
			if (Reflect.getProperty(PlayState.instance.stageBuild, killMe[0]) != null)
				killMe.insert(0, 'stageBuild');
			else if (Reflect.getProperty(PlayState.instance.uiHUD, killMe[0]) != null)
				killMe.insert(0, 'uiHUD');
		}

		return killMe;
	}

	static function setGroupStuff(leArray:Dynamic, variable:String, value:Dynamic)
	{
		var killMe:Array<String> = variable.split('.');
		if (killMe.length > 1)
		{
			var coverMeInPiss:Dynamic = Reflect.getProperty(leArray, killMe[0]);
			for (i in 1...killMe.length - 1)
			{
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
			}
			Reflect.setProperty(coverMeInPiss, killMe[killMe.length - 1], value);
			return;
		}
		Reflect.setProperty(leArray, variable, value);
	}

	static function resetTextTag(tag:String)
	{
		if (!PlayState.instance.modchartTexts.exists(tag))
		{
			return;
		}

		var pee:ModchartText = PlayState.instance.modchartTexts.get(tag);
		pee.kill();
		if (pee.wasAdded)
		{
			PlayState.instance.remove(pee, true);
		}
		pee.destroy();
		PlayState.instance.modchartTexts.remove(tag);
	}

	static function resetSpriteTag(tag:String)
	{
		if (!PlayState.instance.modchartSprites.exists(tag))
		{
			return;
		}

		var pee:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
		pee.kill();
		if (pee.wasAdded)
		{
			PlayState.instance.remove(pee, true);
		}
		pee.destroy();
		PlayState.instance.modchartSprites.remove(tag);
	}

	static function cancelTween(tag:String)
	{
		if (PlayState.instance.modchartTweens.exists(tag))
		{
			PlayState.instance.modchartTweens.get(tag).cancel();
			PlayState.instance.modchartTweens.get(tag).destroy();
			PlayState.instance.modchartTweens.remove(tag);
		}
	}

	static function tweenShit(tag:String, vars:String)
	{
		cancelTween(tag);
		var variables:Array<String> = vars.replace(' ', '').split('.');
		var sexyProp:Dynamic = Reflect.getProperty(getInstance(), variables[0]);
		if (PlayState.instance.modchartSprites.exists(variables[0]))
		{
			sexyProp = PlayState.instance.modchartSprites.get(variables[0]);
		}
		if (PlayState.instance.modchartTexts.exists(variables[0]))
		{
			sexyProp = PlayState.instance.modchartTexts.get(variables[0]);
		}

		for (i in 1...variables.length)
		{
			sexyProp = Reflect.getProperty(sexyProp, variables[i]);
		}
		return sexyProp;
	}

	static function cancelTimer(tag:String)
	{
		if (PlayState.instance.modchartTimers.exists(tag))
		{
			var theTimer:FlxTimer = PlayState.instance.modchartTimers.get(tag);
			theTimer.cancel();
			theTimer.destroy();
			PlayState.instance.modchartTimers.remove(tag);
		}
	}

	static function getPropertyLoopThingWhatever(killMe:Array<String>, ?checkForTextsToo:Bool = true):Dynamic
	{
		var coverMeInPiss:Dynamic = getObjectDirectly(killMe[0], checkForTextsToo);
		for (i in 1...killMe.length - 1)
		{
			coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
		}
		return coverMeInPiss;
	}

	static function getObjectDirectly(objectName:String, ?checkForTextsToo:Bool = true):Dynamic
	{
		var coverMeInPiss:Dynamic = null;
		if (PlayState.instance.modchartSprites.exists(objectName))
		{
			coverMeInPiss = PlayState.instance.modchartSprites.get(objectName);
		}
		else if (checkForTextsToo && PlayState.instance.modchartTexts.exists(objectName))
		{
			coverMeInPiss = PlayState.instance.modchartTexts.get(objectName);
		}
		else
		{
			coverMeInPiss = Reflect.getProperty(getInstance(), objectName);
		}
		return coverMeInPiss;
	}

	#if LUA_ALLOWED
	public function stop()
	{
		if (lua == null)
			return;

		Lua.close(lua);
		lua = null;
	}
	#end

	inline static function getInstance()
	{
		return PlayState.instance.isDead ? GameOverSubstate.instance : PlayState.instance;
	}
}

class ModchartSprite extends FlxSprite
{
	public var wasAdded:Bool = false;

	var hShader:DynamicShaderHandler;

	public function new(?x:Float = 0, ?y:Float = 0, shaderSprite:Bool = false, type:String = '', optimize:Bool = false)
	{
		super(x, y);
		if (shaderSprite)
		{
			// codism
			flipY = true;

			makeGraphic(FlxG.width, FlxG.height, FlxColor.TRANSPARENT);

			hShader = new DynamicShaderHandler(type, optimize);

			if (hShader.shader != null)
			{
				shader = hShader.shader;
			}

			antialiasing = FlxG.save.data.antialiasing;
		}
	}
}

class ModchartText extends FlxText
{
	public var wasAdded:Bool = false;

	public function new(x:Float, y:Float, text:String, width:Float)
	{
		super(x, y, width, text, 16);
		setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		cameras = [PlayState.instance.camHUD];
		scrollFactor.set();
		borderSize = 2;
	}
}

class DebugLuaText extends FlxText
{
	private var disableTime:Float = 6;

	public var parentGroup:FlxTypedGroup<DebugLuaText>;

	public function new(text:String, parentGroup:FlxTypedGroup<DebugLuaText>)
	{
		this.parentGroup = parentGroup;
		super(10, 10, 0, text, 16);
		setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scrollFactor.set();
		borderSize = 1;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		disableTime -= elapsed;
		if (disableTime <= 0)
		{
			kill();
			parentGroup.remove(this);
			destroy();
		}
		else if (disableTime < 1)
			alpha = disableTime;
	}
}
