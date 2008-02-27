module dmocks.Caller;
import dmocks.Call;
import dmocks.Repository;
import dmocks.Model;
import dmocks.Util;

version(MocksDebug) import std.stdio;

struct ReturnOrPass(T) 
{
	static if (!is(T == void))
	{
		T value;
	}
	bool pass;
}

class Caller 
{
	private MockRepository _owner;
	
	public this (MockRepository owner)
	{
		_owner = owner;
	}
	
	public ReturnOrPass!(TReturn) Call(TReturn, U...)(IMocked mocked, string name, U args) 
	{
		ReturnOrPass!(TReturn) rope;
		version(MocksDebug) writefln("checking _owner.Recording...");
        if (_owner.Recording) 
        {
            _owner.Record!(U)(mocked, name, args, !is (TReturn == void));
            return rope;
        } 
        
        version(MocksDebug) writefln("checking for matching call...");
        ICall call = _owner.Match!(U)(mocked, name, args);
        
        version(MocksDebug) writefln("checking if call is null...");
        if (call is null)
        {
            throw new ExpectationViolationException();
        }

        version(MocksDebug) writefln("checking for passthrough...");
        if (call.PassThrough()) 
        {
            rope.pass = true;
            return rope;
        }

        version(MocksDebug) writefln("checking for something to throw...");
        if (call.ToThrow() !is null) 
        {
            version(MocksDebug) writefln("throwing");
            throw call.ToThrow();
        }

        version(MocksDebug) writefln("checking for delegate to execute...");
        auto action = call.Action();
        static if (is (TReturn == void)) 
        {
        	alias typeof(delegate (U u){}) action_type;
            if (action.hasValue() && action.peek!(action_type)) 
            {
                auto func = *action.peek!(action_type);
                version(MocksDebug) writefln("i can has action");
                if (func is null) 
                {
                    version(MocksDebug) writefln("noooo they be stealin mah action");
                    throw new InvalidOperationException("The specified delegate was of the wrong type.");
                }

                version(MocksDebug) writefln("executing action");
                func(args);
            }
        }
        else 
        {
        	alias typeof(delegate (U u){ return TReturn.init; }) action_type;
        	if (action.hasValue() && action.peek!(action_type)) 
        	{
        		auto func = *action.peek!(action_type);
        		version(MocksDebug) writefln("i can has action");
        		if (func is null) 
        		{
        			version(MocksDebug) writefln("noooo they be stealin mah action");
        			throw new InvalidOperationException("The specified delegate was of the wrong type.");
        		}

        		version(MocksDebug) writefln("executing action");
        		rope.value = func(args);
        		version(MocksDebug) writefln("executed action");
        		return rope;
        	} 
        	else 
        	{
        		version(MocksDebug) writefln("i no can has action");
        	}
        	if (call.ReturnValue().hasValue()) 
        	{
            	version(MocksDebug) writefln("getting a value to return...");
            	auto ptr = call.ReturnValue().peek!(TReturn);
            	if (ptr is null)
            	{
            		throw new InvalidOperationException("It looks like you tried to return the wrong type from a mocked function.");
            	}
            	rope.value = *ptr; 
        	}
        }
        
    	version(MocksDebug) writefln("returning...");
    	return rope;
	}
}