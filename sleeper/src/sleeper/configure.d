/**
  * The contents of this module are internal configuration methods. They should
  * not be used externally in normal circumstances; the api will change without
  * notice, but public modules should have consistent apis.
  *
  * Instead of this, import sleeper.api.
  * Instead of using these methods, use the mixins defined in sleeper.attribute
  * and described in docs/attributes.
  */
module sleeper.configure;
import sleeper.type, sleeper.rttimanager;

private RttiManager _mgr = RttiManager.get();

/**
  * For internal use only. While you can use this, it's more cumbersome and
  * less future-safe than the markup style.
  */
void configure_db_class (TClass) (string dbname) {
    _mgr.add!(TClass)(dbname);
}

/**
  * For internal use only. While you can use this, it's more cumbersome and
  * less future-safe than the markup style.
  */
void configure_db_field (TParent, TField) 
    (string realname, string dbname, void delegate(TParent, TField) setter,
     bool allow_nulls, bool primary_key) {

    auto current = _mgr.get!(TParent);
    ISetter isetter = new Setter!(TParent, TField)(setter);
    DbField field = new DbField(isetter);
    current.fields ~= field;

    // pk goes in both fields[] and pk
    if (primary_key) {
        if (current.pk !is null) {
            throw new MappingException("Primary key specified twice on type " 
                    ~ TParent.stringof);
        }
        current.pk = field;
    }
}
