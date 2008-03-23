module dunittests.testfixturetests;

import dunit.api;
import dunit.repository;
import dunit.expect;
import dunit.main;

class TestTest : TestFixture
{
    mixin(DunitTest);
	public
	{
		static int setupcount;
		static int teardowncount;
		static int test_one_count;
		static int test_two_count;

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
			tests["failing test three"] = failing!(Exception)
			({ 
				throw new Exception("mew?");
			});
		}
	}
}

void main () 
{
	dunit_main(null);
    TestTest tests = new TestTest();
    expect(tests.test_two_count).equals(1);
    auto dg = tests.failing!(Exception)
	({ 
		throw new Exception("mew?"); 
	});
    dg();
    auto array = tests.tests;
    dg = tests.failing!(Exception)({});
    try
    {
    	dg();
    	throw new Exception("this shouldn't work");
    }
    catch{}
}
