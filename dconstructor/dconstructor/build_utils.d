module dconstructor.build_utils;

import dconstructor.singleton;
import dconstructor.util;
import dconstructor.traits;

char[] get_deps (T) ()
{
	static if (is (typeof(new T) == T))
	{
		return `return new T();`;
	}
	else
	{
		return `return new T(` ~ get_deps_impl!(T, 0, "_ctor")() ~ `);`;
	}
}

char[] get_post_deps (T) ()
{
	static if (is (typeof (T.inject) == function))
	{
		return `obj.inject(` ~ get_deps_impl!(T, 0, "inject") ~ `);`;
	}
	else
	{
		return ``;
	}
}

char[] get_deps_impl (T, int i, char[] method) ()
{
	mixin("alias T." ~ method ~ " inject_method;");
	static if (i < ParameterTupleOf!(inject_method).length)
	{
		char[]
				ret = `parent.get!(ParameterTupleOf!(T.` ~ method ~ `)[` ~ (to_string!(
						i)) ~ `])`;
		static if (i < ParameterTupleOf!(inject_method).length - 1)
			ret ~= `,`;
		return ret ~ get_deps_impl!(T, i + 1, method)();
	}
	else
	{
		return ``;
	}
}
