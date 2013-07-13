module dmocks.factory;

import dmocks.object_mock;
import dmocks.repository; 
import dmocks.util;
import dmocks.caller;
import std.stdio;

public class MockFactory 
{
    public 
    {
        /** Get a mock object of the given type. */
        static T Mock (T) (MockRepository rep) 
        {
            static assert (is(T == class) || is(T == interface), 
                    "only classes and interfaces can be mocked");
            
            debugLog("factory: about to build");
            Mocked!(T) ret = new Mocked!(T);
            debugLog("factory: about to set owner");
            ret._owner = new Caller(rep);
            debugLog("factory: returning the mocked object");
            return ret;
        }
    }
}
