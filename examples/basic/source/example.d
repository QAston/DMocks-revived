import std.stdio;
import std.random;

// this is a dependency class with complex behavior (emulated here with randomness)
class Bar {
    int doSomeCalculations(ubyte[]) { return uniform(0, 20); }
}

// this class depends on Bar
class Foo {
    private Bar bar;

    this (Bar bar) {
        this.bar = bar;
    }

    int calculateThings (ubyte[] data) {
        int i = bar.doSomeCalculations(data);
        return i;
    }
	
	// here we will test what happens when Bar.doSomeCalculations returns 12
	// it'd be hard to test that reliably without mocks
    unittest {
		// import only for test builds
		import dmocks.mocks;

        std.stdio.writeln("Running tests...");
		
        Mocker m = new Mocker();
		// create mock object
        Bar bar = m.mock!(Bar);
        ubyte[] data;
		// we expect bar.doSomeCalculations to be called, value 12 will be returned
        m.expect(bar.doSomeCalculations(data)).returns(12);

		// stop registering expected calls
        m.replay();

		// add mocked bar object as a dependency
        Foo f = new Foo(bar);
		// run our function using mocked dependency
        int result = f.calculateThings(data);

		// test the result of the function
		// in our example the value should be the same as that produced by Bar
		assert(result == 12);
		// verify that calls were made as expected (you can verify order of calls, that all required calls were done etc)
        m.verify();

        std.stdio.writeln("All tests passed successfuly");
    }
}

void main()
{
    // run the tests by using dub build --build=unittest, you should get "All tests passed successfuly" message
	// the program is silent when tests are disabled
}