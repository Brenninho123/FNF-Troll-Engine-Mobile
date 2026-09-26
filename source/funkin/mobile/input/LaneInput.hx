package funkin.mobile.input;

#if mobile
import flixel.FlxG;

class LaneInput
{
	public var laneCount(default, set):Int;
	public var areaX:Float = 0;
	public var areaWidth:Float = -1;
	public var slide:Bool = false;
	public var onPress:Null<Int->Void>;
	public var onRelease:Null<Int->Void>;

	final touchIds:Array<Int> = [];
	final touchLanes:Array<Int> = [];
	final holds:Array<Int> = [];

	public function new(laneCount:Int, ?onPress:Int->Void, ?onRelease:Int->Void)
	{
		this.laneCount = laneCount;
		this.onPress = onPress;
		this.onRelease = onRelease;
	}

	function set_laneCount(value:Int):Int
	{
		releaseAll();
		laneCount = value;

		while (holds.length < value)
			holds.push(0);

		return value;
	}

	public function update():Void
	{
		var i:Int = touchIds.length;

		while (i-- > 0)
		{
			final touch = FlxG.touches.getByID(touchIds[i]);

			if (touch == null || touch.released)
			{
				releaseAt(i);
			}
			else if (slide)
			{
				final lane:Int = laneAt(touch.gameX);

				if (lane != touchLanes[i])
				{
					final id:Int = touchIds[i];
					releaseAt(i);
					press(id, lane);
				}
			}
		}

		for (touch in FlxG.touches.list)
		{
			if (!touch.justPressed || touchIds.contains(touch.touchPointID))
				continue;

			if (TouchGestures.instance?.getPoint(touch.touchPointID)?.startEdge == TouchEdge.TOP)
				continue;

			press(touch.touchPointID, laneAt(touch.gameX));
		}
	}

	public function releaseAll():Void
	{
		while (touchIds.length > 0)
			releaseAt(touchIds.length - 1);
	}

	public function laneAt(x:Float):Int
	{
		final width:Float = areaWidth > 0 ? areaWidth : FlxG.width;
		final lane:Int = Math.floor((x - areaX) / width * laneCount);
		return lane < 0 ? 0 : (lane >= laneCount ? laneCount - 1 : lane);
	}

	function press(id:Int, lane:Int):Void
	{
		touchIds.push(id);
		touchLanes.push(lane);
		holds[lane]++;

		if (onPress != null)
			onPress(lane);
	}

	function releaseAt(index:Int):Void
	{
		final lane:Int = touchLanes[index];
		touchIds.splice(index, 1);
		touchLanes.splice(index, 1);

		if (holds[lane] > 0)
			holds[lane]--;

		if (holds[lane] == 0 && onRelease != null)
			onRelease(lane);
	}
}
#end
