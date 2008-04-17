module selfmock.methodmock;
import tango.core.Traits;
import selfmock.traits;
import selfmock.action;
import selfmock.caller;
import selfmock.mockobject;
public import selfmock.util;


template method(alias themethod, char[] name)
{
	const char[] method = method!(name, ReturnTypeOf!(themethod), ParameterTupleOf!(themethod))();
}

char[] method(char[] name, TReturn, TArgs...)()
{
    char[] sigargs = typedArgs!(TArgs);
    char[] args = untypedArgs!(TArgs);
    char[] returnType = TReturn.stringof;
    char[] returns = (is (TReturn == void)) ? `false` : `true`;
    char[] returnArgs = getReturnArgs(returnType, TArgs.stringof);
    char[] qualified = "typeof(this).stringof ~ `.` ~ `" ~ name ~ "`";
    char[] nameArgs = (args.length) ? qualified ~ `, ` ~ args : qualified;
    return 
    returnType ~ ` ` ~ name ~ `(` ~ sigargs ~ `)
    {
    	version(MocksDebug) Stdout("checking _owner...").newline;
    	if (_owner is null)
    	{
    		throw new Exception("owner cannot be null! Contact the stupid mocks developer.");
    	}
    	auto rope = _owner.call!(` ~ returnArgs ~ `)(this, ` ~ nameArgs ~ `);
    	if (rope.pass)
    	{
    		static if (is (typeof (super.` ~ name ~ `)))
    		{
    			return super.` ~ name ~ `(` ~ args ~ `);
    		}
    		else
    		{
    			throw new InvalidOperationException("I was supposed to pass this call through to an abstract class or interface -- I can't do that!");
    		}
    	}
    	else
    	{
    		static if (!is (` ~ returnType ~ ` == void))
    		{
    			return rope.value;
    		}
    	}
    }`;
}

char[] nameof(char[] name)
{
	char[] realName = "";
	foreach (c; name)
	{
		if (c == '(') return realName;
		realName ~= c;
	}
	return realName;
}

char[] getReturnArgs(char[] returnType, char[] argTypes)
{
    if (argTypes.length > 2)
    {
        return returnType ~ `, ` ~ argTypes[1..$-1];
    }
    else
    {
        return returnType;
    }
}

// Outputs `int arg3, char[] arg2, float arg1` or such.
char[] typedArgs(T...)()
{
    static if (T.length)
    {
        char[] current = T[0].stringof ~ ` arg` ~ ToString!(T.length);
        static if (T.length > 1)
        {
            current ~= `, ` ~ typedArgs!(T[1..$])();
        }
        return current;
    }
    else
    {
        return ``;
    }
}

char[] untypedArgs(T...)()
{
    static if (T.length)
    {
        char[] current = `arg` ~ ToString!(T.length);
        static if (T.length > 1)
        {
            current ~= `, ` ~ untypedArgs!(T[1..$])();
        }
        return current;
    }
    else
    {
        return ``;
    }
}

version (MocksTest)
{
	/*
	interface IFoo
	{
		void bar();
		void bat(int i);
		int baz(IFoo other, int j);
	}
	
	class Bar : Mocked, IFoo
	{
		//pragma(msg, method!(IFoo.bar, "bar")());
		//pragma(msg, method!(IFoo.bat, "bat")());
		mixin(method!(typeof(IFoo.bar), "bar")());
		mixin(method!(typeof(IFoo.bat), "bat")());
		mixin(method!(typeof(IFoo.baz), "baz")());
	}
	*/
}

