module dmocks.arguments;

import std.conv;

import dmocks.util;

package:

interface ArgumentsMatch
{
    bool matches(IArguments args);
    string toString();
}

 //TODO: allow richer specification of arguments
class StrictArgumentsMatch : ArgumentsMatch
{
    private IArguments _arguments;
    this(IArguments args)
    {
        _arguments = args;
    }

    override bool matches(IArguments args)
    {
        return _arguments == args;
    }

    override string toString()
    {
        return _arguments.toString();
    }
}

class AnyArgumentsMatch : ArgumentsMatch
{
    override bool matches(IArguments args)
    {
        return true;
    }

    override string toString()
    {
        return "(<any arguments>)";
    }
}

interface IArguments
{
    string toString();
    bool opEquals (Object other);
}

//TODO: this type must be replaced with something not relying on templates
template Arguments (U...) 
{
    static if (U.length == 0) 
    {
        class Arguments : IArguments
        {
            this () {}
            override bool opEquals (Object other) 
            {
                return cast(typeof(this)) other !is null;
            }

            override string toString ()
            { 
                return "()"; 
            }
        }
    } 
    else 
    {
        class Arguments : IArguments
        {
            this (U args) 
            { 
                Arguments = args; 
            }
            
            public U Arguments;
            
            override bool opEquals (Object other) 
            {
                auto args = cast(typeof(this)) other;
                if (args is null) return false;
                foreach (i, arg; Arguments) 
                {
                    if (args.Arguments[i] != arg) 
                    {
                        return false;
                    }
                }

                return true;
            }

            override string toString ()
            { 
                string value = "(";
                foreach (u; Arguments) 
                {
                    value ~= u.to!string() ~ ", ";
                }

                return value[0..$-2] ~ ")";
            }
        }
    }
}

version (DMocksTest)
{
    unittest {
        mixin(test!("argument equality"));

        auto a = new Arguments!(int, real)(5, 9.7);
        auto b = new Arguments!(int, real)(5, 9.7);
        auto c = new Arguments!(int, real)(9, 1.1);
        auto d = new Arguments!(int, float)(5, 9.7f);

        assert (a == b);
        assert (a != c);
        assert (a != d);
    }

    unittest {
        mixin(test!("argument toString"));

        auto a = new Arguments!(int, real)(5, 9.7);
        a.toString();
    }
}