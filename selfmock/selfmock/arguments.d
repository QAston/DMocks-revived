module selfmock.arguments;


interface IArguments
{
	bool opEquals(IArguments other);
	char[] toString();
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

            override char[] toString () 
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
            
            public U arguments;
            
            bool opEquals (IArguments other) 
            {
                auto args = cast(typeof(this)) other;
                if (args is null) return false;
                foreach (i, arg; arguments) 
                {
                    if (args.arguments[i] !is arg) 
                    {
                        return false;
                    }
                }

                return true;
            }

            override char[] toString () 
            { 
                char[] value = "(";
                foreach (u; arguments) 
                {
                    value ~= selfmock.util.toString(u) ~ ", ";
                }

                return value[0..$-2] ~ ")";
            }
        }
    }
}
