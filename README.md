DMocks-revived
====================

What is it?
---------------------
DMocks-revived is a mock object framework for the D Programming Language, written also in D.

Why "revived"?
---------------------
The project is a reactivation of the dmocks subproject of felt project (http://dsource.org/projects/dmocks/)

Why is it useful?
---------------------
Assuming that you've decided to use unit tests (fantastic! I applaud your decision), you need a strategy for keeping your unit tests small, so they only test one method or one small group of methods at a time. Otherwise, you're using a unit test system for integration tests (which is fine).
The simplest strategy is to keep your classes small and not have them talk to each other. This might work for a standard library such as Tango or Phobos, but it does not scale to large applications.
If you want to test the interactions of one class with another, your only real solution is to use mock objects. While you can create them manually, it's tedious and time-consuming. A mock objects framework allows you to quickly create mock objects, set up expectations for them, and check to see whether these expectations have been fulfilled.

Supported platforms
---------------------
DMocks should build with DMD 2.063 and newer (older versions were not tested, might work aswell) on any platform DMD supports, as it contains only platform independent code. Other compilers should build the project too.

Examples
---------------------
Examples how to include DMocks-revived in your project and basic usage of the lib can be found inside examples directory. See unittests in dmocks/mocks.d for more examples of usage.

Build
---------------------
DMocks uses dub (github.com/rejectedsoftware/dub) as a build system. Dub was chosen because it supports generation of visuald and monod projects and is actively maintained. You can use any other build system if you wish.

###Build using dub:
	- install dub (github.com/rejectedsoftware/dub)
	- in root directory of DMocks run using your shell (or cmd.exe on windows): `dub build` or `dub build --config=[build configuration, see below]
	- more info about using dub is available on their git repository
	
###Available dub build configurations:
	- library - produces dmocks-revived.lib file which can be included in your project, see examples/with-lib in the repository to see how this can be used
	- tests - produces standalone executable useful for debugging the library itself
	
###Available version switches:
	- DMocksTest - compile unit tests into the library (works only when unittest build enabled)
	- DMocksTestStandalone - produce main function to run tests, so standalone executable can be generated
	- DMocksDebug - add various debug messages, mostly internal dmocks stuff

Capabilities
---------------------
dmocks can mock any class, interface, templated class, or templated interface. It uses inheritance, so it cannot mock structs. It cannot mock templated methods; that is, in the following example, the method bar will not be mocked:

	class Foo {
		void bar (T) (T value) {}
	}

At the same time, using that method will not result in an error. So take care in that situation.
dmocks supports repetition intervals:

	// This call can be repeated anywhere from five to nine times.
	// It must take the same arguments and will return the same value.
	m.expect(obj.method(args)).returns(value).repeat(5, 9);


dmocks supports unordered and ordered expectations.

Currently, dmocks intercepts method calls on methods in Object that are not overridden, such as opEquals and opHash. This can make Bad Things happen with associative arrays. One future point is to allow the methods that are inherited from Object and not overridden to pass through. In the meantime, though, you can do the following:

	// Allow storage in associative arrays
	// This is only necessary when mocking a concrete class, not with interfaces 
	mocker.expect(mocked.toHash).passThrough.repeatAny;
	mocker.expect(mocked.opEquals).ignoreArgs.passThrough.repeatAny;