dmocks : a mock object framework for the D Programming Language

Version 0.2.


Rationale.
    Assuming that you've decided to use unit tests (fantastic! I applaud your decision), you need a strategy for keeping your unit tests small, so they only test one method or one small group of methods at a time. Otherwise, you're using a unit test system for integration tests (which is fine).
    The simplest strategy is to keep your classes small and not have them talk to each other. This might work for a standard library such as Tango or Phobos, but it does not scale to large applications.
    If you want to test the interactions of one class with another, your only real solution is to use mock objects. While you can create them manually, it's tedious and time-consuming. A mock objects framework allows you to quickly create mock objects, set up expectations for them, and check to see whether these expectations have been fulfilled.

Examples.

class Bar {
    int doSomeCalculations() { ... }
}

class Foo {
    private Bar bar;

    this (Bar bar) {
        this.bar = bar;
    }

    int calculateThings (ubyte[] data) {
        int i = bar.doSomeCalculations(data);
        ...
        return i;
    }

    unittest {
        Mocker m = new Mocker();
        Bar bar = m.Mock!(Bar);
        ubyte[] data = [];
        m.Expect(bar.doSomeCalculations(data)).Return(12);

        m.Replay();

        Foo f = new Foo(bar);
        f.calculateThings(data);

        m.Verify();
    }
}


Capabilities.
    dmocks can mock any class, interface, templated class, or templated interface. It uses inheritance, so it cannot mock structs. It cannot mock templated methods; that is, in the following example, the method bar will not be mocked:

class Foo {
    void bar (T) (T value) {}
}

    At the same time, using that method will not result in an error. So take care in that situation.
    dmocks supports repetition intervals:

    // This call can be repeated anywhere from five to nine times.
    // It must take the same arguments and will return the same value.
    m.Expect(obj.method(args)).Return(value).Repeat(5, 9);

    dmocks supports unordered expectations. It does not support ordered expectations, however.

    dmocks supports expectations on void methods, of course; unfortunately, the syntax is different (I'm looking for ways around this):

    mocked.method(args);
    LastCall.Repeat(3, 4);

    You can use that syntax with methods that have return values, too.

    Currently, dmocks intercepts method calls on methods in Object that are not overridden, such as opEquals and opHash. This can make Bad Things happen with associative arrays. One future point is to allow the methods that are inherited from Object and not overridden to pass through. Another point is to allow methods to pass through to the original in such cases. This can cause problems for methods that use members, though, so it will not be a recommended thing if it is implemented.
