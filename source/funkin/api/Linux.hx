package funkin.api;

#if (linux && cpp)
import cpp.Int16;
@:build(funkin.macros.Sowy.addApiBuildXml())
@:include("refreshrate.hpp")
extern class Linux {
    @:native("getMonitorRefreshRate")
	static function getMonitorRefreshRate():Int16;
}
#end