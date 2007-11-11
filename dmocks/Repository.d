module dmocks.Repository;

import dmocks.Util;
import dmocks.Model;
import std.variant;
import std.stdio;

version(MocksDebug) version = OrderDebug;

public class MockRepository {
    private ICall[] _calls = [];
    private bool _recording = true;
    private bool _ordered = false;
    private ICall _lastCall;
    private ICall _lastOrdered;

    private void CheckOrder(ICall current, ICall previous) {
        version(OrderDebug) writefln("CheckOrder: init");
        version(OrderDebug) writefln("CheckOrder: current: %s", dmocks.Util.toString(current));
        if (current !is null)
            version(OrderDebug) writefln("CheckOrder: current.Last: %s", dmocks.Util.toString(current.LastCall));
        version(OrderDebug) writefln("CheckOrder: previous: %s", dmocks.Util.toString(previous));
        if (current !is null)
            version(OrderDebug) writefln("CheckOrder: previous.Next: %s", dmocks.Util.toString(current.NextCall));
        if (current is null || (current.LastCall is null && previous !is null && previous.NextCall is null)) {
            version(OrderDebug) writefln("CheckOrder: nothing to do, returning");
            return; // nothing to do
        }

        /* The user set up:
           m.Expect(foo.bar(5)).Repeat(3, 4).Return(blah);
           m.Expect(foo.bar(3)).Repeat(2).Return(blah);
           So I need to track the last two calls.

           Or:
           m.Expect(baz.foobar)...
           m.Expect(foo.bar(5)).Repeat(0, 2).Return(blah);
           m.Expect(foo.bar(3)).Repeat(2).Return(blah);
           Then, I basically have a linked list to traverse. And it must be
           both ways.
         */
        auto last = previous;
        while (last !is null && last.NextCall !is null) {
            version(OrderDebug) writefln("CheckOrder: checking forward");
            if (last.NextCall == cast(Object)current) {
                break;
            }
            if (last.Repeat().Min > 0) {
                // We expected this to be called between _lastCall and icall.
                version(OrderDebug) writefln("CheckOrder: got one");
                ThrowForwardOrderException(previous, current);
            }

            last = last.NextCall;
        }

        last = current;
        while (last !is null && last.LastCall !is null) {
            version(OrderDebug) writefln("CheckOrder: checking backward");
            if (last.LastCall == cast(Object)previous) {
                break;
            }
            if (last.Repeat().Min > 0) {
                // We expected this to be called between _lastCall and icall.
                version(OrderDebug) writefln("CheckOrder: got one");
                ThrowBackwardOrderException(previous, current);
            }

            last = last.LastCall;
        }
    }

    private void ThrowBackwardOrderException(ICall previous, ICall current) {
        string msg = 
                "Ordered calls received in wrong order: \n" ~
                "Before: " ~ dmocks.Util.toString(current) ~ "\n" ~
                "Expected: " ~ current.LastCall().toString ~ "\n" ~
                "Actual: " ~ dmocks.Util.toString(current);
        throw new ExpectationViolationException(msg);
    }

    private void ThrowForwardOrderException(ICall previous, ICall actual) {
        string msg =
                "Ordered calls received in wrong order: \n" ~
                "After: " ~ dmocks.Util.toString(previous) ~ "\n" ~
                "Expected: " ~ previous.NextCall().toString ~ "\n" ~
                "Actual: " ~ dmocks.Util.toString(actual);
        throw new ExpectationViolationException(msg);
    }

public {
    bool Recording () { return _recording; }
    void Replay () { 
        _recording = false; 
        _lastCall = null;
        _lastOrdered = null;
    }
    void BackToRecord () { _recording = true; }
    ICall LastCall () { return _lastCall; }
    void Ordered (bool value) { 
        version(MocksDebug) writefln("SETTING ORDERED: %s", value);
        _ordered = value; 
    }
    bool Ordered () { return _ordered; }

    void Record(U...)(IMocked mocked, string name, U args) {
        ICall call;
        // I hate having to check for an empty tuple.
        static if (U.length) {
            call = new Call!(U)(mocked, name, new Arguments!(U)(args));
        } else {
            call = new Call!(U)(mocked, name, new Arguments!(U)());
        }

        if (_ordered) {
            call.Ordered = true;
            call.LastCall = _lastOrdered;
            if (_lastOrdered !is null) {
                _lastOrdered.NextCall = call;
            }
            _lastOrdered = call;
        }

        _calls ~= call;
        _lastCall = call;
    }

    ICall Match(U...)(IMocked mocked, string name, U args) {
        version(MocksDebug) writefln("about to match");
        auto match = new Call!(U)(mocked, name, new Arguments!(U)(args));
        version(MocksDebug) writefln("created call");

        foreach (icall; _calls) {
            version(MocksDebug) writefln("checking call");
            if (icall == match) {
                version(MocksDebug) writefln("found a match");
                icall.Called();
                version(MocksDebug) writefln("called the match");
                if (icall.Ordered) {
                    CheckOrder(icall, _lastOrdered);
                    _lastOrdered = icall;
                }

                _lastCall = icall;
                return icall;
            }
        }
        return null;
    }

    void Verify () {
        foreach (call; _calls) {
            if (!call.Satisfied) {
                // TODO: eventually we'll aggregate these, but for now,
                // just quit on the first one.
                throw new ExpectationViolationException(call);
            }
        }
    }

    version (MocksTest) {
        unittest {
            writef("repository record/replay unit test...");
            scope(failure) writefln("failed");
            scope(success) writefln("success");

            MockRepository r = new MockRepository();
            assert (r.Recording());
            r.Replay();
            assert (!r.Recording());
            r.BackToRecord();
            assert (r.Recording());
        }

        unittest {
            writef("match object with no expectations unit test...");
            scope(failure) writefln("failed");
            scope(success) writefln("success");

            MockRepository r = new MockRepository();
            r.Match!()(new FakeMocked, "toString");
        }

        unittest {
            writef("repository match unit test...");
            scope(failure) writefln("failed");
            scope(success) writefln("success");
            FakeMocked m = new FakeMocked();
            string name = "Tom Jones";
            int args = 3;
            
            MockRepository r = new MockRepository();
            r.Record!(int)(m, name, args);
            r.Record!(int)(m, name, args);
            ICall call = r.Match!(int)(m, name, args);
            assert (call !is null);
            call = r.Match!(int)(m, name, args + 5);
            assert (call is null);
        }

        unittest {
            writef("repository match ignore arguments unit test...");
            scope(failure) writefln("failed");
            scope(success) writefln("success");
            FakeMocked m = new FakeMocked();
            string name = "Tom Jones";
            int args = 3;
            
            MockRepository r = new MockRepository();
            r.Record!(int)(m, name, args);
            r.Record!(int)(m, name, args);
            r._lastCall.IgnoreArguments = true;
            ICall call = r.Match!(int)(m, name, args);
            assert (call !is null);
            call = r.Match!(int)(m, name, args + 5);
            assert (call !is null);
        }

        unittest {
            writef("repository match counts unit test...");
            scope(failure) writefln("failed");
            scope(success) writefln("success");
            FakeMocked m = new FakeMocked();
            string name = "Tom Jones";
            int args = 3;
            
            MockRepository r = new MockRepository();
            r.Record!(int)(m, name, args);
            ICall call = r.Match!(int)(m, name, args);
            assert (call !is null);
            try {
                call = r.Match!(int)(m, name, args);
                assert (false, "expected exception not called");
            } catch (ExpectationViolationException e) {}
        }
    }
}
}

/++
    An abstract representation of a method call.
 ++/
public interface ICall {
    // Interfaces don't include the stuff in Object by default.
    // If we want == with an interface, we include it explicitly.
    // Rather ugly.
    int opEquals (Object other);
    string toString ();
    void IgnoreArguments (bool value);
    Variant ReturnValue ();
    void ReturnValue (Variant value);
    void Repeat (Interval value);
    Interval Repeat ();
    void Called ();
    bool Void ();
    bool Satisfied ();
    Variant Action ();
    void Action (Variant value);
    // TODO Error doesn't inherit from Exception, I think.
    // This will have to get an override to deal with errors as well.
    void Throw (Exception e);
    void SetPassThrough ();
    ICall LastCall ();
    void LastCall (ICall call);
    ICall NextCall ();
    void NextCall (ICall call);
    void Ordered (bool value);
    bool Ordered ();
}

public class Call (U...) : ICall {
    private {
        bool _ignoreArguments;
        bool _void;
        bool _passThrough;
        bool _ordered;
        Variant _returnValue;
        Arguments!(U) _arguments;
        IMocked _mocked;
        string _name = "unknown";
        Interval _repeat;
        int _callCount;
        Variant _action;
        Exception _toThrow;
        ICall _lastCall = null;
        ICall _nextCall = null;
    }

    void Throw (Exception e) {
        _toThrow = e;
    }

    Exception ToThrow () {
        return _toThrow;
    }

    override string toString () {
        version(MocksDebug) writefln("trying get arg string");
        string args = (_arguments == null) ? "(<unknown>)" : _arguments.toString;
        version(MocksDebug) writefln("trying get callcount string");
        string callCount = dmocks.Util.toString(_callCount);
        version(MocksDebug) writefln("trying get repeat string");
        string expected = _repeat.toString;
        version(MocksDebug) writefln("putting it together");
        string ret = _name ~ args ~ " Expected: " ~ expected ~ " Actual: " ~ callCount;
        version(MocksDebug) writefln("returning");
        return ret;
        /*
        return _mocked.GetUnmockedTypeNameString() ~ `.` ~ _name ~ args ~
                " Expected: " ~ dmocks.Util.toString(_callCount) ~
                " Actual " ~ _repeat.toString;*/
    }

    bool Satisfied () {
        return _callCount <= _repeat.Max && _callCount >= _repeat.Min;
    }

    void Repeat (Interval value) {
        if (value.Valid() && value.Max >= 0) {
            _repeat = value;
        } else {
            throw new InvalidOperationException("Repeat interval must be a valid interval allowing a nonnegative number of repetitions.");
        }
    }

    Interval Repeat () { return _repeat; }

    override int opEquals (Object other) {
        auto call = cast(typeof(this)) other;
        if (call is null) {
            version(MocksDebug) writefln("Call.opEquals: wrong type");
            return false;
        }

        if (call._mocked !is _mocked) {
            version(MocksDebug) writefln("Call.opEquals: wrong mock");
            return false;
        }
        
        if (call._name != _name) {
            version(MocksDebug) writefln("Call.opEquals: wrong method; expected %s; was %s", _name, call._name);
            return false;
        }

        if ((!_ignoreArguments) && (_arguments != call._arguments)) {
            version(MocksDebug) writefln("Call.opEquals: wrong arguments");
            return false;
        }
        return true;
    }

    void IgnoreArguments (bool value) { _ignoreArguments = value; }
    bool IgnoreArguments () { return _ignoreArguments; }

    void Void (bool value) { _void = value; }
    bool Void () { return _void; }

    Variant ReturnValue () { 
        if (_void) {
            throw new InvalidOperationException("voids have no return value");
        }
        return _returnValue; 
    }

    void ReturnValue (Variant value) { 
        if (_void) {
            throw new InvalidOperationException("voids have no return value");
        }
        _returnValue = value; 
    }

    void Called () {
        version(MocksDebug) writefln("call called");
        _callCount++;
        version(MocksDebug) writefln("checking against repeat");
        if (_callCount > _repeat.Max) {
            version(MocksDebug) writefln("repeat violated");
            throw new ExpectationViolationException(this);
        }
        version(MocksDebug) writefln("repeat verified");
    }

    // TODO: only accept delegates with arguments of same type as this
    // call.
    void Action (Variant action) {
        _action = action;
    }

    Variant Action () {
        return _action;
    }

    void SetPassThrough () {
        _passThrough = true;
    }

    bool PassThrough () {
        return _passThrough;
    }

    ICall LastCall () {
        return _lastCall;
    }

    void LastCall (ICall call) {
        version(MocksDebug) writefln("SETTING LASTCALL: ", dmocks.Util.toString(call)); 
        _lastCall = call;
    }

    ICall NextCall () {
        return _nextCall;
    }

    void NextCall (ICall call) {
        version(MocksDebug) writefln("SETTING NEXTCALL: ", dmocks.Util.toString(call)); 
        _nextCall = call;
    }

    void Ordered (bool value) { _ordered = value; }
    bool Ordered () { return _ordered; }

    this (IMocked mocked, string name, Arguments!(U) arguments) {
        _mocked = mocked;
        _name = name;
        _arguments = arguments;
        _repeat = Interval(1, 1);
    }
}


version (MocksTest) {
    unittest {
        // Matching.
        writef("Call.opEquals unit test...");
        scope(failure) writefln("failed");
        scope(success) writefln("success");
        auto o = new FakeMocked();
        auto name = "Thwackum";
        auto args = new Arguments!(int)(5);
        auto args2 = new Arguments!(int)(1111);
        auto a = new Call!(int)(o, name, args);
        auto b = new Call!(int)(o, name, args);
        auto c = new Call!(int)(o, name, args2);
        auto d = new Call!()(o, name, new Arguments!()());
        assert (a == b);
        assert (a != c);
        assert (d != c);
    }

    unittest {
        // Ignore arguments.
        writef("ignore arguments unit test...");
        scope(failure) writefln("failed");
        scope(success) writefln("success");
        auto o = new FakeMocked();
        auto name = "Thwackum";
        auto args = new Arguments!(int)(5);
        auto args2 = new Arguments!(int)(1111);
        auto a = new Call!(int)(o, name, args);
        auto b = new Call!(int)(o, name, args2);
        a.IgnoreArguments = true;
        assert (a == b);
        assert (b != a);
    }

    unittest {
        writef("set repeat interval unit test...");
        scope(failure) writefln("failed");
        scope(success) writefln("success");
        auto o = new FakeMocked();
        auto name = "Thwackum";
        auto args = new Arguments!(int)(5);
        auto args2 = new Arguments!(int)(1111);
        auto a = new Call!(int)(o, name, args);
        //auto b = new Call!(int)(o, name, args2);
        a.Repeat(Interval(0, 1));
        assert (a._repeat.Min == 0);
        assert (a._repeat.Max == 1);
    }

    unittest {
        writef("set repeat interval to invalid values unit test...");
        scope(failure) writefln("failed");
        scope(success) writefln("success");
        auto a = new Call!(int)(new FakeMocked(), "frumious", new Arguments!(int)(5));
        //auto b = new Call!(int)(o, name, args2);
        try {
            a.Repeat(Interval(5, 1));
            assert (false, "invalid interval not caught");
        } catch {}
        try {
            a.Repeat(Interval(-10, -1));
            assert (false, "invalid interval not caught");
        } catch {}
    }

    unittest {
        writef("complain about too many calls unit test...");
        scope(failure) writefln("failed");
        scope(success) writefln("success");
        auto a = new Call!(int)(new FakeMocked(), "frumious", new Arguments!(int)(5));
        a.Repeat(Interval(0, 1));
        a.Called();
        try {
            a.Called();
            assert (false, "exception not thrown");
        } catch (ExpectationViolationException e) {}
    }

    unittest {
        writef("satisfied unit test...");
        scope(failure) writefln("failed");
        scope(success) writefln("success");
        auto a = new Call!(int)(new FakeMocked(), "frumious", new Arguments!(int)(5));
        a.Repeat(Interval(2, 3));
        a.Called();
        assert (!a.Satisfied());
        a.Called();
        assert (a.Satisfied());
        a.Called();
        assert (a.Satisfied());
        try {
            a.Called();
            assert (false, "exception not thrown");
        } catch (ExpectationViolationException e) {}
    }

    unittest {
        writef("default interval unit test...");
        scope(failure) writefln("failed");
        scope(success) writefln("success");
        auto a = new Call!(int)(new FakeMocked(), "frumious", new Arguments!(int)(5));
        assert (a._repeat.Min == 1);
        assert (a._repeat.Max == 1);
    }

    unittest {
        writef("Call.toString test...");
        scope(failure) writefln("failed");
        scope(success) writefln("success");
        auto a = new Call!(int)(new FakeMocked(), "frumious", new Arguments!(int)(5));
        a.Repeat(Interval(2, 3));
        a.toString();
    }

    unittest {
        writef("Call.toString no arguments test...");
        scope(failure) writefln("failed");
        scope(success) writefln("success");
        auto a = new Call!()(new FakeMocked(), "frumious", new Arguments!());
        a.Repeat(Interval(2, 3));
        a.toString();
    }

    unittest {
        writef("Call set exceptions test...");
        scope(failure) writefln("failed");
        scope(success) writefln("success");
        auto a = new Call!()(new FakeMocked(), "frumious", new Arguments!());
        Exception e = new Exception("DIVIDE BY CUCUMBER ERROR");
        a.Throw(e);
        assert (a.ToThrow() is e);
    }
}


/++
    There used to be a LOT of code duplication because D doesn't like
    a variable whose type is an empty type tuple. This is all that remains.
 ++/
template Arguments (U...) {
    static if (U.length == 0) {
        public class Arguments {
            this () {}
            override int opEquals (Object other) {
                return cast(typeof(this)) other !is null;
            }

            override string toString () { return "()"; }
        }
    } else {
        class Arguments {
            this (U args) { Arguments = args; }
            public U Arguments;
            override int opEquals (Object other) {
                auto args = cast(typeof(this)) other;
                if (args is null) return false;
                foreach (i, arg; Arguments) {
                    if (args.Arguments[i] !is arg) {
                        return false;
                    }
                }

                return true;
            }

            override string toString () { 
                string value = "(";
                foreach (u; Arguments) {
                    value ~= dmocks.Util.toString(u) ~ ", ";
                }

                return value[0..$-2] ~ ")";
            }
        }
    }
}

version (MocksTest) {
    unittest {
        writef("argument equality unit test...");
        scope(failure) writefln("failed");
        scope(success) writefln("success");
        auto a = new Arguments!(int, real)(5, 9.7);
        auto b = new Arguments!(int, real)(5, 9.7);
        auto c = new Arguments!(int, real)(9, 1.1);
        auto d = new Arguments!(int, float)(5, 9.7f);

        assert (a == b);
        assert (a != c);
        assert (a != d);
    }

    unittest {
        writef("argument toString unit test...");
        scope(failure) writefln("failed");
        scope(success) writefln("success");
        auto a = new Arguments!(int, real)(5, 9.7);
        a.toString();
    }
}

public class ExpectationViolationException : Exception {
    private static string _defaultMessage = "An unexpected call has occurred."; 
    this () { super(_defaultMessage); }
    this (string msg) { super(msg); }
    this (ICall call) {
        //this();
        if (call !is null) {
            super (call.toString());
        } else {
            super (_defaultMessage);
        }
    }

    version (MocksTest) {
        unittest {
            writef("ExpectationViolation constructor test...");
            scope(failure) writefln("failed");
            scope(success) writefln("success");
            
            FakeMocked o = new FakeMocked();
            auto call = new Call!()(o, "toString", new Arguments!());
            new ExpectationViolationException(call); 
        }
    }
}

