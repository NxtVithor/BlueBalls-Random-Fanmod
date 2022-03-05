package gameObjects.userInterface;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import meta.CoolUtil;
import meta.InfoHud;
import meta.data.Conductor;
import meta.data.Script;
import meta.data.Timings;
import meta.state.PlayState;

using StringTools;

class ClassHUD extends FlxTypedGroup<FlxBasic>
{
	// set up variables and stuff here
	public var infoBar:FlxText; // small side bar like kade engine that tells you engine info
	public var scoreTxt:FlxText;

	public var scoreTxtTween:FlxTween;

	var scoreLast:Float = -1;

	public var healthBarBG:FlxSprite;
	public var healthBar:FlxBar;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	public var grpIcons:FlxTypedGroup<HealthIcon>;

	private var stupidHealth:Float = 0;

	private var timingsMap:Map<String, FlxText> = [];

	// eep
	public function new()
	{
		// call the initializations and stuffs
		super();

		// le healthbar setup
		var barY = FlxG.height * 0.875;
		if (Init.trueSettings.get('Downscroll'))
			barY = 64;

		healthBarBG = new FlxSprite(0,
			barY).loadGraphic(Paths.image(ForeverTools.returnSkinAsset('healthBar', PlayState.assetModifier, PlayState.changeableSkin, 'UI')));
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		add(healthBarBG);

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8));
		healthBar.scrollFactor.set();
		reloadHealthBarColors();
		// healthBar
		add(healthBar);

		grpIcons = new FlxTypedGroup<HealthIcon>(2);
		add(grpIcons);

		iconP1 = new HealthIcon(PlayState.instance.boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		grpIcons.add(iconP1);

		iconP2 = new HealthIcon(PlayState.instance.dadOpponent.healthIcon, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		grpIcons.add(iconP2);

		scoreTxt = new FlxText(0, healthBarBG.y + 40, 0, '', 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.screenCenter(X);
		updateScoreText();
		scoreTxt.scrollFactor.set();
		add(scoreTxt);

		// small info bar based on scoretxt, kinda like the KE watermark
		var infoDisplay:String = CoolUtil.dashToSpace(PlayState.SONG.song) + ' - ' + CoolUtil.difficulties[PlayState.storyDifficulty];
		var engineDisplay:String = "Forever Modding v" + Main.gameVersion;
		var engineBar:FlxText = new FlxText(0, FlxG.height - 30, 0, engineDisplay, 16);
		engineBar.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		engineBar.updateHitbox();
		engineBar.x = FlxG.width - engineBar.width - 5;
		engineBar.scrollFactor.set();
		add(engineBar);

		infoBar = new FlxText(5, FlxG.height - 30, 0, infoDisplay, 20);
		infoBar.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		infoBar.scrollFactor.set();
		add(infoBar);

		// counter
		if (Init.trueSettings.get('Counter') != 'None')
		{
			var judgementNameArray:Array<String> = [];
			for (i in Timings.judgementsMap.keys())
				judgementNameArray.insert(Timings.judgementsMap.get(i)[0], i);
			judgementNameArray.sort(sortByShit);
			for (i in 0...judgementNameArray.length)
			{
				var textAsset:FlxText = new FlxText(5
					+ (!left ? (FlxG.width - 10) : 0),
					(FlxG.height / 2)
					- (counterTextSize * (judgementNameArray.length / 2))
					+ (i * counterTextSize), 0, '', counterTextSize);
				if (!left)
					textAsset.x -= textAsset.text.length * counterTextSize;
				textAsset.setFormat(Paths.font("vcr.ttf"), counterTextSize, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				textAsset.scrollFactor.set();
				timingsMap.set(judgementNameArray[i], textAsset);
				add(textAsset);
			}
		}
		updateCounter();
	}

	public function reloadHealthBarColors()
	{
		healthBar.createFilledBar(PlayState.instance.dadOpponent.healthBarColor, PlayState.instance.boyfriend.healthBarColor);
		healthBar.updateBar();
	}

	var counterTextSize:Int = 18;

	function sortByShit(Obj1:String, Obj2:String):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Timings.judgementsMap.get(Obj1)[0], Timings.judgementsMap.get(Obj2)[0]);

	var left = (Init.trueSettings.get('Counter') == 'Left');

	override public function update(elapsed:Float)
	{
		if (PlayState.cpuControlled)
			scoreTxt.text = 'Botplay';
		else
			scoreTxt.text = lastScoreText;
		scoreTxt.x = FlxG.width / 2 - scoreTxt.width / 2;

		// pain, this is like the 7th attempt
		healthBar.percent = (PlayState.health * 50);

		grpIcons.forEachAlive(function(icon:HealthIcon)
		{
			icon.setGraphicSize(Std.int(FlxMath.lerp(icon.width, 150, Main.framerateAdjust(0.07))));
			icon.updateHitbox();
		});

		var iconOffset:Int = 26;
		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);

		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;
	}

	static final divider:String = ' - ';

	var lastScoreText:String;

	public function updateScoreText()
	{
		PlayState.instance.setOnLuas('score', PlayState.songScore);
		PlayState.instance.setOnLuas('misses', PlayState.misses);
		PlayState.instance.setOnLuas('hits', PlayState.songHits);

		var ret:Dynamic = PlayState.instance.callOnLuas('onRecalculateRating', []);

		if (ret != Script.Function_Stop)
		{
			lastScoreText = 'Score: ' + PlayState.songScore;
			if (Init.trueSettings.get('Display Accuracy'))
			{
				lastScoreText += divider + 'Combo Breaks: ' + PlayState.misses;
				lastScoreText += divider + 'Accuracy: ' + Std.string(Math.floor(Timings.trueAccuracy * 100) / 100) + '%' + Timings.comboDisplay;
				lastScoreText += divider + Timings.ratingFinal;
			}
		}

		// update counter
		updateCounter();

		// update playstate
		PlayState.detailsSub = scoreTxt.text;
		PlayState.updateRPC(false);
	}

	function updateCounter()
	{
		if (Init.trueSettings.get('Counter') != 'None')
		{
			for (i in timingsMap.keys())
			{
				timingsMap[i].text = '${(i.charAt(0).toUpperCase() + i.substring(1, i.length))}: ${Timings.gottenJudgements.get(i)}';
				timingsMap[i].x = (5 + (!left ? (FlxG.width - 10) : 0) - (!left ? (6 * counterTextSize) : 0));
			}
		}
	}

	public function beatHit()
	{
		if (!Init.trueSettings.get('Reduced Movements'))
			grpIcons.forEachAlive(function(icon:HealthIcon)
			{
				icon.setGraphicSize(Std.int(icon.width + 30));
				icon.updateHitbox();
			});
	}
}
