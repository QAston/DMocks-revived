/**
  * For internal use.
  * Handles database queries.
  */
module sleeper.dbmanager;

import sleeper.brains;
import dbi.Database, dbi.Result, dbi.Row;

class HLDbManager {
    private LLDbManager _lldm;
    private HqlTranslator _translator;

    this (LLDbManager low, HqlTranslator translator) {
        _lldm = low;
        _translator = translator;
    }

    void execute (string hql) {
        _lldm.execute(_translator.translate(hql));
    }

    T unique (T) (string hql) { 
        return _lldm.unique!(T)(_translator.translate(hql));
    }

    T[] list (T) (string sql) {
        return _lldm.list!(T)(_translator.translate(hql));
    }
}

/**
  * Low-level db querior. Needs to get sql that's specific to the db flavor it's
  * using.
  */
class LLDbManager {
    private:
        Database _db;
        RttiManager _rtti = RttiManager.get;
        T translate(T) (Row row) {
            DbClass dbc = _rtti.get!(T)();
            return cast(T)dbc.build(row);
        }

    public:
        this (Database db) { _db = db; }

        void execute (string sql) { _db.execute(sql); }

        T unique (T) (string sql) { 
            Row row = _db.queryFetchOne(sql);
            return translate!(T)(row);
        }

        T[] list (T) (string sql) {
            Row[] res = _db.query(sql).fetchAll();
            T[] array = new T[res.length];
            foreach (i, row; res) {
                array[i] = translate!(T)(row);
            }

            return array;
        }
}
