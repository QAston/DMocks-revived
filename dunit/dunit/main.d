module dunit.main;

import dunit.repository;
import tango.io.Stdout;

private bool haveRunMain = false;

void ensure_main(char[][] args = null)
{
	if (!haveRunMain)
	{
		haveRunMain = true;
		dunit_main(args);
	}
}

bool contains(T)(T[] array, T value)
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

void dunit_main(char[][] args)
{
    bool quiet = false;
    bool progress = false;
    if (args.contains("-quiet") || args.contains("-q") ||
                                   args.contains("--quiet"))
        quiet = true;
    if (args.contains("-progress") || args.contains("-p") ||
                                   args.contains("--progress"))
        progress = true;

    Repository repo = Repository.instance;
    int failed, passed;
    int remaining()
    {
        return repo.testCount - (failed + passed);
    }
    double testprogress()
    {
        return 100.0 * (cast(double)repo.testCount) / (failed + passed);
    }
    foreach (fixtureName, fixture; repo.testFixtures)
    {
        if (!quiet) Stdout.formatln("Test fixture {}", fixtureName);
        foreach (name, test; fixture.tests)
        {
            try
            {
                if (!quiet) Stdout.formatln("Running: {}.", name);
                fixture.setup;
                test();
                fixture.teardown;
                if (!quiet) Stdout.formatln("Passed: {}.", name);
                passed++;
            }
            catch (Exception o)
            {
                failed++;
                Stdout.formatln("Failure: {}: {}", name, o);
            }
        }
        if (progress)
        {
            Stdout.formatln("Failed: {} Passed: {} Remaining: {} ({}%)",
                failed,
                passed,
                remaining,
                testprogress);
        }
    }
}
