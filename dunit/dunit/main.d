module dunit.main;

import dunit.repository;
import dunit.testrunner;
import dunit.testcollection;
import dunit.consolerunner;

private bool haveRunMain = false;

void ensure_main (char[][] args = null)
{
	if (!haveRunMain)
	{
		haveRunMain = true;
		dunit_main(args);
	}
}

bool contains (T) (T[] array, T value)
{
	foreach (T thing; array)
	{
		if (thing == value)
			return true;
	}
	return false;
}

// TODO: only run particular tests (based on packages listed on command line)
// Any other options?

void dunit_main (char[][] args)
{
	Repository repo = Repository.instance;
	ITestRunner runner = repo.runner;
	if (runner is null)
	{
		runner = repo.runner = new ConsoleRunner();
	}

	runner.args = args;

	foreach (fixtureName, fixtureBuilder; repo.testFixtures)
	{
		if (!runner.startFixture(fixtureName))
		{
			continue;
		}
		auto fixture = fixtureBuilder();
		runner.endFixture(fixture);
	}
}
