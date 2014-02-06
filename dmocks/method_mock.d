module dmocks.method_mock;

import std.stdio;
import std.traits;
import std.metastrings;
import std.conv;

import dmocks.util;
import dmocks.repository;
import dmocks.qualifiers;

package:

//These are too complicated for decent unittests. Can't mock templates!

/++
The only method we care about externally.
Returns a string containing the overrides for this method
and all its overloads.
++/
string Methods (T, bool INHERITANCE, string methodName) () {
    /+version(DMocksDebug)
    {
        pragma(msg, methodName);
        pragma(msg, T);
    }+/
    string methodBodies = "";

    static if (is (typeof(__traits(getOverloads, T, methodName))))
    {
        foreach (overloadIndex, method; __traits(getOverloads, T, methodName)) 
        {
            static if (!__traits(isStaticFunction, method) && !(methodName[0..2] == "__") && 
                       !(INHERITANCE && __traits(isFinalFunction, method)))
                methodBodies ~= BuildMethodOverloads!(T.stringof, methodName, overloadIndex, method, INHERITANCE);
        }
    }
    return methodBodies;
}

/++
Returns a string containing the overload for a single function.
This function has a return value.
++/
string BuildMethodOverloads (string objectType, string methodName, int overloadIndex, alias method, bool inheritance)() 
{
    alias FunctionTypeOf!(method) METHOD_TYPE;
    enum returns = !is (ReturnType!(METHOD_TYPE) == void);

    enum self = `__traits(getOverloads, T, "` ~ methodName ~ `")[` ~ overloadIndex.to!string ~ `]`;
    enum selfType = "FunctionTypeOf!("~self~")";
    enum ret = returns ? `ReturnType!(` ~ selfType ~ `)` : `void`;
    enum paramTypes = `ParameterTypeTuple!(` ~ selfType ~ `)`;
    enum qualified = objectType ~ `.` ~ methodName;
    enum bool override_ = is(typeof(mixin (`Object.` ~ methodName))) && !__traits(isFinalFunction, method);
    enum header = ((inheritance || override_) ? `override ` : `final `) ~ ret ~ ` ` ~ methodName ~ `
        (` ~ paramTypes ~ ` params) ` ~ formatQualifiers!(method);

    string delegate_ = `delegate `~ret~` (`~paramTypes~` args){ ` ~ BuildForwardCall!("super", methodName) ~ `}`;

    return header ~` {  return mockMethodCall!(`~self~`, "`~methodName~`", T)(this, _owner, ` ~ delegate_ ~ `, params); `~`} `;
}

string BuildForwardCall(string mockedObject, string methodName)()
{
    return `static if (is (typeof (mocked___.` ~ methodName~`)))
            {
                return (mocked___.` ~ methodName ~`(args));
            }
            else static if (is (typeof (super.` ~ methodName~`)))
            {
                return (super.` ~ methodName ~`(args));
            }
            else
            {
                assert(false, "Cannot pass the call through - there's no implementation in base object!");
            }`;
}