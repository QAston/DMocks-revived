module dmocks.method_mock;


import std.stdio;
import std.traits;
import std.metastrings;
import std.conv;

import dmocks.util;
import dmocks.repository;

//These are too complicated for decent unittests. Can't mock templates!

/++
The only method we care about externally.
Returns a string containing the overrides for this method
and all its overloads.
++/
string Methods (T, string name) () {
    version(DMocksDebug) pragma(msg, name);
    string methodBodies = "";

    static if (is (typeof(__traits(getVirtualFunctions, T, name))))
    {
        foreach (i, method; __traits(getVirtualFunctions, T, name)) 
        {
            static if (!__traits(isFinalFunction, method))
            {
                alias typeof(method) func;
                methodBodies ~= ReturningMethod!(T.stringof, name, i, !is (ReturnType!(func) == void));
            }
        }
    }
    return methodBodies;
}

string Constructor (T) () 
{
    static if (!is (typeof(T._ctor)))
    {
        return ``;
    } 
    else 
    {
        static assert (false, "Mocking types with constructors is not currently supported");
    }
}


/++
Returns a string containing the overload for a single function.
This function has a return value.
++/
string ReturningMethod (string type, string name, int index, bool returns)() 
{
    string indexstr = index.to!string;
    string self = `typeof(__traits(getVirtualFunctions, T, "` ~ name ~ `")[` ~ index.to!string ~ `])`;
    string ret = returns ? `ReturnType!(` ~ self ~ `)` : `void`;
    string paramTypes = `ParameterTypeTuple!(` ~ self ~ `)`;
    string qualified = type ~ `.` ~ name;
    return `override ` ~ ret ~ ` ` ~ name ~ `
    (` ~ paramTypes ~ ` params)` ~
    `{
    version(DMocksDebug) writefln("checking _owner...");
    if (_owner is null) 
    {
        throw new Exception("owner cannot be null! Contact the stupid mocks developer.");
    }
    auto rope = _owner.Call!(` ~ ret ~ `, ` ~ paramTypes ~ `)(this, "` ~ qualified ~ `", params);
    if (rope.pass)
    {
        static if (is (typeof (super.` ~ name ~ `)))
        {
            return super.` ~ name ~ `(params);
        }
        else
        {
            throw new InvalidOperationException("I was supposed to pass this call through to an abstract class or interface -- I can't do that!");
        }
    }
    else
    {
        static if (!is (` ~ ret ~ ` == void))
        {
            return rope.value;
        }
    }
}
`;
} 


/++
Returns a string containing an expanded version of the type tuple
along with identifiers unique to the element. In suitable form for
method signatures and so forth.
++/
string TypedArguments (T...)() {
    string ret = "";
    foreach (i, U; T) {
        ret ~= U.stringof ~ " arg" ~ i.to!string ~ ", ";
    }

    if (T.length > 0) 
        ret = ret[0..$-2];

    return ret;
}
version (DMocksTest) {
    unittest {
        mixin(test!("typedarguments unit"));
        assert (TypedArguments!(float, int, Object) == "float arg0, int arg1, Object arg2");
    }
}


/++
Returns a string containing arg0, arg1, arg2...argn,
where n == T.length. To be used with TypedArguments.
++/
string Arguments (T...)() {
    string ret = "";
    foreach (i, U; T) {
        ret ~= "arg" ~ i.to!string ~ ", ";
    }

    if (T.length > 0) 
        ret = ret[0..$-2];

    return ret;
}
version (DMocksTest) {
    unittest {
        // If this fails, it'll show you what went wrong...
        mixin(test!("arguments unit"));
        assert (Arguments!(float, int, Object) == "arg0, arg1, arg2", Arguments!(float, int, Object)); 
    }
}

/++
Some things complain about the extra parentheses; remove them.
++/
string String (U...)() {
    return (U.stringof)[1..$-1];
}
version (DMocksTest) {
    unittest {
        mixin(test!("tuple string"));
        assert (String!(float, int, Object) == "float, int, Object");
    }
}
