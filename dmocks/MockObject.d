module dmocks.MockObject;

import dmocks.Util;
import dmocks.Repository;
import dmocks.MethodMock;
import dmocks.Model;
import std.stdio;


template Mocked (T) {
    class Mocked : T, IMocked {
        version (MocksDebug) {
            pragma (msg, T.stringof);
            pragma (msg, Body!(T)());
        }
        mixin (Body!(T)());
    }
}

string Body (T) () {
    return 
   ` 
        public MockRepository _owner;
        `
            ~ Constructor!(T)()
            ~  BodyPart!(T, 0)(); 
}

string BodyPart (T, int i) () {
    string ret = Methods!(T, __traits(allMembers, T)[i]);
    static if (i < __traits(allMembers, T).length - 1) {
        ret ~= BodyPart!(T, i + 1)();
    }
    return ret;
}

