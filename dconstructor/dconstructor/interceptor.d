module dconstructor.interceptor;
import dconstructor.object_builder;

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

	public void intercept(T) (Entity!(T) built, char[][] buildStack)
	{
		if (built.intercepted) return;
		static if (TInterceptor.length > 0)
		{
			_mine.intercept!(T) (built.object, buildStack);
		}
		static if (TInterceptor.length > 1)
		{
			_tail.intercept!(T) (built.object, buildStack);
		}
	}
}

