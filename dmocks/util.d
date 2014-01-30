module dmocks.util;

import std.conv;
import std.utf;
import std.string;
public import dmocks.interval;


string test(string name)() {
    return `std.stdio.writefln(__FILE__~" line: %d"~": ` ~ name ~ ` test", __LINE__);
            scope(failure) std.stdio.writeln("failed");
            scope(success) std.stdio.writeln("success");`;
}

string nullableToString(T)(T obj)
{
    if (obj is null)
        return "<null>";
    return obj.to!string;
}

void debugLog(T...)(lazy T args) @trusted nothrow
{
    version (DMocksDebug) {
        try {
            std.stdio.writefln(args);
        }
        catch (Exception ex) {
            assert (false, "Could not write to error log");
        }
    }
}

template IsConcreteClass(T)
{
    static if ((is (T == class)) && (!__traits(isAbstractClass, T)))
    {
        const bool IsConcreteClass = true;
    }
    else 
    {
        const bool IsConcreteClass = false;
    }
}

class InvalidOperationException : Exception 
{
    this () { super(typeof(this).stringof ~ "The requested operation is not valid."); }
    this (string msg) { super(typeof(this).stringof ~ msg); }
}



public class ExpectationViolationException : Exception 
{
    this (string msg, string file = __FILE__, size_t line = __LINE__) 
    { 
        super(msg);
    }
}

public class MocksSetupException : Exception {
    this (string msg, string file = __FILE__, size_t line = __LINE__) {
        super (typeof(this).stringof ~ ": " ~ msg);
    }
}

