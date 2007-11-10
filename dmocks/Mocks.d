module dmocks.Mocks;

import dmocks.MockObject;
import dmocks.Repository; 
import dmocks.Util; 
import std.stdio;
import std.variant;

/++
    A class through which one creates mock objects and manages expected calls. 
 ++/
public class Mocker {
    private MockRepository _repository;

    public {
        this () {
            _repository = new MockRepository();
        }

        /** 
          * Stop setting up expected calls. Any calls after this point will
          * be verified against the expectations set up before calling Replay.
          */
        void Replay () {
            _repository.Replay();
        }
        alias Replay replay;

        /**
          * Record method calls starting at this point. These calls are not
          * checked against existing expectations; they create new expectations.
          */
        void Record () {
            _repository.BackToRecord();
        }
        alias Record record;

        /**
          * Check to see if there are any expected calls that haven't been
          * matched with a real call. Throws an ExpectationViolationException
          * if there are any outstanding expectations.
          */
        void Verify () {
            _repository.Verify();
        }
        alias Verify verify;

        /** Get a mock object of the given type. */
        T Mock (T) () {
            return new Mocked!(T)(_repository);
        }
        alias Mock mock;

        /**
          * Only for non-void methods. Start an expected call; this returns
          * an object that allows you to set various properties on the call,
          * such as return value and number of repetitions.
          *
          * Examples:
          * ---
          * Mocker m = new Mocker;
          * Object o = m.Mock!(Object);
          * m.Expect(o.toString).Return("hello?");
          * ---
          */
        ExternalCall Expect (T) (T ignored) {
            return new ExternalCall(_repository.LastCall());
        }
        alias Expect expect;
        
        /**
          * For void and non-void methods. Start an expected call; this returns
          * an object that allows you to set various properties on the call,
          * such as return value and number of repetitions.
          *
          * Examples:
          * ---
          * Mocker m = new Mocker;
          * Object o = m.Mock!(Object);
          * o.toString;
          * m.LastCall().Return("hello?");
          * ---
          */
        ExternalCall LastCall () {
            return new ExternalCall(_repository.LastCall());
        }
        alias LastCall lastCall;
    }
}

/++
    An ExternalCall allows you to set up various options on a Call,
    such as return value, number of repetitions, and so forth.
    Examples:
    ---
    Mocker m = new Mocker;
    Object o = m.Mock!(Object);
    o.toString;
    m.LastCall().Return("Are you still there?").Repeat(1, 12);
 ++/
public class ExternalCall {
    private ICall _call;

    this (ICall call) {
        _call = call;
    }

    // TODO: how can I get validation here that the type you're
    // inserting is the type expected before trying to execute it?
    // Not really an issue, since it'd be revealed in the space
    // of a single test.
    /**
      * Set the return value of call.
      * Params:
      *     value = the value to return
      */
    ExternalCall Return (T)(T value) {
        _call.ReturnValue(Variant(value));
        return this;
    }
    alias Return returnValue;

    /**
      * The arguments for this call will be ignored.
      */
    ExternalCall IgnoreArguments () {
        _call.IgnoreArguments = true;
        return this;
    }
    alias IgnoreArguments ignoreArguments;

    /**
      * This call must be repeated at least min times and can be repeated at
      * most max times.
      */
    ExternalCall Repeat (int min, int max) {
        if (min > max) {
            throw new InvalidOperationException("The specified range is invalid.");
        }
        _call.Repeat(Interval(min, max));
        return this;
    }
    alias Repeat repeat;

    /**
      * This call must be repeated exactly i times.
      */
    ExternalCall Repeat (int i) {
        _call.Repeat(Interval(i, i));
        return this;
    }

    /**
      * This call can be repeated any number of times.
      */
    ExternalCall RepeatAny () {
        return Repeat(0, int.max);
    }
    alias RepeatAny repeatAny;

    /**
      * When the method is executed (with matching arguments), execute the
      * given delegate. The delegate's signature must match the signature
      * of the called method. If it does not, an exception will be thrown.
      * The called method will return whatever the given delegate returns.
      * Examples:
      * ---
      * m.Expect(myObj.myFunc(0, null, null, 'a')
      *     .IgnoreArguments()
      *     .Do((int i, string s, Object o, char c) { return -1; });
      * ---
      */
    ExternalCall Do (T, U...)(T delegate(U) action) {
        Variant a = Variant(action);
        _call.Action(a);
        return this;
    }
    alias Do action;

    /**
      * When the method is called, throw the given exception. If there are any
      * actions specified (via the Do method), they will not be executed.
      */
    ExternalCall Throw (Exception e) {
        _call.Throw(e);
        return this;
    }
    alias Throw throwException;

    /**
      * Instead of returning or throwing a given value, pass the call through to
      * the base class. This is dangerous -- the private fields of the class may
      * not be set up properly, so only use this when the function does not depend
      * on these fields. Things such as using Object's toHash and opEquals when your
      * class doesn't override them and you use associative arrays.
      */
    ExternalCall PassThrough () {
        _call.SetPassThrough();
        return this;
    }
}

version (MocksTest) {
    unittest {
        writef("LastCall test...");
        scope(success) writefln("success");
        scope(failure) writefln("failure");

        Mocker m = new Mocker();
        Object o = m.Mock!(Object);
        o.print;
        auto e = m.LastCall;

        assert (e._call !is null);
    }

    unittest {
        writef("return a value test...");
        scope(success) writefln("success");
        scope(failure) writefln("failure");

        Mocker m = new Mocker();
        Object o = m.Mock!(Object);
        o.toString;
        auto e = m.LastCall;

        assert (e._call !is null);
        e.Return("frobnitz");
    }

    unittest {
        writef("expect test...");
        scope(success) writefln("success");
        scope(failure) writefln("failure");

        Mocker m = new Mocker();
        Object o = m.Mock!(Object);
        m.Expect(o.toString).Return("foom?");
    }

    unittest {
        writef("repeat single test...");
        scope(success) writefln("success");
        scope(failure) writefln("failure");

        Mocker m = new Mocker();
        Object o = m.Mock!(Object);
        m.Expect(o.toString).Repeat(2).Return("foom?");

        m.Replay();

        o.toString;
        o.toString;
        try {
            o.toString;
            assert (false, "expected exception not thrown");
        } catch (ExpectationViolationException) {}
    }

    unittest {
        writef("repository match counts unit test...");
        scope(failure) writefln("failed");
        scope(success) writefln("success");

        MockRepository r = new MockRepository();
        auto o = new Mocked!(Object)(r);
        o.toString;
        r.LastCall().Repeat(Interval(2, 2));
        r.Replay();
        try {
            r.Verify();
            assert (false, "expected exception not thrown");
        } catch (ExpectationViolationException) {}
    }

    unittest {
        writef("delegate payload test...");
        scope(failure) writefln("failed");
        scope(success) writefln("success");

        bool calledPayload = false;
        Mocker r = new Mocker();
        auto o = r.Mock!(Object);

        o.print;
        r.LastCall().Do({ calledPayload = true; });
        r.Replay();

        o.print;
        assert (calledPayload);
    }

    unittest {
        writef("exception payload test...");
        scope(failure) writefln("failed");
        scope(success) writefln("success");

        Mocker r = new Mocker();
        auto o = r.Mock!(Object);

        string msg = "divide by cucumber error";
        o.print;
        r.LastCall().Throw(new Exception(msg));
        r.Replay();

        try {
            o.print;
            assert (false, "expected exception not thrown");
        } catch (Exception e) {
            // Careful -- assertion errors derive from Exception
            assert (e.msg == msg, e.msg);
        }
    }

    class HasPrivateMethods {
        protected void method () {}
    }

    unittest {
        writef("passthrough test...");
        scope(failure) writefln("failed");
        scope(success) writefln("success");

        Mocker r = new Mocker();
        auto o = r.Mock!(Object);
        o.toString;
        r.LastCall().PassThrough();

        r.Replay();
        string str = o.toString;
        writefln("%s", str);
    }

    unittest {
        writef("associative arrays test...");
        scope(failure) writefln("failed");
        scope(success) writefln("success");

        Mocker r = new Mocker();
        auto o = r.Mock!(Object);
        r.Expect(o.toHash()).PassThrough().RepeatAny;
        r.Expect(o.opEquals(null)).IgnoreArguments().PassThrough().RepeatAny;

        r.Replay();
        int[Object] i;
        i[o] = 5;
        int j = i[o];
    }

    /+
    // Not supported -- templated methods. A templated class with methods
    // using those template arguments is fine. Templated methods are not
    // virtual.
    class Foo {
        void bar (T) (T value) { writefln("Broken test!"); }
    }

    unittest {
        writef("templated method verify test...");
        scope(success) writefln("success");
        scope(failure) writefln("failure");
        writefln("\n%s", __traits(allMembers, Foo));
        writefln("%s", __traits(getVirtualFunctions, Foo, "bar").length);

        Mocker m = new Mocker();
        auto o = m.Mock!(Foo);
        o.bar!(int)(5);

        m.Replay();

        o.bar!(int)(5);

        m.Verify();
    }

    unittest {
        writef("templated method too many invocations test...");
        scope(success) writefln("success");
        scope(failure) writefln("failure");

        Mocker m = new Mocker();
        auto o = m.Mock!(Foo);
        o.bar!(int)(5);

        m.Replay();

        o.bar!(int)(5);
        try {
            o.bar!(int)(5);
            //o.toString();
            assert (false, "expected exception not thrown");
        } catch (ExpectationViolationException) {}
    }
    +/
}
