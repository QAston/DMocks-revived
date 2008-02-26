module dmocks.Factory;

import dmocks.MockObject;
import dmocks.Repository; 
import dmocks.Util; 
import std.gc;
import std.variant;

version (MocksDebug) import std.stdio;
version (MocksTest) import std.stdio;

public class MockFactory {
    public {
        /** Get a mock object of the given type. */
        static T Mock (T) (MockRepository rep) {
            static assert (is(T == class) || is(T == interface), 
                    "only classes and interfaces can be mocked");
            static if (is (T == interface)) {
                version (MocksDebug) writefln("got interface; using a constructor");
                auto ret = new Mocked!(T);
                ret._owner = rep;
                return ret;
            } else {
                // WARNING: THIS IS UGLY AND IMPLEMENTATION-SPECIFIC
                void*[] mem = cast(void*[])malloc(__traits(classInstanceSize, Mocked!(T)));
                mem[0] = (Mocked!(T)).classinfo.vtbl.ptr;
                setTypeInfo(typeid(Mocked!(T)), mem.ptr);
                setInterfaces(mem.ptr, (Mocked!(T)).classinfo);

                version(MocksDebug) writefln("set the vtbl ptr");

                auto t = cast(Mocked!(T))(mem.ptr);

                version(MocksDebug) writefln("casted");

                assert (t !is null);
                t._owner = rep;

                version(MocksDebug) writefln("set repository");

                T retval = cast(T)t;

                version(MocksDebug) writefln("cast to T");
                version(MocksDebug) assert (retval !is null);
                version(MocksDebug) writefln("returning");
                return retval;
            }
        }
    }

    private {
        static void setInterfaces(void** _this, ClassInfo type) {
            return; // TODO delete this line when dmd bug 1712 is fixed
            if (type.base !is null) {
                setInterfaces(_this, type.base);
            }
            foreach (iface; type.interfaces) {
                auto ptr = iface.classinfo.vtbl[0];
                auto offset = (iface.offset / (void*).sizeof);
                *(_this + offset) = ptr;
                version(MocksDebug) writefln("%d: %x", offset, ptr);
            }
        }
    }
}
