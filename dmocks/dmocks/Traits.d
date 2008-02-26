module Traits;
version (Tango) {
    import tango.core.Tuple;
    import tango.core.Traits;
} else {
    import std.typetuple;
    import std.traits;
    template BaseTypeTupleOf(T) {
        alias BaseTypeTuple!(T) BaseTypeTupleOf;
    }
}

template ImplementedInterfacesOf(T) {
    static if (is (T == Object)) {
        alias TypeTuple!() ImplementedInterfacesOf;
    } else static if (is (T == interface)) {
        alias T ImplementedInterfacesOf;
    } else static if (is (T == class)) {
        alias TypeTuple!(
            Interfaces!(BaseTypeTupleOf!(T)),
            ImplementedInterfacesOf!(BaseTypeOf!(T))
        ) ImplementedInterfacesOf;
    } else {
        static assert (false, "Only class types are supported for ImplementedInterfacesOf");
    }
}

template Interfaces(T...) {
    static if (T.length == 0) {
        alias TypeTuple!() Interfaces;
    } else static if (is (T[0] == interface)) {
        alias TypeTuple!(T[0], Interfaces!(T[1..$])) Interfaces;
    } else {
        alias Interfaces!(T[1..$]) Interfaces;
    }
}

version (MocksTest) {
    void main(){}
    interface I0 {}
    interface I1 {}
    interface I2 {}
    class C0 : I0 {}
    class C1 : C0, I1{}
    class C2 : C1, I2 {}
    unittest {
        alias ImplementedInterfacesOf!(C2) Ifaces;
        assert (Ifaces.length == 3);
        assert (is (Ifaces[0] == I2));
        assert (is (Ifaces[1] == I1));
        assert (is (Ifaces[2] == I0));
    }
}

// This is cruddy and implementation-specific.
template BaseTypeOf(T) {
    alias BaseTypeTupleOf!(T)[0] BaseTypeOf;
}

template Classes(T...) {
    static if (T.length == 0) {
        alias TypeTuple!() Classes;
    } else static if (is (T[0] == class)) {
        alias TypeTuple!(T[0], Classes!(T[1..$])) Classes;
    } else {
        alias Classes!(T[1..$]) Classes;
    }
}
