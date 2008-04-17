module dunit.consolerunner;

import dunit.testrunner;
import dunit.testfixture;
import dunit.repository;
import dunit.xmlrunner;
import tango.io.Stdout;
import tango.core.Array;

private bool hasArg(char[][] args, char[] name, char brief)
{
	const char[][] prefixes = ["-", "--", "/"];
	foreach (prefix; prefixes)
	{
		if (args.contains(prefix ~ name))
		{
			return true;
		}
		if (args.contains(prefix ~ brief))
		{
			return true;
		}
	}
	return false;
}

class ConsoleRunner : ITestRunner
{
	bool quiet;
	bool progress;
	uint pass, fail, notRun;

	this ()
	{
		quiet = false;
		progress = true;
	}

	void args (char[][] arguments)
	{
		if (arguments.hasArg("xml", 'x'))
		{
			Repository.instance().runner = new XmlRunner();
			Repository.instance().runner.args = arguments;
			return;
		}
		quiet = arguments.hasArg("quiet", 'q');
		progress = arguments.hasArg("progress", 'p');
	}

	void notifyResult (TestFixture fixture, TestResult result)
	{
		if ((!quiet) || (result.type == ResultType.Fail))
		{
			Stdout.formatln("{0}", result);
		}
		switch (result.type)
		{
			case ResultType.Fail:
				fail++;
				break;
			case ResultType.NotRun:
				notRun++;
				break;
			case ResultType.Pass:
				pass++;
				break;
			default:
				throw new Exception("result type not handled");
		}
	}

	bool startTest (TestFixture fixture, char[] name)
	{
        /*
		if (!quiet)
		{
			Stdout.format("running {}...", name);
		}
        */
		return true;
	}

	bool startFixture (char[] name)
	{
		if (!quiet)
		{
			Stdout.formatln("Test fixture {}", name);
		}
		return true;
	}

	void endFixture (TestFixture fixture)
	{
		if (progress)
		{
			Stdout.formatln("pass: {} fail: {}", pass, fail);
		}
	}

	int endTests ()
	{
		return fail;
	}
}
