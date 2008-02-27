module dmocks.MethodMock;

import dmocks.Repository;
import std.stdio;
import std.traits;
import std.metastrings;

// These are too complicated for decent unittests. Can't mock templates!

/++
    The only method we care about externally.
    Returns a string containing the overrides for this method
    and all its overloads.
 ++/
string Methods (T, string name) () {
    string methodBodies = "";
    foreach (i, method; __traits(getVirtualFunctions, T, name)) 
    {
        alias typeof(method) func;
        methodBodies ~= ReturningMethod!(T.stringof, name, i, !is (ReturnType!(func) == void));
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
	string indexstr = ToString!(index);
	//string self = `__traits(getVirtualFunctions, T, "` ~ name ~ `")[` ~ ToString!(index) ~ `]`;
	string self = `T.` ~ name;
	string ret = returns ? `ReturnType!(` ~ self ~ `)` : `void`;
	string paramTypes = `ParameterTypeTuple!(` ~ self ~ `)`;
    string qualified = type ~ `.` ~ name;
    return `override ` ~ ret ~ ` ` ~ name ~ `
    		(` ~ paramTypes ~ ` params)` ~
        `{
            version(MocksDebug)version(MocksDebug) writefln("checking _owner...");
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
    Returns a string containing the overload for a single function.
    This function does not have a return value. 
 ++/
string VoidMethod (string type, string name, U...)() 
{
    string qualified = type ~ `.` ~ name;
    string args = String!(U)();
    string argArgs = Arguments!(U);
    string nameArgs = `"` ~ qualified ~ (U.length == 0 ? `"` : `", ` ~ Arguments!(U)());
    string retArgs = `void` ~ (U.length == 0 ? `` : `, ` ~ args);
    return "override void " ~ name ~ "(" ~ TypedArguments!(U)() ~ ")"  ~ 
    `{
	    version(MocksDebug)version(MocksDebug) writefln("checking _owner...");
	    if (_owner is null) 
	    {
	        throw new Exception("owner cannot be null! Contact the stupid mocks developer.");
	    }
	    auto rope = _owner.Call!(` ~ retArgs ~ `)(this, ` ~ nameArgs ~ `);
	    if (rope.pass)
	    {
	    	static if (is (typeof (super.` ~ name ~ `)))
        	{
        		return super.` ~ name ~ `(` ~ argArgs ~ `);
        	}
        	else
        	{
        		throw new InvalidOperationException("I was supposed to pass this call through to an abstract class or interface -- I can't do that!");
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
        ret ~= U.stringof ~ " arg" ~ ToString!(i) ~ ", ";
    }

    if (T.length > 0) 
        ret = ret[0..$-2];

    return ret;
}
version (MocksTest) {
    unittest {
        writef("typedarguments unit test...");
        scope(failure) writefln("failed");
        scope(success) writefln("success");
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
        ret ~= "arg" ~ ToString!(i) ~ ", ";
    }

    if (T.length > 0) 
        ret = ret[0..$-2];

    return ret;
}
version (MocksTest) {
    unittest {
        // If this fails, it'll show you what went wrong...
        writef("arguments unit test...");
        scope(failure) writefln("failed");
        scope(success) writefln("success");
        assert (Arguments!(float, int, Object) == "arg0, arg1, arg2", Arguments!(float, int, Object)); 
    }
}

/++
    Some things complain about the extra parentheses; remove them.
 ++/
string String (U...)() {
    return (U.stringof)[1..$-1];
}
version (MocksTest) {
    unittest {
        writef("tuple string unit test...");
        scope(failure) writefln("failed");
        scope(success) writefln("success");
        assert (String!(float, int, Object) == "float, int, Object");
    }
}
