package meta.data.dependency;

import flixel.FlxSprite;

class AttachedSprite extends FlxSprite
{
	public var sprTracker:FlxSprite;

	public var copyAlpha:Bool = false;

	public var xAdd:Float = 0;
	public var yAdd:Float = 0;

	override public function new(?tracker:FlxSprite)
	{
		super();
		sprTracker = tracker;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
		{
			if (copyAlpha)
				alpha = sprTracker.alpha;

			setPosition(sprTracker.x + xAdd, sprTracker.y + yAdd);
		}
	}
}
