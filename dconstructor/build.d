module dconstructor.build;

private {
    import dconstructor.singleton;
    import dconstructor.object_builder;
    import dconstructor.aggregate;
    import dconstructor.exception;
    import dconstructor.util;
    import dconstructor.traits;
    
    version(BuildTest) {
        version (Tango) {
            import tango.io.Stdout;
        } else {
            import std.stdio;
        }
    }
}

public Builder builder;

static this () {
    builder = new Builder();
}

/**
  * The main object builder. Use it to create objects.
  */
class Builder {
    /**
      * Get an instance of class/interface T.
      * If T is an interface and there are no bindings for it, throw a
      * BindingException.
      * If T is a singleton (if it implements the Singleton interface), 
      * build a copy if none exist, else return the existing copy.
      */
    T get(T)() {
        string mangle = T.stringof;
        static if (is (T : Singleton)) {
            // No inheritance for non-classes, so this is safe....
            if (mangle in _built) {
                return cast(T)_built[mangle];
            }
        }

        if (!(mangle in _builders)) {
            _builders[mangle] = getBuilder!(T);
        }

        auto b = cast(AbstractBuilder!(T)) _builders[mangle];
        T obj = b.build(this);

        static if (is (T : Singleton)) {
            // No inheritance for non-classes, so this is safe....
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
        // again, only possible b/c no inheritance for structs
        _builders[TVisible.stringof] = 
            new DelegatingBuilder!(TVisible, TImpl)();
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

    Builder fillList (TVal) (TVal[] elems) {
        _builders[typeof(elems).stringof] = new GlobalListBuilder!(TVal)(elems);
        return this;
    }


    private {
        ISingleBuilder[string] _builders;
        Object[string] _built;
        AbstractBuilder!(T) getBuilder(T)() {
            static if (is (T : T[]) || is (T V : V[K])) {
                static assert (false, "Cannot build an array or associative array; you have to provide it."); 
            } else static if (is (T == struct)) {
                return new StructBuilder!(T);
            } else static if (is (T == class)) {
                return new ObjectBuilder!(T);
            } else {
                throw new BindingException 
                    ("Cannot build " ~ T.stringof ~ 
                     ": no bindings, not provided, and cannot create an " ~
                     "instance. You must bind interfaces and provide " ~
                     "primitives manually.");
            }
        }
    }
}

// For storing AbstractBuilder!(T) arrays for heterogenous T
interface ISingleBuilder {}

abstract class AbstractBuilder(T) : ISingleBuilder {
    T build (Builder parent);
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
        // tests no explicit constructor
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
        // tests no explicit constructor and singleton
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

    unittest {
        assert (builder !is null);
    }

    class Bandersnatch : IFrumious {}

    class Snark {
        public IFrumious[] frumiousity;
        this (IFrumious[] frums) { frumiousity = frums; }
    }

    unittest {
        IFrumious one = builder.get!(Frumious);
        IFrumious two = builder.get!(Bandersnatch);
        builder.fillList([one, two]);
        
        auto snark = builder.get!(Snark);
        assert (snark.frumiousity[0] is one);
        assert (snark.frumiousity[1] is two);
    }

    void main () {}
}

