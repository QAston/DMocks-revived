module dconstructor.multibuilder;

import dconstructor.object_builder;
import dconstructor.exception;

class MultiBuilder (TBuilder, T) : AbstractBuilder!(TBuilder, T)
{
	private AbstractBuilder!(TBuilder, T) [char[]] _subbuilders;
	private AbstractBuilder!(TBuilder, T) _default;

	Entity!(T) build (TBuilder b)
	{
		char[] objective = b._build_for;
		if (objective is null || !(objective in _subbuilders))
		{
			if (_default is null)
			{
				error();
			}
			return _default.build(b);
		}

		return _subbuilders[objective].build(b);
	}

	void add (char[] objective, AbstractBuilder!(TBuilder, T) maker)
	{
		if (objective is null)
		{
			set_default(maker);
		}
		else
		{
			_subbuilders[objective] = maker;
		}
	}

	void set_default (AbstractBuilder!(TBuilder, T) maker)
	{
		_default = maker;
	}

	private void error ()
	{
		throw new BindingException(
				"Trying to build type " ~ T.stringof ~ ": no binding for the current type, and no default binding.");
	}
}
