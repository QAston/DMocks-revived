module assertions.exception;

import tango.core.Exception;

class UnsupportedOperationException : TracedException
{
	this (char[] message) 
	{
		super(message);
	}
}

class AssertionError : TracedException
{
	this (char[] message)
	{
		super(message);
	}
}
