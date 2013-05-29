module dmocks.mocks;

import dmocks.object_mock;
import dmocks.factory;
import dmocks.repository; 
import dmocks.util;
import dmocks.call;
import std.variant;
import std.stdio;

version (DMocksDebug) import std.stdio;
version (DMocksTest) import std.stdio;

/++
    A class through which one creates mock objects and manages expected calls. 
 ++/
public class Mocker 
{
    private MockRepository _repository;

    public 
    {
        this () 
        {
            _repository = new MockRepository();
        }

        /** 
         * Stop setting up expected calls. Any calls after this point will
         * be verified against the expectations set up before calling Replay.
         */
        void replay () 
        {
            _repository.Replay();
        }

        /**
         * Record method calls starting at this point. These calls are not
         * checked against existing expectations; they create new expectations.
         */
        void record () 
        {
            _repository.BackToRecord();
        }

        /**
         * Check to see if there are any expected calls that haven't been
         * matched with a real call. Throws an ExpectationViolationException
         * if there are any outstanding expectations.
         */
        void verify () 
        {
            _repository.Verify();
        }

        /**
         * By default, all expectations are unordered. If I want to require that
         * one call happen immediately after another, I call Mocker.ordered, make
         * those expectations, and call Mocker.unordered to avoid requiring a
         * particular order afterward.
         *
         * Currently, the support for ordered expectations is rather poor. It works
         * well enough for expectations with a constant number of repetitions, but
         * with a range, it tends to fail: once you call one method the minimum number
         * of times, you can omit that method in subsequent invocations of the set.
         */
        void ordered () 
        {
            _repository.Ordered(true);
        }

        void unordered () 
        {
            _repository.Ordered(false);
        }

        /** Get a mock object of the given type. */
        T mock (T) () 
        {
            return MockFactory.Mock!(T)(_repository);
        }

        /**
         * Only for non-void methods. Start an expected call; this returns
         * an object that allows you to set various properties on the call,
         * such as return value and number of repetitions.
         *
         * Examples:
         * ---
         * Mocker m = new Mocker;
         * Object o = m.Mock!(Object);
         * m.expect(o.toString).returns("hello?");
         * ---
         */
        ExternalCall expect (T) (T ignored) {
            return lastCall();
        }

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
         * m.LastCall().returns("hello?");
         * ---
         */
        ExternalCall lastCall () {
            return new ExternalCall(_repository.LastCall());
        }

        /**
         * Set up a result for a method, but without any backend accounting for it.
         * Things where you want to allow this method to be called, but you aren't
         * currently testing for it.
         */
        ExternalCall allowing (T) (T ignored) {
            return lastCall().repeatAny;
        }

        /** Ditto */
        ExternalCall allowing (T = void) () {
            return lastCall().repeatAny();
        }

        /**
         * Do not require explicit return values for expectations. If no return
         * value is set, return the default value (null / 0 / nan, in most
         * cases). By default, if no return value, exception, delegate, or
         * passthrough option is set, an exception will be thrown.
         */
        void allowDefaults () {
            _repository.AllowDefaults(true);
        }
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
   m.LastCall().returns("Are you still there?").repeat(1, 12);
   ---
++/
public class ExternalCall 
{
   private ICall _call;

   this (ICall call) 
   {
       assert (call !is null, "can't create an ExternalCall if ICall is null");
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
   ExternalCall returns (T)(T value) 
   {
       _call.Action.returnValue(Variant(value));
       return this;
   }

   /**
    * The arguments for this call will be ignored.
    */
   ExternalCall ignoreArgs () 
   {
       _call.IgnoreArguments = true;
       return this;
   }

   /**
    * This call must be repeated at least min times and can be repeated at
    * most max times.
    */
   ExternalCall repeat (int min, int max) 
   {
       if (min > max) 
       {
           throw new InvalidOperationException("The specified range is invalid.");
       }
       _call.Repeat(Interval(min, max));
       return this;
   }

   /**
    * This call must be repeated exactly i times.
    */
   ExternalCall repeat (int i) 
   {
       _call.Repeat(Interval(i, i));
       return this;
   }

   /**
    * This call can be repeated any number of times.
    */
   ExternalCall repeatAny () 
   {
       return repeat(0, int.max);
   }

   /**
    * When the method is executed (with matching arguments), execute the
    * given delegate. The delegate's signature must match the signature
    * of the called method. If it does not, an exception will be thrown.
    * The called method will return whatever the given delegate returns.
    * Examples:
    * ---
    * m.expect(myObj.myFunc(0, null, null, 'a')
    *     .ignoreArgs()
    *     .action((int i, char[] s, Object o, char c) { return -1; });
    * ---
    */
   ExternalCall action (T, U...)(T delegate(U) action) 
   {
       Variant a = Variant(action);
       _call.Action.action = a;
       return this;
   }

   /**
    * When the method is called, throw the given exception. If there are any
    * actions specified (via the action method), they will not be executed.
    */
   ExternalCall throws (Exception e) 
   {
       _call.Action.toThrow = e;
       return this;
   }

   /**
    * Instead of returning or throwing a given value, pass the call through to
    * the base class. This is dangerous -- the private fields of the class may
    * not be set up properly, so only use this when the function does not depend
    * on these fields. Things such as using Object's toHash and opEquals when your
    * class doesn't override them and you use associative arrays.
    */
   ExternalCall passThrough () 
   {
       _call.Action.passThrough = true;
       return this;
   }
}

version (DMocksTest) {
    
    class Templated(T) {}
    interface IM {
        void bar ();
    }

    class ConstructorArg {
        this (int i) {}
    }

    unittest {
        mixin(test!("nontemplated mock"));
        (new Mocker()).mock!(Object);
    }

    unittest {
        mixin(test!("templated mock"));
        (new Mocker()).mock!(Templated!(int));
    }

    unittest {
        mixin(test!("templated mock"));
        (new Mocker()).mock!(IM);
    }

    unittest {
        mixin(test!("execute mock method"));
        scope(failure) writefln("failed");
        scope(success) writefln("success");
        auto r = new Mocker();
        auto o = r.mock!(Object);
        o.toString();
        assert (r.lastCall()._call !is null);
    }

//    unittest {
//		  mixin(test!("constructor argument"));
//        auto r = new Mocker();
//        r.mock!(ConstructorArg);
//    }

    unittest {
        mixin(test!("lastCall"));
        Mocker m = new Mocker();
        Object o = m.mock!(Object);
        o.toString;
        auto e = m.lastCall;

        assert (e._call !is null);
    }

    unittest {
        mixin(test!("return a value"));

        Mocker m = new Mocker();
        Object o = m.mock!(Object);
        o.toString;
        auto e = m.lastCall;

        assert (e._call !is null);
        e.returns("frobnitz");
    }

    unittest {
        mixin(test!("expect"));

        Mocker m = new Mocker();
        Object o = m.mock!(Object);
        m.expect(o.toString).repeat(0).returns("mrow?");
        m.replay();
        try {
            o.toString;
        } catch (Exception e) {}
    }

    unittest {
        mixin(test!("repeat single"));

        Mocker m = new Mocker();
        Object o = m.mock!(Object);
        m.expect(o.toString).repeat(2).returns("foom?");

        m.replay();

        o.toString;
        o.toString;
        try {
            o.toString;
            assert (false, "expected exception not thrown");
        } catch (ExpectationViolationException) {}
    }

    unittest {
        mixin(test!("repository match counts"));

        auto r = new Mocker();
        auto o = r.mock!(Object);
        o.toString;
        r.lastCall().repeat(2, 2).returns("mew.");
        r.replay();
        try {
            r.verify();
            assert (false, "expected exception not thrown");
        } catch (ExpectationViolationException) {}
    }

    unittest {
        mixin(test!("delegate payload"));

        bool calledPayload = false;
        Mocker r = new Mocker();
        auto o = r.mock!(Object);

        o.toString;
        r.lastCall().action({ calledPayload = true; });
        r.replay();

        o.toString;
        assert (calledPayload);
    }

    unittest {
        mixin(test!("exception payload"));

        Mocker r = new Mocker();
        auto o = r.mock!(Object);

        string msg = "divide by cucumber error";
        o.toString;
        r.lastCall().throws(new Exception(msg));
        r.replay();

        try {
            o.toString;
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
        mixin(test!("passthrough"));

        Mocker r = new Mocker();
        auto o = r.mock!(Object);
        o.toString;
        r.lastCall().passThrough();

        r.replay();
        string str = o.toString;
        assert (str == "dmocks.object_mock.Mocked!(Object).Mocked", str);
    }

    unittest {
        mixin(test!("associative arrays"));

        Mocker r = new Mocker();
        auto o = r.mock!(Object);
        r.expect(o.toHash()).passThrough().repeatAny;
        r.expect(o.opEquals(null)).ignoreArgs().passThrough().repeatAny;

        r.replay();
        int[Object] i;
        i[o] = 5;
        int j = i[o];
    }

    unittest {
        mixin(test!("ordering in order"));

        Mocker r = new Mocker();
        auto o = r.mock!(Object);
        r.ordered;
        r.expect(o.toHash).returns(cast(hash_t)5);
        r.expect(o.toString).returns("mow!");

        r.replay();
        o.toHash;
        o.toString;
        r.verify;
    }

    unittest {
        mixin(test!("ordering not in order"));

        Mocker r = new Mocker();
        auto o = r.mock!(Object);
        r.ordered;
        r.expect(o.toHash).returns(5);
        r.expect(o.toString).returns("mow!");

        r.replay();
        try {
            o.toString;
            o.toHash;
            assert (false);
        } catch (ExpectationViolationException) {}
    }

    unittest {
        mixin(test!("ordering interposed"));

        Mocker r = new Mocker();
        auto o = r.mock!(Object);
        r.ordered;
        r.expect(o.toHash).returns(cast(hash_t)5);
        r.expect(o.toString).returns("mow!");
        r.unordered;
        o.toString;

        r.replay();
        o.toHash;
        o.toString;
        o.toString;
    }

    unittest {
        mixin(test!("allowing"));

        Mocker r = new Mocker();
        auto o = r.mock!(Object);
        r.allowing(o.toString).returns("foom?");

        r.replay();
        o.toString;
        o.toString;
        o.toString;
        r.verify;
    }

    unittest {
        mixin(test!("nothing for method to do"));

        try {
            Mocker r = new Mocker();
            auto o = r.mock!(Object);
            r.allowing(o.toString);

            r.replay();
            assert (false, "expected a mocks setup exception");
        } catch (MocksSetupException e) {
        }
    }

    unittest {
        mixin(test!("allow defaults test"));

        Mocker r = new Mocker();
        auto o = r.mock!(Object);
        r.allowDefaults;
        r.allowing(o.toString);

        r.replay();
        assert (o.toString == (char[]).init);
    }

    interface IFace {
        void foo (string s);
    }

    class Smthng : IFace {
        void foo (string s) { }
    }
//
//    unittest {
//        mixin(test!("going through the guts of Smthng"));
//        auto foo = new Smthng();
//        auto guts = *(cast(int**)&foo);
//        auto len = __traits(classInstanceSize, Smthng) / size_t.sizeof; 
//        auto end = guts + len;
//        for (; guts < end; guts++) {
//            writefln("\t%x", *guts);
//        } 
//    }

    unittest {
        mixin(test!("mock interface"));
        auto r = new Mocker;
        IFace o = r.mock!(IFace);
        version(DMocksDebug) writefln("about to call once...");
        o.foo("hallo");
        r.replay;
        version(DMocksDebug) writefln("about to call twice...");
        o.foo("hallo");
        r.verify;
    }
    
    unittest {
        mixin(test!("cast mock to interface"));

        auto r = new Mocker;
        IFace o = r.mock!(Smthng);
        version(DMocksDebug) writefln("about to call once...");
        o.foo("hallo");
        r.replay;
        version(DMocksDebug) writefln("about to call twice...");
        o.foo("hallo");
        r.verify;
    }

    unittest {
        mixin(test!("cast mock to interface"));

        auto r = new Mocker;
        IFace o = r.mock!(Smthng);
        version(DMocksDebug) writefln("about to call once...");
        o.foo("hallo");
        r.replay;
        version(DMocksDebug) writefln("about to call twice...");
        o.foo("hallo");
        r.verify;
    }
    
    interface IRM 
    {
        IM get();
        void set (IM im);
    }
    
    unittest
    {
        mixin(test!("return user-defined type"));

        auto r = new Mocker;
        auto o = r.mock!(IRM);
        auto im = r.mock!(IM);
        version(DMocksDebug) writefln("about to call once...");
        r.expect(o.get).returns(im);
        o.set(im);
        r.replay;
        version(DMocksDebug) writefln("about to call twice...");
        assert (o.get is im, "returned the wrong value");
        o.set(im);
        r.verify;
    }
    
    class HasMember
    {
        int member;
    }
    
    unittest
    {
        mixin(test!("return user-defined type"));

        auto r = new Mocker;
        auto o = r.mock!(HasMember);    	
    }

    class Overloads
    {
        void foo() {}
        void foo(int i) {}
    }
    
    unittest
    {
        mixin(test!("overloaded method"));

        auto r = new Mocker;
        auto o = r.mock!(Overloads);  
        o.foo();
        o.foo(1);
        r.replay;
        o.foo(1);
        o.foo;
        r.verify;
    }
    
    version (DMocksTestStandalone)
    {
        void main () {
            writefln("All tests pass.");
        }
    }
}