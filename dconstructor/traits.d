module dconstructor.traits;

version (Tango) {
    public import tango.core.Traits;
    template isAssociativeArray(T) {
        const bool isAssociativeArray = isAssocArrayType!(T);
    }
} else {
    static if (__VERSION__ < 2000) {
        template isAssociativeArray(T) {
            const bool isAssociativeArray = 
                is (typeof (T.init.keys[0])[typeof(T.init.values[0])] == T);
        }
    } else {
        public import std.traits;
    }
}

template isArray (T) {
    const bool isArray = is (typeof(T[0])[] == T);
}

unittest {
    assert (isArray!(int[]));
    assert (!isArray!(int));
}

template assocArrayVal (AA) {
    alias typeof(AA.init.values[0]) assocArrayVal;
}

unittest {
    assert (is (assocArrayVal!(int[long]) == int));
}

template assocArrayKey (AA) {
    alias typeof(AA.init.keys[0]) assocArrayKey;
}

unittest {
    assert (is (assocArrayKey!(int[long]) == long));
}
