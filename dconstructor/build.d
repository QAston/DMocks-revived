/**
  * Currently, this can't build anything unless there is an explicity
  * constructor for that class or for one of its base classes.
  */
module try_no_traits;

import std.traits;

version (BuildTest)
    import std.stdio;

string get_deps(T)() {
    string ret = "return new " ~ T.stringof ~ "(";
    foreach (i, U; ParameterTypeTuple!(T._ctor)) {
        static assert (
            is (U == class) ||
            is (U == interface),
            "type " ~ T.stringof ~ " depends on type " ~ U.stringof
                ~ ", which is not a class or an interface.");
        ret ~= `build!(` ~ U.stringof ~ `)`;
        static if (i < (ParameterTypeTuple!(T._ctor)).length - 1) {
            ret ~= ", ";
        }
    }
    ret ~= ");";
    return ret;
}

class Builder {
    public T build (T) () {
        mixin (get_deps!(T)());
    }
}

version (BuildTest) {
    class Foo {
        int i;
        this () {}
    }

    class Bar : Foo {}

    class Frumious {
        public Bar kid;
        this (Bar bar) { kid = bar; }
    }

    unittest {
        auto b = new Builder();
        auto o = b.build!(Foo)();
        auto p = b.build!(Bar)();
        assert (o !is null);
    }

    unittest {
        auto b = new Builder();
        auto o = b.build!(Frumious)();
        assert (o !is null);
        assert (o.kid !is null);
    }

    void main () {}
}
