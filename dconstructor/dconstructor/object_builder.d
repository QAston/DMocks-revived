module dconstructor.object_builder;

private
{
	import dconstructor.property;
	import dconstructor.build_utils;
	import tango.core.Traits;
}


struct Entity(T)
{
	T object;
	bool intercepted;
}

abstract class ISingleBuilder {}

abstract class AbstractBuilder (TBuilder, T) : ISingleBuilder
{
	Entity!(T) build (TBuilder parent);
}

class SingletonBuilder (TBuilder, T): AbstractBuilder!(TBuilder, T)
{
	private T _singleton;

	Entity!(T) build (TBuilder parent)
	{
		Entity!(T) entity;
		if (_singleton is null)
		{
			_singleton = get (parent);
			entity.intercepted = false;
		}
		else
		{
			entity.intercepted = true;
		}
		entity.object = _singleton;
		return entity;
	}

	T get (TBuilder parent)
	{
		static assert (is (T == class), "Tried to build something that wasn't a class with an ObjectBuilder. Maybe you're missing a binding? Sorry.");
		mixin (get_deps!(T) ());
	}
}

class ObjectBuilder (TBuilder, T): AbstractBuilder!(TBuilder, T)
{
	Entity!(T) build (TBuilder parent)
	{
		Entity!(T) entity;
		entity.intercepted = false;
		entity.object = get(parent);
		return entity;
	}

	T get (TBuilder parent)
	{
		static assert (is (T == class), "Tried to build something that wasn't a class with an ObjectBuilder. Maybe you're missing a binding? Sorry.");
		mixin (get_deps!(T) ());
	}
}

// This is cruddy. Without struct constructors, ugly!
class StructBuilder (TBuilder, T): AbstractBuilder!(TBuilder, T)
{
	Entity!(T) build (TBuilder parent)
	{
		Entity!(T) entity;
		entity.object = T.init;
		return entity;
	}
}

class StaticBuilder (TBuilder, T): SingletonBuilder!(TBuilder, T)
{
	private T _provided;

	this (T t)
	{
		_provided = t;
	}

	override T get (TBuilder parent)
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

	Entity!(T) build (TBuilder parent)
	{
		Entity!(T) entity;
		auto actual = _builder.build(parent);
		entity.object = actual.object;
		entity.intercepted = actual.intercepted;
		return entity;
	}
}
