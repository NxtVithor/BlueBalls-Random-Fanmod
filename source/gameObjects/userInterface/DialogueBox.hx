package gameObjects.userInterface;

import meta.CoolUtil;
import meta.MusicBeat.MusicBeatState;
import meta.state.PlayState;
import meta.data.Alphabet;
import openfl.media.Sound;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.text.FlxTypeText;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;
import flixel.input.FlxKeyManager;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

using StringTools;

class DialogueBox extends FlxSpriteGroup
{
	var box:FlxSprite;

	var curCharacter:String = '';

	var dialogueList:Array<String> = [];

	// SECOND DIALOGUE FOR THE PIXEL SHIT INSTEAD???
	var swagText:FlxTypeText;

	var dropText:FlxText;

	public var finishThing:Void->Void;

	var portraitLeft:FlxSprite;
	var portraitRight:FlxSprite;

	var bgFade:FlxSprite;

	var skipText:FlxText;

	var skin:String;

	var isPixelSkin:Bool = false;

	public function new(?skin:String = 'normal', ?music:Sound, ?characters:Array<Array<String>>, ?dialogueList:Array<String>)
	{
		super();

		this.skin = skin;

		if (characters == null)
			characters = [['senpai', 'Senpai Portrait Enter'], ['bf-pixel', 'Boyfriend portrait enter']];

		if (music != null)
		{
			FlxG.sound.playMusic(music, 0);
			FlxG.sound.music.fadeIn(1, 0, 0.8);
		}

		bgFade = new FlxSprite(-200, -200).makeGraphic(Std.int(FlxG.width * 1.3), Std.int(FlxG.height * 1.3), 0xFFB3DFd8);
		bgFade.scrollFactor.set();
		bgFade.alpha = 0;
		add(bgFade);

		new FlxTimer().start(0.83, function(tmr:FlxTimer)
		{
			bgFade.alpha += (1 / 5) * 0.7;
			if (bgFade.alpha > 0.7)
				bgFade.alpha = 0.7;
		}, 5);

		box = new FlxSprite(0, 45);

		var boxBase:String = 'dialogue/boxes/';

		var portraitBase:String = 'dialogue/portraits/';

		switch (skin.toLowerCase())
		{
			case 'evil-pixel':
				isPixelSkin = true;
				box.frames = Paths.getSparrowAtlas(boxBase + 'dialogueBox-evil');
				box.animation.addByPrefix('normalOpen', 'Spirit Textbox spawn', 24, false);
				box.animation.addByIndices('normal', 'Spirit Textbox spawn', [11], "", 24);
			case 'pixel':
				isPixelSkin = true;
				box.frames = Paths.getSparrowAtlas(boxBase + 'dialogueBox-pixel');
				box.animation.addByPrefix('normalOpen', 'Text Box Appear', 24, false);
				box.animation.addByIndices('normal', 'Text Box Appear', [4], "", 24);
			default:
				box.frames = Paths.getSparrowAtlas(boxBase + 'speech_bubble_talking');
				box.animation.addByPrefix('normalOpen', 'Speech Bubble Normal Open', 24, false);
				box.animation.addByPrefix('normal', 'speech bubble normal', 24, true);
				box.y = FlxG.height - box.height / 1.1;
		}

		this.dialogueList = dialogueList;

		portraitLeft = new FlxSprite(-20, 40);
		portraitLeft.frames = Paths.getSparrowAtlas(portraitBase + characters[0][0]);
		portraitLeft.animation.addByPrefix('enter', characters[0][1], 24, false);
		if (characters[0][0].endsWith('-pixel') || characters[0][0].startsWith('senpai'))
			portraitLeft.setGraphicSize(Std.int(portraitLeft.width * PlayState.daPixelZoom * 0.9));
		portraitLeft.flipX = true;
		portraitLeft.updateHitbox();
		portraitLeft.scrollFactor.set();
		portraitLeft.visible = false;
		add(portraitLeft);

		portraitRight = new FlxSprite(0, 40);
		portraitRight.frames = Paths.getSparrowAtlas(portraitBase + characters[1][0]);
		portraitRight.animation.addByPrefix('enter', characters[1][1], 24, false);
		if (characters[1][0].endsWith('-pixel') || characters[1][0].startsWith('senpai'))
			portraitRight.setGraphicSize(Std.int(portraitRight.width * PlayState.daPixelZoom * 0.9));
		portraitRight.updateHitbox();
		portraitRight.scrollFactor.set();
		portraitRight.visible = false;
		add(portraitRight);

		box.animation.play('normalOpen');
		if (isPixelSkin)
			box.setGraphicSize(Std.int(box.width * PlayState.daPixelZoom * 0.9));
		else
			box.flipX = getCurCharacter() == 'dad';
		box.updateHitbox();
		add(box);

		box.screenCenter(X);
		if (!isPixelSkin)
			box.x += 32;

		portraitLeft.screenCenter(X);

		var textX:Float = 240;
		var textY:Float = 500;
		if (!isPixelSkin)
		{
			textX -= 75;
			textY -= 35;
		}

		dropText = new FlxText(textX + 2, textY + 2, Std.int(FlxG.width * 0.6), "", 32);
		dropText.font = 'Pixel Arial 11 Bold';
		dropText.color = 0xFFD89494;
		add(dropText);

		swagText = new FlxTypeText(textX, textY, Std.int(FlxG.width * 0.6), "", 32);
		swagText.font = 'Pixel Arial 11 Bold';
		swagText.color = 0xFF3F2021;
		swagText.sounds = [FlxG.sound.load(Paths.sound('pixelText'), 0.6)];
		add(swagText);

		skipText = new FlxText(0, FlxG.height - 25, FlxG.width, 'PRESS SHIFT TO SKIP', 20);
		skipText.setFormat(Paths.font('vcr.ttf'), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		skipText.borderSize = 1.5;
		skipText.visible = false;
		add(skipText);

		if (skin == 'evil-pixel')
		{
			portraitLeft.color = FlxColor.BLACK;
			swagText.color = FlxColor.WHITE;
			dropText.color = FlxColor.BLACK;
		}
	}

	var dialogueOpened:Bool = false;
	var dialogueStarted:Bool = false;

	override function update(elapsed:Float)
	{
		dropText.text = swagText.text;

		if (box.animation.curAnim != null)
		{
			if (box.animation.curAnim.name == 'normalOpen' && box.animation.curAnim.finished)
			{
				box.animation.play('normal');
				dialogueOpened = true;
			}
		}

		if (dialogueOpened && !dialogueStarted)
		{
			startDialogue();
			dialogueStarted = true;
			skipText.visible = true;
		}

		var shift = FlxG.keys.justPressed.SHIFT;

		if ((shift || CoolUtil.getControls().ACCEPT) && dialogueStarted == true)
		{
			if (!isEnding)
				FlxG.sound.play(Paths.sound('clickText'), 0.8);

			if (shift || (dialogueList[1] == null && dialogueList[0] != null))
			{
				if (!isEnding)
				{
					isEnding = true;

					remove(skipText);

					if (FlxG.sound.music != null)
						FlxG.sound.music.fadeOut(2.2, 0);

					new FlxTimer().start(0.2, function(tmr:FlxTimer)
					{
						box.alpha -= 1 / 5;
						bgFade.alpha -= 1 / 5 * 0.7;
						portraitLeft.visible = false;
						portraitRight.visible = false;
						swagText.alpha -= 1 / 5;
						dropText.alpha = swagText.alpha;
					}, 5);

					new FlxTimer().start(1.2, function(tmr:FlxTimer)
					{
						finishThing();
						kill();
					});
				}
			}
			else
			{
				dialogueList.remove(dialogueList[0]);
				startDialogue();
			}
		}

		super.update(elapsed);
	}

	var isEnding:Bool = false;

	function startDialogue()
	{
		cleanDialog();

		swagText.resetText(dialogueList[0]);
		swagText.start(0.04, true);

		switch (curCharacter)
		{
			case 'dad':
				portraitRight.visible = false;
				if (!portraitLeft.visible)
				{
					portraitLeft.visible = true;
					portraitLeft.animation.play('enter');
				}
				if (!isPixelSkin)
					box.flipX = true;
			case 'bf':
				portraitLeft.visible = false;
				if (!portraitRight.visible)
				{
					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}
				if (!isPixelSkin)
					box.flipX = false;
		}
	}

	function getCurCharacter()
	{
		return dialogueList[0].split(":")[1];
	}

	function cleanDialog()
	{
		curCharacter = getCurCharacter();
		dialogueList[0] = dialogueList[0].substr(dialogueList[0].split(":")[1].length + 2).trim();
	}
}
