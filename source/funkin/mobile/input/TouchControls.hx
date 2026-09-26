package funkin.mobile.input;

#if mobile
import flixel.input.FlxInput.FlxInputState;

private class ActionState
{
	public var pressed:Bool = false;
	public var justPressed:Bool = false;
	public var justReleased:Bool = false;

	public function new() {}
}

class TouchControls
{
	public static inline final EDGE_RIGHT:String = "touch_edge_right";
	public static inline final EDGE_BOTTOM:String = "touch_edge_bottom";

	public static var enabled:Bool = true;
	public static var naturalScrolling:Bool = true;

	static final actions:Map<String, ActionState> = [];
	static var claimFrame:Int = -10;

	public static function claimTaps():Void
	{
		final gestures:Null<TouchGestures> = TouchGestures.instance;

		if (gestures != null)
			claimFrame = gestures.frame;
	}

	public static function init(gestures:TouchGestures):Void
	{
		gestures.onTap.add(onTap);
		gestures.onSwipe.add(onSwipe);
	}

	public static function beginFrame():Void
	{
		for (state in actions)
		{
			state.justReleased = false;

			if (state.pressed)
			{
				state.pressed = false;
				state.justPressed = false;
				state.justReleased = true;
			}
		}
	}

	public static function pulse(id:String):Void
	{
		var state:Null<ActionState> = actions.get(id);

		if (state == null)
		{
			state = new ActionState();
			actions.set(id, state);
		}

		state.pressed = true;
		state.justPressed = true;
		state.justReleased = false;
	}

	public static inline function justPressed(id:String):Bool
		return check(id, FlxInputState.JUST_PRESSED);

	public static function check(id:String, state:FlxInputState):Bool
	{
		if (!enabled)
			return false;

		final action:Null<ActionState> = actions.get(id);

		if (action == null)
			return state == FlxInputState.RELEASED;

		return switch (state)
		{
			case FlxInputState.PRESSED: action.pressed;
			case FlxInputState.JUST_PRESSED: action.justPressed;
			case FlxInputState.RELEASED: !action.pressed;
			case FlxInputState.JUST_RELEASED: action.justReleased;
		}
	}

	static function onTap(point:TouchPoint):Void
	{
		final gestures:Null<TouchGestures> = TouchGestures.instance;

		if (point.startEdge == TouchEdge.NONE && (gestures == null || gestures.frame - claimFrame > 1))
			pulse("accept");
	}

	static function onSwipe(point:TouchPoint, direction:SwipeDirection):Void
	{
		if (point.startEdge != TouchEdge.NONE)
		{
			if (point.swipeCount != 1)
				return;

			if (point.startEdge == TouchEdge.LEFT && direction == SwipeDirection.RIGHT)
				pulse("back");
			else if (point.startEdge == TouchEdge.TOP && direction == SwipeDirection.DOWN)
				pulse("pause");
			else if (point.startEdge == TouchEdge.RIGHT && direction == SwipeDirection.LEFT)
				pulse(EDGE_RIGHT);
			else if (point.startEdge == TouchEdge.BOTTOM && direction == SwipeDirection.UP)
				pulse(EDGE_BOTTOM);

			return;
		}

		switch (direction)
		{
			case SwipeDirection.UP:
				pulse(naturalScrolling ? "ui_down" : "ui_up");
			case SwipeDirection.DOWN:
				pulse(naturalScrolling ? "ui_up" : "ui_down");
			case SwipeDirection.LEFT:
				pulse(naturalScrolling ? "ui_right" : "ui_left");
			case SwipeDirection.RIGHT:
				pulse(naturalScrolling ? "ui_left" : "ui_right");
			case SwipeDirection.NONE:
		}
	}
}
#end
