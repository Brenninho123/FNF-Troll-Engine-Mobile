package funkin.mobile.input;

#if mobile
import haxe.Timer;

class TouchPoint
{
	public final id:Int;
	public final startX:Float;
	public final startY:Float;
	public final startEdge:TouchEdge;
	public final startStamp:Float;

	public var x:Float;
	public var y:Float;
	public var anchorX:Float;
	public var anchorY:Float;
	public var deltaX:Float = 0;
	public var deltaY:Float = 0;
	public var duration:Float = 0;
	public var travel:Float = 0;
	public var swipeCount:Int = 0;
	public var vertical:Bool = false;
	public var longPressed:Bool = false;
	public var lastFrame:Int = 0;

	public var swiped(get, never):Bool;

	public function new(id:Int, x:Float, y:Float, edge:TouchEdge, frame:Int)
	{
		this.id = id;
		this.startX = this.x = this.anchorX = x;
		this.startY = this.y = this.anchorY = y;
		this.startEdge = edge;
		this.startStamp = Timer.stamp();
		this.lastFrame = frame;
	}

	public function move(x:Float, y:Float, frame:Int):Void
	{
		this.deltaX = x - this.x;
		this.deltaY = y - this.y;
		this.x = x;
		this.y = y;
		this.lastFrame = frame;
		this.duration = Timer.stamp() - startStamp;

		final dx:Float = x - startX;
		final dy:Float = y - startY;
		final distance:Float = Math.sqrt(dx * dx + dy * dy);

		if (distance > travel)
			travel = distance;
	}

	inline function get_swiped():Bool
		return swipeCount > 0;
}
#end
