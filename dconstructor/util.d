module dconstructor.util;

version (Tango) {
    alias char[] string;
}

template to_string(uint i) {
    static if (i < 10) {
        const string to_string = `` ~ cast(char)(i + '0');
    } else {
        const string to_string = (to_string!(i / 10)) ~ (to_string!(i % 10));
    }
}
