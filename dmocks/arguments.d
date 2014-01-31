module dmocks.arguments;

import std.conv;
import std.algorithm;
import std.array;

import dmocks.util;
import dmocks.dynamic;

interface ArgumentsMatch
{
    bool matches(Dynamic[] args);
    string toString();
}

 //TODO: allow richer specification of arguments
class StrictArgumentsMatch : ArgumentsMatch
{
    private Dynamic[] _arguments;
    this(Dynamic[] args)
    {
        _arguments = args;
    }

    override bool matches(Dynamic[] args)
    {
        return _arguments == args;
    }

    override string toString()
    {
        return _arguments.formatArguments();
    }
}

class AnyArgumentsMatch : ArgumentsMatch
{
    override bool matches(Dynamic[] args)
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

auto arguments(ARGS...)(ARGS args)
{
    Dynamic[] res = new Dynamic[](ARGS.length);
    foreach(i, arg; args)
    {
        res[i] = dynamic(arg);
    }
    return res;
}

auto formatArguments(Dynamic[] _arguments)
{
    return "(" ~ _arguments.map!(a=>a.type.toString ~ " " ~ a.toString()).join(", ") ~")";
}

version (DMocksTest)
{
    unittest {
        mixin(test!("argument equality"));

        auto a = arguments!(int, real)(5, 9.7);
        auto b = arguments!(int, real)(5, 9.7);
        auto c = arguments!(int, real)(9, 1.1);
        auto d = arguments!(int, float)(5, 9.7f);

        assert (a == b);
        assert (a != c);
        assert (a != d);
    }

    unittest {
        mixin(test!("argument toString"));

        auto a = arguments!(int, real)(5, 9.7);
        a.formatArguments();
    }
}