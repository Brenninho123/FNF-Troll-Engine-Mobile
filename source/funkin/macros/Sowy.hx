package funkin.macros;

import haxe.macro.Expr.Field;

// what DOES sowy mean
class Sowy
{
	/**
		Returns the build date as a String
	**/
	public static macro function getBuildDate()
	{
		return macro $v{Date.now().toString()};
	}

	/**
	 * Returns a map of all conditional compilation flags that were set.
	 */
	public static macro function getDefines() 
	{
		return macro $v{haxe.macro.Context.getDefines()};
	}

	/**
		Returns the contents of a file at compile time
	**/
	public static macro function readFile(path:String, throwException:Bool = true) {
		if (!sys.FileSystem.exists(path)) {
			if (throwException)
				haxe.macro.Context.error('File "$path" does not exist', haxe.macro.Context.currentPos());
			return macro $v{null};
		}
		return macro $v{sys.io.File.getContent(path)};
	}

	#if macro
	/**
		Build macro that includes `funkin/api/build.xml` in the hxcpp build using an absolute path,
		since a relative path breaks when the build directory is nested differently (e.g. iOS)
	**/
	public static function addApiBuildXml():Null<Array<Field>> {
		var path:String = haxe.macro.Context.resolvePath("funkin/api/build.xml");
		path = StringTools.replace(sys.FileSystem.fullPath(path), "\\", "/");

		var cls = haxe.macro.Context.getLocalClass().get();
		cls.meta.add(":buildXml", [macro $v{'<include name="$path" />'}], cls.pos);
		return null;
	}
	#end

	public static function findByName(fields:Array<Field>, name:String):Null<Field>{
		for (field in fields){
			if (field.name == name)
				return field;
		}
		return null;
	}
}