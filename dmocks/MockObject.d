module mocks.MockObject;

import mocks.Util;
import mocks.Repository;
import mocks.MethodMock;
import mocks.Model;
import std.stdio;


template Mocked (T) {
    class Mocked : T, IMocked {
        version (MocksTest) pragma (msg, Body!(T)());
        mixin (Body!(T)());
    }
}

string Body (T) () {
    return 
   ` 
        private MockRepository _owner;
        this (MockRepository owner) {
            _owner = owner;
        }
        string GetUnmockedTypeNameString () { return "` ~ T.stringof ~ `"; }
        ` ~  BodyPart!(T, 0)(); 
}

string BodyPart (T, int i) () {
    string ret = Methods!(T, __traits(allMembers, T)[i]);
    static if (i < __traits(allMembers, T).length - 1) {
        ret ~= BodyPart!(T, i + 1)();
    }
    return ret;
}

version (MocksTest) {
    class Templated(T) {}
    interface IM {
        void bar ();
    }

    unittest {
        writef("nontemplated mock unit test...");
        scope(failure) writefln("failed");
        scope(success) writefln("success");
        // We just need to be able to create the object, really.
        new Mocked!(Object)(null);
    }

    unittest {
        writef("templated mock unit test...");
        scope(failure) writefln("failed");
        scope(success) writefln("success");
        new Mocked!(Templated!(int))(null);
    }

    unittest {
        writef("templated mock unit test...");
        scope(failure) writefln("failed");
        scope(success) writefln("success");
        auto r = new MockRepository();
        auto o = new Mocked!(IM)(r);
        o.toString();
    }
    
    unittest {
        writef("execute mock method unit test...");
        scope(failure) writefln("failed");
        scope(success) writefln("success");
        // We just need to be able to create the object, really.
        auto r = new MockRepository();
        auto o = new Mocked!(Object)(r);
        o.toString();
        assert (r.LastCall() !is null);
    }

    void main () {
        writefln("All tests pass.");
    }
}
