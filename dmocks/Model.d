module dmocks.Model;

interface IMocked {
    string GetUnmockedTypeNameString ();
}

class FakeMocked : IMocked {
    string GetUnmockedTypeNameString () {
        return "FakeMocked";
    }
}
