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
        pragma (msg, Body!(T)());
    }
    
    mixin ((Body!(T)()));
}

string Body (T) () {
    return 
   ` 
        public Caller _owner;
        `
            ~ Constructor!(T)()
            ~  BodyPart!(T, 0)(); 
}

string BodyPart (T, int i) ()
{
	pragma(msg, __traits(allMembers, T)[i]);
    static if (i < __traits(allMembers, T).length - 1) 
    {
    	return Methods!(T, __traits(allMembers, T)[i]) ~ BodyPart!(T, i + 1)();
    }
    else 
    {
    	return Methods!(T, __traits(allMembers, T)[i]);
    }
}

