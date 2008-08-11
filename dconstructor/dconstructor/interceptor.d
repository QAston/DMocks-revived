module dconstructor.interceptor;

public class InterceptorCollection (T...)
{
	static if (T.length > 0)
	{
		private T[0] _mine;
	}

	static if (T.length > 1)
	{
		private InterceptorCollection!(T[1 .. $]) _tail;
	}
	
	this ()
	{
		static if (T.length > 0)
		{
			_mine = new typeof(T[0])();
			static if (T.length > 1)
			{
				_tail = typeof(_tail)();
			}
		}
	}

	public void intercept(T) (T built)
	{
		static if (T.length > 0)
		{
			_mine.intercept!(T) (built);
		}
		static if (T.length > 1)
		{
			_tail.intercept!(T) (built);
		}
	}
}

unittest
{
	class Something
	{
		static int count;
		static Object[] seen = [];
		void intercept(T)(T obj)
		{
			static if (is (T : Object))
			{
				seen ~= obj;
			}
			count++;
		}
	}
	
	auto coll = new InterceptorCollection!(Something)();
	Object o = new Object();
	coll.intercept(o);
	assert (Something.seen.length == 1, "intercepted the wrong number of elements");
	assert (Something.seen[0] is o, "intercepted the wrong element");
}
