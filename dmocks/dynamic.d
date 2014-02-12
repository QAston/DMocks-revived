module dmocks.dynamic;

import std.conv;
import std.traits;
import std.typecons;

/++
+ This is a very very simple class for storing a variable regardless of it's size and type
+/
abstract class Dynamic
{
    // toHash, toString and opEquals are also part of this class
    // but i'm not sure how to express that in code so this comment has to be enough:)

    /// returns stored typeinfo
    abstract TypeInfo type();
    /// converts stored value to given "to" type and returns 1el array of target type vals or null when conversion failed
    abstract void[] convertTo(TypeInfo to);

    /// returns true if variable held by dynamic is convertible to given type
    bool canConvertTo(TypeInfo to)
    {
        return type==to || convertTo(to) !is null;
    }
}

/// returns stored value if type T is precisely the type of variable stored, variable stored can be implicitly to that type
T get(T)(Dynamic d)
{
    // in addition to init property requirement disallow user defined value types which can have alias this to null-able type 
    static if (!is(T==union) && !is(T==struct) && is(typeof(T.init is null)))
    {
        if (d.type == typeid(typeof(null)))
            return null;
    }
    if (d.type == typeid(T))
        return ((cast(DynamicT!T)d).data());
    void[] convertResult = d.convertTo(typeid(T));
    return (cast(T*)convertResult)[0];
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

    ///
    override void[] convertTo(TypeInfo to)
    {
        foreach(target;ImplicitConversionTargets!(T))
        {
            if (typeid(target) == to)
            {
                auto ret = new target[1];
                ret[0] = _data;
                return ret;
            }
        }
        return null;
    }
}

version (DMocksTest) {

    class A
    {
    }

    class B : A
    {
    }


    unittest
    {
        auto d = dynamic(6);
        assert(d.toString == "6");
        assert(d.type.toString == "int");
        auto e = dynamic(6);
        assert(e == d);
        assert(e.get!int == 6);
    }

    unittest
    {
        auto d = dynamic(new B);
        assert(d.get!A !is null);
        assert(d.get!B !is null);
    }

    unittest
    {
        auto d = dynamic(null);
        assert(d.get!A is null);
    }

    struct C
    {
    }

    struct D
    {
        private C _c;
        alias _c this;
    }

    unittest {
        int[5] a;
        auto d = dynamic(a);
        assert(d.get!(int[5]) == [0,0,0,0,0]);
    }

    /+ ImplicitConversionTargets doesn't include alias thises
    unittest
    {
        auto d = dynamic(D());
        d.get!C;
        d.get!D;
    }
    +/
}
