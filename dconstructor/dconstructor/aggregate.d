/**
 * Builders for aggregate types: arrays and dictionaries.
 */
module dconstructor.aggregate;

import dconstructor.build;

/**
 * Provides an array of the given type. Members of the array are provided 
 * statically. This array is provided for every type that requires an 
 * array of that type.
 */
class GlobalListBuilder (TList) : AbstractBuilder!(TList[])
{
	private TList[] _objs;

	this (TList[] objs)
	{
		_objs = objs.dup;
	}

	TList[] build (Builder parent)
	{
		return _objs.dup;
	}
}

/**
 * Provides a static, global associative array with the given keys and values.
 * Anything taking a dictionary of that type will be given this dictionary.
 */
class GlobalDictionaryBuilder (TKey, TValue) : AbstractBuilder!(TValue [TKey])
{
	private TValue [TKey] _dict;

	this (TKey [TValue] dict)
	{
		_dict = dict.dup;
	}

	TKey [TValue] build (Builder parent)
	{
		return _dict.dup;
	}
}
