module dmocks.mocks;

public import dmocks.object_mock;
public import dmocks.dynamic;
import dmocks.factory;
import dmocks.repository; 
import dmocks.util;
import std.stdio;
import std.typecons;

/++
    A class through which one creates mock objects and manages expectations about calls to their methods.
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
        * Start setting up expectations. Method calls on mock object will create (and record) new expectations. 
        * You can just call methods directly or use Mocker.expect/lastCall to customize expectations.
        */
        void record () 
        {
            _repository.BackToRecord();
        }

        /** 
         * Stop setting up expectations. Any method calls after this point will
         * be matched against the expectations set up before calling replay and
         * expectations' actions will be executed.
         */
        void replay () 
        {
            _repository.Replay();
        }

        /**
         * Verifies that certain expectation requirements were satisfied during replay phase.
         *
         * checkUnmatchedExpectations - Check to see if there are any expectations that haven't been
         * matched to a call. 
         *
         * checkUnexpectedCalls - Check to see if there are any calls that there were no
         * expectation set up for.
         *
         * Throws an ExpectationViolationException if those issues occur.
         */
        void verify (bool checkUnmatchedExpectations = true, bool checkUnexpectedCalls = true) 
        {
            _repository.Verify(checkUnmatchedExpectations, checkUnexpectedCalls);
        }

        /**
         * By default, all expectations are unordered. If I want to require that
         * one call happen immediately after another, I call Mocker.ordered, make
         * those expectations, and call Mocker.unordered to avoid requiring a
         * particular order afterward.
         */
        void ordered () 
        {
            _repository.Ordered(true);
        }

        void unordered () 
        {
            _repository.Ordered(false);
        }

        /** 
         * Disables exceptions thrown on unexpected calls while in Replay phase
         * Unexpected methods called will return default value of their type
         *
         * Useful when using mocks as stubs or when you don't want exceptions 
         * to change flow of execution of your tests, for example when using nothrow functions
         *
         * Default: false
         */
        void allowUnexpectedCalls(bool allow)
        {
            _repository.AllowUnexpected(allow);
        }

        /** 
         * Creates a mock object for a given type.
         *
         * Calls matching expectations with passThrough enabled
         * will call equivalent methods of T object constructed with args.
         *
         * Type returned is binarily compatibile with given type
         * All virtual calls made to the object will be mocked
         * Final and template calls will not be mocked
         *
         * Use this type of mock to substitute interface/class objects
         */
        T mock (T, CONSTRUCTOR_ARGS...) (CONSTRUCTOR_ARGS args) 
        {
            static assert (is(T == class) || is(T == interface), 
                           "only classes and interfaces can be mocked using this type of mock");
            return dmocks.factory.mock!(T)(_repository, args);
        }

        /** 
         * Creates a mock object for a given type.
         *
         * Calls matching expectations with passThrough enabled
         * will call equivalent methods of T object constructed with args.
         *
         * Type of the mock is incompatibile with given type
         * Final, template and virtual methods will be mocked
         *
         * Use this type of mock to substitute template parameters
         */
        MockedFinal!T mockFinal(T, CONSTRUCTOR_ARGS...) (CONSTRUCTOR_ARGS args)
        {
            static assert (is(T == class) || is(T == interface), 
                           "only classes and interfaces can be mocked using this type of mock");
            return dmocks.factory.mockFinal!(T)(_repository, args);
        }

        /** 
         * Creates a mock object for a given type.
         *
         * Calls matching expectations with passThrough enabled
         * will call equivalent methods of "to" object.
         *
         * Type of the mock is incompatibile with given type
         * Final, template and virtual methods will be mocked
         *
         * Use this type of mock to substitute template parameters
         */
        MockedFinal!T mockFinalPassTo(T) (T to)
        {
            static assert (is(T == class) || is(T == interface), 
                           "only classes and interfaces can be mocked using this type of mock");
            return dmocks.factory.mockFinalPassTo!(T)(_repository, to);
        }

        /** 
         * Creates a mock object for a given type.
         *
         * Calls matching expectations with passThrough enabled
         * will call equivalent methods of T object constructed with args.
         *
         * Type of the mock is incompatibile with given type
         * Final, template and virtual methods will be mocked
         *
         * Use this type of mock to substitute template parameters
         */
        MockedStruct!T mockStruct(T, CONSTRUCTOR_ARGS...) (CONSTRUCTOR_ARGS args)
        {
            static assert (is(T == struct), 
                           "only structs can be mocked using this type of mock");
            return dmocks.factory.mockStruct!(T)(_repository, args);
        }

        /** 
         * Creates a mock object for a given type.
         *
         * Calls matching expectations with passThrough enabled
         * will call equivalent methods of "to" object.
         *
         * Type of the mock is incompatibile with given type
         * Final, template and virtual methods will be mocked
         *
         * Use this type of mock to substitute template parameters
         */
        MockedStruct!T mockStructPassTo(T) (T to)
        {
            static assert (is(T == struct), 
                           "only structs can be mocked using this type of mock");
            return dmocks.factory.mockStructPassTo!(T)(_repository, to);
        }

        /**
         * Record new expectation that will exactly match method called in methodCall argument
         *
         * Returns an object that allows you to set various properties of the expectation,
         * such as return value, number of repetitions or matching options.
         *
         * Examples:
         * ---
         * Mocker m = new Mocker;
         * Object o = m.Mock!(Object);
         * m.expect(o.toString).returns("hello?");
         * ---
         */
        ExpectationSetup expect (T) (lazy T methodCall) {
            auto pre = _repository.LastRecordedCallExpectation();
            methodCall();
            auto post = _repository.LastRecordedCallExpectation();
            if (pre is post)
                throw new InvalidOperationException("mocks.Mocker.expect: you did not call a method mocked by the mocker!");
            return lastCall();
        }

        /**
         * Returns ExpectationSetup object for most recent call on a method of a mock object.
         *
         * This object allows you to set various properties of the expectation,
         * such as return value, number of repetitions or matching options.
         *
         * Examples:
         * ---
         * Mocker m = new Mocker;
         * Object o = m.Mock!(Object);
         * o.toString;
         * m.LastCall().returns("hello?");
         * ---
         */
        ExpectationSetup lastCall () {
            return new ExpectationSetup(_repository.LastRecordedCallExpectation(), _repository.LastRecordedCall());
        }

        /**
         * Set up a result for a method, but without any backend accounting for it.
         * Things where you want to allow this method to be called, but you aren't
         * currently testing for it.
         */
        ExpectationSetup allowing (T) (T ignored) {
            return lastCall().repeatAny;
        }

        /** Ditto */
        ExpectationSetup allowing (T = void) () {
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
   An ExpectationSetup object allows you to set various properties of the expectation,
   such as: 
    - what action should be taken when method matching expectation is called
        - return value, action to call, exception to throw, etc

   Examples:
   ---
   Mocker m = new Mocker;
   Object o = m.Mock!(Object);
   o.toString;
   m.LastCall().returns("Are you still there?").repeat(1, 12);
   ---
++/
public class ExpectationSetup 
{
    import dmocks.arguments;
    import dmocks.expectation;
    import dmocks.dynamic;
    import dmocks.qualifiers;
    import dmocks.call;

    private CallExpectation _expectation;

    private Call _setUpCall;

   this (CallExpectation expectation, Call setUpCall) 
   {
       assert (expectation !is null, "can't create an ExpectationSetup if expectation is null");
       assert (setUpCall !is null, "can't create an ExpectationSetup if setUpCall is null");
       _expectation = expectation;
       _setUpCall = setUpCall;
   }

   /**
    * Ignore method argument values in matching calls to this expectation.
    */
   ExpectationSetup ignoreArgs () 
   {
       _expectation.arguments = new ArgumentsTypeMatch(_setUpCall.arguments, (Dynamic a, Dynamic b)=>true);
       return this;
   }

   /**
    * Allow providing custom argument comparator for matching calls to this expectation.
    */
   ExpectationSetup customArgsComparator (bool delegate(Dynamic expected, Dynamic provided) del) 
   {
       _expectation.arguments = new ArgumentsTypeMatch(_setUpCall.arguments, del);
       return this;
   }

   /**
    * This expectation must match to at least min number of calls and at most to max number of calls.
    */
   ExpectationSetup repeat (int min, int max) 
   {
       if (min > max) 
       {
           throw new InvalidOperationException("The specified range is invalid.");
       }
        _expectation.repeatInterval = Interval(min, max);
       return this;
   }

   /**
    * This expectation will match exactly i times.
    */
   ExpectationSetup repeat (int i) 
   {
       repeat(i,i);
       return this;
   }

   /**
    * This expectation will match to any number of calls.
    */
   ExpectationSetup repeatAny () 
   {
       return repeat(0, int.max);
   }

   /**
    * When the method which matches this expectation is called execute the
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
   ExpectationSetup action (T, U...)(T delegate(U) action) 
   {
       _expectation.action.action = dynamic(action);
       return this;
   }

   // TODO: how can I get validation here that the type you're
   // inserting is the type expected before trying to execute it?
   // Not really an issue, since it'd be revealed in the space
   // of a single test.
   /**
    * Set the value to return when method matching this expectation is called on a mock object.
    * Params:
    *     value = the value to return
    */
   ExpectationSetup returns (T)(T value) 
   {
       _expectation.action.returnValue(dynamic(value));
       return this;
   }

   /**
    * When the method which matches this expectation is called,
    * throw the given exception. If there are any
    * actions specified (via the action method), they will not be executed.
    */
   ExpectationSetup throws (Exception e) 
   {
       _expectation.action.toThrow = e;
       return this;
   }

   /**
    * Instead of returning or throwing a given value, pass the call through to
    * the mocked type object. For mock***PassTo(obj) obj has to be valid for this to work.
    * 
    * This is useful for example for enabling use of mock object in hashmaps by enabling 
    * toHash and opEquals of your class.
    */
   ExpectationSetup passThrough () 
   {
       _expectation.action.passThrough = true;
       return this;
   }
}

/// backward compatibility alias
alias ExpectationSetup ExternalCall;

version (DMocksTest) {
    
    class Templated(T) {}
    interface IM {
        void bar ();
    }

    class ConstructorArg {
        this (int i) { a = i;}
        int a;
        int getA()
        {
            return a;
        }
    }

    class SimpleObject {
        this()
        {
        }
        void print()
        {
            writeln(toString());
        }
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
        auto r = new Mocker();
        auto o = r.mock!(Object);
        o.toString();
    }

    unittest {
        mixin(test!("constructor argument"));
        auto r = new Mocker();
        auto o = r.mock!(ConstructorArg)(4);
    }

    unittest {
        mixin(test!("lastCall"));
        Mocker m = new Mocker();
        SimpleObject o = m.mock!(SimpleObject);
        o.print;
        auto e = m.lastCall;

        assert (e !is null);
    }

    unittest {
        mixin(test!("return a value"));

        Mocker m = new Mocker();
        Object o = m.mock!(Object);
        o.toString;
        auto e = m.lastCall;

        assert (e !is null);
        e.returns("frobnitz");
    }

    unittest {
        mixin(test!("unexpected call"));

        Mocker m = new Mocker();
        Object o = m.mock!(Object);
        m.replay();
        try {
            o.toString;
            assert (false, "expected exception not thrown");
        } catch (ExpectationViolationException) {}
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
        auto o = r.mock!(SimpleObject);

        //o.print;
        r.expect(o.print).action({ calledPayload = true; });
        r.replay();

        o.print;
        assert (calledPayload);
    }

    unittest {
        mixin(test!("exception payload"));

        Mocker r = new Mocker();
        auto o = r.mock!(SimpleObject);

        string msg = "divide by cucumber error";
        o.print;
        r.lastCall().throws(new Exception(msg));
        r.replay();

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
        mixin(test!("class with constructor init check"));
        auto r = new Mocker();
        auto o = r.mock!(ConstructorArg)(4);
        o.getA();
        r.lastCall().passThrough();
        r.replay();
        assert (4 == o.getA());
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
        auto o = r.mock!(SimpleObject);
        r.ordered;
        r.expect(o.toHash).returns(cast(hash_t)5);
        r.expect(o.toString).returns("mow!");
        r.unordered;
        o.print;

        r.replay();
        o.toHash;
        o.print;
        o.toString;
    }

    unittest {
        mixin(test!("allow unexpected"));

        Mocker r = new Mocker();
        auto o = r.mock!(Object);
        r.ordered;
        r.allowUnexpectedCalls(true);
        r.expect(o.toString).returns("mow!");
        r.replay();
        o.toHash; // unexpected tohash calls
        o.toString;
        o.toHash;
        try {
            r.verify(false, true);
            assert (false, "expected a mocks setup exception");
        } catch (ExpectationViolationException e) {
        }

        r.verify(true, false);
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
        debugLog("about to call once...");
        o.foo("hallo");
        r.replay;
        debugLog("about to call twice...");
        o.foo("hallo");
        r.verify;
    }
    
    unittest {
        mixin(test!("cast mock to interface"));

        auto r = new Mocker;
        IFace o = r.mock!(Smthng);
        debugLog("about to call once...");
        o.foo("hallo");
        r.replay;
        debugLog("about to call twice...");
        o.foo("hallo");
        r.verify;
    }

    unittest {
        mixin(test!("cast mock to interface"));

        auto r = new Mocker;
        IFace o = r.mock!(Smthng);
        debugLog("about to call once...");
        o.foo("hallo");
        r.replay;
        debugLog("about to call twice...");
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
        debugLog("about to call once...");
        r.expect(o.get).returns(im);
        o.set(im);
        r.replay;
        debugLog("about to call twice...");
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

    class Qualifiers {
        int make() shared
        {
            return 0;
        }

        int make() const
        {
            return 1;
        }

        int make() shared const
        {
            return 2;
        }

        int make()
        {
            return 3;
        }

        int make() immutable
        {
            return 4;
        }
    }

    unittest
    {
        mixin(test!("overloaded method qualifiers"));

        {
            auto r = new Mocker;
            auto s = r.mock!(shared(Qualifiers));
            auto sc = cast(shared const) s;

            r.expect(s.make).passThrough;
            r.expect(sc.make).passThrough; 
            r.replay;

            assert(s.make == 0);
            assert(sc.make == 2);

            r.verify;
        }

        {
            auto r = new Mocker;
            auto m = r.mock!(Qualifiers);
            auto c = cast(const) m;
            auto i = cast(immutable) m;

            r.expect(i.make).passThrough;
            r.expect(m.make).passThrough; 
            r.expect(c.make).passThrough; 
            r.replay;

            assert(i.make == 4);
            assert(m.make == 3);
            assert(c.make == 1);

            r.verify;
        }

        {
            auto r = new Mocker;
            auto m = r.mock!(Qualifiers);
            auto c = cast(const) m;
            auto i = cast(immutable) m;

            r.expect(i.make).passThrough;
            r.expect(m.make).passThrough; 
            r.expect(m.make).passThrough; 
            r.replay;

            assert(i.make == 4);
            assert(m.make == 3);
            try
            {
                assert(c.make == 1);
                assert(false, "exception not thrown");
            }
            catch (ExpectationViolationException e) {
            }

        }
    }


    interface VirtualFinal
    {
        int makeVir();
    }

    unittest {
        import std.exception;
        mixin(test!("final mock of virtual methods"));

        auto r = new Mocker;
        auto o = r.mockFinal!(VirtualFinal);  
        r.expect(o.makeVir()).returns(5);
        r.replay;
        assert(o.makeVir == 5);
    }

    class MakeAbstract
    {
        int con;
        this(int con)
        {
            this.con = con;
        }
        abstract int abs();

        int concrete()
        {
            return con;
        }
    }

    unittest {
        mixin(test!("final mock of abstract methods"));

        auto r = new Mocker;
        auto o = r.mockFinal!(MakeAbstract)(6);
        r.expect(o.concrete()).passThrough;
        r.replay;
        assert(o.concrete == 6);
        r.verify;
    }

    class FinalMethods : VirtualFinal {
        final int make()
        {
            return 0;
        }
        final int make(int i)
        {
            return 2;
        }
        int makeVir()
        {
            return 5;
        }
    }

    unittest {
        mixin(test!("final methods"));

        auto r = new Mocker;
        auto o = r.mockFinal!(FinalMethods);  
        r.expect(o.make()).passThrough;
        r.expect(o.make(1)).passThrough; 
        r.replay;
        static assert(!is(typeof(o)==FinalMethods));
        assert(o.make == 0);
        assert(o.make(1) == 2);
        r.verify;
    }

    final class FinalClass
    {
        int fortyTwo()
        {
            return 42;
        }
    }

    unittest {
        mixin(test!("final class"));

        auto r = new Mocker;
        auto o = r.mockFinal!(FinalClass);  
        r.expect(o.fortyTwo()).passThrough;
        r.replay;
        assert(o.fortyTwo == 42);
        r.verify;
    }

    unittest {
        mixin(test!("final class with no underlying object"));

        auto r = new Mocker;
        auto o = r.mockFinalPassTo!(FinalClass)(null);  
        r.expect(o.fortyTwo()).returns(43);
        r.replay;
        assert(o.fortyTwo == 43);
        r.verify;
    }

    class TemplateMethods
    {
        string get(T)(T t)
        {
            import std.traits;
            return fullyQualifiedName!T;
        }

        int getSomethings(T...)(T t)
        {
            return T.length;
        }
    }

    unittest {
        mixin(test!("template methods"));

        auto r = new Mocker;
        auto o = r.mockFinal!(TemplateMethods);  
        r.expect(o.get(1)).passThrough;
        r.expect(o.getSomethings(1, 2, 3)).passThrough;
        r.replay;
        assert(o.get(1) == "int");
        auto tm = new TemplateMethods();
        assert(o.getSomethings(1, 2, 3) == 3);
        r.verify;
    }

    struct Struct {
        int get()
        {
            return 1;
        }
    }

    unittest {
        mixin(test!("struct"));

        auto r = new Mocker;
        auto o = r.mockStruct!(Struct);  
        r.expect(o.get).passThrough;
        r.replay;
        assert(o.get() == 1);
        r.verify;
    }

    struct StructWithFields {
        int field;
        int get()
        {
            return field;
        }
    }

    unittest {
        mixin(test!("struct with fields"));

        auto r = new Mocker;
        auto o = r.mockStruct!(StructWithFields)(5);  
        r.expect(o.get).passThrough;
        r.replay;
        assert(o.get() == 5);
        r.verify;
    }

    struct StructWithConstructor {
        int field;
        this(int i)
        {
            field = i;
        }
        int get()
        {
            return field;
        }
    }

    unittest {
        mixin(test!("struct with fields"));

        auto r = new Mocker;
        auto o = r.mockStruct!(StructWithConstructor)(5);  
        r.expect(o.get).passThrough;
        r.replay;
        assert(o.get() == 5);
        r.verify;
    }

    unittest {
        mixin(test!("struct with no underlying object"));

        auto r = new Mocker;
        auto o = r.mockStructPassTo(StructWithConstructor.init);  
        r.expect(o.get).returns(6);
        r.replay;
        assert(o.get() == 6);
        r.verify;
    }

    class Dependency
    {
        private int[] arr = [1, 2];
        private int index = 0;
        public int foo() { return arr[index++]; }
    }

    unittest
    {
        mixin(test!("returning different values on the same expectation"));
        auto mocker = new Mocker;
        auto dependency = mocker.mock!Dependency;

        //mocker.ordered;
        mocker.expect(dependency.foo).returns(1);
        mocker.expect(dependency.foo).returns(2);
        mocker.replay;
        assert(dependency.foo == 1);
        assert(dependency.foo == 2);
        mocker.verify;
    }

    class TakesFloat
    {
        public void foo(float a) {  }
    }

    unittest
    {
        import std.math;
        mixin(test!("customArgsComparator"));
        auto mocker = new Mocker;
        auto dependency = mocker.mock!TakesFloat;
        mocker.expect(dependency.foo(1.0f)).customArgsComparator(
             (Dynamic a, Dynamic b) 
             { 
                 if (a.type == typeid(float))
                    { return ( abs(a.get!float() - b.get!float()) < 0.1f); } 
                 return true;
             }).repeat(2);
        mocker.replay;

        // custom comparison example - treat similar floats as equals
        dependency.foo(1.01);
        dependency.foo(1.02);
    }

    class Property
    {
        private int _foo;
        @property int foo()
        {
            return _foo;
        }

        @property void foo(int i)
        {
            _foo = i;
        }

        @property T foot(T)()
        {
            static if (is(T == int))
            {
                return _foo;
            }
            else
                return T.init;
        }

        @property void foot(T)(T i)
        {
            static if (is(T == int))
            {
                _foo = i;
            }
        }
    }

    unittest
    {
        auto mocker = new Mocker;
        auto dependency = mocker.mockFinal!Property;
        mocker.ordered;
        mocker.expect(dependency.foo = 2).ignoreArgs.passThrough;
        mocker.expect(dependency.foo).passThrough;
        //TODO: these 2 don't work yet
        //mocker.expect(dependency.foot!int = 5).passThrough;
        //mocker.expect(dependency.foot!int).passThrough;
        mocker.replay;

        dependency.foo = 7;
        assert(dependency.foo ==7);
        //dependency.foot!int = 3;
        //assert(dependency.foot!int == 3);
        mocker.verify;
    }

    class Foo {
        int x;
        string s;

        this(int x, string s) {
            this.x = x;
            this.s = s;
        }
    }

    class Varargs
    {
        import core.vararg;
        
        int varDyn(int first, ...)
        {
            return vvarDyn(first, _arguments, _argptr);
        }

        // idiom from C - for every dynamic vararg function there has to be vfunction(Args, TypeInfo[] arguments, va_list argptr)
        // otherwise passThrough is impossible
        int vvarDyn(int first, TypeInfo[] arguments, va_list argptr)
        {
            assert(arguments[0] == typeid(int));
            int second = va_arg!int(argptr);
            return first + second;
        }

        /*TODO - typesafe variadic methods do not work yet
        int varArray(int first, int[] next...)
        {
            return first + next[0];
        }

        int varClass(int first, Foo f...)
        {
            return first + f.x;
        }*/
    }

    unittest 
    {
        
        import core.vararg;

        auto mocker = new Mocker;
        auto dependency = mocker.mock!Varargs;
        mocker.record;
        // we only specify non-vararg arguments in setup because typeunsafe varargs can't have meaningful operations on them (like comparision, etc)
        mocker.expect(dependency.varDyn(42)).passThrough; // passThrough works with typeunsafe vararg functions only when v[funcname](Args, Typeinfo[], va_list) function variant is provided
        mocker.replay;

        assert(dependency.varDyn(42, 5) == 47);
    }

    version (DMocksTestStandalone)
    {
        void main () {
            writefln("All tests pass.");
        }
    }
}
