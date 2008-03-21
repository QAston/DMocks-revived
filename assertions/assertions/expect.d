module assertions.expect;

import assertions.exception;
import assertions.constraint;
import tango.text.convert.Layout;
import tango.core.Traits;
import tango.core.Variant;
import tango.io.Stdout;
import tango.stdc.math;
import tango.core.Traits;

private const char[] standardMessage = "Expected: {0} {1} but was: {2}";
private const char[] untypedMessage = "Expected: {0} but was: {1}";


template ExpectReturn(T) {
	static if (is (T == bool))
	{
		alias void ExpectReturn;
	}
	else 
	{
		alias expect ExpectReturn;
	}
}

/+
Variant toVar(T)(T obj) {
	static if (isStaticArrayType!(T)) {
		return Variant(obj[]);
	} else {
		return Variant(obj);	
	}
}
+/

/**
 * expect: a more verbose interface for assert.
 * Usage:
 * ---
 * expect([1, 2, 3, 4]).has(2).where((int x) { return x % 2 == 0; });
 * expect(true);
 * expect(null).isNull;
 * auto o = new Object;
 * auto p = o;
 * expect(o).sameAs(p);
 * p = new Object;
 * expect(p).not.sameAs(o);
 * ---
 */
struct expect
{
	Variant actual;
	Range count;
	bool isnull = false;
	bool truth = true;

	/**
	 * Start an expectation with the given value.
	 * `actual` is the real value for which any further constraints must apply.
	 * If actual is a boolean, it is evaluated immediately; the implicit constraint is
	 * that it is true.
	 */
	static ExpectReturn!(T) opCall (T) (T value)
	{
		static if (is (T == bool)) 
		{
			if (!value)
			{
				fail(format(untypedMessage, true, false));
			}
		}
		else 
		{
			expect e;
			e.actual = Variant(value);
			static if (isReferenceType!(T))
			{
				e.isnull = value is null;
			}
			return e;
		}
	}

	/**
	 * Negate the constraint.
	 * Note the difference between the following. Both succeed:
	 * ---
	 * // it doesn't have exactly one thing equal to 2 
	 * expect([2, 2]).not.has(1).equals(2);
	 * // it has exactly one that isn't equal to 2
	 * expect([1, 2]).has(1).not.equals(2);
	 * ---
	 */
	expect not ()
	{
		// TODO: formatting for all these with 'not'.
		truth = false;
		return *this;
	}

	/**
	 * Test for equality. This uses opEquals/opCmp.
	 * Params:
	 *     expected = the expected value against which to compare the actual value.
	 */
	void equals (T) (T expected)
	{
		Variant var = Variant(expected);
		if (count.valid()) 
		{
			hasCountWhere(actual, 
				(T value) { return (expected == value); }, 
				count, 
				format("equal to {0}", toString(var)), 
				truth);
		}
		else if ((actual == expected) != truth)
		{
			fail(
				format(
					standardMessage, 
					(truth) ? "equal to" : "not equal to", 
					toString(var), 
					toString(actual)));
		}
	}

	/**
	 * Test for sameness. This uses the is operator
	 * Params:
	 *     expected = the expected value against which to compare the actual value.
	 */
	void sameAs (T) (T expected)
	{
		Variant var = Variant(expected);
		if (count.valid()) 
		{
			hasCountWhere(actual, 
				(T value) { return (expected is value); }, 
				count, 
				format("same as {0}", toString(var)),
				truth);
		}
		else if ((actual.get!(T) is expected) != truth)
		{
			fail(format(standardMessage, "same as", toString(var), toString(actual)));
		}
	}

	/**
	 * Require that the actual value be an aggregate type with the number of
	 * elements for which the sieve returns true is in the given range.
	 * 
	 * Params:
	 *     sieve = a delegate that returns true iff the given element is valid
	 *     according to user-defined criteria
	 */
	void where (T) (bool delegate (T) sieve) 
	{
		if (count.valid()) 
		{
			hasCountWhere(actual, sieve, count, "that match", truth);
		}
		else
		{
			fail("You must use `has` before calling `where`.");
		}
	}

	/**
	 * For an actual value that is an aggregate type, require that the number
	 * of elements that match the constraint to be given is not greater than
	 * max and not less than min.
	 * 
	 * Aggregate types are arrays (not associative arrays) or any type that implements
	 * tango.util.collection.model.View.
	 */
	expect has(int min, int max) 
	{
		this.count = Range(min, max);
		if (!truth) 
		{
			count.inverse = true;
			truth = true;
		}
		return *this;
	}
	
	/**
	 * For an actual value that is an aggregate type, require that the number
	 * of elements that match the constraint to be given is exactly count.
	 * 
	 * Aggregate types are arrays (not associative arrays) or any type that implements
	 * tango.util.collection.model.View.
	 */
	expect has(int count) 
	{
		return has(count, count);
	}

	/**
	 * For an actual value that is an aggregate type, require that no elements
	 * match the constraint to be given.
	 * 
	 * Aggregate types are arrays (not associative arrays) or any type that implements
	 * tango.util.collection.model.View.
	 */
	expect hasNone()
	{
		return has(0, 0);
	}

	/**
	 * For an actual value that is an aggregate type, require that exactly one element
	 * matches the constraint to be given.
	 * 
	 * Aggregate types are arrays (not associative arrays) or any type that implements
	 * tango.util.collection.model.View.
	 */
	expect hasOne()
	{
		return has(1, 1);
	}

	/**
	 * For an actual value that is an aggregate type, require that at least one element
	 * matches the constraint to be given.
	 * 
	 * Aggregate types are arrays (not associative arrays) or any type that implements
	 * tango.util.collection.model.View.
	 */
	expect hasSome()
	{
		return has(1, int.max);
	}
	
	/**
	 * Require that the actual value is null.
	 */
	void isNull()
	{
		if ((actual.isImplicitly!(Object) && actual.get!(Object) is null) == truth)
		{
			return;
		}
		if ((actual.isImplicitly!(void*) && actual.get!(void*) is null) == truth)
		{
			return;
		}
		
		fail(format(untypedMessage, truth ? "null" : "not null", toString(actual)));
	}
	
	void isNaN()
	{
		if (!actual.isImplicitly!(real) || !isnan(actual.get!(real))) 
		{
			fail(format(untypedMessage, "Not a Number", toString(actual)));
		}
	}
}

// uncomment the following line to run tests
//version = AssertionsTest;
version (AssertionsTest)
{
	void main () {}
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
	
		Range r = Range(2, 3);
		assert (2 in r);
		assert (3 in r);
		assert (!(4 in r));
		r.inverse = true;
		assert (!(2 in r));
		assert (!(3 in r));
		assert ((4 in r));
		
		expect(4).equals(4);
		expect([1, 2, 3, 4]).has(2).where((int x) { return x % 2 == 0; });
		// should be 2 where the constraint is false
		expect([1, 2, 3, 4]).has(2).not.where((int x) { return x % 2 == 0; });
		
		// should be other than two where the constraint is false
		expect([1, 2, 3, 4]).not.has(2).where((int x) { return x % 3 == 0; });
		expect([1, 2, 3, 4]).hasOne.sameAs(2);
		expect(true);
		
		expect e = expect(1).not;
		assert (!e.truth);
		expect(null).sameAs(null);
		expect(null).isNull;
		
		o = new Object;
		expect(o).not.isNull;
		auto p = o;
		expect(o).sameAs(p);
		p = new Object;
		expect(p).not.sameAs(o);
	
		bool failed = false;
		try {
			expect(p).sameAs(o);
			failed = true;
		} catch (AssertionError e) {
			Stdout(e.msg).newline;
		}
		expect(!failed);
	
		try {
			expect([1, 2, 3, 4]).has(3, 4).where((int x) { return x % 2 == 0; });
			failed = true;
		} catch (AssertionError e) {
			Stdout(e.msg).newline;
		}
		expect(!failed);
		
		expect(real.nan).isNaN;
		expect(2).not.equals(0);
		expect(real.nan).not.equals(real.nan);
		

		// These all pass.
		auto obj = new Object;
		expect(obj).sameAs(obj);
		expect(obj).not.sameAs(new Object);
		expect(obj).not.isNull;

		int i = 0;
		long j = 0;
		expect(i).equals(j);
		expect(real.nan).isNaN;

		auto list = [1, 1, 2, 3];
		expect(list).hasNone.equals(4);
		expect(list).has(2).equals(1);
		expect(list).has(0, 3).equals(1); // 2 is in the range 0..3
		expect(list).has(0, 2).equals(1); // ranges are inclusive
		expect(list).has(2).not.equals(1); // success -- [2, 3] are not equal to 1
		expect(list).hasSome.equals(3); // success -- at least one
		expect(list).not.has(1).equals(1); // success -- it has two, not one

		// These fail.
		try 
		{
			expect(list).not.has(2).equals(1); // It does have 2 elements equal to 1
			failed = true;
		}
		catch (AssertionError e) 
		{
			Stdout(e.msg).newline;
		}
		expect(!failed);
		
		try 
		{
			expect(list).has(1).equals(1); // Fails: not in exact range specified
			failed = true;
		}
		catch (AssertionError e) 
		{
			Stdout(e.msg).newline;
		}
		expect(!failed);
		
		try 
		{
			expect(null).not.isNull; // Fails: not in exact range specified
			failed = true;
		}
		catch (AssertionError e) 
		{
			Stdout(e.msg).newline;
		}
		expect(!failed);
		
		try 
		{
			expect("hello"[]).equals("boowah"[]);
			failed = true;
		}
		catch (AssertionError e) 
		{
			Stdout(e.msg).newline;
		}
		expect("hello").equals("hello");
		//expect("hello").sameAs("hello");
		expect(!failed);
	}
}
