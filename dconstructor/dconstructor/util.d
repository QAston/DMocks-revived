module dconstructor.util;


template to_string (uint i)
{
	static if (i < 10)
	{
		const char[] to_string = `` ~ cast(char) (i + '0');
	}
	else
	{
		const char[] to_string = (to_string!(i / 10)) ~ (to_string!(i % 10));
	}
}
