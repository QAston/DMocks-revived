/**
  * Currently, this can't build anything unless there is an explicity
  * constructor for that class or for one of its base classes.
  * I can change that for d2, but not d1.
  */
module dconstructor.object_builder;

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

