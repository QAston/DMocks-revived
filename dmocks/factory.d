module dmocks.factory;

import dmocks.object_mock;
import dmocks.repository; 
import dmocks.util;
import dmocks.repository;
import std.stdio;
import std.typecons;

package:

/** Get a mock object of the given type. */
T mock (T, CONSTRUCTOR_ARGS...) (MockRepository rep, CONSTRUCTOR_ARGS cargs) 
{
    Mocked!(T) ret = new Mocked!(T)(cargs);
    ret._owner = rep;
    return cast(T)ret;
}

MockedFinal!(T) mockFinal (T, CONSTRUCTOR_ARGS...) (MockRepository rep, CONSTRUCTOR_ARGS t) 
{
    static if (__traits(isFinalClass, T))
        T obj = new T(t);
    else
        T obj = new WhiteHole!T(t);
    MockedFinal!(T) ret = new MockedFinal!(T)(obj);
    ret._owner = rep;
    return ret;
}

MockedFinal!(T) mockFinalPassTo (T, CONSTRUCTOR_ARGS...) (MockRepository rep, T obj) 
{
    MockedFinal!(T) ret = new MockedFinal!(T)(obj);
    ret._owner = rep;
    return ret;
}

MockedStruct!(T) mockStruct (T, CONSTRUCTOR_ARGS...) (MockRepository rep, CONSTRUCTOR_ARGS t) 
{
    MockedStruct!(T) ret = MockedStruct!(T)(T(t));
    ret._owner = rep;
    return ret;
}

MockedStruct!(T) mockStructPassTo (T, CONSTRUCTOR_ARGS...) (MockRepository rep, T obj) 
{
    MockedStruct!(T) ret = MockedStruct!(T)(obj);
    ret._owner = rep;
    return ret;
}