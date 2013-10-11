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

Capabilities
---------------------
DMocks can create a mocked object for any (even templated) class or interface.
A mocked object has interface of specified type and customizable behavior.
Main use of mocks is to substitute them for class/method dependencies. Classical example is an object which depends on DB connection.
Testing such object is difficult because you have to alter DB/config for tests. An alternative is to create mock object which will pretend that it's DB object and run tests against that object.

DMocks is a source-level mocking frameworks, so it's capabilities are limited by the language.
Fortunately, D has many capabilities in terms of compile time source manipulation, code generation and parametrisation (templates).

DMocks can create 2 distinct types of mocks:
- mocks created by Mocker.mock function:
-- can be used whenever variable of mocked type is used (can be assigned to a variable of this type, be passed to a function in place of object of original type, etc)
-- can mock calls to virtual methods
-- cannot mock calls to final and template methods
-- cannot mock final classes

- mocks created by Mocker.mockFinal
-- can be used whenever you can use distinct type from the original one (the object type should be a template parameter to substitute mocks of this type for objects)
-- cannot be assigned to a variable of the original type
-- can mock calls to any method (virtual, final, template)
-- can mock final classes

DMocks supports repetition intervals:

	// This call can be repeated anywhere from five to nine times.
	// It must take the same arguments and will return the same value.
	m.expect(obj.method(args)).returns(value).repeat(5, 9);

DMocks supports unordered and ordered expectations.

Currently, dmocks intercepts method calls on methods in Object that are not overridden, such as opEquals and opHash. This can make Bad Things happen with associative arrays. One future point is to allow the methods that are inherited from Object and not overridden to pass through. In the meantime, though, you can do the following:

	// Allow storage in associative arrays
	// This is only necessary when mocking a concrete class, not with interfaces 
	mocker.expect(mocked.toHash).passThrough.repeatAny;
	mocker.expect(mocked.opEquals).ignoreArgs.passThrough.repeatAny;

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