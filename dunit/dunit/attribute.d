module dunit.attribute;

public const char[] DunitTest =
	`
	unittest
	{
		auto fixture = new typeof(this)();
		fixture.runtests;
	}
`;