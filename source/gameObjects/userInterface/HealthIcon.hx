package gameObjects.userInterface;

import meta.data.dependency.AttachedSprite;
import flixel.graphics.FlxGraphic;

using StringTools;

class HealthIcon extends AttachedSprite
{
	// rewrite using da new icon system as ninjamuffin would say it
	public var initialWidth:Float = 0;
	public var initialHeight:Float = 0;

	var isPlayer:Bool = false;

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		this.isPlayer = isPlayer;
		updateIcon(char, isPlayer);
	}

	public function updateIcon(char:String = 'bf', ?isPlayer:Bool)
	{
		if (isPlayer == null)
			isPlayer = this.isPlayer;

		var path:String = 'icons/' + char;
		if (!Paths.exists(Paths.getPath('images/' + path + '.png', IMAGE)))
			path = 'icons/icon-' + char;
		if (!Paths.exists(Paths.getPath('images/' + path + '.png', IMAGE)))
			path = 'icons/icon-face';

		var iconGraphic:FlxGraphic = Paths.image(path);
		loadGraphic(iconGraphic, true, Std.int(iconGraphic.width / 2), iconGraphic.height);

		initialWidth = width;
		initialHeight = height;

		animation.add('icon', [0, 1], 0, false, isPlayer);
		animation.play('icon');

		antialiasing = !char.endsWith('-pixel');
	}
}
