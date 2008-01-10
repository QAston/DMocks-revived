module dconstructor.provider;

/**
  * Template to register a class as the implementor of a given interface.
  * Usage:
  * ---
  * import dconstructor.api;
  *
  * class C : I {
  *     mixin(provides!(I));
  * }
  * ---
  */
string provides(T)() {
    return `static this () { builder.bind!(` ~ 
            T.stringof ~ 
            `, typeof(this)); }`;
}
