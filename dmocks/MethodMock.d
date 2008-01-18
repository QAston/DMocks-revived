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
    foreach (method; __traits(getVirtualFunctions, T, name)) {
        alias typeof(method) func;
        static if (is(ReturnType!(func) == void)) {
            methodBodies ~= VoidMethod!(T.stringof, name, ParameterTypeTuple!(func));
        } else {
            methodBodies ~= ReturningMethod!(
                                T.stringof,
                                name,
                                ReturnType!(func),
                                ParameterTypeTuple!(func));
        }
    }
    return methodBodies;
}

string Constructor (T) () {
    static if (!__traits(compiles, T._ctor)) {
        return ``;
    } else {
        return `this (` ~ TypedArguments!(ParameterTypeTuple!(T._ctor)) ~ `) {
            super(` ~ Arguments!(ParameterTypeTuple!(T._ctor))() ~ `);
        }`;
    }
}


/++
    Returns a string containing the overload for a single function.
    This function has a return value.
 ++/
string ReturningMethod (string type, string name, T, U...)() {
    /+
    static if (U.length == 0) {
        if (name == "toHash") {
            // I don't want to override toHash; bad things happen
            // since I use associative arrays.
            return ``;
        }
    }+/
    string qualified = type ~ `.` ~ name;
    string args = String!(U)();
    string argArgs = Arguments!(U);
    string nameArgs = `"` ~ qualified ~ (U.length == 0 ? `"` : `", ` ~ Arguments!(U)());
    string retArgs = T.stringof ~ (U.length == 0 ? `` : `, ` ~ args);
    return `override ` ~ T.stringof ~ " " ~ name ~ "(" ~ TypedArguments!(U)() ~ ")" ~
        `{
            version(MocksDebug)version(MocksDebug) writefln("checking _owner...");
            if (_owner is null) {
                throw new Exception("owner cannot be null!");
            }
            version(MocksDebug) writefln("checking _owner.Recording...");
            if (_owner.Recording) {
                _owner.Record!(` ~ args ~ `)(this, ` ~ nameArgs ~ `, true);
                return (` ~ T.stringof ~ `).init;
            } 
            version(MocksDebug) writefln("checking for matching call...");
            auto call = cast(Call!(` ~ args ~ `))
                    _owner.Match!(` ~ args ~ `)(this, ` ~ nameArgs ~ `);
            version(MocksDebug) writefln("checking if call is null...");
            if (call is null) {
                throw new ExpectationViolationException();
            }

            version(MocksDebug) writefln("checking for passthrough...");
            if (call.PassThrough()) {
                static if (__traits(compiles, super.` ~ name ~ `(` ~ argArgs ~ `))) {
                    return super.` ~ name ~ `(` ~ argArgs ~ `);
                } else {
                    throw new InvalidOperationException("Attempted to pass through to an abstract or interface method. This operation is not allowed.");
                }
            }

            version(MocksDebug) writefln("checking for something to throw...");
            if (call.ToThrow() !is null) {
                version(MocksDebug) writefln("throwing");
                throw call.ToThrow();
            }

            version(MocksDebug) writefln("checking for delegate to execute...");
            auto action = call.Action();
            alias typeof(delegate (` ~ args ~ `){return (` ~ T.stringof ~ `).init; }) action_type;
            if (action.hasValue() && action.peek!(action_type)) {
                auto func = *action.peek!(action_type);
                version(MocksDebug) writefln("i can has action");
                if (func is null) {
                    version(MocksDebug) writefln("noooo they be stealin mah action");
                    throw new InvalidOperationException("The specified delegate was of the wrong type.");
                }

                version(MocksDebug) writefln("executing action");
                auto ret = func(` ~ Arguments!(U)() ~ `);
                version(MocksDebug) writefln("executed action");
                return ret;
            } else {
                version(MocksDebug) writefln("i no can has action");
            }
            if (!call.ReturnValue().hasValue()) {
                version(MocksDebug) writefln("no return value set");
                return (` ~ T.stringof ~ `).init;
            }

            version(MocksDebug) writefln("getting a value to return...");
            auto retval = *call.ReturnValue().peek!(` ~ T.stringof ~ `); 
            version(MocksDebug) writefln("returning...");
            return retval;
        }
        `;
                //throw new ExpectationViolationException!(` ~ args ~ `)(` ~ nameArgs ~ `);
} 

/++
    Returns a string containing the overload for a single function.
    This function does not have a return value. 
 ++/
string VoidMethod (string type, string name, U...)() {
    string qualified = type ~ `.` ~ name;
    string args = String!(U)();
    string argArgs = Arguments!(U);
    string nameArgs = `"` ~ qualified ~ (U.length == 0 ? `"` : `", ` ~ Arguments!(U)());
    string retArgs = `void` ~ (U.length == 0 ? `` : `, ` ~ args);
    return "/*override*/ void " ~ name ~ "(" ~ TypedArguments!(U)() ~ ")"  ~ 
        `{
            version(MocksDebug) writefln("checking _owner...");
            if (_owner is null) {
                throw new Exception("owner cannot be null!");
            }
            if (_owner.Recording) {
                _owner.Record!(` ~ args ~ `)(this, ` ~ nameArgs ~ `, false);
                return;
            } 
            auto call = cast(Call!(` ~ args ~ `))
                    _owner.Match!(` ~ args ~ `)(this, ` ~ nameArgs ~ `);
            if (call is null) {
                throw new ExpectationViolationException();
            }

            if (call.PassThrough()) {
                static if (__traits(compiles, super.` ~ name ~ `(` ~ argArgs ~ `))) {
                    super.` ~ name ~ `(` ~ argArgs ~ `);
                    return;
                } else {
                    throw new InvalidOperationException("Attempted to pass through to an abstract or interface method. This operation is not allowed.");
                }
            }

            if (call.ToThrow() !is null) {
                throw call.ToThrow();
            }

            auto action = call.Action();
            alias typeof(delegate(` ~ args ~ `){}) action_type;
            if (action.hasValue() && action.peek!(action_type)) {
                auto func = *action.peek!(action_type);
                version(MocksDebug) writefln("i can has action");
                if (func is null) {
                    version(MocksDebug) writefln("noooo they be stealin mah action");
                    throw new InvalidOperationException("The specified delegate was of the wrong type.");
                }

                version(MocksDebug) writefln("executing action");
                func(` ~ argArgs ~ `);
                version(MocksDebug) writefln("executed action");
            } else {
                version(MocksDebug) writefln("i no can has action");
            }
        }
        `;
                //throw new ExpectationViolationException!(` ~ args ~ `)(` ~ nameArgs ~ `);
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
