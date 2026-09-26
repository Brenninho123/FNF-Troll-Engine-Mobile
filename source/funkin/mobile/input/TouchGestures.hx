package funkin.mobile.input;

#if mobile
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.input.touch.FlxTouch;
import flixel.util.FlxSignal.FlxTypedSignal;
import haxe.Timer;

class TouchGestures extends FlxBasic
{
	public static var instance(default, null):TouchGestures;

	public static function init():TouchGestures
	{
		if (instance == null)
		{
			instance = new TouchGestures();
			FlxG.plugins.addPlugin(instance);
			TouchControls.init(instance);
		}

		return instance;
	}

	public var swipeDistance:Float = 0.07;
	public var tapDistance:Float = 0.03;
	public var tapTime:Float = 0.25;
	public var longPressTime:Float = 0.5;
	public var doubleTapTime:Float = 0.3;
	public var edgeSize:Float = 0.05;

	public final onTouchStart:FlxTypedSignal<TouchPoint->Void> = new FlxTypedSignal();
	public final onTouchEnd:FlxTypedSignal<TouchPoint->Void> = new FlxTypedSignal();
	public final onTap:FlxTypedSignal<TouchPoint->Void> = new FlxTypedSignal();
	public final onDoubleTap:FlxTypedSignal<TouchPoint->Void> = new FlxTypedSignal();
	public final onLongPress:FlxTypedSignal<TouchPoint->Void> = new FlxTypedSignal();
	public final onSwipe:FlxTypedSignal<TouchPoint->SwipeDirection->Void> = new FlxTypedSignal();

	final points:Map<Int, TouchPoint> = [];
	final stale:Array<Int> = [];
	public var frame(default, null):Int = 0;
	public var dragX(default, null):Float = 0;
	public var dragY(default, null):Float = 0;

	var tapPoint:Null<TouchPoint>;
	var tapFrame:Int = -1;
	var longPressPoint:Null<TouchPoint>;
	var longPressFrame:Int = -1;
	var swipeDirection:SwipeDirection = SwipeDirection.NONE;
	var swipeFrame:Int = -1;
	var lastTapStamp:Float = -1;
	var lastTapX:Float = 0;
	var lastTapY:Float = 0;

	function new()
	{
		super();
		visible = false;
	}

	public inline function getPoint(id:Int):Null<TouchPoint>
		return points.get(id);

	public inline function getTap():Null<TouchPoint>
		return tapFrame == frame ? tapPoint : null;

	public inline function getLongPress():Null<TouchPoint>
		return longPressFrame == frame ? longPressPoint : null;

	public inline function getSwipe():SwipeDirection
		return swipeFrame == frame ? swipeDirection : SwipeDirection.NONE;

	override function update(elapsed:Float):Void
	{
		frame++;
		dragX = 0;
		dragY = 0;
		TouchControls.beginFrame();

		for (touch in FlxG.touches.list)
		{
			final id:Int = touch.touchPointID;
			var point:Null<TouchPoint> = points.get(id);

			if (touch.justPressed && point != null)
			{
				finish(point, true);
				point = null;
			}

			if (point == null)
			{
				if (!touch.pressed)
					continue;

				point = begin(touch);
			}

			point.move(TouchUtil.gameX(touch), TouchUtil.gameY(touch), frame);

			if (touch.justReleased)
				finish(point, false);
			else
				track(point);

			if (point.swiped && point.startEdge == TouchEdge.NONE)
			{
				if (point.vertical)
					dragY += point.deltaY;
				else
					dragX += point.deltaX;
			}
		}

		for (id => point in points)
		{
			if (point.lastFrame != frame)
				stale.push(id);
		}

		while (stale.length > 0)
			finish(points.get(stale.pop()), true);
	}

	function begin(touch:FlxTouch):TouchPoint
	{
		final point:TouchPoint = new TouchPoint(touch.touchPointID, TouchUtil.gameX(touch), TouchUtil.gameY(touch), getEdge(TouchUtil.gameX(touch), TouchUtil.gameY(touch)), frame);
		points.set(point.id, point);
		onTouchStart.dispatch(point);
		return point;
	}

	function track(point:TouchPoint):Void
	{
		final threshold:Float = Math.min(FlxG.width, FlxG.height) * swipeDistance;
		final dx:Float = point.x - point.anchorX;
		final dy:Float = point.y - point.anchorY;

		if (Math.abs(dx) >= threshold || Math.abs(dy) >= threshold)
		{
			final direction:SwipeDirection = Math.abs(dx) > Math.abs(dy) ? (dx < 0 ? SwipeDirection.LEFT : SwipeDirection.RIGHT) : (dy < 0 ? SwipeDirection.UP : SwipeDirection.DOWN);

			if (!point.swiped)
				point.vertical = direction == SwipeDirection.UP || direction == SwipeDirection.DOWN;

			point.swipeCount++;
			point.anchorX = point.x;
			point.anchorY = point.y;

			if (point.startEdge == TouchEdge.NONE)
			{
				swipeDirection = direction;
				swipeFrame = frame;
			}

			onSwipe.dispatch(point, direction);
		}
		else if (!point.swiped && !point.longPressed && point.duration >= longPressTime && point.travel <= tapPixels())
		{
			point.longPressed = true;
			longPressPoint = point;
			longPressFrame = frame;
			onLongPress.dispatch(point);
		}
	}

	function finish(point:TouchPoint, cancelled:Bool):Void
	{
		points.remove(point.id);

		if (!cancelled && !point.swiped && !point.longPressed && point.duration <= tapTime && point.travel <= tapPixels())
		{
			final now:Float = Timer.stamp();
			final dx:Float = point.x - lastTapX;
			final dy:Float = point.y - lastTapY;
			final isDouble:Bool = lastTapStamp >= 0 && now - lastTapStamp <= doubleTapTime && Math.sqrt(dx * dx + dy * dy) <= tapPixels() * 2;

			tapPoint = point;
			tapFrame = frame;
			onTap.dispatch(point);

			if (isDouble)
			{
				lastTapStamp = -1;
				onDoubleTap.dispatch(point);
			}
			else
			{
				lastTapStamp = now;
				lastTapX = point.x;
				lastTapY = point.y;
			}
		}

		onTouchEnd.dispatch(point);
	}

	inline function tapPixels():Float
		return Math.min(FlxG.width, FlxG.height) * tapDistance;

	function getEdge(x:Float, y:Float):TouchEdge
	{
		final left:Float = x / FlxG.width;
		final right:Float = 1 - left;
		final top:Float = y / FlxG.height;
		final bottom:Float = 1 - top;
		final nearest:Float = Math.min(Math.min(left, right), Math.min(top, bottom));

		if (nearest > edgeSize)
			return TouchEdge.NONE;

		if (nearest == left)
			return TouchEdge.LEFT;

		if (nearest == top)
			return TouchEdge.TOP;

		if (nearest == right)
			return TouchEdge.RIGHT;

		return TouchEdge.BOTTOM;
	}
}
#end
