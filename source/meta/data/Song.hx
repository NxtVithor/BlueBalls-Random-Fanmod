package meta.data;

import meta.data.Section.SwagSection;

using StringTools;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	// used for higher compatibility
	var player3:String;
	var gfVersion:String;
	var stage:String;
	var validScore:Bool;
}

class Song
{
	public var song:String;
	public var notes:Array<SwagSection>;
	public var events:Array<Dynamic>;
	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var speed:Float = 1;

	public var player1:String = 'bf';
	public var player2:String = 'dad';

	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static function loadFromJson(jsonInput:String, ?directory:String)
	{
		var song:SwagSong = CoolUtil.readJson(Paths.songJson(directory.toLowerCase(), jsonInput.toLowerCase())).song;
		if (song.events == null)
			song.events = [];
		return song;
	}
}
