module dmocks.Model;

interface IMocked {
}

class FakeMocked : IMocked {
    string GetUnmockedTypeNameString () {
        return "FakeMocked";
    }
}
