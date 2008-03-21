module dunit.repository;

import dunit.testfixture;

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
	TestFixture[char[]] testFixtures;
    bool stdoutProgress = true;
    int testCount;
    int failed;
    int passed;
	
	void add(char[] name, TestFixture value)
	{
		testFixtures[name] = value;
        testCount += value.tests.length;
	}

    void start(char[] testname)
    {
//        Stdout.formatln("\tRunning test {}.", testname);
    }
}
