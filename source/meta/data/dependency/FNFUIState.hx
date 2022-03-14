package meta.data.dependency;

import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIState;

class FNFUIState extends FlxUIState
{
	override function create()
	{
		// state stuffs
		if (!FlxTransitionableState.skipNextTransOut)
			openSubState(new FNFTransition(null, true));
		else
			FlxTransitionableState.skipNextTransOut = false;

		super.create();
	}
}
