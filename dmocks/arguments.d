module dmocks.arguments;

import std.conv;

interface IArguments
{
    bool opEquals(IArguments other);
    string toString();
}

/++
    There used to be a LOT of code duplication because D doesn't like
    a variable whose type is an empty type tuple. This is all that remains.
 ++/
template Arguments (U...) 
{
    static if (U.length == 0) 
    {
        public class Arguments : IArguments
        {
            this () {}
            bool opEquals (IArguments other) 
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
            
            bool opEquals (IArguments other) 
            {
                auto args = cast(typeof(this)) other;
                if (args is null) return false;
                foreach (i, arg; Arguments) 
                {
                    if (args.Arguments[i] !is arg) 
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
