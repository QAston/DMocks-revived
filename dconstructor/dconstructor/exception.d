module dconstructor.exception;

import dconstructor.util;

class BindingException : Exception
{
	this (string msg)
	{
		super(msg);
	}
}
