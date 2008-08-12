module interception;

static import dconstructor.build;
import dconstructor.singleton;
import tango.core.Thread;
import tango.io.Stdout;

dconstructor.build.Builder!(ThreadRunnableInterceptor) _builder;
typeof(_builder) builder ()
{
	if (_builder is null) _builder = new typeof(_builder);
	return _builder;
}

interface IServer
{
	void Run();
}

interface IConnection
{
	char[] ReadAll();
}

class Connection : IConnection
{
	char[] ReadAll ()
	{
		return "Hello, world!";
	}
}

interface IListener
{
	IConnection Accept();
}

class Listener : IListener
{
	IConnection Accept ()
	{
		return new Connection();
	}
}

class Server : IServer
{
	mixin (Implements!(IServer));
	private IListener _listener;

	this (IListener listener)
	{
		_listener = listener;
	}

	void Run ()
	{
		while (true)
		{
			IConnection connection = _listener.Accept();
			Stdout.formatln ("new connection: {}", connection.ReadAll ());
			Thread.sleep(1.0);
		}
	}
}

class ThreadRunnableInterceptor
{
	void intercept (T)(T obj)
	{
		Stdout.formatln("interceptor, build stack: {}", builder().buildStack());
		static if (is (typeof (T.Run)))
		{
			auto thread = new Thread(&obj.Run);
			thread.start();
		}
	}
}

void main ()
{
	builder().bind!(IListener, Listener);
	auto server = builder().get!(IServer);
	Stdout.formatln("built the server");
}
