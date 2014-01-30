module dmocks.repository;

import dmocks.util;
import dmocks.model;
import dmocks.arguments;

import std.variant;
import std.stdio;
import std.conv;

import dmocks.event;
import dmocks.expectation;

package:

class MockRepository
{
    // TODO: split this up somehow!
    private bool _allowDefaults = false;
    private bool _recording = true;
    private bool _ordered = false;
    private bool _allowUnexpected = false;

    private Event[] _events = [];
    private Event[] _unexpectedEvents = [];
    private GroupExpectation _rootGroupExpectation;
    private EventExpectation _lastEventExpectation; // stores last event added to _lastGroupExpectation
    private GroupExpectation _lastGroupExpectation; // stores last group added to _rootGroupExpectation

    private void CheckLastCallSetup ()
    {
        if (_allowDefaults || _lastEventExpectation is null || _lastEventExpectation.action.hasAction)
        {
            return;
        }

        throw new MocksSetupException(
                "Last expectation: if you do not specify the AllowDefaults option, you need to return a value, throw an exception, execute a delegate, or pass through to base function. The expectation is: " ~ _lastEventExpectation.toString());
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

    void Record(EventExpectation expectation)
    {
        CheckLastCallSetup();
        _lastGroupExpectation.addExpectation(expectation);
        _lastEventExpectation = expectation;
    }

    EventExpectation Match(Event event)
    {
        _events ~= event;
        auto exp = _rootGroupExpectation.match(event);
        if (exp is null)
            _unexpectedEvents ~= _events;
        return exp;
    }

    EventExpectation LastExpectation ()
    {
        return _lastEventExpectation;
    }

    void Verify (bool checkUnmatchedExpectations, bool checkUnexpectedCalls)
    {
        string expectationError = "";
        if (checkUnmatchedExpectations && !_rootGroupExpectation.satisfied)
            expectationError~="\n" ~ _rootGroupExpectation.toString();
                
        if (checkUnexpectedCalls && _unexpectedEvents.length > 0)
            expectationError~="\n" ~ UnexpectedEventsReport;
        if (expectationError != "")
            throw new ExpectationViolationException(expectationError);
    }

    string UnexpectedEventsReport()
    {
        import std.array;
        auto apndr = appender!(string);
        apndr.put("Unexpected events(calls):\n");
        foreach(Event ev; _unexpectedEvents)
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
    }
}
