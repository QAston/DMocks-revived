module dmocks.Factory;

import dmocks.MockObject;
import dmocks.Repository; 
import dmocks.Util;
import dmocks.Caller;

public class MockFactory 
{
    public 
    {
        /** Get a mock object of the given type. */
        static T Mock (T) (MockRepository rep) 
        {
            static assert (is(T == class) || is(T == interface), 
                    "only classes and interfaces can be mocked");
            
            
            Mocked!(T) ret = new Mocked!(T);
            ret._owner = new Caller(rep);
            return ret;
        }
    }
}
