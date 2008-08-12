module dconstructor.object_builder;

private
{
	import dconstructor.singleton;
	import dconstructor.build_utils;
	import tango.core.Traits;
}

abstract class ISingleBuilder {}

abstract class AbstractBuilder (TBuilder, T) : ISingleBuilder
{
	T build (TBuilder parent);
}

class SingletonBuilder (TBuilder, T): AbstractBuilder!(TBuilder, T)
{
	private T _singleton;

	T build (TBuilder parent)
	{
		if (_singleton is null)
		{
			_singleton = getSingleton (parent);
		}
		return _singleton;
	}

	private T getSingleton (TBuilder parent)
	{
		static assert (is (T == class), "Tried to build something that wasn't a class with an ObjectBuilder. Maybe you're missing a binding? Sorry.");
		mixin (get_deps!(T) ());
	}
}

class ObjectBuilder (TBuilder, T): AbstractBuilder!(TBuilder, T)
{
	T build (TBuilder parent)
	{
		static assert (is (T == class), "Tried to build something that wasn't a class with an ObjectBuilder. Maybe you're missing a binding? Sorry.");
		mixin (get_deps!(T) ());
	}
}

// This is cruddy. Without struct constructors, ugly!
class StructBuilder (TBuilder, T): AbstractBuilder!(TBuilder, T)
{
	T build (TBuilder parent)
	{
		return T.init;
	}
}

class StaticBuilder (TBuilder, T): AbstractBuilder!(TBuilder, T)
{
	private T _provided;

	this (T t)
	{
		_provided = t;
	}

	T build (TBuilder parent)
	{
		return _provided;
	}
}

class DelegatingBuilder (TBuilder, T, TImpl): AbstractBuilder!(TBuilder, T)
{
	private ObjectBuilder!(TBuilder, TImpl) _builder;

	this ()
	{
		_builder = new typeof(_builder)();
	}

	T build (TBuilder parent)
	{
		return cast(T)_builder.build(parent);
	}
}
