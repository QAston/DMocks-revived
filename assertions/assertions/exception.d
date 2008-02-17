module assertions.exception;

import tango.core.Exception;

class AssertionError : TracedException
{
	this (char[] message)
	{
		super(message);
	}
}
