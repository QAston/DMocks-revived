module dmocks.name_match;

import std.regex;

interface NameMatch
{
    bool matches(string against);
    string toString();
}

/++
+ String name matcher
+ Match occurs when string given are equal
+/
class NameMatchText : NameMatch
{
    private string _text;
    /// takes a string which will be tested for exact match
    this(string text)
    {
        this._text = text;
    }
    bool matches(string against)
    {
        return _text == against;
    }

    override string toString()
    {
        return _text;
    }
}

/++
+ Regex pattern matcher
+ Match occurs when there's non-empty set of matches for a given pattern
+/
class NameMatchRegex : NameMatch
{
    private string _pattern;
    private const(char)[] _flags;
    /++
    + creates a name matcher using std.regex module
    + takes regex pattern and flags as described in std.regex.regex
    +/
    this(string pattern, const(char)[] flags="")
    {
        this._pattern = pattern;
        this._flags = flags;
    }

    bool matches(string against)
    {
        return !matchFirst(against, regex(_pattern, _flags)).captures.empty();
    }

    override string toString()
    {
        return "(regex:)" ~ _pattern;
    }
}

unittest {
    {
        NameMatch a = new NameMatchText("asd");
        assert(a.matches("asd"));
        assert(!a.matches("qwe"));
        assert(!a.matches("asdasd"));
    }

    {
        NameMatch a = new NameMatchRegex("asd");
        assert(a.matches("asdasd"));
        assert(a.matches("asd"));
        assert(!a.matches("a"));
    }

    {
        NameMatch a = new NameMatchRegex("a..");
        assert(a.matches("asd"));
        assert(a.matches("asdq"));
        assert(!a.matches("a"));
    }
}