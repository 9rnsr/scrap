import std.algorithm : move;
import std.conv : emplace;
import std.traits;
//import std.exception : assumeUnique;	//?


void main()
{
}


template isRef(T)
{
	static if (is(T U == U*))
		enum isRef = true;
	else static if (is(U == class) || is(U == interface))
		enum isRef = true;
	else
		enum isRef = false;
}
template isRef(alias V)
{
	enum isRef = __traits(isRef, V) || .isRef!(typeof(V));

}

/**
unique type ... from Concurrent Clean
has ownership

Construction:
	Unique constructor receive only constrution arguments or
	rvalue T or Unique.
*/
struct Unique(T)
	if (!is(T == interface))
{
private:
  static if (is(T == class))
	enum payloadSize = __traits(claasInstanceSize, T);
  else
	enum payloadSize = T.sizeof;
	void[payloadSize] payload;
	bool filled;

//	enum DummyTag { DUMMY }
//	this(U)(U __unused, ref Unique u) if (is(U == DummyTag))
//	{
//		
//	}

public:
	// in-place construction
	this(A...)(A args) if (!is(A[0] == Unique) && !is(A[0] == T))
	{
		emplace(payload, args);
		filled = true;
	}

	// receive rvalue T
	this(U)(auto ref U u) if (is(U == T) && !isRef!u)
	{
		payload[] = typeid(T).init;
		move(u, *(cast(T*)payload.ptr));
		filled = true;
	}
	
	// receive rvalue Unique(move ownership)
	this(U)(auto ref U u) if (is(U == Unique) && !isRef!u)
	{
		if (u.filled)
		{
			payload[] = u.payload[];
			filled = true;
		}
	}
	
	// need fixing @@@BUG4437@@@ and @@@BUG4499@@@
	@disable this(this)
	{
		typeid(T).destroy(payload.ptr);
	//	.object.clear(payload);	// erabolate destructor problem?
	}
	
	~this()
	{
		if (filled)
		{
			typeid(T).destroy(payload.ptr);
			filled = false;
		}
	}
	
	void opAssign(U)(auto ref U u) if (is(U == T) && !isRef!u)
	{
		move(u, *(cast(T*)payload.ptr));
	}
	void opAssign(U)(auto ref U u) if (is(U == Unique) && !isRef!u)
	{
		move(u, *(cast(T*)payload.ptr));
	}
	
	bool isEmpty() const
	{
		return filled;
	}
	
	// extract value and release uniqueness
	T release()
	{
		filled = false;
		return move(*cast(T*)payload.ptr);
	}
	
  version(none)
  {
	// std.algorithm.move/swap でたぶんOK
//	Unique move()	// move元はinitになるのでfilled=falseとなりownershipが移動する
//	void swap()		// ownershipが交換されるので一意性は崩れない
  }

	alias payload this;
}


/+
// todo
Unique!T assumeUnique(T t) if (is(Unqual!T == T) || is(T == const))
{
	return Unique!T(t);
}
T assumeUnique(T t) if (is(T == immutable))
{
	return Unique!T(t);
}+/



T* emplaceCopy(T)(void[] chunk, ref T obj) if (!is(T == struct))
{
    enforce(chunk.length >= T.sizeof,
            new ConvException("emplace: target size too small"));
	
	chunk[] = (cast(void*)&obj)[0 .. T.sizeof];
	
  static if (hasElaborateCopyConstructor!T)
	typeid(T).postblit(chunk.ptr);
	
	return cast(T*)chunk.ptr;
}
