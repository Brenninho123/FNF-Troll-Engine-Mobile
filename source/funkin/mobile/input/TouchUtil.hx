package funkin.mobile.input;

#if mobile
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;

class TouchUtil
{
	public static var dragX(get, never):Float;
	public static var dragY(get, never):Float;

	public static inline function gameX(touch:FlxTouch):Int
	{
		#if (flixel >= "5.9.0")
		return touch.gameX;
		#else
		@:privateAccess
		return touch._globalScreenX;
		#end
	}

	public static inline function gameY(touch:FlxTouch):Int
	{
		#if (flixel >= "5.9.0")
		return touch.gameY;
		#else
		@:privateAccess
		return touch._globalScreenY;
		#end
	}

	public static function anyJustPressed():Bool
	{
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
				return true;
		}

		return false;
	}

	public static function anyPressed():Bool
	{
		for (touch in FlxG.touches.list)
		{
			if (touch.pressed)
				return true;
		}

		return false;
	}

	public static function anyJustReleased():Bool
	{
		for (touch in FlxG.touches.list)
		{
			if (touch.justReleased)
				return true;
		}

		return false;
	}

	public static inline function justPressedOn(object:FlxObject, ?camera:FlxCamera):Bool
		return overlaps(object, camera, 0);

	public static inline function pressedOn(object:FlxObject, ?camera:FlxCamera):Bool
		return overlaps(object, camera, 1);

	public static inline function justReleasedOn(object:FlxObject, ?camera:FlxCamera):Bool
		return overlaps(object, camera, 2);

	public static function tappedTouch():Null<FlxTouch>
	{
		final tap:Null<TouchPoint> = TouchGestures.instance?.getTap();
		return tap == null ? null : FlxG.touches.getByID(tap.id);
	}

	public static function tappedOn(object:FlxObject, ?camera:FlxCamera):Bool
	{
		final touch:Null<FlxTouch> = tappedTouch();
		return touch != null && touch.overlaps(object, camera);
	}

	public static inline function swipedDirection():SwipeDirection
		return TouchGestures.instance?.getSwipe() ?? SwipeDirection.NONE;

	public static function longPressedTouch():Null<FlxTouch>
	{
		final press:Null<TouchPoint> = TouchGestures.instance?.getLongPress();
		return press == null ? null : FlxG.touches.getByID(press.id);
	}

	public static inline function tappedItem<T:FlxSprite>(items:Iterable<T>, ?camera:FlxCamera, fullWidth:Bool = false):Null<T>
		return itemAt(tappedTouch(), items, camera, fullWidth);

	public static inline function longPressedItem<T:FlxSprite>(items:Iterable<T>, ?camera:FlxCamera, fullWidth:Bool = false):Null<T>
		return itemAt(longPressedTouch(), items, camera, fullWidth);

	static function itemAt<T:FlxSprite>(touch:Null<FlxTouch>, items:Iterable<T>, ?camera:FlxCamera, fullWidth:Bool = false):Null<T>
	{
		if (touch == null)
			return null;

		final position:FlxPoint = FlxPoint.get();
		final bounds:FlxRect = FlxRect.get();
		var closest:Null<T> = null;
		var closestDistance:Float = Math.POSITIVE_INFINITY;

		for (item in items)
		{
			if (item == null || !item.exists || !item.visible)
				continue;

			final itemCamera:FlxCamera = camera ?? item.camera;

			touch.getPositionInCameraView(itemCamera, position);
			item.getScreenBounds(bounds, itemCamera);

			if (fullWidth)
			{
				bounds.x -= 10000;
				bounds.width += 20000;
			}

			if (!bounds.containsPoint(position))
				continue;

			final dx:Float = position.x - (bounds.x + bounds.width * 0.5);
			final dy:Float = position.y - (bounds.y + bounds.height * 0.5);
			final distance:Float = dx * dx + dy * dy;

			if (distance < closestDistance)
			{
				closest = item;
				closestDistance = distance;
			}
		}

		position.put();
		bounds.put();
		return closest;
	}

	static function overlaps(object:FlxObject, ?camera:FlxCamera, mode:Int):Bool
	{
		for (touch in FlxG.touches.list)
		{
			final matches:Bool = switch (mode)
			{
				case 0: touch.justPressed;
				case 1: touch.pressed;
				default: touch.justReleased;
			}

			if (matches && touch.overlaps(object, camera))
				return true;
		}

		return false;
	}

	static inline function get_dragX():Float
		return TouchGestures.instance?.dragX ?? 0;

	static inline function get_dragY():Float
		return TouchGestures.instance?.dragY ?? 0;
}
#end
