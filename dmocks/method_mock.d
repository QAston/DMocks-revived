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
string Methods (T, string methodName) () {
    /+version(DMocksDebug)
    {
        pragma(msg, methodName);
        pragma(msg, T);
    }+/
    string methodBodies = "";

    static if (is (typeof(__traits(getVirtualFunctions, T, methodName))))
    {
        foreach (virtualMethodIndex, method; __traits(getVirtualFunctions, T, methodName)) 
        {
            static if (!__traits(isFinalFunction, method))
            {
                alias typeof(method) func;
                methodBodies ~= BuildMethodOverloads!(T.stringof, methodName, virtualMethodIndex, func);
            }
        }
    }
    return methodBodies;
}

/++
Returns a string containing the overload for a single function.
This function has a return value.
++/
string BuildMethodOverloads (string objectType, string methodName, int virtualMethodIndex, METHOD_TYPE)() 
{
    bool returns = !is (ReturnType!(METHOD_TYPE) == void);
    auto attributes = functionAttributes!METHOD_TYPE;
    bool isNothrowMethod = (attributes & FunctionAttribute.nothrow_) != 0;

    string self = `typeof(__traits(getVirtualFunctions, T, "` ~ methodName ~ `")[` ~ virtualMethodIndex.to!string ~ `])`;
    string ret = returns ? `ReturnType!(` ~ self ~ `)` : `void`;
    string paramTypes = `ParameterTypeTuple!(` ~ self ~ `)`;
    string qualified = objectType ~ `.` ~ methodName;
    string header = `override ` ~ ret ~ ` ` ~ methodName ~ `
        (` ~ paramTypes ~ ` params)` ~ formatQualifiers!(METHOD_TYPE);

    string funBody = 
    `
    debugLog("checking _owner...");
    if (_owner is null) 
    {
        assert(false, "owner cannot be null! Contact the stupid mocks developer.");
    }
    dmocks.action.ReturnOrPass!(` ~ ret ~ `) rope;`
    ~ (isNothrowMethod ? `try { ` : ``) ~
        // CAST CHEATS here - can't operate on const/shared refs without cheating on typesystem. this makes these calls threadunsafe
    `
        rope = (cast(Caller)_owner).Call!(` ~ ret ~ `, ` ~ paramTypes ~ `)(cast(IMocked)this, "` ~ qualified ~ `", "` ~ formatQualifiers!(METHOD_TYPE) ~ `", params);
    ` ~ (isNothrowMethod ? ` } catch (Exception ex) { assert(false, "Throwing in a mock of a nothrow method!"); }` : ``) ~
    `
    if (rope.pass)
    {
        static if (is (typeof (super.` ~ methodName ~ `)))
        {
            return super.` ~ methodName ~ `(params);
        }
        else
        {
            assert(false, "Cannot pass the call through to an abstract class or interface -- there's no method in super class!");
        }
    }
    else
    {
        static if (!is (` ~ ret ~ ` == void))
        {
            return rope.value;
        }
    }
    `;

    return header ~'{'~ funBody ~'}';
}

string formatQualifiers(T)()
{
    import std.array;
    auto ret = appender!(string[]);
    static if (is(T == const))
    {
        ret.put("const");
    }
    static if (is(T == immutable))
    {
        ret.put("immutable");
    }
    static if (is(T == shared))
    {
        ret.put("shared");
    }
    return ret.data.join(" ");
}

unittest {
    class A
    {
        void make() const shared
        {
        }
    }

    static assert(formatQualifiers!(typeof(A.make)) == "const shared");
}