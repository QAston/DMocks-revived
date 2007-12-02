
/**
  * Builders for aggregate types: arrays and dictionaries.
  */
module dconstructor.aggregate;

interface IListBuilder {
    void[] deps();
}

/**
  * Provides an array of the given type. Members of the array are provided 
  * statically. This array is provided for every type that requires an 
  * array of that type.
  */
class GlobalListBuilder (TList) : IListBuilder {
    private TList[] _objs;
    this (TList[] objs) {
        _objs = objs.dup;
    }

    void[] deps () { return cast(void[])_objs.dup; }
}

/**
  * Provides a static, global associative array with the given keys and values.
  * Anything taking a dictionary of that type will be given this dictionary.
  */
class GlobalDictionaryBuilder (TKey, TValue) {
    private TValue[TKey] _dict;
    this (TKey[TValue] dict) {
        _dict = dict.dup;
    }

    TKey[TValue] deps () { return _dict.dup; }
}


