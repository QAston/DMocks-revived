module dmocks.util;

import std.conv;
import std.utf;
import std.string;


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

version (DMocksTest) {
    unittest {
        Interval t = Interval(1, 2);
        assert (to!string(t) == "1..2");
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

struct Interval 
{
    bool Valid () { return Min <= Max; }
    int Min;
    int Max;

    string toString () const
    {
        return std.conv.to!string(Min) ~ ".." ~ std.conv.to!string(Max);
    }

    this (int min, int max) 
    {
        this.Min = min;
        this.Max = max;
    }
}

class InvalidOperationException : Exception 
{
    this () { super(typeof(this).stringof ~ "The requested operation is not valid."); }
    this (string msg) { super(typeof(this).stringof ~ msg); }
}



public class ExpectationViolationException : Exception 
{
    this (string msg) 
    { 
        super(msg);
    }
}

public class MocksSetupException : Exception {
    this (string msg) {
        super (typeof(this).stringof ~ ": " ~ msg);
    }
}

