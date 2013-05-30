module dmocks.repository;

import dmocks.util;
import dmocks.model;
import dmocks.call;
import dmocks.arguments;
import std.variant;
import std.stdio;
import std.conv;

public class MockRepository
{
    // TODO: split this up somehow!
    private bool _allowDefaults = false;
    private ICall[] _calls = [];
    private bool _recording = true;
    private bool _ordered = false;
    private ICall _lastCall;
    private ICall _lastOrdered;

    private void CheckLastCallSetup ()
    {
        if (_allowDefaults || _lastCall is null || _lastCall.HasAction)
        {
            return;
        }

        throw new MocksSetupException(
                "Last call: if you do not specify the AllowDefaults option, you need to return a value, throw an exception, execute a delegate, or pass through to base function. The call is: " ~ _lastCall.toString);
    }

    private void CheckOrder (ICall current, ICall previous)
    {
        mixin(debugLog!"CheckOrder: init");
        mixin(debugLog!("CheckOrder: current: %s", current));
        if (current !is null)
            version (DMocksDebug)
                debugLog("CheckOrder: current.Last: %s", current.LastCall.toString());
        mixin(debugLog!("CheckOrder: previous: %s", previous));
        if (current !is null)
            version (DMocksDebug)
                debugLog("CheckOrder: previous.Next: %s", current.NextCall.toString());
        if (current is null || (current.LastCall is null && previous !is null && previous.NextCall is null))
        {
            mixin(debugLog!("CheckOrder: nothing to do, returning"));
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
        while (last !is null && last.NextCall !is null)
        {
            mixin(debugLog!("CheckOrder: checking forward"));
            if (last.NextCall == cast(Object) current)
            {
                break;
            }
            if (last.Repeat().Min > 0)
            {
                // We expected this to be called between _lastCall and icall.
                mixin(debugLog!("CheckOrder: got one"));
                ThrowForwardOrderException(previous, current);
            }

            last = last.NextCall;
        }

        last = current;
        while (last !is null && last.LastCall !is null)
        {
            mixin(debugLog!("CheckOrder: checking backward"));
            if (last.LastCall == cast(Object) previous)
            {
                break;
            }
            if (last.Repeat().Min > 0)
            {
                // We expected this to be called between _lastCall and icall.
                mixin(debugLog!("CheckOrder: got one"));
                ThrowBackwardOrderException(previous, current);
            }

            last = last.LastCall;
        }
    }

    private void ThrowBackwardOrderException (ICall previous, ICall current)
    {
        string msg = "Ordered calls received in wrong order: \n" ~ "Before: " ~ current.to!string
                         ~ "\n" ~ "Expected: " ~ current.LastCall().to!string ~ "\n" ~ "Actual: " ~ current.to!string;
        throw new ExpectationViolationException(msg);
    }

    private void ThrowForwardOrderException (ICall previous, ICall actual)
    {
        string msg = "Ordered calls received in wrong order: \n" ~ "After: " ~ previous.to!string
                    ~ "\n" ~ "Expected: " ~ previous.NextCall().to!string ~ "\n" ~ "Actual: " ~ actual.to!string;
        throw new ExpectationViolationException(msg);
    }

public
{
    void AllowDefaults (bool value)
    {
        _allowDefaults = value;
    }

    bool Recording ()
    {
        return _recording;
    }

    void Replay ()
    {
        CheckLastCallSetup();
        _recording = false;
        _lastCall = null;
        _lastOrdered = null;
    }


    void BackToRecord ()
    {
        _recording = true;
    }

    ICall LastCall ()
    {
        return _lastCall;
    }

    void Ordered (bool value)
    {
        mixin(debugLog!("SETTING ORDERED: %s", value));
        _ordered = value;
    }

    bool Ordered ()
    {
        return _ordered;
    }

    void Record (U...) (IMocked mocked, string name, U args, bool returns)
    {
        CheckLastCallSetup();
        ICall call;
        // I hate having to check for an empty tuple.
        static if (U.length)
        {
            call = new Call(mocked, name, new Arguments!(U)(args));
        }
        else
        {
            call = new Call(mocked, name, new Arguments!(U)());
        }
        call.Void(!returns);

        if (_ordered)
        {
            call.Ordered = true;
            call.LastCall = _lastOrdered;
            if (_lastOrdered !is null)
            {
                _lastOrdered.NextCall = call;
            }
            _lastOrdered = call;
        }

        _calls ~= call;
        _lastCall = call;
    }

    ICall Match (U...) (IMocked mocked, string name, U args)
    {
        mixin(debugLog!"about to match");
        auto match = new Call(mocked, name, new Arguments!(U)(args));
        mixin(debugLog!"created call");

        foreach (icall; _calls)
        {
            mixin(debugLog!"checking call");
            if (icall == match)
            {
                mixin(debugLog!"found a match");
                icall.Called();
                mixin(debugLog!"called the match");
                if (icall.Ordered)
                {
                    CheckOrder(icall, _lastOrdered);
                    _lastOrdered = icall;
                }

                _lastCall = icall;
                return icall;
            }
        }
        return null;
    }

    void Verify ()
    {
        foreach (call; _calls)
        {
            if (!call.Satisfied)
            {
                // TODO: eventually we'll aggregate these, but for now,
                // just quit on the first one.
                throw new ExpectationViolationException(call.toString());
            }
        }
    }

    version (DMocksTest)
    {
        unittest {
            mixin(test!("repository record/replay"));

            MockRepository r = new MockRepository();
            assert (r.Recording());
            r.Replay();
            assert (!r.Recording());
            r.BackToRecord();
            assert (r.Recording());
        }

        unittest {
            mixin(test!("match object with no expectations"));

            MockRepository r = new MockRepository();
            r.Match!()(new FakeMocked, "toString");
        }

        unittest {
            mixin(test!("repository match"));

            FakeMocked m = new FakeMocked();
            string name = "Tom Jones";
            int args = 3;

            MockRepository r = new MockRepository();
            r.Record!(int)(m, name, args, false);
            r.Record!(int)(m, name, args, false);
            ICall call = r.Match!(int)(m, name, args);
            assert (call !is null);
            call = r.Match!(int)(m, name, args + 5);
            assert (call is null);
        }

        unittest {
            mixin(test!("repository match ignore arguments"));

            FakeMocked m = new FakeMocked();
            string name = "Tom Jones";
            int args = 3;

            MockRepository r = new MockRepository();
            r.Record!(int)(m, name, args, false);
            r.Record!(int)(m, name, args, false);
            r._lastCall.IgnoreArguments = true;
            ICall call = r.Match!(int)(m, name, args);
            assert (call !is null);
            call = r.Match!(int)(m, name, args + 5);
            assert (call !is null);
        }

        unittest {
            mixin(test!("repository match counts"));

            FakeMocked m = new FakeMocked();
            string name = "Tom Jones";
            int args = 3;

            MockRepository r = new MockRepository();
            r.Record!(int)(m, name, args, false);
            ICall call = r.Match!(int)(m, name, args);
            assert (call !is null);
            try
            {
                call = r.Match!(int)(m, name, args);
                assert (false, "expected exception not called");
            }
            catch (ExpectationViolationException e)
            {
            }
        }
    }
}
}

version (DMocksTest)
{
    unittest {
        mixin(test!("argument equality"));

        auto a = new Arguments!(int, real)(5, 9.7);
        auto b = new Arguments!(int, real)(5, 9.7);
        auto c = new Arguments!(int, real)(9, 1.1);
        auto d = new Arguments!(int, float)(5, 9.7f);

        assert (a == b);
        assert (a != c);
        assert (a != d);
    }

    unittest {
        mixin(test!("argument toString"));

        auto a = new Arguments!(int, real)(5, 9.7);
        a.toString();
    }
}
