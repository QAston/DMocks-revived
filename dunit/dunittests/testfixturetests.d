module dunittests.testfixturetests;

import dunit.testfixture;
import dunit.expect;

class TestTest : TestFixture
{
	public
	{
		int setupcount;
		int teardowncount;
		int test_one_count;
		int test_two_count;

		override void setup ()
		{
			setupcount++;
		}

		override void teardown ()
		{
			teardowncount++;
		}

		this ()
		{
			tests["test one"] = 
			{
			 	test_one_count++;
			 	assert(false, "this is an expected error");
			};
			tests["test two"] =
			{
			 	test_two_count++;
			};
		}
	}
}

void main () 
{
	auto tests = new TestTest();
	tests.runtests = "hallo there";
	expect(tests.setupcount).equals(2);
	expect(tests.teardowncount).equals(1);
	expect(tests.test_one_count).equals(1);
	expect(tests.test_two_count).equals(1);
}
