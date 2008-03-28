module dunit.xmlrunner;

import dunit.testrunner;
import dunit.testfixture;
import dunit.xmlwriter;
import dunit.expect;
import tango.core.Array;
import tango.text.convert.Layout;
import tango.io.stream.TextFileStream;
import tango.time.WallClock;
import tango.time.StopWatch;
import tango.text.xml.Document;

Layout!(char) format;

static this ()
{
	format = new Layout!(char);
}

class XmlRunner : ITestRunner
{
    char[] outfilename;
	TestHierarchy hierarchy;
	StopWatch watch;

	this ()
	{
        outfilename = "TestResults.xml";
		hierarchy = new TestHierarchy();
	}

	void notifyResult (TestFixture test, TestResult result)
	{
		result.seconds = watch.stop;
		result.assertions = expect.assertionCount;
		hierarchy.add(test.classinfo.name, result);
	}

	bool startTest (TestFixture test, char[] name)
	{
		expect.assertionCount = 0;
		watch.start;
		return true;
	}

	void endFixture (TestFixture fixture)
	{
	}

	bool startFixture (char[] name)
	{
		return true;
	}

	void args (char[][] arguments)
	{
        const char[] filearg = "file=";
        foreach (arg; arguments)
        {
            int i = arg.find(filearg);
            if (i < arg.length)
            {
                int start = filearg.length + i;
                outfilename = arg[start .. $];
                return;
            }
        }
	}

	int endTests ()
	{
		TextFileOutput output = new TextFileOutput(outfilename);
		output.formatln(getXml(hierarchy));
		output.flush();
		output.close();
		return 0;
	}
}

class TestHierarchy
{
	TestResultSet[char[]] tests;

	uint sum (ResultType type)
	{
		uint fail = 0;
		foreach (name, leaf; tests)
		{
			fail += leaf.sum(type);
		}
		return fail;
	}
	
	void add (char[] name, TestResult result)
	{
		if (!(name in tests))
		{
			tests[name] = new TestResultSet();
		}
		tests[name].tests ~= result;
	}
}

class TestResultSet
{
	char[] qualified;
	TestResult[] tests;

	uint sum (ResultType type)
	{
		uint fail = 0;
		foreach (leaf; tests)
		{
			if (leaf.type == type)
			{
				fail++;
			}
		}
		return fail;
	}

	double time ()
	{
		double seconds = 0.0;
		foreach (leaf; tests)
		{
			seconds += leaf.seconds;
		}
		return seconds;
	}

	void add (TestResult result)
	{
		tests ~= result;
	}
}

