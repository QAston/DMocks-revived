module dconstructor.traits;

version (Tango)
{
	public import tango.core.Traits;

	template isAssociativeArray (T)
	{
		const bool isAssociativeArray = isAssocArrayType!(T);
	}
}
else
{
	public import std.traits;
	import std.typetuple;
	import std.stdio;

	template ParameterTupleOf (T)
	{
		alias ParameterTypeTuple!(T) ParameterTupleOf;
	}

	template ParameterTupleOf (alias T)
	{
		alias ParameterTypeTuple!(T) ParameterTupleOf;
	}

	static if (__VERSION__ < 2000)
	{
		template isAssociativeArray (T)
		{
			const bool
					isAssociativeArray = is (typeof(T.init.keys[0]) [typeof(T.init.values[0])] == T);
		}
	}
}

template isArray (T)
{
	const bool isArray = is (typeof(T[0])[] == T);
}

unittest {
	assert (isArray!(int[]));
	assert (!isArray!(int));
}

template assocArrayVal (AA)
{
	alias typeof(AA.init.values[0]) assocArrayVal;
}

unittest {
	assert (is (assocArrayVal!(int [long]) == int));
}

template assocArrayKey (AA)
{
	alias typeof(AA.init.keys[0]) assocArrayKey;
}

unittest {
	assert (is (assocArrayKey!(int [long]) == long));
}

string Tostring (int i)
{
	string ret = ``;
	do
	{
		ret = `` ~ cast(char) ('0' + (i % 10)) ~ ret;
		i /= 10;
	}
	while (i);
	return ret;
}

template ToString (int i)
{
	const string ToString = Tostring(i);
}
//
//unittest {
//	assert (ToChar!(5) == '5');
//	assert (ToChar!(0) == '0');
//	assert (ToChar!(9) == '9');
//}

unittest {
	string str = ToString!(17795);
	assert (str == "17795", str);
	assert (ToString!(0) == "0");
}
