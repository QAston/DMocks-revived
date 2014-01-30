module dmocks.event;

import dmocks.model;
import dmocks.arguments;
import dmocks.qualifiers;

import std.array;
import std.conv;

package:

class Event
{
    MockId object;
    string name;
    string[] qualifiers;
    IArguments arguments;

    override string toString()
    {
        string arguments = (arguments is null) ? "(<unknown>)" : arguments.to!string;
        return name ~ " "~ arguments ~ " " ~ qualifiers.join(" ");
    }
}

Event createEvent(alias METHOD, ARGS...)(MockId object, string name, ARGS args)
{
    auto ret = new Event;
    ret.object = object;
    ret.name = name;
    ret.qualifiers = qualifiers!METHOD;
    ret.arguments = new Arguments!ARGS(args);
    return ret;
}