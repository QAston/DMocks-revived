module dunit.testfixture;
import dunit.repository;
import dunit.exception;

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
		
		void delegate () failing(TException)(void delegate() test)
		{
			auto closure = new catcher!(TException);
			closure.dg = test;
			return &closure.call;
		}
		
		/** 
		 * This method gets called before every test. Override it for any test fixture-specific behavior.  
		 */
		void setup () {}
		
		/**
		 * This method gets called after every test. Override it for any test fixture-specific behavior. 
		 */
		void teardown () {}
	}
}

struct catcher(TException)
{
	void delegate() dg;
	void call()
	{
		try
		{
			dg();
			throw new AssertionError("Expected exception of type " ~ TException.stringof ~ " but none was thrown.");
		}
		catch (TException ex)
		{
			if (ex.classinfo !is TException.classinfo)
			{
				throw ex;
			}
		}
	}
}
