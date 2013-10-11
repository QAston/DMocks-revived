module dmocks.object_mock;

import dmocks.util;
import dmocks.caller;
import dmocks.method_mock;
import dmocks.model;
import std.traits;
import std.typecons;

class Mocked (T) : T, IMocked 
{
    /+version (DMocksDebug) 
    {
        pragma (msg, T.stringof);
        pragma (msg, Body!(T));
    }+/

    static if(__traits(hasMember, T,"__ctor"))
        this(ARGS...)(ARGS args)
        {
            super(args);
        }

    public Caller _owner;
    version (DMocksDebug)
        public string _body = Body!(T, true);
    mixin ((Body!(T, true)));
}

class MockedFinal(T) : IMocked
{
    public T mocked___;
    public Caller _owner;

    static if (__traits(isFinalClass, T))
        alias T MOCKED_TYPE;
    else
        alias WhiteHole!T MOCKED_TYPE;

    static if(__traits(hasMember, T,"__ctor"))
        this(ARGS...)(ARGS args)
        {
            mocked___ = new MOCKED_TYPE(args);
        }
    else
    {
        this()
        {
            mocked___ = new MOCKED_TYPE;
        }
    }

    auto ref opDispatch(string name, Args...)(auto ref Args params)
    {
        mixin("alias mocked___."~name~"!Args self;");
        auto del = delegate ReturnType!(self) (Args args){ mixin(BuildForwardCall!("mocked___", name ~ "!Args")()); };
        return mockMethodCall!(self, name, T)(mocked___, _owner, del, params);
    }

    mixin ((Body!(T, false)));
}

auto ref mockMethodCall(alias self, string name, T, OBJ, CALLER, FORWARD, Args...)(OBJ obj, CALLER _owner, FORWARD forwardCall, auto ref Args params)
{
    debugLog("checking _owner...");
    if (_owner is null) 
    {
        assert(false, "owner cannot be null! Contact the stupid mocks developer.");
    }
    dmocks.action.ReturnOrPass!(ReturnType!(typeof(self))) rope;
    void setRope()
    {
        // CAST CHEATS here - can't operate on const/shared refs without cheating on typesystem. this makes these calls threadunsafe
        rope = (cast(Caller)_owner).Call!(ReturnType!(typeof(self)), ParameterTypeTuple!(self))(cast(IMocked)obj, __traits(identifier, T) ~ "." ~ name, formatAllAttributes!(typeof(self)), params);
    }
    static if (functionAttributes!(typeof(self)) & FunctionAttribute.nothrow_)
    {
        try {
            setRope();
        }
        catch (Exception ex)
        {
            assert(false, "Throwing in a mock of a nothrow method!");
        }
    }
    else
    {
        setRope();
    }
    if (rope.pass)
    {
        return forwardCall(params);
    }
    else
    {
        static if (!is (ReturnType!(typeof(self)) == void))
        {
            return rope.value;
        }
    }
}

template Body (T, bool INHERITANCE) 
{
    enum Body = BodyPart!(T, 0);

    template BodyPart (T, int i)
    {
        static if (i < __traits(allMembers, T).length) 
        {
            //pragma(msg, __traits(allMembers, T)[i]);
            enum BodyPart = Methods!(T, INHERITANCE, __traits(allMembers, T)[i]) ~ BodyPart!(T, i + 1);
        }
        else 
        {
            enum BodyPart = ``;
        }
    }
}

