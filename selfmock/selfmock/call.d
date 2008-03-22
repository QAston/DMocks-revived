module selfmock.call;

import tango.core.Variant;
import selfmock.mockobject;
import selfmock.util;
import selfmock.arguments;
import selfmock.action;

version (MocksDebug)
	import tango.io.Stdout;

version (MocksTest)
	import tango.io.Stdout;

/++
 An abstract representation of a method call.
 ++/
public interface ICall
{
	// TODO: separate this into Match, Action, and Ordering.
	// Ordering doesn't need any template stuff.
	int opEquals (Object other);

	char[] toString ();

	void ignoreArguments (bool value);

	void repeat (Interval value);

	Interval repeat ();

	void called ();

	bool isVoid ();

	void isVoid (bool value);

	bool hasAction ();

	bool satisfied ();

	IAction action ();

	ICall lastCall ();

	void lastCall (ICall call);

	ICall nextCall ();

	void nextCall (ICall call);

	void ordered (bool value);

	bool ordered ();
}

public class Call : ICall
{
	private
	{
		IAction _action;
		bool _ignoreArguments;
		bool _void;
		bool _ordered;
		IArguments _arguments;
		Mocked _mocked;
		char[] _name = "unknown";
		Interval _repeat;
		int _callCount;
		ICall _lastCall = null;
		ICall _nextCall = null;
	}

	bool hasAction ()
	{
		return _void || _action.hasAction;
	}

	IAction action ()
	{
		return _action;
	}

	override char[] toString ()
	{
		version (MocksDebug)
			Stdout.formatln("trying get arg char[]");
		char[]
				args = (_arguments is null) ? "(<unknown>)" : _arguments.toString;
		version (MocksDebug)
			Stdout.formatln("trying get callcount char[]");
		char[] callCount = selfmock.util.toString(_callCount);
		version (MocksDebug)
			Stdout.formatln("trying get repeat char[]");
		char[] expected = _repeat.toString;
		version (MocksDebug)
			Stdout.formatln("putting it together");
		char[]
				ret = _name ~ args ~ " Expected: " ~ expected ~ " Actual: " ~ callCount;
		version (MocksDebug)
			Stdout.formatln("returning");
		return ret;
	}

	bool satisfied ()
	{
		return _callCount <= _repeat.max && _callCount >= _repeat.min;
	}

	void repeat (Interval value)
	{
		if (value.valid && value.max >= 0)
		{
			_repeat = value;
		}
		else
		{
			throw new InvalidOperationException(
					"Repeat interval must be a valid interval allowing a nonnegative number of repetitions.");
		}
	}

	Interval repeat ()
	{
		return _repeat;
	}

	override int opEquals (Object other)
	{
		auto call = cast(typeof(this)) other;
		if (call is null)
		{
			version (MocksDebug)
				Stdout.formatln("Call.opEquals: wrong type");
			return false;
		}

		if (call._mocked !is _mocked)
		{
			version (MocksDebug)
				Stdout.formatln("Call.opEquals: wrong mock");
			return false;
		}

		if (call._name != _name)
		{
			version (MocksDebug)
				Stdout.formatln(
						"Call.opEquals: wrong method; expected %s; was %s",
						_name, call._name);
			return false;
		}

		if ((!_ignoreArguments) && (_arguments != call._arguments))
		{
			version (MocksDebug)
				Stdout.formatln("Call.opEquals: wrong arguments");
			return false;
		}
		return true;
	}

	void ignoreArguments (bool value)
	{
		_ignoreArguments = value;
	}

	bool ignoreArguments ()
	{
		return _ignoreArguments;
	}

	void isVoid (bool value)
	{
		_void = value;
	}

	bool isVoid ()
	{
		return _void;
	}

	void called ()
	{
		version (MocksDebug)
			Stdout.formatln("call called");
		_callCount++;
		version (MocksDebug)
			Stdout.formatln("checking against repeat");
		if (_callCount > _repeat.max)
		{
			version (MocksDebug)
				Stdout.formatln("repeat violated");
			throw new ExpectationViolationException(toString);
		}
		version (MocksDebug)
			Stdout.formatln("repeat verified");
	}

	ICall lastCall ()
	{
		return _lastCall;
	}

	void lastCall (ICall call)
	{
		version (MocksDebug)
			Stdout.formatln("SETTING LASTCALL: ", selfmock.util.toString(call));
		_lastCall = call;
	}

	ICall nextCall ()
	{
		return _nextCall;
	}

	void nextCall (ICall call)
	{
		version (MocksDebug)
			Stdout.formatln("SETTING NEXTCALL: ", selfmock.util.toString(call));
		_nextCall = call;
	}

	void ordered (bool value)
	{
		_ordered = value;
	}

	bool ordered ()
	{
		return _ordered;
	}

	this (Mocked mocked, char[] name, IArguments arguments)
	{
		_mocked = mocked;
		_name = name;
		_arguments = arguments;
		_repeat = Interval(1, 1);
		// dmd apparently complains if you have a module, property, and type
		// all with the same name.
		_action = new selfmock.action.Action();
	}
}


version (MocksTest)
{
	unittest {
		// Matching.
		Stdout("Call.opEquals unit test...");
		scope (failure)
			Stdout("failed").newline;
		scope (success)
			Stdout("success").newline;
		auto o = new Mocked();
		auto name = "Thwackum";
		auto args = new Arguments!(int)(5);
		auto args2 = new Arguments!(int)(1111);
		auto a = new Call(o, name, args);
		auto b = new Call(o, name, args);
		auto c = new Call(o, name, args2);
		auto d = new Call(o, name, new Arguments!()());
		assert (a == b);
		assert (a != c);
		assert (d != c);
	}

	unittest {
		Stdout("Call.HasAction test...");
		scope (failure)
			Stdout.formatln("failed");
		scope (success)
			Stdout.formatln("success");

		auto o = new Mocked();
		auto name = "Thwackum";
		auto args = new Arguments!(int)(5);
		auto b = new Call(o, name, args);
	}

	unittest {
		// Ignore arguments.
		Stdout("ignore arguments unit test...");
		scope (failure)
			Stdout.formatln("failed");
		scope (success)
			Stdout.formatln("success");
		auto o = new Mocked();
		auto name = "Thwackum";
		auto args = new Arguments!(int)(5);
		auto args2 = new Arguments!(int)(1111);
		auto a = new Call(o, name, args);
		auto b = new Call(o, name, args2);
		a.ignoreArguments = true;
		assert (a == b);
		assert (b != a);
	}

	unittest {
		Stdout("set repeat interval unit test...");
		scope (failure)
			Stdout.formatln("failed");
		scope (success)
			Stdout.formatln("success");
		auto o = new Mocked();
		auto name = "Thwackum";
		auto args = new Arguments!(int)(5);
		auto args2 = new Arguments!(int)(1111);
		auto a = new Call(o, name, args);
		//auto b = new Call(o, name, args2);
		a.repeat(Interval(0, 1));
		assert (a._repeat.min == 0);
		assert (a._repeat.max == 1);
	}

	unittest {
		Stdout("set repeat interval to invalid values unit test...");
		scope (failure)
			Stdout.formatln("failed");
		scope (success)
			Stdout.formatln("success");
		auto a = new Call(new Mocked(), "frumious", new Arguments!(int)(5));
		//auto b = new Call(o, name, args2);
		try
		{
			a.repeat(Interval(5, 1));
			assert (false, "invalid interval not caught");
		}
		catch
		{
		}
		try
		{
			a.repeat(Interval(-10, -1));
			assert (false, "invalid interval not caught");
		}
		catch
		{
		}
	}

	unittest {
		Stdout("complain about too many calls unit test...");
		scope (failure)
			Stdout.formatln("failed");
		scope (success)
			Stdout.formatln("success");
		auto a = new Call(new Mocked(), "frumious", new Arguments!(int)(5));
		a.repeat(Interval(0, 1));
		a.called();
		try
		{
			a.called();
			assert (false, "exception not thrown");
		}
		catch (ExpectationViolationException e)
		{
		}
	}

	unittest {
		Stdout("satisfied unit test...");
		scope (failure)
			Stdout.formatln("failed");
		scope (success)
			Stdout.formatln("success");
		auto a = new Call(new Mocked(), "frumious", new Arguments!(int)(5));
		a.repeat(Interval(2, 3));
		a.called();
		assert (!a.satisfied());
		a.called();
		assert (a.satisfied());
		a.called();
		assert (a.satisfied());
		try
		{
			a.called();
			assert (false, "exception not thrown");
		}
		catch (ExpectationViolationException e)
		{
		}
	}

	unittest {
		Stdout("default interval unit test...");
		scope (failure)
			Stdout.formatln("failed");
		scope (success)
			Stdout.formatln("success");
		auto a = new Call(new Mocked(), "frumious", new Arguments!(int)(5));
		assert (a._repeat.min == 1);
		assert (a._repeat.max == 1);
	}

	unittest {
		Stdout("Call.toString test...");
		scope (failure)
			Stdout.formatln("failed");
		scope (success)
			Stdout.formatln("success");
		auto a = new Call(new Mocked(), "frumious", new Arguments!(int)(5));
		a.repeat(Interval(2, 3));
		a.toString();
	}

	unittest {
		Stdout("Call.toString no arguments test...");
		scope (failure)
			Stdout.formatln("failed");
		scope (success)
			Stdout.formatln("success");
		auto a = new Call(new Mocked(), "frumious", new Arguments!());
		a.repeat(Interval(2, 3));
		a.toString();
	}
}
