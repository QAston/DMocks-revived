module selfmock.util;


import tango.group.convert;

version(MocksDebug) import tango.io.Stdout;
version(MocksTest) import tango.io.Stdout;

char[] test(char[] name)()
{
    return `Stdout("` ~ name ~ ` unit test...");
    scope(success) Stdout("success").newline;
    scope(failure) Stdout("failure").newline;
    `;
}

char[] toString (T) (T value) 
{
    static if (is (T : T[])) 
    {
        return ArrayToString(value);
    } 
    /*
    else static if (__traits(isScalar, T)) 
    {
        return Float.toString(cast(real)value);
    }
    */
    else static if (is (typeof (value is null))) 
    {
        return ((value is null) ? "<null>" : strof(value));
    } 
    else 
    {
        return strof(value);
    }
}

char[] strof(T)(T value)
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

unittest 
{
    int i = 5;
    //assert (toString(5) == "5");
    Interval t = Interval(1, 2);
    assert (toString(t) == "1..2");
}

char[] ArrayToString (T) (T[] value) 
{
    static if (is (T == char[]) || is (T == wchar[]) || is (T == dchar[])) 
    {
        return `"` ~ toUTF8(value) ~ `"`;
    } 
    else 
    {
        char[] ret = "[";
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
    bool valid () { return min <= max; }
    int min;
    int max;

    char[] toString () 
    {
        return Integer.toString(min) ~ ".." ~ Integer.toString(max);
    }

    static Interval opCall (int min, int max) 
    {
        Interval s;
        s.min = min;
        s.max = max;
        return s;
    }
}

class InvalidOperationException : Exception 
{
    this () { super("The requested operation is not valid."); }
    this (char[] msg) { super(typeof(this).stringof ~ msg); }
}



public class ExpectationViolationException : Exception 
{
    private static char[] _defaultMessage = "An unexpected call has occurred."; 
    this () 
    { 
    	super(_defaultMessage); 
    }
    
    this (char[] msg) 
    { 
    	super(msg);
    }
}

public class MocksSetupException : Exception {
    this (char[] msg) {
        super (msg);
    }
}

