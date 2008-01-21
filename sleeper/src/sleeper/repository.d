module sleeper.repository;

abstract class Repository (T) {
    T get(int key);
    void save (T value);
    void update (T value);
}
