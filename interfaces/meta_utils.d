module meta_utils;


template staticChain(T...) if( T.length > 0 )
{
	static if( T.length == 1 )
	{
		enum staticChain = T[0];
	}
	else
	{
		enum staticChain = T[0] ~ staticChain!(T[1..$]);
	}
}
