module dunittests.attributetests;

import dunit.api;
import dunit.expect;

class RandomTest : TestFixture
{
	mixin(DunitTest);
	static int testCount;
	this ()
	{
		tests["one"] =
		{
		 	testCount++;
		};
	}
}

void main ()
{
	expect(RandomTest.testCount).equals(1);
}