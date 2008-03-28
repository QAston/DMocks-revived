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

char[] nowDate()
{
	const char[] dateformat = "{}-{}-{}";
	auto date = WallClock.toDate.date;
	return format(dateformat, date.year, date.month, date.day);
}

char[] nowTime()
{
	const char[] dateformat = "{}:{}:{}";
	auto time = WallClock.now.time.span;
	return format(dateformat, time.hours, time.minutes % 60, time.seconds % 60);
}

class XmlRunner : ITestRunner
{
	// Format string OF DOOM!
	const char[]
			testFormat = `<?xml version="1.0" encoding="utf-8" standalone="no"?>
<test-results name="{0}" total="{1}" failures="{2}" not-run="{3}" date="{4}" time="{5}">
  <environment />
  <culture-info current-culture="en-US" current-uiculture="en-US" />
  {6}
  </test-results>`;
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

