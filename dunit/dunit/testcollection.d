module dunit.testcollection;

import dunit.testrunner;
import dunit.testfixture;

class TestCollection
{
	TestFixture fixture;
	TestResult[] results;
	uint fail = 0;
	uint pass = 0;
	
	this(TestFixture fixture)
	{
		this.fixture = fixture;
	}

	/**
	 * This code is such a lie.
	 * It's pretending to store delegates (look! opIndexAssign!), but it's
	 * executing them and storing the results. It makes it seem like dunit
	 * is slow but all your tests are insanely fast. And it doesn't let you
	 * disable a test fixture very easily, or only execute a subset of them
	 * or anything like that.
	 */
	void opIndexAssign (void delegate () test, char[] name)
	{
		TestResult result = run(test, fixture, name);
		results ~= result;
		switch (result.type)
		{
		case ResultType.Fail:
			fail++;
		case ResultType.Pass:
			pass++;
		default:
		}
	}
}
