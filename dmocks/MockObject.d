module dmocks.MockObject;

import dmocks.Util;
import dmocks.Repository;
import dmocks.MethodMock;
import dmocks.Model;
import std.stdio;


template Mocked (T) {
    class Mocked : T, IMocked {
        version (MocksTest) {
            pragma (msg, T.stringof);
            pragma (msg, Body!(T)());
        }
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
    class ConstructorArg {
        this (int i) {}
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
        auto r = new MockRepository();
        auto o = new Mocked!(Object)(r);
        o.toString();
        assert (r.LastCall() !is null);
    }
    
    /*
    unittest {
        writef("constructor argument unit test...");
        scope(failure) writefln("failed");
        scope(success) writefln("success");
        auto r = new MockRepository();
        auto o = new Mocked!(ConstructorArg)(r);
        o.toString();
        assert (r.LastCall() !is null);
    }
    */

    void main () {
        writefln("All tests pass.");
    }
}
