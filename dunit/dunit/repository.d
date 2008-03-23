module dunit.repository;

import dunit.testfixture;
import dunit.testrunner;

// Singleton pattern for the win!
class Repository
{
	private static Repository _repository;

	public static Repository instance ()
	{
		if (!_repository)
		{
			_repository = new Repository();
		}
		return _repository;
	}

	public:
		ITestRunner runner;
		TestFixture delegate () [char[]] testFixtures;
		bool stdoutProgress = true;
		uint testCount;
		uint failed;
		uint passed;

		void add (char[] name, TestFixture delegate () value)
		{
			testFixtures[name] = value;
		}
}
