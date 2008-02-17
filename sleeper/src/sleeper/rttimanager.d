/**
  * Internal use. Aggregates RTTI information.
  */
module sleeper.rttimanager;
import sleeper.type;

// TODO: index classes by db table
class RttiManager {
    // Singleton. If dconstructor worked with static stuff, I'd just use
    // the Singleton interface from that. Actually, I might do that at some
    // point.
    private static RttiManager _default;
    public static RttiManager getmgr () {
        if (_default is null) {
            _default = new RttiManager();
        }
        return _default;
    }

    private DbClass[string] _classes;
    private DbClass[string] _byTable;

    public DbClass get (T)() {
        if (T.stringof in _classes) {
            return _classes[T.stringof];
        }

        DbClass t = new DbClass();
        t.cinfo = T.classinfo;
        t.type = typeid(T);
        _classes[T.stringof] = t;
        return t;
    }

    public DbClass add (T) (string table) {
        auto dbc = get!(T);
        _byTable[table] = dbc;
        return dbc;
    }
}
