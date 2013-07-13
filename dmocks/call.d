module dmocks.call;

import std.variant;
import std.conv;
import dmocks.util;
import dmocks.model;
import dmocks.arguments;
import dmocks.action;

/++
 An abstract representation of a method call.
 ++/
public interface ICall
{
    // TODO: separate this into Match, Action, and Ordering.
    // Ordering doesn't need any template stuff.
    bool opEquals (Object other);

    string toString ();

    void IgnoreArguments (bool value);

    void Repeat (Interval value);

    Interval Repeat ();

    void Called ();

    bool Void ();

    void Void (bool value);

    bool HasAction ();

    bool Satisfied ();

    IAction Action ();

    ICall LastCall ();

    void LastCall (ICall call);

    ICall NextCall ();

    void NextCall (ICall call);

    void Ordered (bool value);

    bool Ordered ();
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
    IMocked _mocked;
    string _name = "unknown";
    Interval _repeat;
    int _callCount;
    ICall _lastCall = null;
    ICall _nextCall = null;
}

    bool HasAction ()
    {
        return _void || _action.hasAction;
    }

    IAction Action ()
    {
        return _action;
    }

    override string toString ()
    {
        debugLog("Call.toString");
        string args = (_arguments is null) ? "(<unknown>)" : _arguments.to!string;
        debugLog("got args: %s", args);
        string callCount = _callCount.to!string;
        debugLog("got callcount: %s", callCount);
        string expected = _repeat.to!string;
        debugLog("got expected: %s", expected);
        string ret = _name ~ args ~ " Expected: " ~ expected ~ " Actual: " ~ callCount;
        debugLog("returning: %s", ret);
        return ret;
    }

    bool Satisfied ()
    {
        return _callCount <= _repeat.Max && _callCount >= _repeat.Min;
    }

    void Repeat (Interval value)
    {
        if (value.Valid() && value.Max >= 0)
        {
            _repeat = value;
        }
        else
        {
            throw new InvalidOperationException(
                    "Repeat interval must be a valid interval allowing a nonnegative number of repetitions.");
        }
    }

    Interval Repeat ()
    {
        return _repeat;
    }

    override bool opEquals (Object other)
    {
        auto call = cast(typeof(this)) other;
        if (call is null)
        {
            debugLog("Call.opEquals: wrong type");
            return false;
        }

        if (call._mocked !is _mocked)
        {
            debugLog("Call.opEquals: wrong mock");
            return false;
        }

        if (call._name != _name)
        {
            debugLog("Call.opEquals: wrong method; expected %s; was %s", _name, call._name);
            return false;
        }

        if ((!_ignoreArguments) && (_arguments != call._arguments))
        {
            debugLog("Call.opEquals: wrong arguments");
            return false;
        }
        return true;
    }

    void IgnoreArguments (bool value)
    {
        _ignoreArguments = value;
    }

    bool IgnoreArguments ()
    {
        return _ignoreArguments;
    }

    void Void (bool value)
    {
        _void = value;
    }

    bool Void ()
    {
        return _void;
    }

    void Called ()
    {
        debugLog("call called");
        _callCount++;
        debugLog("checking against repeat");
        if (_callCount > _repeat.Max)
        {
            debugLog("repeat violated");
            throw new ExpectationViolationException(toString);
        }
        debugLog("repeat verified");
    }

    ICall LastCall ()
    {
        return _lastCall;
    }

    void LastCall (ICall call)
    {
        debugLog("SETTING LASTCALL: ", call);
        _lastCall = call;
    }

    ICall NextCall ()
    {
        return _nextCall;
    }

    void NextCall (ICall call)
    {
        debugLog("SETTING NEXTCALL: ", call);
        _nextCall = call;
    }

    void Ordered (bool value)
    {
        _ordered = value;
    }

    bool Ordered ()
    {
        return _ordered;
    }

    this (IMocked mocked, string name, IArguments arguments)
    {
        _mocked = mocked;
        _name = name;
        _arguments = arguments;
        _repeat = Interval(1, 1);
        // dmd apparently complains if you have a module, property, and type
        // all with the same name.
        _action = new dmocks.action.Action();
    }
}


version (DMocksTest)
{
    unittest {
        // Matching.
        mixin(test!("Call.opEquals"));
        auto o = new FakeMocked();
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
        mixin(test!("Call.HasAction"));

        auto o = new FakeMocked();
        auto name = "Thwackum";
        auto args = new Arguments!(int)(5);
        auto b = new Call(o, name, args);
    }

    unittest {
        // Ignore arguments.
        mixin(test!("ignore arguments"));
        auto o = new FakeMocked();
        auto name = "Thwackum";
        auto args = new Arguments!(int)(5);
        auto args2 = new Arguments!(int)(1111);
        auto a = new Call(o, name, args);
        auto b = new Call(o, name, args2);
        a.IgnoreArguments = true;
        assert (a == b);
        assert (b != a);
    }

    unittest {
        mixin(test!("set repeat interval"));
        auto o = new FakeMocked();
        auto name = "Thwackum";
        auto args = new Arguments!(int)(5);
        auto args2 = new Arguments!(int)(1111);
        auto a = new Call(o, name, args);
        //auto b = new Call(o, name, args2);
        a.Repeat(Interval(0, 1));
        assert (a._repeat.Min == 0);
        assert (a._repeat.Max == 1);
    }

    unittest {
        mixin(test!("set repeat interval to invalid values"));
        auto a = new Call(new FakeMocked(), "frumious", new Arguments!(int)(5));
        //auto b = new Call(o, name, args2);
        try
        {
            a.Repeat(Interval(5, 1));
            assert (false, "invalid interval not caught");
        }
        catch
        {
        }
        try
        {
            a.Repeat(Interval(-10, -1));
            assert (false, "invalid interval not caught");
        }
        catch
        {
        }
    }

    unittest {
        mixin(test!("complain about too many calls"));
        auto a = new Call(new FakeMocked(), "frumious", new Arguments!(int)(5));
        a.Repeat(Interval(0, 1));
        a.Called();
        try
        {
            a.Called();
            assert (false, "exception not thrown");
        }
        catch (ExpectationViolationException e)
        {
        }
    }

    unittest {
        mixin(test!("satisfied"));
        auto a = new Call(new FakeMocked(), "frumious", new Arguments!(int)(5));
        a.Repeat(Interval(2, 3));
        a.Called();
        assert (!a.Satisfied());
        a.Called();
        assert (a.Satisfied());
        a.Called();
        assert (a.Satisfied());
        try
        {
            a.Called();
            assert (false, "exception not thrown");
        }
        catch (ExpectationViolationException e)
        {
        }
    }

    unittest {
        mixin(test!("default interval"));
        auto a = new Call(new FakeMocked(), "frumious", new Arguments!(int)(5));
        assert (a._repeat.Min == 1);
        assert (a._repeat.Max == 1);
    }

    unittest {
        mixin(test!("Call.toString"));
        auto a = new Call(new FakeMocked(), "frumious", new Arguments!(int)(5));
        a.Repeat(Interval(2, 3));
        a.toString();
    }

    unittest {
        mixin(test!("Call.toString no arguments"));

        auto a = new Call(new FakeMocked(), "frumious", new Arguments!());
        a.Repeat(Interval(2, 3));
        a.toString();
    }
}
