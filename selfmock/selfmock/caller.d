module selfmock.caller;

import selfmock.call;
import selfmock.repository;
import selfmock.mockobject;
import selfmock.util;
import selfmock.action;
import selfmock.arguments;

version (MocksDebug)
	import tango.io.Stdout;


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
			Stdout.formatln("checking _owner.Recording...");
		if (_owner.recording)
		{
			_owner.record!(U)(mocked, name, args, !is (TReturn == void));
			return rope;
		}

		version (MocksDebug)
			Stdout.formatln("checking for matching call...");
		ICall call = _owner.match!(U)(mocked, name, args);

		version (MocksDebug)
			Stdout.formatln("checking if call is null...");
		if (call is null)
		{
			ICall thecall = new Call(mocked, name, new Arguments!(U)(args));
			thecall.repeat = Interval(0, 0);
			thecall.called();
			char[] msg = thecall.toString();
			throw new ExpectationViolationException(msg);
		}

		rope = call.action.getActor().act!(TReturn, U)(args);
		version (MocksDebug)
			Stdout.formatln("returning...");
		return rope;
	}
}
