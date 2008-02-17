module assertions.constraint;

import assertions.exception;
import tango.core.Variant;
import tango.core.Traits;
import tango.util.collection.model.View;
import tango.text.convert.Layout;
import tango.group.convert;

Layout!(char) format;
static this () { format = new Layout!(char); }
private const char[] standardMessage = "Expected: {0} {1} but was: {2}";
private const char[] untypedMessage = "Expected: {0} but was: {1}";
private const char[] strEmpty = "<empty>";
private const char[] strNull = "<null>";



int countWhere (T) (Variant collection, bool delegate(T) sieve, bool expected) 
{
	if (collection.isImplicitly!(T[]))
	{
		auto array = collection.get!(T[]);
		int count = 0;
		foreach (a; array)
		{
			if (sieve(a) == expected)
			{
				count++;
			}
		}
		return count;
	}
	static if (!isStaticArrayType!(T)) {
		if (collection.isImplicitly!(View!(T)))
		{
			auto view = collection.get!(View!(T));
			int count = 0;
			foreach (a; view)
			{
				if (sieve(a) == expected)
				{
					count++;
				}
			}
			return count;
		}
	}
	else 
	{
		throw new UnsupportedOperationException("Cannot search for a static array inside a Tango collection." ~
			"You're probably looking for a string literal. In that case, please use \"literal\"[] rather than " ~
			"\"literal\".");
	}
	fail("Cannot apply a collection constraint on a type that is not a collection.");
	
}

struct Range
{
	int min = int.max;
	int max = int.min;
	bool inverse = false;
	static Range opCall(int min, int max)
	{
		Range r;
		r.min = min;
		r.max = max;
		return r;
	}
	
	bool valid () 
	{
		return (min != int.max) && (max != int.min);
	}
	
	bool opIn_r(int i) 
	{
		return ((min <= i) && (i <= max)) != inverse;
	}
	
	char[] toString() 
	{
		if (min == max) 
		{
			if (inverse) 
			{
				return format("more or fewer than {0}", min);
			}
			else 
			{
				return format("{0}", min);
			}
		} 
		else 
		{
			if (inverse)
			{
				return format("fewer than {0} or more than {1}", min, max);
			}
			else
			{
				return format("{0} to {1}", min, max);
			}
		}
	}
}

void hasCountWhere (T) (Variant actual, bool delegate(T) sieve, Range range, char[] message, bool result)
{
	int amount = countWhere(actual, sieve, result);
	if (amount in range)
	{
		return;
	}
	else
	{
		if (result) {
			fail(
				format(
						"Expected: list with {0} element(s) {1} But was: list with {2} element(s) {1}",
						range.toString, message, amount));
		}
		else 
		{
			fail (format("Expected: list with other than {0} element(s) {1} But was: list with {2} element(s) {1}",
				range.toString, message, amount));
		}
	}
}

void fail (char[] message)
{
	throw new AssertionError(message);
}


char[] toString(Variant v)
{
   if (v.isImplicitly!(long)) 
   {
      return Integer.toString(v.get!(long));
   }
   else if (v.isImplicitly!(real))
   {
      return Float.toString(v.get!(real));
   }
   else if (v.isImplicitly!(Object))
   {
	   auto obj = v.get!(Object);
	   return (obj is null) ? strNull : obj.toString;
   }
   else if (v.isImplicitly!(char[])) 
   {
	   auto obj = v.get!(char[]);
	   return (obj.length) ? `"` ~ obj ~ `"` : strEmpty;
   }
   else if (v.isImplicitly!(wchar[])) 
   {
	   auto obj = v.get!(wchar[]);
	   return (obj.length) ? `"` ~ cast(char[])obj ~ `"` : strEmpty;
   }
   else if (v.isImplicitly!(dchar[])) 
   {
	   auto obj = v.get!(dchar[]);
	   return (obj.length) ? `"` ~ cast(char[])obj ~ `"` : strEmpty;
   }
   else
   {
      // current implementation
      return v.type.toString;
   }
}


version (AssertionTests)
{
	unittest
	{
	   Variant v = 5;
	   assert ("5" == toString(v));
	   auto o = new Object;
	   v = o;
	   assert (o.toString == toString(v));
	   v = 7.83;
	   assert (Float.toString(7.83) == toString(v));
	   ubyte[] array = [];
	   v = array;
	   assert (typeid(ubyte[]).toString == toString(v));
	}
	void main(){}
}