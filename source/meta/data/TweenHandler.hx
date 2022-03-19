package meta.data;

import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

/**
	The tween handler, made for making use of tweens in your modchart easier.w

	NOTE: You should call the update function for make sure tweens work!
**/
class TweenHandler
{
	private var tweens:Map<Int, Array<FlxTween>> = new Map<Int, Array<FlxTween>>();

	// empty but allow instanciation so shut up
	public function new() {}

	inline public function addByBeat(beat:Float, objects:Array<Dynamic>, values:Dynamic, duration:Float = 1, ?ease:EaseFunction)
	{
		addByStep(Math.floor(beat * 4), objects, values, duration, ease);
	}

	public function addByStep(step:Int, objects:Array<Dynamic>, values:Dynamic, duration:Float = 1, ?ease:EaseFunction)
	{
		if (ease == null)
			ease = FlxEase.linear;

		for (obj in objects)
		{
			if (Std.isOfType(obj, FlxTypedGroup) || Std.isOfType(obj, FlxSpriteGroup))
			{
				var leArray:Array<Dynamic> = obj.members;
				for (spr in leArray)
					setTween(step, FlxTween.tween(spr, values, duration, {ease: ease,}));
			}
			else
				setTween(step, FlxTween.tween(obj, values, duration, {ease: ease,}));
		}
	}

	private function setTween(step:Int, tween:FlxTween)
	{
		tween.active = false;

		var tweenArray:Array<FlxTween> = [];
		if (tweens.exists(step))
			tweenArray = tweens.get(step);

		tweenArray.push(tween);
		tweens.set(step, tweenArray);

		// trace('new tween added at step $step');
	}

	// YOU SHOULD RUN THIS AT EVERY STEP HIT FOR MAKE SHIT WORK
	public function update(step:Int)
	{
		if (tweens.exists(step))
		{
			// trace('updating tweens for step $step');
			for (tween in tweens.get(step))
				tween.start();
		}
	}
}
