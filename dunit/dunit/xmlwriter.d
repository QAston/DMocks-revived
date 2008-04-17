module dunit.xmlwriter;

import dunit.testrunner;
import dunit.xmlrunner;
import tango.text.xml.Document;
import tango.text.xml.XmlPrinter;
import tango.text.xml.PullParser;
import tango.group.convert;
import tango.core.Exception;

alias Document!(char) Xmldoc;
alias Document!(char).Node Node;

char[] getXml(TestHierarchy hierarchy)
{
	Xmldoc doc = new Xmldoc();
	foreach (name, testset; hierarchy.tests)
	{
		getXml(name, testset, doc);
	}
	return (new XmlPrinter!(char)()).print(doc);
}

void getXml(char[] name, TestResultSet tests, Xmldoc doc)
{
	Node testsuite = doc.root.element(null, "testsuite", null)
		.attribute(null, "name", name)
		.attribute(null, "timestamp", "")
		.attribute(null, "tests", Integer.toString(tests.tests.length))
		.attribute(null, "failures", Integer.toString(tests.sum(ResultType.Fail)))
		.attribute(null, "errors", "0")
		.attribute(null, "time", Float.toString(tests.time));
	addTests(tests, testsuite);
}

char[] join (char[][] data, char[] sep)
{
	char[] ret;
	foreach (i, datum; data)
	{
		ret ~= datum;
		if (i < data.length - 1)
		{
			ret ~= sep;
		}
	}
	return ret;
}

void addTests(TestResultSet tests, Node node)
{
	foreach (test; tests.tests)
	{
		Node testNode = node.element(null, "testcase")
			.attribute(null, "name", test.name)
			.attribute(null, "classname", test.parent.classinfo.name)
			.attribute(null, "time", Float.toString(test.seconds));
		if (test.type == ResultType.Fail)
		{
			testNode.element(null, "failure")
				.attribute(null, "message", test.ex.msg)
				.attribute(null, "type", test.ex.classinfo.name)
				.cdata(test.stacktrace);
		}
	}
}
