module dconstructor.object_builder;

private {
    import dconstructor.singleton;
    import dconstructor.exception;
    import dconstructor.util;
    import dconstructor.build;
    import dconstructor.build_utils;
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

