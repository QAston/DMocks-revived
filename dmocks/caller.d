module dmocks.caller;

import dmocks.call;
import dmocks.repository;
import dmocks.model;
import dmocks.util;
import dmocks.Action;

version (DMocksDebug)
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
		version (DMocksDebug)
			writefln("checking _owner.Recording...");
		if (_owner.Recording)
		{
			_owner.Record!(U)(mocked, name, args, !is (TReturn == void));
			return rope;
		}

		version (DMocksDebug)
			writefln("checking for matching call...");
		ICall call = _owner.Match!(U)(mocked, name, args);

		version (DMocksDebug)
			writefln("checking if call is null...");
		if (call is null)
		{
			throw new ExpectationViolationException();
		}

		rope = call.Action.getActor().act!(TReturn, U)(args);
		version (DMocksDebug)
			writefln("returning...");
		return rope;
	}
}
