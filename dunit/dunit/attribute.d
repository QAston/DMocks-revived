module dunit.attribute;

public const char[] DunitAutorunTest = `
	static this ()
	{
		dunit.repository.Repository.instance.add((typeof(this).stringof), delegate TestFixture () { return new typeof(this)(); });
	}

	unittest
	{
		dunit.main.ensure_main();
	}
`;

public const char[] DunitTest = `
	static this ()
	{
		dunit.repository.Repository.instance.add((typeof(this).stringof), delegate TestFixture () { return new typeof(this)(); });
	}
`;
	
public const char[] DunitMain = `
    void main(char[][] args)
    {
        dunit.main.dunit_main(args);
    }
`;
