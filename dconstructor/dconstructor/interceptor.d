module dconstructor.interceptor;

public class InterceptorCollection (TInterceptor...)
{
	static if (TInterceptor.length > 0)
	{
		private alias TInterceptor[0] TMine;
		private TMine _mine;
	}

	static if (TInterceptor.length > 1)
	{
		private InterceptorCollection!(TInterceptor[1 .. $]) _tail;
	}
	
	this ()
	{
		static if (TInterceptor.length > 0)
		{
			_mine = new TMine();
			static if (TInterceptor.length > 1)
			{
				_tail = typeof(_tail)();
			}
		}
	}

	public void intercept(T) (T built)
	{
		static if (TInterceptor.length > 0)
		{
			_mine.intercept!(T) (built);
		}
		static if (TInterceptor.length > 1)
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
