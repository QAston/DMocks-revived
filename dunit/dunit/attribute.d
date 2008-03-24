module dunit.attribute;

public const char[] DunitAutorunTest = `
	static this ()
	{
		dunit.repository.Repository.instance.add(typeof(this).classinfo.name, delegate TestFixture () { return new typeof(this)(); });
	}

	unittest
	{
		dunit.main.ensure_main();
	}
`;

public const char[] DunitTest = `
	static this ()
	{
		dunit.repository.Repository.instance.add(typeof(this).classinfo.name, delegate TestFixture () { return new typeof(this)(); });
	}
`;
	
public const char[] DunitMain = `
    int main(char[][] args)
    {
        return dunit.main.dunit_main(args);
    }
`;
