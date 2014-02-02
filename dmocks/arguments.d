module dmocks.arguments;

import std.conv;
import std.algorithm;
import std.array;
import std.range;

import dmocks.util;
import dmocks.dynamic;

interface ArgumentsMatch
{
    bool matches(Dynamic[] args);
    string toString();
}

auto delegateArgumentsMatch(Dynamic[] expected, bool delegate(Dynamic[] expected, Dynamic[] called) del)
{
    return new DelegateArgumentsMatch(expected, del);
}

/++
+ Compares expectated arguments with arguments from a call by user provided delegate
++/
class DelegateArgumentsMatch : ArgumentsMatch
{
    private Dynamic[] _arguments;
    private bool delegate(Dynamic[], Dynamic[]) _delegate;
    this(Dynamic[] args, bool delegate(Dynamic[], Dynamic[]) del)
    {
        _arguments = args;
        _delegate = del;
    }
    override bool matches(Dynamic[] args)
    {
        return _delegate(_arguments, args);
    }
    override string toString()
    {
        return "(args checked by delegate)";
    }
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

class ArgumentsTypeMatch : ArgumentsMatch
{
    private Dynamic[] _arguments;
    this(Dynamic[] args)
    {
        _arguments = args;
    }
    override bool matches(Dynamic[] args)
    {
        import std.range;
        if (args.length != _arguments.length)
            return false;

        foreach(e; zip(args, _arguments))
        {
            if (e[0].type != e[1].type)
                return false;
        }
        return true;
    }

    override string toString()
    {
        return "("~_arguments.map!(a=>a.type.toString).join(", ")~")";
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