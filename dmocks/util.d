module dmocks.util;

static import std.conv;
import std.utf;

version(DMocksDebug) import std.stdio;
version(DMocksTest) import std.stdio;

string test(string name)() {
    return `writeln("` ~ name ~ ` test");
            scope(failure) writeln("failed");
            scope(success) writeln("success");`;
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

    static Interval opCall (int min, int max) 
    {
        Interval s;
        s.Min = min;
        s.Max = max;
        return s;
    }
}

class InvalidOperationException : Exception 
{
    this () { super(typeof(this).stringof ~ "The requested operation is not valid."); }
    this (string msg) { super(typeof(this).stringof ~ msg); }
}



public class ExpectationViolationException : Exception 
{
    private static string _defaultMessage = "An unexpected call has occurred."; 
    this () 
    { 
        super(typeof(this).stringof ~ ": " ~  _defaultMessage); 
    }
    
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

