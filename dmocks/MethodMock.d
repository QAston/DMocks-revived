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
            methodBodies ~= VoidMethod!(name, ParameterTypeTuple!(func));
        } else {
            methodBodies ~= ReturningMethod!(
                                name,
                                ReturnType!(func),
                                ParameterTypeTuple!(func));
        }
    }
    return methodBodies;
}


/++
    Returns a string containing the overload for a single function.
    This function has a return value.
 ++/
string ReturningMethod (string name, T, U...)() {
    /+
    static if (U.length == 0) {
        if (name == "toHash") {
            // I don't want to override toHash; bad things happen
            // since I use associative arrays.
            return ``;
        }
    }+/
    string args = String!(U)();
    string argArgs = Arguments!(U);
    string nameArgs = `"` ~ name ~ (U.length == 0 ? `"` : `", ` ~ Arguments!(U)());
    string retArgs = T.stringof ~ (U.length == 0 ? `` : `, ` ~ args);
    return `override ` ~ T.stringof ~ " " ~ name ~ "(" ~ TypedArguments!(U)() ~ ")" ~
        `{
            if (_owner is null) {
                throw new Exception("owner cannot be null!");
            }
            if (_owner.Recording) {
                _owner.Record!(` ~ args ~ `)(this, ` ~ nameArgs ~ `);
                return (` ~ T.stringof ~ `).init;
            } 
            auto call = cast(Call!(` ~ args ~ `))
                    _owner.Match!(` ~ args ~ `)(this, ` ~ nameArgs ~ `);
            if (call is null) {
                throw new ExpectationViolationException();
            }

            if (call.PassThrough()) {
                static if (__traits(compiles, super.` ~ name ~ `(` ~ argArgs ~ `))) {
                    return super.` ~ name ~ `(` ~ argArgs ~ `);
                } else {
                    throw new InvalidOperationException("Attempted to pass through to an abstract or interface method. This operation is not allowed.");
                }
            }

            if (call.ToThrow() !is null) {
                throw call.ToThrow();
            }

            auto action = call.Action();
            if (action.hasValue() && action.peek!(` ~ T.stringof ~ ` delegate (` ~ args ~ `))) {
                auto func = *action.peek!(` ~ T.stringof ~ ` delegate (` ~ args ~ `));
                //writefln("i can has action");
                if (func is null) {
                    writefln("noooo they be stealin mah action");
                    throw new InvalidOperationException("The specified delegate was of the wrong type.");
                }

                //writefln("executing action");
                auto ret = func(` ~ Arguments!(U)() ~ `);
                //writefln("executed action");
                return ret;
            } else {
                //writefln("i no can has action");
            }
            if (!call.ReturnValue().hasValue()) {
                return (` ~ T.stringof ~ `).init;
            }
            return call.ReturnValue().coerce!(` ~ T.stringof ~ `);
        }
        `;
                //throw new ExpectationViolationException!(` ~ args ~ `)(` ~ nameArgs ~ `);
} 

/++
    Returns a string containing the overload for a single function.
    This function does not have a return value. 
 ++/
string VoidMethod (string name, U...)() {
    string args = String!(U)();
    string argArgs = Arguments!(U);
    string nameArgs = `"` ~ name ~ (U.length == 0 ? `"` : `", ` ~ Arguments!(U)());
    string retArgs = `void` ~ (U.length == 0 ? `` : `, ` ~ args);
    return "override void " ~ name ~ "(" ~ TypedArguments!(U)() ~ ")"  ~ 
        `{
            if (_owner.Recording) {
                _owner.Record!(` ~ args ~ `)(this, ` ~ nameArgs ~ `);
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
            if (action.hasValue() && action.peek!(void delegate (` ~ args ~ `))) {
                auto func = *action.peek!(void delegate (` ~ args ~ `));
                //writefln("i can has action");
                if (func is null) {
                    //writefln("noooo they be stealin mah action");
                    throw new InvalidOperationException("The specified delegate was of the wrong type.");
                }

                //writefln("executing action");
                func(` ~ argArgs ~ `);
                //writefln("executed action");
            } else {
                //writefln("i no can has action");
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
