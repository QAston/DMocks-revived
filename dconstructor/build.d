/**
  * Currently, this can't build anything unless there is an explicity
  * constructor for that class or for one of its base classes.
  * I can change that for d2, but not d1.
  */
module build;

version (Tango) {
    import tango.core.Traits;
    alias char[] string;
    template ParameterTypeTuple(alias dg) {
        alias ParameterTupleOf!(dg) ParameterTypeTuple;
    }
} else {
    import std.traits;
}

string get_deps(T)() {
    static if (is (typeof (new T) == T)) {
        return `return new ` ~ T.stringof ~ `();`;
    } else {
        return `return new ` ~ T.stringof ~ `(` ~
                get_deps_impl!(T, 0)()
                ~ `);`;
    }
}

string get_deps_impl(T, int i)() {
    static if (i < ParameterTypeTuple!(T._ctor).length) {
        string ret = `parent.get!(` ~ ParameterTypeTuple!(T._ctor)[i].stringof
                ~ `)`;
        static if (i < ParameterTypeTuple!(T._ctor).length - 1) 
            ret ~= `,`;
        return ret ~ get_deps_impl!(T, i + 1)();
    } else {
        return ``;
    }
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
        static assert (is (TImpl : TVisible),
                "binding failure: cannot convert type " ~ TImpl.stringof
                ~ " to type " ~ TVisible.stringof);
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
        public Foo kid;
        this (Foo bar) { kid = bar; }
    }

    unittest {
        auto b = new Builder();
        auto o = b.get!(Object)();
        assert (o !is null);
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

    /*
    unittest {
        // This shouldn't compile. The body of this test will be commented
        // out in the general case for that reason.
        auto b = new Builder();
        b.bind!(Frumious, Foo);
    }
    */

    unittest {
        auto b = new Builder();
        b.bind!(IFrumious, Frumious)();
        b.bind!(Foo, Bar)();
        auto o = b.get!(IFrumious)();
        assert (o !is null);
        auto frum = cast(Frumious)o;
        assert (frum !is null);
        assert (frum.kid !is null);
        assert (cast(Bar)frum.kid !is null);
    }

    void main () {}
}
