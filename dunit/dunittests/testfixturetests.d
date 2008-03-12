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
	expect.because("setup count").that(tests.setupcount).equals(2);
	expect.because("teardown count").that(tests.teardowncount).equals(1);
	expect.because("test one count").that(tests.test_one_count).equals(1);
	expect.because("test two count").that(tests.test_two_count).equals(1);
}
