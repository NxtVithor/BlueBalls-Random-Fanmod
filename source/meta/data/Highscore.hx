package meta.data;

import flixel.FlxG;

using StringTools;

class Highscore
{
	public static var songScores:Map<String, Int> = new Map();

	public static function saveScore(song:String, score:Int = 0, ?diff:Int = 0):Void
	{
		var daSong:String = CoolUtil.formatSong(song, diff);

		if (songScores.exists(daSong))
		{
			if (songScores.get(daSong) < score)
				setScore(daSong, score);
		}
		else
			setScore(daSong, score);
	}

	public static function saveWeekScore(week:Int = 1, score:Int = 0, ?diff:Int = 0):Void
	{
		var daWeek:String = CoolUtil.formatSong('week' + week, diff);

		if (songScores.exists(daWeek))
		{
			if (songScores.get(daWeek) < score)
				setScore(daWeek, score);
		}
		else
			setScore(daWeek, score);
	}

	/**
	 * YOU SHOULD FORMAT SONG WITH formatSong() BEFORE TOSSING IN SONG VARIABLE
	 */
	static function setScore(song:String, score:Int):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		songScores.set(song, score);
		FlxG.save.data.songScores = songScores;
		FlxG.save.flush();
	}

	public static function getScore(song:String, diff:Int):Int
	{
		var poop:String = CoolUtil.formatSong(song, diff);

		if (!songScores.exists(poop))
			setScore(poop, 0);

		return songScores.get(poop);
	}

	public static function getWeekScore(week:Int, diff:Int):Int
	{
		var poop:String = CoolUtil.formatSong('week' + week, diff);

		if (!songScores.exists(poop))
			setScore(poop, 0);

		return songScores.get(poop);
	}

	public static function load():Void
	{
		if (FlxG.save.data.songScores != null)
			songScores = FlxG.save.data.songScores;
	}
}
