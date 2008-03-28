module dconstructor.exception;

import dconstructor.util;

class BindingException : Exception
{
	this (char[] msg)
	{
		super(msg);
	}
}

class CircularDependencyException : Exception
{
	private const char[] _defaultMessage = "A circular dependency was encountered.";
	this () 
	{
		this(_defaultMessage);
	}

	this (char[] msg)
	{
		super(msg);
	}
}
