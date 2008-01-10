module dconstructor.build;

private {
    import dconstructor.singleton;
    import dconstructor.object_builder;
    import dconstructor.multibuilder;
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
      * Get an instance of type T. T can be anything -- primitive, array,
      * interface, struct, or class.
      *
      * If T is an interface and there are no bindings for it, throw a
      * BindingException.
      *
      * If T is a singleton (if it implements the Singleton interface), 
      * build a copy if none exist, else return the existing copy.
      */
    T get(T)() {
        static if (is (T : Singleton)) {
            string mangle = T.stringof;
            // No inheritance for non-classes, so this is safe....
            if (mangle in _built) {
                return cast(T)_built[mangle];
            }
        }

        auto b = get_or_add!(T)();
        T obj = b.build(this);

        static if (is (T : Singleton)) {
            // No inheritance for non-classes, so this is safe....
            _built[T.stringof] = cast(Object)obj;
        }

        return obj;
    }

    /**
      * The next call to bind, provide, etc will only apply to the given type.
      * Subsequent calls will not apply to the given type unless you call this
      * method again.
      */
    Builder on(T)() {
        _context = T.stringof;
        return this;
    }

    /**
      * When someone asks for TVisible, give them a TImpl instead.
      */
    Builder bind (TVisible, TImpl)() {
        static assert (is (TImpl : TVisible),
                "binding failure: cannot convert type " ~ TImpl.stringof
                ~ " to type " ~ TVisible.stringof);
        // again, only possible b/c no inheritance for structs
        wrap!(TVisible)(new DelegatingBuilder!(TVisible, TImpl)());
        return this;
    }

    /** 
      * For the given type, rather than creating an object automatically, 
      * whenever anything requires that type, return the given object.
      * Implicit singletonization. This is required for structs, if you want to
      * set any of the fields (since by default static opCall is not called).
      */
    Builder provide (T) (T obj) {
        wrap!(T)(new StaticBuilder!(T)(obj));
        return this;
    }

    /**
      * Whenever anyone asks for an array of the given type, insert the given
      * array. There is no other way to provide structs.
      */
    Builder list (TVal) (TVal[] elems) {
        wrap!(T)(new GlobalListBuilder!(TVal)(elems));
        return this;
    }

    /**
      * Whenever someone asks for an associative array of the given type,
      * insert the given associative array.
      */
    Builder map (TVal, TKey) (TVal[TKey] elems) {
        wrap!(T)(new GlobalDictionaryBuilder!(TKey, TVal)(elems));
        return this;
    }

    public string _build_for () {
        if (_build_target_stack.length >= 2) {
            return _build_target_stack[$-2];
        }
        return null;
    }

    private {
        ISingleBuilder[string] _builders;
        Object[string] _built;
        string[] _build_target_stack;
        string _context;

        AbstractBuilder!(T) get_or_add(T)() {
            string mangle = T.stringof;
            if (mangle in _builders) {
                return cast(AbstractBuilder!(T))_builders[mangle];
            }

            auto b = make_builder!(T)();
            _builders[mangle] = b;
            return b;
        }

        AbstractBuilder!(T) wrap(T)(AbstractBuilder!(T) b) {
            auto ret = wrap_s(_context, b);
            _context = null;
            return ret;
        }

        AbstractBuilder!(T) wrap_s(T)(string context, AbstractBuilder!(T) b) {
            string mangle = T.stringof;
            if (mangle in _builders) {
                auto existing = cast(MultiBuilder!(T)) _builders[mangle];
                existing.add(context, b);
                return existing;
            }
            MultiBuilder!(T) mb = new MultiBuilder!(T)();
            mb.add(context, b);
            _builders[mangle] = b;
            return b;
        }

        AbstractBuilder!(T) make_builder(T)() {
            return wrap_s!(T)(null, make_real_builder!(T)());
        }

        AbstractBuilder!(T) make_real_builder(T)() {
            static if (is (T : T[]) || is (T V : V[K])) {
                static assert (false, "Cannot build an array or associative array; you have to provide it."); 
            } else static if (is (T == struct)) {
                return new StructBuilder!(T);
            } else static if (is (T == class)) {
                return new ObjectBuilder!(T);
            } else {
                // If this is a static assert, it always gets tripped, since
                // a bound interface can't be built directly. Everything's
                // resolved at runtime.
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

