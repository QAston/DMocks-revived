module dconstructor.exception;

import dconstructor.util;

class BindingException : Exception
{
	this (string msg)
	{
		super(msg);
	}
}

class CircularDependencyException : Exception
{
	private const string _defaultMessage = "A circular dependency was encountered."
	this () 
	{
		this(_defaultMessage);
	}

	this (string msg)
	{
		super(msg);
	}
}
