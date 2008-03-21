module selfmock.traits;

template ToString(int i)
{
    static if (i == 0)
    {
        const ToString = '0';
    }
    else
    {
        const ToString = ToStringImpl!(i);
    }
}

template ToStringImpl(int i)
{
    static if (i > 0)
    {
        const ToStringImpl = ToDigit!(i % 10) ~ ToStringImpl!(i / 10);
    }
    else
    {
        const ToStringImpl = ``;
    }
}

template ToDigit(int i)
{
    const char ToDigit = cast(char)(i + '0');
}
