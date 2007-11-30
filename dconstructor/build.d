/**
  * Currently, this can't build anything unless there is an explicity
  * constructor for that class or for one of its base classes.
  * I can change that for d2, but not d1.
  */
module dconstructor.build;

private {
    import dconstructor.singleton;
    import dconstructor.object_builder;
    import dconstructor.exception;
    import dconstructor.util;
}

interface IObjectBuilder {
    Object build (Builder parent);
}

class ObjectBuilder(T) : IObjectBuilder {
    Object build (Builder parent) {
        static if (is (T == class)) {
            mixin (get_deps!(T)());
        } else {
            throw new BindingException("no bindings exist for type " 
                    ~ T.stringof);
        }
    }
}

class StaticBuilder : IObjectBuilder {
    private Object _provided;
    this (Object o) { _provided = o; }
    Object build (Builder parent) {
        return _provided;
    }
}


class Builder {
    IObjectBuilder[string] _builders;
    Object[string] _built;

    /**
      * Get an instance of class/interface T.
      * If T is an interface and there are no bindings for it, throw a
      * BindingException.
      * If T is a singleton (if it implements the Singleton interface), 
      * build a copy if none exist, else return the existing copy.
      */
    T get(T)() {
        if (is (T : Singleton)) {
            if (T.stringof in _built) {
                return cast(T)_built[T.stringof];
            }
        }

        T obj;
        if (T.stringof in _builders) {
            obj = cast(T)(_builders[T.stringof].build(this));
        } else {
            auto b = new ObjectBuilder!(T)();
            obj = cast(T)b.build(this);
            _builders[T.stringof] = b;
        }

        /*
           This'd be a worthwhile check, except it eliminates the possibility
           of the user requesting null be inserted, and it's handled elsewhere.

        if (obj is null) {
            throw new BindingException("Aw, man, I'm really sorry. I think a cast must have failed on me. Maybe there's a bad binding somewhere, or maybe you told me to give null, but I dunno, man, this isn't good.");
        }
        */

        if (is (T : Singleton)) {
            _built[T.stringof] = cast(Object)obj;
        }

        return obj;
    }

    /**
      * When someone asks for TVisible, give them a TImpl instead.
      */
    Builder bind (TVisible, TImpl)() {
        static assert (is (TImpl : TVisible),
                "binding failure: cannot convert type " ~ TImpl.stringof
                ~ " to type " ~ TVisible.stringof);
        _builders[TVisible.stringof] = new ObjectBuilder!(TImpl)();
        return this;
    }

    /** 
      * For the given type, rather than creating an object automatically, 
      * whenever anything requires that type, return the given object.
      */
    Builder provide (T) (T obj) {
        _builders[T.stringof] = new StaticBuilder(obj);
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

    unittest {
        auto b = new Builder();
        try {
            b.get!(IFrumious)();
            assert (false, "expected exception not thrown");
        } catch (BindingException e) {}
    }

    class Wha : Singleton {}

    unittest {
        auto b = new Builder();
        auto one = b.get!(Wha)();
        auto two = b.get!(Wha)();
        assert (one is two);
    }

    unittest {
        auto b = new Builder();
        auto o = new Object;
        b.provide(o);
        assert (b.get!(Object) is o);
    }

    void main () {}
}

