package meta.data;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

/**
	The tween handler, made for making use of tweens in your modchart easier.

	NOTE: You should call the update function for make sure tweens work!
**/
class TweenHandler
{
	private var tweens:Map<Int, Array<FlxTween>> = new Map<Int, Array<FlxTween>>();

	// empty but allow instanciation so shut up
	public function new() {}

	public function addByBeat(beat:Float, objects:Array<Dynamic>, values:Dynamic, duration:Float = 1, ?ease:EaseFunction)
	{
		if (ease == null)
			ease = FlxEase.linear;

		var step:Int = Math.floor(beat * 4);
		for (obj in objects)
			setTween(step, FlxTween.tween(obj, values, duration, {ease: ease}));
	}

	public function addByStep(step:Int, objects:Array<Dynamic>, values:Dynamic, duration:Float = 1, ?ease:EaseFunction)
	{
		if (ease == null)
			ease = FlxEase.linear;

		for (obj in objects)
			setTween(step, FlxTween.tween(obj, values, duration, {ease: ease,}));
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

	private function setTween(step:Int, tween:FlxTween)
	{
		var tweenArray:Array<FlxTween> = [];
		if (tweens.exists(step))
			tweenArray = tweens.get(step);

		tween.active = false;

		tweenArray.push(tween);
		tweens.set(step, tweenArray);

		// trace('new tween added at step $step');
	}
}
