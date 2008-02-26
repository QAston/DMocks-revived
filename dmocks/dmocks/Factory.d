module dmocks.Factory;

import dmocks.MockObject;
import dmocks.Repository; 
import dmocks.Util;

public class MockFactory 
{
    public 
    {
        /** Get a mock object of the given type. */
        static T Mock (T) (MockRepository rep) 
        {
            static assert (is(T == class) || is(T == interface), 
                    "only classes and interfaces can be mocked");
            
            auto ret = new Mocked!(T);
            ret._owner = rep;
            return ret;
        }
    }
}
