module dunit.testrunner;

import tango.text.convert.Layout;
import tango.text.Util;
import dunit.testfixture;
import dunit.repository;

Layout!(char) format;

static this()
{
	format = new Layout!(char)();
}

enum ResultType
{
	Pass,
	Fail,
	NotRun
}

interface ITestRunner
{
	void notifyResult (TestFixture test, TestResult result);
	bool startTest (TestFixture test, char[] name);
	void endFixture (TestFixture fixture);
	bool startFixture (char[] name);
	void args(char[][] arguments);
	int endTests();
}

public class TestResult
{
	TestFixture parent;
	char[] name;
	ResultType type;
	Exception ex;
	char[] stacktrace;
	double seconds;
	int assertions;

	this (char[] name, TestFixture fixture)
	{
		this.parent = fixture;
		this.name = name;
		type = ResultType.NotRun;
	}

	override char[] toString ()
	{
		if (type == ResultType.Fail)
		{
			if (stacktrace.length)
			{
				return format("Error: {}: {}: {}\n\n{}", name, ex.classinfo.name, ex.msg, stacktrace);
			}
			else
			{
				return format("Error: {}: {}:\n\n{}", name, ex.classinfo.name, ex.msg);
			}
		}
		else
		{
			return format("Success: {0}", name);
		}
	}
}

public TestResult run (void delegate () test, TestFixture fixture, char[] name)
{
	TestResult result = new TestResult(name, fixture);
	ITestRunner runner = Repository.instance.runner;
	if (runner is null)
	{
		throw new Exception("Attempted to run unittests without an active TestRunner.");
	}
	if (!runner.startTest(fixture, name))
	{
		return result;
	}
	
	try
	{
        fixture.setup();
		test();
        fixture.teardown();
		result.type = ResultType.Pass;
	}
	catch (Exception ex)
	{
		result.ex = ex;
		if (ex.info)
		{
			result.stacktrace = ex.info.toString().substitute("0x", "\n0x");
		}
		result.type = ResultType.Fail;
	}
	Repository.instance.runner.notifyResult(fixture, result);
	return result;
}