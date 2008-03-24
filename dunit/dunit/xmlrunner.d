module dunit.xmlrunner;

import dunit.testrunner;
import dunit.testfixture;
import dunit.expect;
import tango.core.Array;
import tango.text.convert.Layout;
import tango.io.stream.TextFileStream;
import tango.time.WallClock;
import tango.time.StopWatch;

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
			testFormat = `﻿<?xml version="1.0" encoding="utf-8" standalone="no"?>
<test-results name="{0}" total="{1}" failures="{2}" not-run="{3}" date="{4}" time="{5}">
  <environment />
  <culture-info current-culture="en-US" current-uiculture="en-US" />
  {6}
  </test-results>`;
	TestHierarchy hierarchy;
	StopWatch watch;

	this ()
	{
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
	}

	int endTests ()
	{
		uint failed = hierarchy.sum(ResultType.Fail);
		uint notRun = hierarchy.sum(ResultType.NotRun);
		uint passed = hierarchy.sum(ResultType.Pass);
		uint total = failed + notRun + passed;

		TextFileOutput output = new TextFileOutput("TestResults.xml");
		output.formatln(testFormat, "$NAME", total, failed, notRun,
				nowDate(), nowTime(), hierarchy.toXml);
		output.flush();
		output.close();
		return failed;
	}
}

class TestHierarchy
{
	const char[]
			fixtureStart = `<test-suite name="{0}" success="{1}" time="{2}" asserts="0"><results>` ~ '\n';
	const char[] fixtureEnd = "\n" ~ `</results></test-suite>`;
	const char[]
			passedTest = `<test-case name="{0}.{1}" executed="True" success="True" time="{2}" asserts="{3}" />`;
	const char[]
			failedTest = `
		<test-case name="{0}.{1}" executed="True" success="False" time="{2}" asserts="{3}">
		<failure><message><![CDATA[{4}]]></message><stack-trace><![CDATA[{5}]]></stack-trace></failure></test-case>`;


	/**
	 * With a hierarchy of tests like:
	 * damask.net.PlayerTests : TestFixture
	 * we would have a TH with qualified = damask, one with qualified = 
	 * damask.net, and one with qualified = damask.net.PlayerTests.
	 */
	char[] qualified;
	char[] segment;
	TestResult[] leaves;
	TestHierarchy[] children;

	uint sum (ResultType type)
	{
		uint fail = 0;
		foreach (leaf; leaves)
		{
			if (leaf.type == type)
			{
				fail++;
			}
		}

		foreach (child; children)
		{
			fail += child.sum(type);
		}

		return fail;
	}

	void add (char[] name, TestResult result)
	{
		// we assume that name starts with this.qualified
		if (name == qualified)
		{
			leaves ~= result;
			return;
		}
		foreach (child; children)
		{
			if (name.find(child.qualified) == 0)
			{
				child.add(name, result);
				return;
			}
		}

		// it doesn't belong in my leaves, nor in any existing child
		int dot = qualified.length + 1;
		int location = find(name[dot..$], '.');
		location += qualified.length;
		char[] subname = name[0..location + 1];
		char[] subfragment = subname[dot..$];

		TestHierarchy child = new TestHierarchy();
		child.qualified = subname;
		child.segment = subfragment;
		children ~= child;
		child.add(name, result);
	}

	char[] toXml ()
	{
		char[] success;
		if (sum(ResultType.Fail))
		{
			success = `False`;
		}
		else
		{
			success = `True`;
		}

		int lastSectionStart = rfind(qualified, '.');
		char[] fragment;
		if (lastSectionStart == qualified.length)
		{
			fragment = qualified;
		}
		else
		{
			fragment = qualified[lastSectionStart + 1..$];
		}
		char[] text = format(fixtureStart, fragment, success, 0.0);

		foreach (child; children)
		{
			text ~= child.toXml;
		}

		foreach (leaf; leaves)
		{
			text ~= getXml(leaf);
		}

		text ~= fixtureEnd;

		return text;
	}

	char[] getXml (TestResult leaf)
	{
		if (leaf.type == ResultType.Fail)
		{
			return format(failedTest, qualified, leaf.name, leaf.seconds, leaf.assertions, leaf.ex,
					leaf.stacktrace);
		}
		else
		{
			return format(passedTest, qualified, leaf.name, leaf.seconds, leaf.assertions);
		}
	}
}

version = XmlRunnerTests;

version (XmlRunnerTests)
{
	unittest {
		TestHierarchy hier = new TestHierarchy();
		hier.qualified = "bob";
		TestResult result = new TestResult("foo");
		hier.add("bob", result);
		assert (hier.leaves.length == 1, "TestHierarchy add leaf: did not add a leaf");
		assert (hier.leaves[0] is result, "TestHierarchy add leaf: wrong leaf added");
	}

	unittest {
		TestHierarchy hier = new TestHierarchy();
		hier.qualified = "bob";
		TestResult result = new TestResult("blargh?");
		hier.add("bob.dobbs", result);
		assert (hier.children.length == 1, "TestHierarchy add child: no child added");
		assert (hier.children[0].leaves.length == 1, "TestHierarchy add child: child did not add leaf");
		assert (hier.children[0].leaves[0] is result, "TestHierarchy add child: child did not add correct result");
	}
}
