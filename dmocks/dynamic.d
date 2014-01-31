module dmocks.dynamic;

import std.conv;

/++
+ This is a very very simple class for storing a variable regardless of it's size and type
+/
abstract class Dynamic
{
    // toHash, toString and opEquals are also part of this class
    // but i'm not sure how to express that in code so this comment has to be enough:)

    /// returns stored typeinfo
    abstract TypeInfo type();
    /// returns stored value if type T is precisely the type of variable stored
    T get(T)()
    in
    {
        assert(typeid(T) == type);
    }
    body
    {
        return (cast(DynamicT!T)this).data;
    }
    // possibly there'll be more operations available here in future
}

/// a helper function for creating Dynamic obhects
Dynamic dynamic(T)(auto ref T t)
{
    return new DynamicT!T(t);
}

class DynamicT(T) : Dynamic
{
    private T _data;
    this(T t)
    {
        _data = t;
    }

    ///
    override TypeInfo type()
    {
        return typeid(T);
    }

    ///
    override string toString()
    {
        return _data.to!string();
    }

    /// two dynamics are equal when they store same type and the values pass opEquals
    override bool opEquals(Object object)
    {
        auto dyn = cast(DynamicT!T)object;
        if (dyn is null)
            return false;
        if (dyn.type != type)
            return false;

        return _data == dyn._data;
    }

    ///
    override size_t toHash()
    {
        return typeid(T).getHash(&_data);
    }

    ///
    T data()
    {
        return _data;
    }
}

unittest {
    auto d = dynamic(6);
    assert(d.toString == "6");
    assert(d.type.toString == "int");
    auto e = dynamic(6);
    assert(e == d);
    assert(e.get!int == 6);
}
