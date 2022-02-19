package gameObjects.userInterface.menu;

import meta.CoolUtil;
import flixel.FlxSprite;

using StringTools;

// haha psych code go brrrr
typedef MenuCharacterFile =
{
	var image:String;
	var scale:Float;
	var position:Array<Int>;
	var idle_anim:String;
	var confirm_anim:String;
}

class MenuCharacter extends FlxSprite
{
	public var character:String = '';

	public function new(x:Float, character:String = 'bf')
	{
		super(x);

		antialiasing = true;

		changeCharacter(character);
	}

	public function confirm()
	{
		if (character != '' && animation.getByName('confirm') != null)
			animation.play('confirm');
	}

	public function changeCharacter(?character:String = 'bf')
	{
		if (character == null)
			character = '';

		this.character = character;
		visible = false;

		scale.set(1, 1);
		updateHitbox();

		if (character != '')
		{
			// compatibility again
			var base:String = 'menucharacters';
			if (!Paths.exists(base))
				base = 'menus/base/storymenu/characters';
			var charFile:MenuCharacterFile = cast CoolUtil.readJson(Paths.json('images/$base/$character'));
			frames = Paths.getSparrowAtlas('$base/' + charFile.image);
			animation.addByPrefix('idle', charFile.idle_anim, 24);
			animation.addByPrefix('confirm', charFile.confirm_anim, 24, false);

			if (charFile.scale != 1)
			{
				scale.set(charFile.scale, charFile.scale);
				updateHitbox();
			}
			offset.set(charFile.position[0], charFile.position[1]);

			visible = true;

			animation.play('idle');
		}
	}
}
