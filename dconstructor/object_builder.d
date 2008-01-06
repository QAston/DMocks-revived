module dconstructor.object_builder;

private {
    import dconstructor.singleton;
    import dconstructor.exception;
    import dconstructor.util;
    import dconstructor.traits;
    import dconstructor.build;
    import dconstructor.build_utils;
}

class ObjectBuilder(T) : AbstractBuilder!(T) {
    T build (Builder parent) {
        static assert (is (T == class), "Tried to build something that wasn't a class with an ObjectBuilder. Maybe you're missing a binding? Sorry.");
        mixin (get_deps!(T)());
    }
}

// This is cruddy. Without struct constructors, ugly!
class StructBuilder(T) : AbstractBuilder!(T) {
    T build (Builder parent) {
        return T.init;
    }
}

class StaticBuilder(T) : AbstractBuilder!(T) {
    private T _provided;
    this (T t) { _provided = t; }
    T build (Builder parent) {
        return _provided;
    }
}

class DelegatingBuilder(T, TImpl) : AbstractBuilder!(T) {
    T build (Builder parent) {
        return cast(T)parent.get!(TImpl);
    }
}
