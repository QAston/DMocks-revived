module dmocks.qualifiers;

import std.traits;
import std.algorithm;
import std.range;
import std.exception;
import std.array;

import dmocks.util;

/// Factory for qualifier matches
/// specifies match that exactly matches passed method T
QualifierMatch qualifierMatch(alias T)()
{
    auto q = QualifierMatch();
    auto quals = qualifiers!T;
    foreach(string name; quals)
    {
        q._qualifiers[name] = true;
    }
    foreach(string name; validQualifiers.filter!(a=>a !in q._qualifiers))
    {
        q._qualifiers[name] = false;
    }
    debug enforceQualifierMatch(q._qualifiers);
    return q;
}

/// Factory for qualifier match objects
/// Let's you create exact pattern for matching methods by qualifiers
/// Params:
///  quals - map specifying matching condition
///  - true - matches to method with qualifier
///  - false - matches to method without qualifier
///  - not included - qualifier is ignored in matching (optional)
QualifierMatch qualifierMatch(bool[string] quals)
{
    enforceQualifierMatch(quals);
    auto q = QualifierMatch();
    q._qualifiers = quals;
    return q;
}

/// Helper function getting qualifiers string array
string[] qualifiers(alias T)()
{
    return getFunctionAttributes!(T)() ~ getMethodAttributes!(T)();
}

string formatQualifiers(alias T)()
{
    return qualifiers!T.join(" ");
}

///
version (DMocksTest) {
    unittest {
        class A
        {
            int a;
            int make() const shared @property
            {
                return a;
            }

            int makePure() inout pure @safe
            {
                return a;
            }

            int makeImut() immutable nothrow @trusted
            {
                return a;
            }

            ref int makeRef()
            {
                return a;
            }
        }
        auto aimut = new immutable(A);
        auto aconst = new const shared(A);
        auto amut = new A;
        assert(qualifiers!(aimut.makeImut)().sort().array() == [Qual!"immutable", Qual!"nothrow", Qual!"@trusted"].sort);
        assert(qualifiers!(aconst.makePure)().sort().array() == [Qual!"@safe", Qual!"inout", Qual!"pure"].sort);
        assert(qualifiers!(aconst.make)().sort().array() == [Qual!"@property", Qual!"@system", Qual!"const", Qual!"shared"].sort);
        assert(qualifiers!(amut.makeRef)().sort().array() == [Qual!"@system", Qual!"ref"]);
        assert(qualifierMatch!(aconst.make).matches([Qual!"@property", Qual!"@system", Qual!"const", Qual!"shared"].sort));
        assert(!qualifierMatch!(aconst.make).matches([Qual!"@property", Qual!"@system", Qual!"shared"].sort));
        assert(!qualifierMatch!(aconst.make).matches([Qual!"@property", Qual!"ref", Qual!"@system", Qual!"shared"].sort));
        assert(!qualifierMatch!(aconst.make).matches(["property", Qual!"@system", Qual!"shared"].sort));
    }
}

private string[] getFunctionAttributes(alias T)()
{
    import std.array;
    enum attributes = functionAttributes!(typeof(&T));
    auto ret = appender!(string[]);
    static if ((attributes & FunctionAttribute.nothrow_) != 0)
    {
        ret.put("nothrow");
    }
    static if ((attributes & FunctionAttribute.pure_) != 0)
    {
        ret.put("pure");
    }
    static if ((attributes & FunctionAttribute.ref_) != 0)
    {
        ret.put("ref");
    }
    static if ((attributes & FunctionAttribute.property) != 0)
    {
        ret.put("@property");
    }
    static if ((attributes & FunctionAttribute.trusted) != 0)
    {
        ret.put("@trusted");
    }
    static if ((attributes & FunctionAttribute.safe) != 0)
    {
        ret.put("@safe");
    }
    static if ((attributes & FunctionAttribute.safe) == 0 && (attributes & FunctionAttribute.trusted) == 0)
    {
        ret.put("@system");
    }
    return ret.data;
}

private string[] getMethodAttributes(alias T)()
{
    alias FunctionTypeOf!T TYPE;
    import std.array;
    auto ret = appender!(string[]);
    static if (is(TYPE == const))
    {
        ret.put("const");
    }
    static if (is(TYPE == immutable))
    {
        ret.put("immutable");
    }
    static if (is(TYPE == shared))
    {
        ret.put("shared");
    }
    static if (is(TYPE == inout))
    {
        ret.put("inout");
    }
    return ret.data;
}

/// checks if qualifiers is a unique set of valid qualifiers
public void enforceQualifierNames(string[] qualifiers)
{
    enforceEx!(MocksSetupException)(qualifiers.uniq.array == qualifiers,"Qualifiers: given qualifiers are not unique: " ~ qualifiers.join(" "));

    // bad perf, but data is small
    foreach(string q; qualifiers)
    {
        enforceEx!(MocksSetupException)(validQualifiers.canFind(q), "Qualifiers: found invalid qualifier: " ~ q);
    }
}

private immutable string[] validQualifiers = sort(["const", "shared", "immutable", "nothrow", "pure", "ref", "@property", "@trusted", "@safe", "inout", "@system"]).array;

/// validates qualifier name
template Qual(string val)
{
    static assert(validQualifiers.canFind(val), "Incorrect qualifier name");
    enum Qual = val;
}

///
version (DMocksTest) {
    unittest {
        static assert(__traits(compiles, Qual!"const"));
        static assert(!__traits(compiles, Qual!"consta"));
        enforceQualifierNames([Qual!"const", Qual!"@property"]);
        assertThrown!(MocksSetupException)(enforceQualifierNames([Qual!"const", Qual!"const", Qual!"@property"]));
        assertThrown!(MocksSetupException)(enforceQualifierNames(["consta", Qual!"@property"]));
    }
}

/// check if qualifier match is correctly formulated
void enforceQualifierMatch(bool[string] qualifiers)
{
    enforceQualifierNames(qualifiers.keys);
    bool testBothSet(string first, string second)()
    {
        return Qual!first in qualifiers && Qual!second in qualifiers && qualifiers[Qual!first] && qualifiers[Qual!second];
    }
    bool testThreeForbidden(string first, string second, string third)()
    {
        return Qual!first in qualifiers && Qual!second && Qual!second in qualifiers && !qualifiers[Qual!first] && !qualifiers[Qual!second] && !qualifiers[Qual!third];
    }
    void enforceBothNotSet(string first, string second)()
    {
        enforceEx!(MocksSetupException)(!testBothSet!(first, second), "Qualifiers: cannot require both "~first~" and "~second);
    }
    void enforceThreeNotSet(string first, string second, string third)()
    {
        enforceEx!(MocksSetupException)(!testThreeForbidden!(first, second, third), "Qualifiers: cannot forbid all "~first~", "~second~" and "~third);
    }
    enforceBothNotSet!("@trusted", "@safe");
    enforceBothNotSet!("@system", "@trusted");
    enforceBothNotSet!("@system", "@safe");
    enforceBothNotSet!("const", "immutable");
    enforceBothNotSet!("const", "inout");
    enforceBothNotSet!("immutable", "inout");
    enforceThreeNotSet!("@system", "@safe", "@trusted");
}

/++
+ type that allows you to specify which qualifiers are required in a match
+ stores required and forbidden qualifiers
+/
struct QualifierMatch
{
    private bool[string] _qualifiers;

    ///
    string toString() const
    {
        auto opt = validQualifiers.dup.filter!((a)=> a !in _qualifiers)().join(" ");
        return _qualifiers.keys.filter!((a)=> _qualifiers[a])().join(" ") ~ 
            (opt.length != 0 ? " (optional: " ~ opt ~")" : "");
    }

    /// returns true if all required qualifiers are present and all forbidden are absent in against array
    bool matches(string[] against) const
    {
        debugLog("QualifierMatch: match against: "~ against.join(" "));
        debugLog("state: " ~ toString());
        foreach(string searched; against)
        {
            const(bool)* found =  searched in _qualifiers;
            if (found is null)
                continue;
            if (!(*found))
                return false;
        }

        foreach(string key, const(bool) val; _qualifiers)
        {
            if (!val)
                continue;
            if (!against.canFind(key))
                return false;
        }
        return true;
    }
}