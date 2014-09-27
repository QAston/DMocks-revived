module dmocks.method_mock;

import std.stdio;
import std.traits;
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
    enum dynVarArgs = variadicFunctionStyle!method == Variadic.d;
    enum varargsString = dynVarArgs ? ", ..." : "";
    enum qualified = objectType ~ `.` ~ methodName;
    enum bool override_ = is(typeof(mixin (`Object.` ~ methodName))) && !__traits(isFinalFunction, method);
    enum header = ((inheritance || override_) ? `override ` : `final `) ~ ret ~ ` ` ~ methodName ~ `
        (` ~ paramTypes ~ ` params`~ varargsString ~`) ` ~ formatQualifiers!(method);

    string delegate_ = `delegate `~ret~` (`~paramTypes~` args, TypeInfo[] varArgsList, void* varArgsPtr){ ` ~ BuildForwardCall!(methodName, dynVarArgs) ~ `}`;

    enum varargsValueString = dynVarArgs ? ", _arguments, _argptr" : ", null, null";
    return header ~` {  return mockMethodCall!(`~self~`, "`~methodName~`", T)(this, _owner, ` ~ delegate_ ~ varargsValueString ~`, params); `~`} `;
}

string BuildForwardCall(string methodName, bool dynamicVarArgs)()
{
    enum methodString = dynamicVarArgs ? "v"~methodName : methodName;
    enum argsPassed = dynamicVarArgs ? "(args, varArgsList, varArgsPtr)" : "(args)";

    return `static if (is (typeof (mocked___.` ~ methodString~`)))
            {
                return (mocked___.` ~ methodString ~ argsPassed~`);
            }
            else static if (is (typeof (super.` ~ methodString~`)))
            {
                return (super.` ~ methodString ~ argsPassed~`);
            }
            else
            {
                assert(false, "Cannot pass the call through - there's no `~methodString~` implementation in base object!");
            }`;
}
