module dmocks.action;

import std.variant;
import dmocks.util;

package:

interface IAction
{
    bool passThrough ();

    void passThrough (bool value);

    Variant returnValue ();

    void returnValue (Variant value);

    void action (Variant value);

    Variant action ();

    Exception toThrow ();

    void toThrow (Exception value);

    bool hasAction ();
    
    Actor getActor ();
}

enum ActionStatus
{
    Success,
    FailBadAction,
}

struct ReturnOrPass (T)
{
    static if (!is (T == void))
    {
        T value;
    }

    bool pass;
    ActionStatus status = ActionStatus.Success;
}

struct Actor 
{
    IAction self;

    ReturnOrPass!(TReturn) act (TReturn, ArgTypes...) (ArgTypes args)
    {
        debugLog("Actor:act");

        ReturnOrPass!(TReturn) rope;
        if (self.passThrough)
        {
            rope.pass = true;
            return rope;
        }
        if (self.toThrow)
        {
            throw self.toThrow;
        }
        static if (is (TReturn == void))
        {
            if (self.action.hasValue)
            {
                debugLog("action found, type: %s", self.action().type);
                auto funcptr = self.action().peek!(void delegate(ArgTypes));
                if (funcptr)
                {
                    (*funcptr)(args);
                }
                else
                {
                    rope.status = ActionStatus.FailBadAction;
                }
            }
        }
        else
        {
            if (self.returnValue.hasValue)
            {
                rope.value = *self.returnValue().peek!(TReturn);
            }
            else if (self.action.hasValue)
            {
                debugLog("action found, type: %s", self.action().type);
                auto funcptr = self.action().peek!(TReturn delegate (ArgTypes a));
                if (funcptr)
                {
                    rope.value = (*funcptr)(args);
                }
                else
                {
                    rope.status = ActionStatus.FailBadAction;
                }
            }
        }

        return rope;
    }
}

//TODO: make action parameters orthogonal or disallow certain combinations of them
//TODO use something different than variant for storing values
class Action : IAction
{
private
{
    bool _passThrough;
    Variant _returnValue;
    Variant _action;
    Exception _toThrow;
    TypeInfo _returnType;
}

    this(TypeInfo returnType)
    {
        this._returnType = returnType;
    }

    bool hasAction ()
    {
        return (_returnType is typeid(void)) || (_passThrough) || (_returnValue.hasValue) || (_action.hasValue) || (_toThrow !is null);
    }

    bool passThrough ()
    {
        return _passThrough;
    }

    void passThrough (bool value)
    {
        _passThrough = value;
    }

    Variant returnValue ()
    {
        return _returnValue;
    }

    void returnValue (Variant value)
    {
        _returnValue = value;
    }
    
    void action (Variant value)
    {
        _action = value;
    }

    Variant action ()
    {
        return _action;
    }

    Exception toThrow ()
    {
        return _toThrow;
    }

    void toThrow (Exception value)
    {
        _toThrow = value;
    }

    Actor getActor ()
    {
        Actor act;
        act.self = this;
        return act;
    }
}

version (DMocksTest)
{
    unittest
    {
        mixin(test!("action returnValue"));
        Variant v = 5;
        Action act = new Action(typeid(int));
        assert (!act.returnValue.hasValue);
        act.returnValue = v;
        assert (act.returnValue() == 5);
    }
    
    unittest
    {
        mixin(test!("action action"));
        Variant v = 5;
        Action act = new Action(typeid(int));
        assert (!act.action.hasValue);
        act.action = v;
        assert (act.action() == v);
    }
    
    unittest
    {
        mixin(test!("action exception"));
        Exception ex = new Exception("boogah");
        Action act = new Action(typeid(int));
        assert (act.toThrow is null);
        act.toThrow = ex;
        assert (act.toThrow is ex);
    }
    
    unittest 
    {
        mixin(test!("action passthrough"));
        Action act = new Action(typeid(int));
        act.passThrough = true;
        assert (act.passThrough());
        act.passThrough = false;
        assert (!act.passThrough());
    }

    unittest
    {
        mixin(test!("action hasAction"));
        Action act = new Action(typeid(int));
        act.returnValue(Variant(5));
        assert(act.hasAction);
    }
}
