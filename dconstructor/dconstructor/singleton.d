module dconstructor.singleton;

/**
 * An empty interface from which a class can inherit to mark it as a singleton.
 */
public interface Singleton
{
}

/**
 * An empty interface from which a class can inherit to mark it as not being a singleton.
 */
public interface Instance
{
}

/**
 * Examples:
 * interface IFoo : ImplementedBy!(Foo) {}
 * class Foo : IFoo {}
 * assert ((cast(Foo) builder.get!(IFoo)) !is null);
 */
public interface ImplementedBy(T)
{
}

public template Implements(T)
{
	const Implements = `
	static this ()
	{
		builder.bind!(` ~ T.stringof ~ `, typeof(this));
	}
	`;
}
