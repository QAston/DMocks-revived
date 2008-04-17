module selfmock.mockobject;

import selfmock.caller;
import selfmock.repository;

class Mocked
{
    public Caller _owner;
	this ()
	{
		_owner = new Caller(MockRepository.get());
	}
}
