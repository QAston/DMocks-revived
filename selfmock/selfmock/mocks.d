module selfmock.mocks;

import selfmock.mockobject;
import selfmock.repository; 
import selfmock.util;
import selfmock.call;
import tango.core.Variant;
import tango.io.Stdout;

version (MocksDebug) import tango.io.Stdout;
version (MocksTest) import tango.io.Stdout;

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

        void add (T)(T mocked)
        {
            Mocked actual = cast(Mocked)actual;
            if (actual is null)
            {
                throw new InvalidOperationException("Did you try to add something to the mocker that isn't a mocked object?");
            }
            actual.caller = new Caller(_repository);
        }

        /** 
         * Stop setting up expected calls. Any calls after this point will
         * be verified against the expectations set up before calling Replay.
         */
        void replay () 
        {
            _repository.replay;
        }

        /**
         * Record method calls starting at this point. These calls are not
         * checked against existing expectations; they create new expectations.
         */
        void record () 
        {
            _repository.backToRecord;
        }

        /**
         * Check to see if there are any expected calls that haven't been
         * matched with a real call. Throws an ExpectationViolationException
         * if there are any outstanding expectations.
         */
        void verify () 
        {
            _repository.verify;
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
            _repository.ordered = true;
        }

        void unordered () 
        {
            _repository.ordered = false;
        }

        /** Get a mock object of the given type. */
        void register (Mocked o)
        {
            throw new InvalidOperationException();
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
        ExternalCall expect (T) (T ignored) 
        {
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
        ExternalCall lastCall () 
        {
            return new ExternalCall(_repository.lastCall);
        }

        /**
         * Set up a result for a method, but without any backend accounting for it.
         * Things where you want to allow this method to be called, but you aren't
         * currently testing for it.
         */
        ExternalCall allowing (T) (T ignored) 
        {
            return lastCall.repeatAny;
        }

        /** Ditto */
        ExternalCall allowing (T = void) () 
        {
            return lastCall.repeatAny();
        }

        /**
         * Do not require explicit return values for expectations. If no return
         * value is set, return the default value (null / 0 / nan, in most
         * cases). By default, if no return value, exception, delegate, or
         * passthrough option is set, an exception will be thrown.
         */
        void allowDefaults () 
        {
            _repository.allowDefaults = true;
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
       _call.ignoreArguments = true;
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
       _call.repeat(Interval(min, max));
       return this;
   }

   /**
    * This call must be repeated exactly i times.
    */
   ExternalCall repeat (int i) 
   {
       _call.repeat(Interval(i, i));
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
       _call.action.action = a;
       return this;
   }

   /**
    * When the method is called, throw the given exception. If there are any
    * actions specified (via the action method), they will not be executed.
    */
   ExternalCall throws (Exception e) 
   {
       _call.action.toThrow = e;
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
       _call.action.passThrough = true;
       return this;
   }
}

version (MocksTest) 
{
//    void main(){}
}
