module dunittests.integration;

import dunit.api;
import dunit.repository;
import dunit.expect;
import tango.io.Stdout;

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
			 	Stdout("test one").newline;
			 	test_one_count++;
			 	expect.because("this is expected").that(1u).equals(2u);
			 	//assert(false, "this is an expected error");
			};
			tests["test two"] =
			{
			 	for (int i = 0; i < 10000000; i++){foo();}
			 	test_two_count++;
			};
			tests["failing test three"] = failing!(Exception)({ throw new Exception("mew?"); });
		}
	}
}

int j;
void foo()
{
	j++;
}

mixin(DunitMain);
