module dmocks.Caller;

import dmocks.Call;
import dmocks.Repository;
import dmocks.Model;
import dmocks.Util;
import dmocks.Action;

version (MocksDebug)
	import std.stdio;


class Caller
{
	private MockRepository _owner;

	public this (MockRepository owner)
	{
		_owner = owner;
	}

	public ReturnOrPass!(TReturn) Call (TReturn, U...) (IMocked mocked,
			string name, U args)
	{
		ReturnOrPass!(TReturn) rope;
		version (MocksDebug)
			writefln("checking _owner.Recording...");
		if (_owner.Recording)
		{
			_owner.Record!(U)(mocked, name, args, !is (TReturn == void));
			return rope;
		}

		version (MocksDebug)
			writefln("checking for matching call...");
		ICall call = _owner.Match!(U)(mocked, name, args);

		version (MocksDebug)
			writefln("checking if call is null...");
		if (call is null)
		{
			throw new ExpectationViolationException();
		}

		rope = call.Action.getActor().act!(TReturn, U)(args);
		version (MocksDebug)
			writefln("returning...");
		return rope;
	}
}
