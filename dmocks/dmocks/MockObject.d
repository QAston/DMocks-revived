module dmocks.MockObject;

import dmocks.Util;
import dmocks.Caller;
import dmocks.MethodMock;
import dmocks.Model;
import std.traits;


class Mocked (T) : T, IMocked 
{
    version (MocksDebug) 
    {
        pragma (msg, T.stringof);
        pragma (msg, Body!(T));
    }
    
    mixin ((Body!(T)));
}

template Body (T) 
{
    enum Body = 
   ` 
        public Caller _owner;
        `
            ~ Constructor!(T)()
            ~  BodyPart!(T, 0); 
}

template BodyPart (T, int i)
{
    static if (i < __traits(allMembers, T).length) 
    {
    	//pragma(msg, __traits(allMembers, T)[i]);
    	enum BodyPart = Methods!(T, __traits(allMembers, T)[i]) ~ BodyPart!(T, i + 1)();
    }
    else 
    {
    	enum BodyPart = ``;
    }
}

