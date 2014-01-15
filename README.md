DMocks-revived
====================

What is it?
---------------------
DMocks-revived is a mock object framework for the D Programming Language, written also in D.

Why "revived"?
---------------------
The project is a reactivation of the dmocks subproject of felt project (http://dsource.org/projects/dmocks/)

Why are mocks useful?
---------------------
Assuming that you've decided to use unit tests (if you didn't you're wrong), you need a strategy for keeping scope of your unit tests small, so they only test one method or one small group of methods at a time. Otherwise, you're using a unit test system for integration tests. Which is fine, but can be uneffective - the number of integration tests needed for full coverage of 3 interacting objects is much larger than number of equivalent unit tests needed and unit tests were invented exactly to solve that problem.

The simplest strategy is to keep your classes small and not have them talk to each other. This might work for a standard library such as Phobos or Unstd, but it does not scale to large applications.

Classical example of the problem is an object which depends on a DB connection. Testing methods of such object is difficult because you have to provide some database for this object, otherwise your code won't compile or throw a NullPointerException. You could provide a separate database for testing, but that brings other problems: it takes long to connect to a DB and it's still hard to simulate certain conditions, like timeouts.

**Mocks** are an alternative sollution to the problem - you create a mock object which will pretend that it provides a DB connection (it implements the same "interface"). You can make the mock object return predefined records, timeout on request (to test error handling), etc. You can make it check if methods are really called i.e you expect function retrieving data to call connect(), because it not doing so is an error. Now you run tests against object with fake (mocked) DB connection. This way, only the code you want to test is tested, nothing more.

More examples about use of mocks can be found at: http://www.youtube.com/watch?v=V98Z11V7kEY

Why is DMocks useful?
---------------------
A mock objects framework (DMocks in this case) allows you to quickly create mock objects, set up expectations for them, and check to see whether these expectations have been fulfilled. This saves you tedious work of creating those objects manually.

Examples
---------------------
Examples how to include DMocks-revived in your project and basic usage of the lib can be found inside examples directory.

Example project can be built using following dub command (assuming you have dub installed & in your path already) while inside directory with package.json:
`dub build --build=unittest`

For more examples of usage see unittests in dmocks/mocks.d.
For quick glance at how it all looks like see Capabilities.

Capabilities
---------------------
DMocks is a source-level mocking framework, therefore it's capabilities are limited by the language. However that doesn't mean the capabilities are small.
D is a compiled language which is intended to produce highly performant code, so it uses static binding whenever possible; unlike languages like python which use dynamic binding and allow much more polymorphism for the price of execution speed.

D mitigates the issue by having two types of polymorphism - both can be used to substitute objects with mocks, each have different tradeoffs.
- compile-time polymorphism - in form of templates - fast, produces "static" code
- runtime polymorphism - in form of interfaces and base classes - a bit slower, produces "dynamic" code

###Mocking using classes and interfaces (runtime polymorphism)

This type of mocking is the default and most widespread approach to mocking (known from java, python, C#, etc).
In this case mock object type is a subtype of the mocked type.
That fact has several consequences:
- mock can be used whenever mocked type is a **non-final class** or **interfece** (including templated ones)
- mock can be used whenever variable of mocked type is used
- in most cases there's no need to alter the code to use this type of mocking
- mock cannot be used if runtime type introspection is used in tested code (like typeid expression) as it depends on type erasure
- you cannot mock final classes and structs at all
- you cannot mock calls to final and template methods (watch out for that!)

Example:

`
// class mock
class Dependency
{
    //string call(TYPE)();  wouldn't be mocked as it's a template

    string call()
    {
        return "Call on me, baby!";
    }
}

void funcToTest(Dependency dep)
{
    writeln(dep.call());
}

unittest
{
    auto mocker = new Mocker();
    Object mock = mocker.mock!(Object)(); // will construct Dependency with given args
    mocker.expect(mock.call());
    mocker.replay;
    funcToTest(mock);
    mocker.verify;
}

void main()
{
    funcToTest(new Dependency());
}
`

###Mocking using templates (compile-time polymorphism)

This type of mocking isn't much widespread as there're only few languages providing templates (D, C++).
In this case mock object type is a final class or struct containing same methods as mocked type and a reference to object of that type.
That fact has several consequences:
- you can mock any **class(even final), interface** or **struct**
- mock can be used whenever type of mocked object is a template parameter (so only in templated functions, types)
- in most cases you need to alter your code to add additional template parameters to your code to use this type of mocking (so type can vary)
- mock cannot be used if runtime or compiletime type introspection is used in tested code (like typeid expression, sizeof, is(), typeof)
- mock cannot be assigned to a variable of the mocked type
- you can mock calls to any method (virtual, final, template)
- all methods of the mock object behave like they're final (no runtime polymorphism)

Example:

`
// final class mock, could be not final (but calls won't be virtual), could be struct
final class Dependency
{
    string call(TYPE)() {
        return "Call on me, baby!";
    }
}

void funcToTest(DEPENDENCY)(DEPENDENCY dep)
{
    writeln(dep.call(int)());
}

unittest
{
    auto mocker = new Mocker();
    Object mock = mocker.mockFinal!(Object)(); // will construct Dependency with given args
    // Object mock = mocker.mockFinalPassTo!(Object)(new Dependency()); - alternative - will use provided object for passThrough type of calls
    mocker.expect(mock.call!(int)());
    mocker.replay;
    funcToTest(mock);
    mocker.verify;
}

void main()
{
    funcToTest(new Dependency());
}
`

###Other features

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

Supported platforms
---------------------
DMocks should build with DMD 2.063 and newer (older versions were not tested, might work aswell) on any platform DMD supports, as it contains only platform independent code. Other compilers should build the project too.

Hacking
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
