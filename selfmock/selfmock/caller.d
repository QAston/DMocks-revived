module selfmock.caller;

import selfmock.call;
import selfmock.repository;
import selfmock.mockobject;
import selfmock.util;
import selfmock.action;

version (MocksDebug)
	import std.stdio;


class Caller
{
	private MockRepository _owner;

	public this (MockRepository owner)
	{
		_owner = owner;
	}

	public ReturnOrPass!(TReturn) call (TReturn, U...) (Mocked mocked,
			char[] name, U args)
	{
		ReturnOrPass!(TReturn) rope;
		version (MocksDebug)
			writefln("checking _owner.Recording...");
		if (_owner.recording)
		{
			_owner.record!(U)(mocked, name, args, !is (TReturn == void));
			return rope;
		}

		version (MocksDebug)
			writefln("checking for matching call...");
		ICall call = _owner.match!(U)(mocked, name, args);

		version (MocksDebug)
			writefln("checking if call is null...");
		if (call is null)
		{
			throw new ExpectationViolationException();
		}

		rope = call.action.getActor().act!(TReturn, U)(args);
		version (MocksDebug)
			writefln("returning...");
		return rope;
	}
}
