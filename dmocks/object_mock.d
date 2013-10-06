module dmocks.object_mock;

import dmocks.util;
import dmocks.caller;
import dmocks.method_mock;
import dmocks.model;
import std.traits;

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
        public string _body = Body!(T);
    
    mixin ((Body!(T)));
}

template Body (T) 
{
    enum Body = BodyPart!(T, 0);
}

template BodyPart (T, int i)
{
    static if (i < __traits(allMembers, T).length) 
    {
        //pragma(msg, __traits(allMembers, T)[i]);
        enum BodyPart = Methods!(T, __traits(allMembers, T)[i]) ~ BodyPart!(T, i + 1);
    }
    else 
    {
        enum BodyPart = ``;
    }
}

