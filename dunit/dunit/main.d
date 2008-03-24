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

int dunit_main (char[][] args)
{
	Repository repo = Repository.instance;
	if (repo.runner is null)
	{
		repo.runner = new ConsoleRunner();
	}

	repo.runner.args = args;

	foreach (fixtureName, fixtureBuilder; repo.testFixtures)
	{
		if (!repo.runner.startFixture(fixtureName))
		{
			continue;
		}
		auto fixture = fixtureBuilder();
		repo.runner.endFixture(fixture);
	}
	
	return repo.runner.endTests();
}
