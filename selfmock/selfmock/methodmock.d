module selfmock.methodmock;
import tango.core.Traits;
import selfmock.traits;

char[] method(alias theMethod)()
{
    char[] name = theMethod.stringof;
    char[] sigargs = typedArgs!(ParameterTupleOf!(theMethod));
    char[] args = untypedArgs(ParameterTupleOf!(theMethod).length);
    char[] returnType = ReturnType!(theMethod).stringof;
    return 
    returnType ~ ` ` ~ name ~ `(` ~ sigargs ~ `)
    {
        auto call = _owner.call(this, ` ~ name ~ `, ` ~ args ~ `);

    }`;
}

// Outputs `int arg3, char[] arg2, float arg1, Object arg0` or such.
char[] typedArgs(T...)()
{
    if (T.length)
    {
        char[] current = T.stringof ~ `arg` ~ ToString!(T.length);
        if (T.length > 1)
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
    if (T.length)
    {
        char[] current = `arg` ~ ToString!(T.length);
        if (T.length > 1)
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


