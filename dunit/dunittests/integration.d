module dunittests.integration;

import dunit.api;
import dunit.repository;
import dunit.expect;

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
			 	throw new Exception("this is an expected error");
			 	//assert(false, "this is an expected error");
			};
			tests["test two"] =
			{
			 	test_two_count++;
			};
			tests["failing test three"] = failing!(Exception)({ throw new Exception("mew?"); });
		}
	}
}

void main () {}
//mixin(DunitMain);
