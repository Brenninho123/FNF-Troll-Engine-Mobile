package funkin.mobile.backend;

#if mobile
import haxe.io.Path;
import lime.system.System;
import sys.FileSystem;
import sys.io.File;
#if android
import extension.androidtools.Permissions;
import extension.androidtools.Settings;
import extension.androidtools.content.Context;
import extension.androidtools.os.Build;
import extension.androidtools.os.Environment;
#end

class StorageUtil
{
	public static inline final SHARED_FOLDER:String = '.TrollEngine';

	public static var directory(default, null):String = null;

	public static function init():Void
	{
		#if android
		requestAccess();
		#end

		var path:String = resolveDirectory();

		try
		{
			createDirectory(path);
			Sys.setCwd(path);
		}
		catch (e:Dynamic)
		{
			path = Path.addTrailingSlash(Path.normalize(System.applicationStorageDirectory));
			createDirectory(path);
			Sys.setCwd(path);
		}

		directory = path;
	}

	public static function resolveDirectory():String
	{
		var path:String = null;

		#if android
		path = getSharedDirectory();

		if (path == null || path.length == 0)
			path = Context.getExternalFilesDir(null);

		if (path == null || path.length == 0)
			path = Context.getFilesDir();
		#elseif ios
		path = System.documentsDirectory;
		#end

		if (path == null || path.length == 0)
			path = System.applicationStorageDirectory;

		return Path.addTrailingSlash(Path.normalize(path));
	}

	public static function createDirectory(path:String):Void
	{
		path = Path.removeTrailingSlashes(Path.normalize(path));

		if (path.length == 0 || FileSystem.exists(path))
			return;

		createDirectory(Path.directory(path));
		FileSystem.createDirectory(path);
	}

	public static function getPath(relativePath:String):String
	{
		return Path.normalize((directory != null ? directory : resolveDirectory()) + relativePath);
	}

	#if android
	public static function getSharedDirectory():Null<String>
	{
		final root:String = Environment.getExternalStorageDirectory();

		if (root == null || root.length == 0)
			return null;

		final path:String = Path.addTrailingSlash(root) + SHARED_FOLDER;

		try
		{
			createDirectory(path);

			final probe:String = Path.addTrailingSlash(path) + '.probe';
			File.saveContent(probe, '');
			FileSystem.deleteFile(probe);
		}
		catch (e:Dynamic)
		{
			return null;
		}

		return path;
	}

	public static function requestAccess():Void
	{
		if (getSharedDirectory() != null)
			return;

		final marker:String = Path.addTrailingSlash(System.applicationStorageDirectory) + '.storage_requested';

		try
		{
			createDirectory(System.applicationStorageDirectory);

			if (FileSystem.exists(marker))
				return;

			File.saveContent(marker, '');
		}
		catch (e:Dynamic)
		{
			return;
		}

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R)
			Settings.requestSetting('MANAGE_APP_ALL_FILES_ACCESS_PERMISSION');
		else
			Permissions.requestPermissions(['READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE']);
	}
	#end
}
#end
