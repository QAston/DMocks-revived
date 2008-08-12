/**
 * Builders for aggregate types: arrays and dictionaries.
 */
module dconstructor.aggregate;

import dconstructor.build;
import dconstructor.object_builder;

/**
 * Provides an array of the given type. Members of the array are provided 
 * statically. This array is provided for every type that requires an 
 * array of that type.
 */
class GlobalListBuilder (TBuilder, TList) : AbstractBuilder!(TBuilder, TList[])
{
	private TList[] _objs;

	this (TList[] objs)
	{
		_objs = objs.dup;
	}

	Entity!(TList[]) build (TBuilder parent)
	{
		Entity!(TList[]) entity;
		entity.object = _objs.dup;
		entity.intercepted = true;
		return entity;
	}
}

TValue[TKey] dup (TValue, TKey)(TValue[TKey] aa)
{
	TValue[TKey] d;
	foreach (a, b; aa) 
	{
		d[a] = b;
	}
	return d;
}

/**
 * Provides a static, global associative array with the given keys and values.
 * Anything taking a dictionary of that type will be given this dictionary.
 * The exception, of course, being when it's wrapped in a MultiBuilder.
 */
class GlobalDictionaryBuilder (TBuilder, TKey, TValue) : AbstractBuilder!(TBuilder, TValue [TKey])
{
	private TValue [TKey] _dict;

	this (TValue [TKey] dict)
	{
		_dict = dup(dict);
	}

	Entity!(TValue [TKey]) build (TBuilder parent)
	{
		Entity!(TValue [TKey]) entity;
		entity.object = dup(_dict);
		entity.intercepted = true;
		return entity;
	}
}
