module sleeper.exception;

/** Exception thrown when the database mapping couldn't be compiled. */
class MappingException : Exception {
    this (string msg) {
        super("Could not compile mapping: " ~ msg);
    }
}

