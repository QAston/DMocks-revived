module dmocks.caller;

import dmocks.repository;
import dmocks.model;
import dmocks.util;
import dmocks.action;
import dmocks.arguments;

import dmocks.event;
import std.array;
import std.traits;
import dmocks.expectation;
import dmocks.qualifiers;

package:

class Caller
{
    private MockRepository _owner;

    public this (MockRepository owner)
    {
        _owner = owner;
    }

    @trusted public auto Call (alias METHOD, ARGS...) (MockId mocked, string name, ARGS args)
    {
        alias ReturnType!(typeof(METHOD)) TReturn;
         
        ReturnOrPass!(TReturn) rope;
        debugLog("checking _owner.Recording...");
        if (_owner.Recording)
        {
            auto expectation = createExpectation!(METHOD)(mocked, name, args);
            _owner.Record(expectation);
            return rope;
        }

        debugLog("checking for matching expectation...");
        auto event = createEvent!METHOD(mocked, name, args);
        auto expectation = _owner.Match(event);

        debugLog("checking if expectation is null...");
        if (expectation is null)
        {
            throw new ExpectationViolationException("Unexpected call to method: " ~ event.toString());
        }

        rope = expectation.action.getActor().act!(TReturn, ARGS)(args);
        debugLog("returning...");
        return rope;
    }
}

// test for correctly formulated template
unittest {
    class A
    {
        public void a()
        {
        }
    }
    auto a = new A;
    auto c = new Caller(null);
    auto mid = new FakeMocked;
    //c.Call!(a.a)(mid, "a");
    static assert(__traits(compiles, c.Call!(a.a)(mid, "a")));
}
