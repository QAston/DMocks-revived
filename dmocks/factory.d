module dmocks.factory;

import dmocks.object_mock;
import dmocks.repository; 
import dmocks.util;
import dmocks.caller;
import std.stdio;
import std.typecons;

/** Get a mock object of the given type. */
T mock (T, CONSTRUCTOR_ARGS...) (MockRepository rep, CONSTRUCTOR_ARGS cargs) 
{
    debugLog("factory: about to build");
    Mocked!(T) ret = new Mocked!(T)(cargs);
    debugLog("factory: about to set owner");
    ret._owner = new Caller(rep);
    debugLog("factory: returning the mocked object");
    return cast(T)ret;
}

MockedFinal!(T) mockFinal (T, CONSTRUCTOR_ARGS...) (MockRepository rep, CONSTRUCTOR_ARGS t) 
{
    debugLog("factory: about to build");
    static if (__traits(isFinalClass, T))
        T obj = new T(t);
    else
        T obj = new WhiteHole!T(t);
    MockedFinal!(T) ret = new MockedFinal!(T)(obj);
    debugLog("factory: about to set owner");
    ret._owner = new Caller(rep);
    debugLog("factory: returning the mocked object");
    return ret;
}

MockedFinal!(T) mockFinalPassTo (T, CONSTRUCTOR_ARGS...) (MockRepository rep, T obj) 
{
    debugLog("factory: about to build");
    MockedFinal!(T) ret = new MockedFinal!(T)(obj);
    debugLog("factory: about to set owner");
    ret._owner = new Caller(rep);
    debugLog("factory: returning the mocked object");
    return ret;
}

MockedStruct!(T) mockStruct (T, CONSTRUCTOR_ARGS...) (MockRepository rep, CONSTRUCTOR_ARGS t) 
{
    debugLog("factory: about to build");
    MockedStruct!(T) ret = new MockedStruct!(T)(T(t));
    debugLog("factory: about to set owner");
    ret._owner = new Caller(rep);
    debugLog("factory: returning the mocked object");
    return ret;
}

MockedStruct!(T) mockStructPassTo (T, CONSTRUCTOR_ARGS...) (MockRepository rep, T obj) 
{
    debugLog("factory: about to build");
    MockedStruct!(T) ret = new MockedStruct!(T)(obj);
    debugLog("factory: about to set owner");
    ret._owner = new Caller(rep);
    debugLog("factory: returning the mocked object");
    return ret;
}