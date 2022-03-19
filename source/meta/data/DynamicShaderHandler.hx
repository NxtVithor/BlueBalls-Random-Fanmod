package meta.data;

import flixel.FlxG;
import flixel.graphics.tile.FlxGraphicsShader;
import haxe.display.Display.Package;
import meta.state.PlayState;
import openfl.display.GraphicsShader;
#if sys
import sys.FileSystem;
#end

/**
	Class to handle animated shaders, calling the new consturctor is enough, 
	the update function will be automatically called by the playstate.

	Shaders should be placed at /shaders directory, with ".frag" extension, 
	See shaders directory for examples and guides.

	Optimize variable might help with some heavy shaders but only makes a difference on decent Intel CPUs.

	Please respect the effort but to this and credit us if used :]

	Edited by Stilic for making it working on FE.

	@author Kemo
 */
class DynamicShaderHandler
{
	public var shader:FlxGraphicsShader;

	private var bHasResolution:Bool = false;
	private var bHasTime:Bool = false;

	public function new(fileName:String, optimize:Bool = false)
	{
		var fragPath:String = Paths.shaderFrag(fileName);
		var vertPath:String = Paths.shaderVertex(fileName);

		var fragSource:String = "";
		var vertSource:String = "";

		if (Paths.exists(fragPath))
			fragSource = Paths.readFile(fragPath);
		if (Paths.exists(vertPath))
			vertSource = Paths.readFile(vertPath);

		if (fragPath != "" || vertPath != "")
			shader = new FlxGraphicsShader(fragSource, optimize, vertSource);

		if (shader == null)
		{
			trace("the shader didn't loaded???? " + fileName);
			return;
		}

		if (fragSource.indexOf("iResolution") != -1)
		{
			bHasResolution = true;
			shader.data.iResolution.value = [FlxG.width, FlxG.height];
		}

		if (fragSource.indexOf("iTime") != -1)
		{
			bHasTime = true;
			shader.data.iTime.value = [0];
		}

		#if LUA_ALLOWED
		PlayState.instance.luaShaders[fileName] = this;
		#end
		PlayState.animatedShaders[fileName] = this;

		// trace(shader.data.get('rOffset'));
	}

	public function modifyShaderProperty(property:String, value:Dynamic)
	{
		if (shader == null)
			return;

		if (shader.data.get(property) != null)
			shader.data.get(property).value = value;
	}

	private function getTime()
	{
		return shader.data.iTime.value[0];
	}

	private function setTime(value)
	{
		shader.data.iTime.value = [value];
	}

	public function update(elapsed:Float)
	{
		if (bHasTime)
			setTime(getTime() + elapsed);
	}
}
