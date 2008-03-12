module dunit.testfixture;
import tango.io.Stdout;

/**
 * This is the base class for user-defined test fixtures. 
 * Authors: gareis
 * Usage:
 * ---
 * import dunit.api;
 * 
 * class SomethingTests : TestFixture
 * {
 * 		override void setup ()
 * 		{
 * 			// shared code goes here, executed before each test
 * 		}
 * 
 * 		override void teardown ()
 * 		{
 * 			// shared code goes here, executed after each test
 * 		}
 * 
 * 		this ()
 * 		{
 * 			tests["make sure that something happens correctly"] =
 * 			{
 * 				// test goes here
 * 			};
 * 			tests["do something else"] =
 * 			{
 * 				// test goes here
 * 			};
 * 		}
 * }
 * ---
 */
public abstract class TestFixture
{
	public
	{
		/**
		 * A collection of tests, indexed by description.
		 */
		void delegate () [char[]] tests;
		
		/** 
		 * This method gets called before every test. Override it for any test fixture-specific behavior.  
		 */
		void setup () {}
		
		/**
		 * This method gets called after every test. Override it for any test fixture-specific behavior. 
		 */
		void teardown () {}
		
		final void runtests (char[] fixtureName)
		{
			Stdout.formatln("Running test fixture {}:", fixtureName);
			foreach (name, test; tests)
			{
				try
				{
					setup();
					test();
					teardown();
					Stdout.formatln("\tTest {} passed.", name).newline;
				}
				catch (Object o)
				{
					Stdout.formatln("\tTest {} failed: {}", name, o);
				}
			}
		}
	}
}
