module simple;

import dconstructor.build;
import dconstructor.singleton;
import tango.core.Thread;
import tango.io.Stdout;

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

void main ()
{
	builder().bind!(IListener, Listener);
	auto server = builder().get!(IServer);
	server.Run();
}
