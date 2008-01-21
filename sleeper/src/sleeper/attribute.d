/**
  * Mixins to configure a class for database interactions.
  */
module sleeper.attribute;

// TODO: validation
// Note that this syntax is forwards and backwards compatible to a much higher
// degree than directly calling the configuration methods.
/**
  * Configuration method for fields in a mapped class.
  * Examples:
  * ---
  * class Foo {
  *    int i, b;
  *    mixin(dbfield!(int, "i", "notnull: true; column: fraggle;"));
  *    mixin(dbfield!(int, "b", "pk; notnull: false; column: rock"));
  * }
  * ---
  */
string dbfield (T, string varname, string attributes)() {
    string notnull = "true";
    string column = null;
    string[] attrs = attributes.split(';');
    foreach (attr; attrs) {
        string[] tokens = attr.split(':');
        string name = tokens[0].trim;
        switch (name) {
            // TODO: document these and add to them
            // Need foreign-key types, collections, etc
            case "notnull":
                notnull = tokens[1];
                break;
            case "column":
                column = tokens[1];
                break;
            case "primary-key":
                primary = true;
                break;
            default:
                assert (false, "unrecognized attribute " ~ name ~ " in class "
                        ~ T.stringof ~ " for field " ~ varname);
        }
    }

    return 
        `static this () {
            sleeper.configure.configure_db_field!(typeof(this), ` 
                ~ T.stringof ~ `) ("` ~ column ~ `", 
                    delegate (` ~ T.stringof ~ ` value) {
                    ` ~ varname ~ ` = value;
                    }, ` ~ (primary ? `true` : `false`) ~
                `);
        }`;
}

/**
  * Configuration method for a mapped class.
  * Examples:
  * ---
  * class Foo {
  *     mixin(dbclass!("table: FooTable;"));
  * }
  * ---
  */
string dbclass(string attributes)() {
    string[] attrs = attributes.split(';');
    string table = attrs[0].split(':')[1].trim;
    return
        `static this () {
            sleeper.configure.configure_db_class!(typeof(this))(`~table~`);
        }`;
}
