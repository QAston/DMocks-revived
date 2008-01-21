module sleeper.factory;

import
    dbi.Database,
    dbi.mssql.MssqlDatabase,
    dbi.sqlite.SqliteDatabase,
    dbi.mysql.MysqlDatabase;


enum DbFlavor {
    Postgres,
    Mysql,
    Mssql,
    Sqlite,
    Odbc,
    Oracle
}

Database create_db (DbFlavor flavor) {
    switch(flavor) {
        case Postgres:
            return new PgDatabase();
        case Mysql:
            return new MysqlDatabase();
        case Sqlite:
            return new SqliteDatabase();
        default:
            throw new Exception("not implemented");
    }
}

