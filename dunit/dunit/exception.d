module dunit.exception;

import tango.core.Exception;

class UnsupportedOperationException : Exception
{
	this (char[] message) 
	{
		super(message);
	}
}

class AssertionError : Exception
{
	this (char[] message)
	{
		super(message);
	}
}
