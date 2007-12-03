
module dconstructor.build_utils;

import dconstructor.singleton;
import dconstructor.exception;
import dconstructor.util;

version (Tango) {
    import tango.core.Traits;
    template ParameterTypeTuple(alias dg) {
        alias ParameterTupleOf!(dg) ParameterTypeTuple;
    }
} else {
    import std.traits;
}

string get_deps(T)() {
    static if (is (typeof (new T) == T)) {
        return `return new T();`;
    } else {
        return `return new T(` ~
                get_deps_impl!(T, 0)()
                ~ `);`;
    }
}

string get_deps_impl(T, int i)() {
    static if (i < ParameterTypeTuple!(T._ctor).length) {
        string ret = `parent.get!(ParameterTypeTuple!(T._ctor)[` ~ (to_string!(i)) ~ `])`;
        static if (i < ParameterTypeTuple!(T._ctor).length - 1) 
            ret ~= `,`;
        return ret ~ get_deps_impl!(T, i + 1)();
    } else {
        return ``;
    }
}

