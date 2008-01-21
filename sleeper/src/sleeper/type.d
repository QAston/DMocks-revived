/**
  * RTTI for various types.
  * Can probably combine this module with rttimanager and configure without much
  * trouble, but that's unnecessary.
  */
module sleeper.type;

class DbClass {
    TypeInfo type;
    ClassInfo cinfo;
    // TODO: index fields by their names
    DbField[] fields;
    DbField pk;
    string table;

    string get_query () {
        string ret = "";
        foreach (field; fields) {
            ret ~= field.name ~ ",";
        }
        // slice off the last comma
        return ret[0..$-1];
    }

    string pk_query () {
        return pk.name;
    }
    
    Object build (Row row) {
        auto obj = cinfo.create;
        foreach (i, field; fields) {
            field.set(obj, row[i]);
        }
    }
}

class DbField {
    public string name;
    private ISetter _setter;

    this (ISetter setter) { _setter = setter; }

    void set (Object obj, string value) {
        _setter.set(obj, value);
    }
}

interface ISetter {
    void set (Object obj, string dbvalue);
}

class Setter (TOn, TSet) : ISetter {
    private delegate (TOn, TSet) _setter;
    this (delegate (TOn, TSet) setter) { _setter = setter; }
    void set (Object obj, string dbvalue) {
        auto value = to!(TSet)(dbvalue);
        auto on = cast(TOn)obj;
        _setter(on, value);
    }
}

