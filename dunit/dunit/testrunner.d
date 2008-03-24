module dunit.testrunner;

import tango.text.convert.Layout;
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
	char[] name;
	ResultType type;
	Exception ex;
	char[] stacktrace;
	double seconds;
	int assertions;

	this (char[] name)
	{
		this.name = name;
		type = ResultType.NotRun;
	}

	override char[] toString ()
	{
		if (type == ResultType.Fail)
		{
			if (stacktrace.length)
			{
				return format("Error: {0}: {1}\n{2}", name, ex, stacktrace);
			}
			else
			{
				return format("Error: {0}: {1}", name, ex.classinfo.name);
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
	TestResult result = new TestResult(name);
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
		test();
		result.type = ResultType.Pass;
	}
	catch (Exception ex)
	{
		result.ex = ex;
		if (ex.info)
		{
			result.stacktrace = ex.info.toString;
		}
		result.type = ResultType.Fail;
	}
	Repository.instance.runner.notifyResult(fixture, result);
	return result;
}
