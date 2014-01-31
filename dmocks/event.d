module dmocks.event;

import dmocks.model;
import dmocks.arguments;
import dmocks.qualifiers;
import dmocks.dynamic;

import std.array;
import std.conv;

package:

class Event
{
    MockId object;
    string name;
    string[] qualifiers;
    Dynamic[] arguments;

    override string toString()
    {
        string arguments = (arguments is null) ? "(<unknown>)" : arguments.formatArguments;
        return name ~ " "~ arguments ~ " " ~ qualifiers.join(" ");
    }
}

Event createEvent(alias METHOD, ARGS...)(MockId object, string name, ARGS args)
{
    auto ret = new Event;
    ret.object = object;
    ret.name = name;
    ret.qualifiers = qualifiers!METHOD;
    ret.arguments = arguments(args);
    return ret;
}