module dmocks.util;


static import std.conv;
import std.utf;

version(DMocksDebug) import std.stdio;
version(DMocksTest) import std.stdio;

string test(string name)() {
	return `writef("` ~ name ~ ` test");
			scope(failure) writefln("failed");
			scope(success) writefln("success");`;
}

string toString (T) (T value) 
{
    static if (is (T : T[])) 
    {
        return ArrayToString(value);
    } 
    else static if (__traits(isScalar, T)) 
    {
        return std.conv.to!string(value);
    }
    else static if (is (typeof (value is null))) 
    {
        return ((value is null) ? "<null>" : strof(value));
    } 
    else 
    {
        return strof(value);
    }
}

string strof(T)(T value)
{
	static if (is (typeof (value.toString)))
	{
		return value.toString;
	}
	else
	{
		return T.stringof;
	}
}

version (DMocksTest) {
	unittest {
		int i = 5;
		assert (toString(5) == "5");
		Interval t = Interval(1, 2);
		assert (toString(t) == "1..2");
	}
}

string ArrayToString (T) (T[] value) 
{
    static if (is (T == string) || is (T == wstring) || is (T == dstring)) 
    {
        return `"` ~ toUTF8(value) ~ `"`;
    } 
    else 
    {
        string ret = "[";
        foreach (i, elem; value) 
        {
            ret ~= elem;
            if (i < value.length - 1) 
            {
                ret ~= ", ";
            }
        }
        return ret ~ "]";
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

