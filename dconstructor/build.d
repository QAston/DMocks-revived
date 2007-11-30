/**
  * Currently, this can't build anything unless there is an explicity
  * constructor for that class or for one of its base classes.
  */
module build_simple;

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

        ret ~= `parent.get!(` ~ U.stringof ~ `)`;
        static if (i < (ParameterTypeTuple!(T._ctor)).length - 1) {
            ret ~= ", ";
        }
    }
    ret ~= ");";
    return ret;
}

interface IObjectBuilder {
    Object build (Builder parent);
}

class ObjectBuilder(T) : IObjectBuilder {
    Object build (Builder parent) {
        static if (is (T == class)) {
            mixin (get_deps!(T)());
        } else {
            return null;
        }
    }
}

class Builder {
    IObjectBuilder[string] builders;
    T get(T)() {
        if (T.stringof in builders) {
            return cast(T)(builders[T.stringof].build(this));
        } else {
            return cast(T)(new ObjectBuilder!(T)()).build(this);
        }
    }

    Builder bind (TVisible, TImpl)() {
        builders[TVisible.stringof] = new ObjectBuilder!(TImpl)();
        return this;
    }
}

version (BuildTest) {
    class Foo {
        int i;
        this () {}
    }

    class Bar : Foo {}

    interface IFrumious {}

    class Frumious : IFrumious {
        public Bar kid;
        this (Bar bar) { kid = bar; }
    }

    unittest {
        auto b = new Builder();
        auto o = b.get!(Foo)();
        auto p = b.get!(Bar)();
        assert (o !is null);
    }

    unittest {
        auto b = new Builder();
        auto o = b.get!(Frumious)();
        assert (o !is null);
        assert (o.kid !is null);
    }

    unittest {
        auto b = new Builder();
        b.bind!(IFrumious, Frumious)();
        auto o = b.get!(IFrumious)();
        assert (o !is null);
        auto frum = cast(Frumious)o;
        assert (frum !is null);
        assert (frum.kid !is null);
    }

    void main () {}
}

