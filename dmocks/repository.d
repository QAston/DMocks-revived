module dmocks.repository;

import dmocks.util;
import dmocks.model;
import dmocks.arguments;

import std.stdio;
import std.conv;
import std.traits;

import dmocks.call;
import dmocks.expectation;
import dmocks.action;

package:

class MockRepository
{
    // TODO: split this up somehow!
    private bool _allowDefaults = false;
    private bool _recording = true;
    private bool _ordered = false;
    private bool _allowUnexpected = false;

    private Call[] _calls = [];
    private Call[] _unexpectedCalls = [];
    private GroupExpectation _rootGroupExpectation;
    private CallExpectation _lastRecordedCallExpectation; // stores last call added to _lastGroupExpectation
    private Call _lastRecordedCall; // stores last call with which _lastRecordedCallExpectation was created
    private GroupExpectation _lastGroupExpectation; // stores last group added to _rootGroupExpectation

    private void CheckLastCallSetup ()
    {
        if (_allowDefaults || _lastRecordedCallExpectation is null || _lastRecordedCallExpectation.action.hasAction)
        {
            return;
        }

        throw new MocksSetupException(
                "Last expectation: if you do not specify the AllowDefaults option, you need to return a value, throw an exception, execute a delegate, or pass through to base function. The expectation is: " ~ _lastRecordedCallExpectation.toString());
    }

    this()
    {   
        _rootGroupExpectation = createGroupExpectation(false);
        Ordered(false);
    }


    void AllowDefaults (bool value)
    {
        _allowDefaults = value;
    }

    void AllowUnexpected(bool value)
    {
        _allowUnexpected = value;
    }

    bool AllowUnexpected()
    {
        return _allowUnexpected;
    }

    bool Recording ()
    {
        return _recording;
    }

    bool Ordered ()
    {
        return _ordered;
    }

    void Replay ()
    {
        CheckLastCallSetup();
        _recording = false;
    }

    void BackToRecord ()
    {
        _recording = true;
    }

    void Ordered(bool value)
    {
        debugLog("SETTING ORDERED: %s", value);
        _ordered = value;
        _lastGroupExpectation = createGroupExpectation(_ordered);
        _rootGroupExpectation.addExpectation(_lastGroupExpectation);
    }

    void Record(CallExpectation expectation, Call call)
    {
        CheckLastCallSetup();
        _lastGroupExpectation.addExpectation(expectation);
        _lastRecordedCallExpectation = expectation;
        _lastRecordedCall = call;
    }

    @trusted public auto MethodCall (alias METHOD, ARGS...) (MockId mocked, string name, ARGS args)
    {
        alias ReturnType!(FunctionTypeOf!(METHOD)) TReturn;

        ReturnOrPass!(TReturn) rope;
        auto call = createCall!METHOD(mocked, name, args);
        debugLog("checking Recording...");
        if (Recording)
        {
            auto expectation = createExpectation!(METHOD)(mocked, name, args);
            Record(expectation, call);
            return rope;
        }

        debugLog("checking for matching expectation...");
        auto expectation = Match(call);

        debugLog("checking if expectation is null...");
        if (expectation is null)
        {
            if (AllowUnexpected())
                return rope;
            throw new ExpectationViolationException("Unexpected call to method: " ~ call.toString());
        }

        rope = expectation.action.getActor().act!(TReturn, ARGS)(args);
        debugLog("returning...");
        return rope;
    }

    CallExpectation Match(Call call)
    {
        _calls ~= call;
        auto exp = _rootGroupExpectation.match(call);
        if (exp is null)
            _unexpectedCalls ~= _calls;
        return exp;
    }

    CallExpectation LastRecordedCallExpectation ()
    {
        return _lastRecordedCallExpectation;
    }

    Call LastRecordedCall ()
    {
        return _lastRecordedCall;
    }

    void Verify (bool checkUnmatchedExpectations, bool checkUnexpectedCalls)
    {
        string expectationError = "";
        if (checkUnmatchedExpectations && !_rootGroupExpectation.satisfied)
            expectationError~="\n" ~ _rootGroupExpectation.toString();
                
        if (checkUnexpectedCalls && _unexpectedCalls.length > 0)
            expectationError~="\n" ~ UnexpectedCallsReport;
        if (expectationError != "")
            throw new ExpectationViolationException(expectationError);
    }

    string UnexpectedCallsReport()
    {
        import std.array;
        auto apndr = appender!(string);
        apndr.put("Unexpected calls(calls):\n");
        foreach(Call ev; _unexpectedCalls)
        {
            apndr.put(ev.toString());
            apndr.put("\n");
        }
        return apndr.data;
    }

    version (DMocksTest)
    {
        unittest {
            mixin(test!("repository record/replay"));

            MockRepository r = new MockRepository();
            assert (r.Recording());
            r.Replay();
            assert (!r.Recording());
            r.BackToRecord();
            assert (r.Recording());
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
            auto c = new MockRepository();
            auto mid = new MockId;
            //c.Call!(a.a)(mid, "a");
            static assert(__traits(compiles, c.MethodCall!(a.a)(mid, "a")));
        }
    }
}
