module dmocks.expectation;

import dmocks.name_match;
import dmocks.qualifiers;
import dmocks.arguments;
import dmocks.util;
import dmocks.action;
import std.typecons;
import std.traits;
import dmocks.model;
import dmocks.event;
import std.range;
import std.conv;

package:

class EventExpectation : Expectation
{
    this(MockId object, NameMatch name, QualifierMatch qualifiers, ArgumentsMatch args, TypeInfo returnType)
    {
        this.object = object;
        this.name = name;
        this.repeatInterval = Interval(1,1);
        this.arguments = args;
        this.qualifiers = qualifiers;
        this.action = new Action(returnType);
        _matchedEvents = [];
    }
    MockId object;
    NameMatch name;
    QualifierMatch qualifiers;
    ArgumentsMatch arguments;
    private Event[] _matchedEvents;
    Interval repeatInterval;

    Action action;

    override string toString(string intendation)
    {
        auto apndr = appender!(string);
        apndr.put(intendation);
        apndr.put("Expectation: ");
        bool details = !satisfied;

        if (!details)
            apndr.put("satisfied, ");
        else
            apndr.put("not satisfied, ");

        apndr.put("Method: " ~ name.toString() ~ " " ~ arguments.toString() ~" "~ qualifiers.toString() ~ " ExpectedCalls: " ~ repeatInterval.toString());
        if (details)
        {
            apndr.put("\n" ~ intendation ~ "Calls: " ~ _matchedEvents.length.to!string);
            foreach(Event event; _matchedEvents)
            {
                apndr.put(intendation ~"  "~event.toString());
            }
        }
        return apndr.data;
    }

 
    override string toString()
    {
        return toString("");
    }

    EventExpectation match(Event event)
    {
        debugLog("Expectation.match:");
        if (object != event.object)
        {
            debugLog("object doesn't match");
            return null;
        }
        if (!name.matches(event.name))
        {
            debugLog("name doesn't match");
            return null;
        }
        if (!qualifiers.matches(event.qualifiers))
        {
            debugLog("qualifiers don't match");
            return null;
        }
        if (!arguments.matches(event.arguments))
        {
            debugLog("arguments don't match");
            return null;
        }
        if (_matchedEvents.length >= repeatInterval.Max)
        {
            debugLog("repeat interval desn't match");
            return null;
        }
        debugLog("full match");
        _matchedEvents ~= event;
        return this;
    }

    bool satisfied()
    {
        return _matchedEvents.length <=  repeatInterval.Max && _matchedEvents.length >=  repeatInterval.Min;
    }
}

class GroupExpectation : Expectation
{
    this()
    {
        repeatInterval = Interval(1,1);
        expectations = [];
    }
    Expectation[] expectations;
    bool ordered;
    Interval repeatInterval;

    EventExpectation match(Event event)
    {
        // match event to expectation
        foreach(Expectation expectation; expectations)
        {
            EventExpectation e = expectation.match(event);
            if (e !is null)
                return e;
            if (ordered && !expectation.satisfied())
                return null;
        }
        return null;
    }

    void addExpectation(Expectation expectation)
    {
        expectations ~= expectation;
    }

    bool satisfied()
    {
        foreach(Expectation expectation; expectations)
        {
            if (!expectation.satisfied())
                return false;
        }
        return true;
    }

    override string toString(string intendation)
    {
        auto apndr = appender!(string);
        apndr.put(intendation);
        apndr.put("GroupExpectation: ");
        bool details = !satisfied;

        if (!details)
            apndr.put("satisfied, ");
        else
            apndr.put("not satisfied, ");

        if (ordered)
            apndr.put("ordered, ");
        else
            apndr.put("unordered, ");

        apndr.put("Interval: ");
        apndr.put(repeatInterval.toString());
        apndr.put("\n");

        if (details)
        {
            foreach(Expectation expectation; expectations)
            {
                apndr.put(expectation.toString(intendation ~ "  "));
            }
        }
        return apndr.data;
    }

    override string toString()
    {
        return toString("");
    }
}

GroupExpectation createGroupExpectation(bool ordered)
{
    auto ret = new GroupExpectation();
    ret.ordered = ordered;
    return ret;
}

// composite design pattern
interface Expectation
{
    EventExpectation match(Event event);
    bool satisfied();
    string toString(string intendation);
    string toString();
}

EventExpectation createExpectation(alias METHOD, ARGS...)(MockId object, string name, ARGS args)
{
    auto ret = new EventExpectation(object, new NameMatchText(name), qualifierMatch!METHOD,
                                    new StrictArgumentsMatch(arguments(args)), typeid(ReturnType!(typeof(METHOD))));
    return ret;
}