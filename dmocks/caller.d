module dmocks.caller;

import dmocks.call;
import dmocks.repository;
import dmocks.model;
import dmocks.util;
import dmocks.action;
import dmocks.arguments;


class Caller
{
    private MockRepository _owner;

    public this (MockRepository owner)
    {
        _owner = owner;
    }

    @trusted public ReturnOrPass!(TReturn) Call (TReturn, U...) (MockId mocked,
            string name, string qualifiers, U args)
    {
        ReturnOrPass!(TReturn) rope;
        debugLog("checking _owner.Recording...");
        if (_owner.Recording)
        {
            _owner.Record!(U)(mocked, name, qualifiers, args, !is (TReturn == void));
            return rope;
        }

        debugLog("checking for matching call...");
        ICall call = _owner.Match!(U)(mocked, name, qualifiers, args);

        debugLog("checking if call is null...");
        if (call is null)
        {
            throw new ExpectationViolationException("Unexpected call to method: " ~name~ " " ~ new Arguments!(U)(args).toString() ~ " " ~ qualifiers);
        }

        rope = call.Action.getActor().act!(TReturn, U)(args);
        debugLog("returning...");
        return rope;
    }
}
