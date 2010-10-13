/**
	original of this module is by rsinfu (http://gist.github.com/598659)
*/
module meta;

@safe:


/**
 */
template Sequence(seq...)
{
	alias seq Sequence;
}


//----------------------------------------------------------------------------//
// Algorithms
//----------------------------------------------------------------------------//


/**
 */
template staticMap(alias map, seq...)
{
	static if (seq.length < 2)
	{
		static if (seq.length == 0)
		{
			alias Sequence!() staticMap;
		}
		else
		{
			alias Sequence!(Instantiate!map.With!(seq[0])) staticMap;
		}
	}
	else
	{
		alias Sequence!(staticMap!(map, seq[ 0	.. $/2]),
						   staticMap!(map, seq[$/2 ..  $ ]))
			  staticMap;
	}
}

unittest
{
}


/**
 */
template staticFilter(alias pred, seq...)
{
	static if (seq.length < 2)
	{
		static if (seq.length == 1 && Instantiate!pred.With!(seq[0]))
		{
			alias seq staticFilter;
		}
		else
		{
			alias Sequence!() staticFilter;
		}
	}
	else
	{
		alias Sequence!(staticFilter!(pred, seq[ 0	.. $/2]),
						   staticFilter!(pred, seq[$/2 ..  $ ]))
			  staticFilter;
	}
}

unittest
{
}


/**
 */
template staticReduce(alias compose, Seed, seq...)
{
	static if (seq.length == 0)
	{
		alias Seed staticReduce;
	}
	else
	{
		alias staticReduce!(compose,
							Instantiate!compose.With!(Seed, seq[0]),
							seq[1 .. $])
			  staticReduce;
	}
}

/// ditto
template staticReduce(alias compose, alias Seed, seq...)
{
	static if (seq.length == 0)
	{
		alias Seed staticReduce;
	}
	else
	{
		alias staticReduce!(compose,
							Instantiate!compose.With!(Seed, seq[0]),
							seq[1 .. $])
			  staticReduce;
	}
}

unittest
{
}


/**
 */
template staticRemove(E, seq...)
{
	alias staticRemoveIf!(Instantiate!isSame.bindFront!E, seq) staticRemove;
}

/// ditto
template staticRemove(alias E, seq...)
{
	alias staticRemoveIf!(Instantiate!isSame.bindFront!E, seq) staticRemove;
}

unittest
{
}


/// ditto
template staticRemoveIf(alias pred, seq...)
{
	alias staticFilter!(templateNot!pred, seq) staticRemoveIf;
}

unittest
{
}


// Groundwork for find-family algorithms
private template _staticFindChunk(alias pred, size_t m)
{
	template index(seq...)
		if (seq.length < m)
	{
		enum index = seq.length;
	}

	template index(seq...)
		if (m <= seq.length && seq.length < 2*m)
	{
		static if (Instantiate!pred.With!(seq[0 .. m]))
		{
			enum index = cast(size_t) 0;
		}
		else
		{
			enum index = index!(seq[1 .. $]) + 1;
		}
	}

	template index(seq...)
		if (2*m <= seq.length)
	{
		static if (index!(seq[0 .. $/2 + m - 1]) < seq.length/2)
		{
			enum index = index!(seq[0 .. $/2 + m - 1]);
		}
		else
		{
			enum index = index!(seq[$/2 .. $]) + seq.length/2;
		}
	}
}


/**
 */
template staticFind(E, seq...)
{
	alias staticFindIf!(Instantiate!isSame.bindFront!E, seq) staticFind;
}

/// ditto
template staticFind(alias E, seq...)
{
	alias staticFindIf!(Instantiate!isSame.bindFront!E, seq) staticFind;
}

unittest
{
}


/// ditto
template staticFindIf(alias pred, seq...)
{
	alias seq[_staticFindChunk!(pred, 1).index!seq .. $] staticFindIf;
}

unittest
{
}


/**
 */
template staticFindAdjacentIf(alias pred, seq...)
{
	alias seq[_staticFindChunk!(pred, 2).index!seq .. $] staticFindAdjacentIf;
}

unittest
{
}


/**
 */
template staticIndexOf(E, seq...)
{
	static if (staticFind!(E, seq).length == 0)
	{
		enum /*sizediff_t*/ staticIndexOf = -1;
	}
	else
	{
		enum /*sizediff_t*/ staticIndexOf = (seq.length -
										 staticFind!(E, seq).length);
	}
}

/// ditto
template staticIndexOf(alias E, seq...)
{
	static if (staticFind!(E, seq).length == 0)
	{
		enum /*sizediff_t*/ staticIndexOf = -1;
	}
	else
	{
		enum /*sizediff_t*/ staticIndexOf = (seq.length -
										 staticFind!(E, seq).length);
	}
}

unittest
{
}


/**
 */
template staticUntil(E, seq...)
{
	alias staticUntilIf!(Instantiate!isSame.bindFront!E, seq) staticUntil;
}

/// ditto
template staticUntil(alias E, seq...)
{
	alias staticUntilIf!(Instantiate!isSame.bindFront!E, seq) staticUntil;
}

unittest
{
}


/// ditto
template staticUntilIf(alias pred, seq...)
{
	alias seq[0 .. _staticFindChunk!(pred, 1).index!seq] staticUntilIf;
}

unittest
{
}


/**
 */
template staticCount(E, seq...)
{
	alias staticCountIf!(Instantiate!isSame.bindFront!E, seq) staticCount;
}

/// ditto
template staticCount(alias E, seq...)
{
	alias staticCountIf!(Instantiate!isSame.bindFront!E, seq) staticCount;
}

unittest
{
}


/// ditto
template staticCountIf(alias pred, seq...)
{
	static if (seq.length <= 1)
	{
		static if (seq.length == 0 || !Instantiate!pred.With!(seq[0]))
		{
			enum size_t staticCountIf = 0;
		}
		else
		{
			enum size_t staticCountIf = 1;
		}
	}
	else
	{
		enum staticCountIf = staticCountIf!(pred, seq[ 0  .. $/2]) +
							 staticCountIf!(pred, seq[$/2 ..  $ ]);
	}
}

unittest
{
}


/**
 */
template staticReplace(From, To, seq...)
{
	alias staticMap!(_staticReplace!(From, To).map, seq) staticReplace;
}

/// ditto
template staticReplace(alias From, To, seq...)
{
	alias staticMap!(_staticReplace!(From, To).map, seq) staticReplace;
}

/// ditto
template staticReplace(From, alias To, seq...)
{
	alias staticMap!(_staticReplace!(From, To).map, seq) staticReplace;
}

/// ditto
template staticReplace(alias From, alias To, seq...)
{
	alias staticMap!(_staticReplace!(From, To).map, seq) staticReplace;
}

private template _staticReplace(tr...)
{
	alias Identity!(tr[0]) from;
	alias Identity!(tr[1])	 to;

	template map(e...)
	{
		static if (isSame!(e, from))
		{
			alias to map;
		}
		else
		{
			alias e  map;
		}
	}
}

unittest
{
}


/**
 */
template staticMost(alias comp, seq...)
	if (seq.length >= 1)
{
	static if (seq.length <= 2)
	{
		static if (seq.length == 1 || !Instantiate!comp.With!(seq[1], seq[0]))
		{
			alias Identity!(seq[0]) staticMost;
		}
		else
		{
			alias Identity!(seq[1]) staticMost;
		}
	}
	else
	{
		alias staticMost!(comp, staticMost!(comp, seq[ 0  .. $/2]),
								staticMost!(comp, seq[$/2 ..  $ ]))
			  staticMost;
	}
}

unittest
{
}


/**
 */
template staticSort(alias comp, seq...)
{
	static if (seq.length < 2)
	{
		alias seq staticSort;
	}
	else
	{
		 alias _staticMerger!comp.Merge!(staticSort!(comp, seq[ 0  .. $/2]))
								  .With!(staticSort!(comp, seq[$/2 ..  $ ]))
			   staticSort;
	}
}

private template _staticMerger(alias comp)
{
	template Merge()
	{
		template With(B...)
		{
			alias B With;
		}
	}

	template Merge(A...)
	{
		template With()
		{
			alias A With;
		}

		template With(B...)
		{
			static if (Instantiate!comp.With!(B[0], A[0]))
			{
				alias Sequence!(B[0], Merge!(A		  )
										 .With!(B[1 .. $])) With;
			}
			else
			{
				alias Sequence!(A[0], Merge!(A[1 .. $])
										 .With!(B		 )) With;
			}
		}
	}
}

/// ditto
template isStaticSorted(alias comp, seq...)
{
	static if (seq.length < 2)
	{
		enum isStaticSorted = true;
	}
	else
	{
		static if (Instantiate!comp.With!(seq[$/2], seq[$/2 - 1]))
		{
			enum isStaticSorted = false;
		}
		else
		{
			enum isStaticSorted = isStaticSorted!(comp, seq[ 0	.. $/2]) &&
								  isStaticSorted!(comp, seq[$/2 ..	$ ]);
		}
	}
}

unittest
{
}


/**
 */
template staticUniqSort(alias comp, seq...)
{
	static if (seq.length < 2)
	{
		alias seq staticUniqSort;
	}
	else
	{
		alias _staticUniqMerger!comp
					.Merge!(staticUniqSort!(comp, seq[ 0  .. $/2]))
					 .With!(staticUniqSort!(comp, seq[$/2 ..  $ ]))
			  staticUniqSort;
	}
}

private template _staticUniqMerger(alias comp)
{
	template Merge()
	{
		template With(B...)
		{
			alias B With;
		}
	}

	template Merge(A...)
	{
		template With()
		{
			alias A With;
		}

		template With(B...)
		{
			static if (Instantiate!comp.With!(A[0], B[0]))
			{
				alias Sequence!(A[0], Merge!(A[1 .. $])
										 .With!(B[0 .. $])) With;
			}
			else static if (Instantiate!comp.With!(B[0], A[0]))
			{
				alias Sequence!(B[0], Merge!(A[0 .. $])
										 .With!(B[1 .. $])) With;
			}
			else
			{
				alias Merge!(A[0 .. $])
					  .With!(B[1 .. $]) With;
			}
		}
	}
}

/// ditto
template isStaticUniqSorted(alias comp, seq...)
{
	static if (seq.length < 2)
	{
		enum isStaticUniqSorted = true;
	}
	else
	{
		static if (Instantiate!comp.With!(seq[$/2 - 1], seq[$/2]))
		{
			enum isStaticUniqSorted =
					isStaticUniqSorted!(comp, seq[ 0  .. $/2]) &&
					isStaticUniqSorted!(comp, seq[$/2 ..  $ ]);
		}
		else
		{
			enum isStaticUniqSorted = false;
		}
	}
}

unittest
{
}


/**
 */
template staticUniq(seq...)
{
	static if (seq.length <= 1)
	{
		alias seq staticUniq;
	}
	else
	{
		static if (isSame!(seq[$/2 - 1], seq[$/2]))
		{
			alias Sequence!(staticUniq!(seq[0 .. $/2]),
							   staticUniq!(seq[$/2 .. $])[1 .. $])
				  staticUniq;
		}
		else
		{
			alias Sequence!(staticUniq!(seq[0 .. $/2]),
							   staticUniq!(seq[$/2 .. $]))
				  staticUniq;
		}
	}
}

unittest
{
}


/**
 */
template staticRemoveDuplicates(seq...)
{
	static if (seq.length <= 1)
	{
		alias seq staticRemoveDuplicates;
	}
	else
	{
		alias Sequence!(seq[0],
						   staticRemoveDuplicates!(staticRemove!(seq[0],
																 seq[1 .. $])))
			  staticRemoveDuplicates;
	}
}

unittest
{
}


/**
 */
template staticReverse(seq...)
{
	static if (seq.length < 2)
	{
		alias seq staticReverse;
	}
	else
	{
		alias Sequence!(staticReverse!(seq[$/2 ..  $ ]),
						   staticReverse!(seq[ 0  .. $/2]))
			  staticReverse;
	}
}

unittest
{
}


/**
 */
template staticRepeat(size_t n, seq...)
{
	static if (n == 0)
	{
		alias Sequence!() staticRepeat;
	}
	else
	{
		static if (n == 1 || seq.length == 0)
		{
			alias seq staticRepeat;
		}
		else
		{
			alias Sequence!(staticRepeat!(	 n	  / 2, seq),
							   staticRepeat!((n + 1) / 2, seq))
				  staticRepeat;
		}
	}
}

unittest
{
}


/**
 */
template staticStride(size_t n, seq...)
	if (n >= 1)
{
	static if (n == 1 || seq.length <= 1)
	{
		alias seq staticStride;
	}
	else
	{
		static if (seq.length <= n)
		{
			alias seq[0 .. 1] staticStride;
		}
		else
		{
			alias Sequence!(staticStride!(n, seq[0 .. _strideMid!($, n)]),
							   staticStride!(n, seq[_strideMid!($, n) .. $]))
				  staticStride;
		}
	}
}

private template _strideMid(size_t n, size_t k)
{
	enum _strideMid = ((n + k - 1) / k / 2) * k;
}

unittest
{
}


/**
 */
template staticTransverse(size_t i, tuples...)
{
	static if (tuples.length < 2)
	{
		static if (tuples.length == 0)
		{
			alias Sequence!() staticTransverse;
		}
		else
		{
			alias Sequence!(tuples[0].Expand[i]) staticTransverse;
		}
	}
	else
	{
		alias Sequence!(staticTransverse!(i, tuples[ 0	.. $/2]),
						staticTransverse!(i, tuples[$/2 ..  $ ]))
			  staticTransverse;
	}
}

/// ditto
template staticFrontTransverse(tuples...)
{
	alias staticTransverse!(0, tuples) staticFrontTransverse;
}

unittest
{
}


/**
 */
template staticZip(tuples...)
{
	alias staticMap!(_ZipTransverser!tuples,
					 staticIota!(0, _minLength!tuples))
		  staticZip;
}

private
{
	template _ZipTransverser(tuples...)
	{
		template _ZipTransverser(size_t i)
		{
			alias Wrap!(staticTransverse!(i, tuples)) _ZipTransverser;
		}
	}

	template _minLength(tuples...)
	{
		alias staticMost!(q{ a < b }, staticMap!(q{ a.length }, tuples))
			  _minLength;
	}
}

unittest
{
}


/**
 */
template staticPermutations(seq...)
{
	static if (seq.length > 5)
	{
		static assert(0, "too many elements for compile-time permutation");
	}
	else
	{
		alias _staticPermutations!(seq.length, seq).Result
			   staticPermutations;
	}
}

private
{
	template _staticPermutations(size_t k, seq...)
		if (k == 0)
	{
		alias Sequence!(metaArray!()) Result;
	}

	template _staticPermutations(size_t k, seq...)
		if (k == 1)
	{
		alias staticMap!(metaArray, seq) Result;
	}

	template _staticPermutations(size_t k, seq...)
		if (k >= 2)
	{
		template consLater(car...)
		{
			template consLater(alias wrap)
			{
				alias Wrap.insertFront!car consLater;
			}
		}

		template consMapAt(size_t i)
		{
			alias staticMap!(consLater!(seq[i]),
							_staticPermutations!(k - 1,
												 seq[  0   .. i],
												 seq[i + 1 .. $]).Result)
				  consMapAt;
		}

		alias staticMap!(consMapAt, staticIota!(seq.length)) Result;
	}
}

unittest
{
}


/**
 */
template staticCombinations(size_t k, seq...)
	if (k <= seq.length)
{
	alias _staticCombinations!(k, seq).Result staticCombinations;
}

private
{
	template _staticCombinations(size_t k, seq...)
		if (k == 0)
	{
		alias Sequence!(Wrap!()) Result;
	}

	template _staticCombinations(size_t k, seq...)
		if (k == 1)
	{
		alias staticMap!(Wrap, seq) Result;
	}

	template _staticCombinations(size_t k, seq...)
		if (k >= 2)
	{
		template consLater(car...)
		{
			template consLater(alias wrap)
			{
				alias wrap.insertFront!car consLater;
			}
		}

		template consMapFrom(size_t i)
		{
			alias staticMap!(consLater!(seq[i]),
							_staticCombinations!(k - 1,
												 seq[i + 1 .. $]).Result)
				  consMapFrom;
		}

		alias staticMap!(consMapFrom, staticIota!(seq.length)) Result;
	}
}

version(unittest)
{
	//pragma(msg, staticCombinations!(3, int, long, float, double));
//	static assert(
//		is(staticCombinations!(3, int, long, float, double)
//			== Sequence!(
//				Wrap!(int,long,float), Wrap!(int,long,double),
//				Wrap!(int,float,double), Wrap!(long,float,double))));
}


/**
 */
template staticCartesian(tuples...)
	if (tuples.length >= 1)
{
	alias _staticCartesian!tuples.Result staticCartesian;
}

private
{
	template _staticCartesian(alias wrap)
	{
		alias staticMap!(Wrap, wrap.Expand) Result;
	}

	template _staticCartesian(alias wrap, rest...)
	{
		alias _staticCartesian!rest.Result subCartesian;

		template consLater(car...)
		{
			template consLater(alias wrap)
			{
				alias wrap.insertFront!car consLater;
			}
		}

		template consMap(car...)
		{
			alias staticMap!(consLater!car, subCartesian) consMap;
		}

		alias staticMap!(consMap, wrap.Expand) Result;
	}
}

version(unittest)
{
	//pragma(msg, staticCartesian!(Wrap!(int, long), Wrap!(float, double)));
}


/**
 */
template staticIota(int beg, int end, int step = 1)
	if (step != 0)
{
	static if (beg + 1 >= end)
	{
		static if (beg >= end)
		{
			alias Sequence!() staticIota;
		}
		else
		{
			alias Sequence!(+beg) staticIota;
		}
	}
	else
	{
		alias Sequence!(staticIota!(beg, _iotaMid!(beg, end)	 ),
						staticIota!(     _iotaMid!(beg, end), end))
			  staticIota;
	}
}

private template _iotaMid(int beg, int end)
{
	enum _iotaMid = beg + (end - beg) / 2;
}

/// ditto
template staticIota(int end)
{
	alias staticIota!(0, end) staticIota;
}

unittest
{
}


/**
 */
template allSatisfy(alias pred, seq...)
{
	enum allSatisfy = (staticCountIf!(pred, seq) == seq.length);
}

/// ditto
template anySatisfy(alias pred, seq...)
{
	enum anySatisfy = (staticCountIf!(pred, seq) > 0);
}

/// ditto
template noneSatisfy(alias pred, seq...)
{
	enum noneSatisfy = (staticCountIf!(pred, seq) == 0);
}

unittest
{
}



//----------------------------------------------------------------------------//
// Convenience Templates
//----------------------------------------------------------------------------//


/**
 */
template Identity(alias E)
{
	alias E Identity;
}

/// ditto
template Identity(E)
{
	alias E Identity;
}

unittest
{
}


/**
 */
template Wrap(seq...)
{
	/**
	 */
	alias seq Expand;


	/**
	 */
	enum bool empty = !seq.length;


	/**
	 */
	enum size_t length = seq.length;


	/**
	 */
	template at(size_t i)
	{
		alias Identity!(seq[i]) at;
	}


	/**
	 */
	template slice(size_t i, size_t j)
	{
		alias Wrap!(seq[i .. j]) slice;
	}


	/**
	 */
	template take(size_t n)
	{
		alias Wrap!(seq[0 .. (n < $ ? n : $)]) take;
	}


	/**
	 */
	template drop(size_t n)
	{
		alias Wrap!(seq[(n < $ ? n : $) .. $]) drop;
	}


	/**
	 */
	template insertFront(aseq...)
	{
		alias Wrap!(aseq, seq) insertFront;
	}


	/**
	 */
	template insertBack(aseq...)
	{
		alias Wrap!(seq, aseq) insertBack;
	}


	/**
	 */
	template insertAt(size_t i, aseq...)
	{
		alias Wrap!(seq[0 .. i], aseq, seq[i .. $]) insertAt;
	}


	/**
	 */
	template contains(subseq...)
	{
		static if (subseq.length == 0 || subseq.length > seq.length)
		{
			enum contains = (subseq.length == 0);
		}
		else
		{
			enum contains = _staticFindChunk!(MatchSequence!aseq.With,
											  subseq.length)
								.index!seq < seq.length;
		}
	}


 private:

	template ToType()
	{
		struct ToType {}
	}

	version (unittest) alias ToType!() _T;
}

unittest
{
}


/**
 */
template MatchSequence(seq...)
{
	/**
	 */
	template With(aseq...)
	{
		enum With = is(Wrap!seq.ToType!() == Wrap!aseq.ToType!());
	}
}

unittest
{
}


/**
 */
template isSame(A, B)
{
	enum isSame = is(A == B);
}

/// ditto
template isSame(alias A, alias B)
{
	enum isSame = is(Wrap!A.ToType!() == Wrap!B.ToType!());
}

/// ditto
template isSame(alias A, B)
{
	enum isSame = false;
}

/// ditto
template isSame(A, alias B)
{
	enum isSame = false;
}

unittest
{
}


/**
 */
template templateFun(string expr)
{
	alias _templateFun!expr._ templateFun;
}

// XXX
private template _templateFun(string expr)
{
	enum size_t maxArgs = ('z' - 'a' + 1);

	template _(args...)
		if (args.length <= maxArgs)
	{
		alias invoke!args.result _;
	}

	template invoke(args...)
		if (args.length <= maxArgs)
	{
		mixin bind!(0, args);
		mixin("alias Identity!(" ~ expr ~ ") result;");
	}

	template bind(size_t i, args...)
	{
		static if (i < args.length)
		{
			mixin("alias Identity!(args[i]) " ~ paramAt!i ~ ";");
			mixin bind!(i + 1, args);
		}
	}

	template paramAt(size_t i)
		if (i < maxArgs)
	{
		enum dchar paramAt = ('a' + i);
	}
}

unittest
{
}


//----------------------------------------------------------------------------//
// Templationals
//----------------------------------------------------------------------------//

/**
 */
template Instantiate(alias templat)
{
	/**
	 */
	template With(args...)
	{
		alias templat!args With;
	}

	/**
	 */
	template Returns(string name)
	{
		template Returns(args...)
		{
			mixin("alias templat!args." ~ name ~ " Returns;");
		}
	}

	/**
	 */
	template bindFront(bind...)
	{
		template bindFront(args...)
		{
			alias templat!(bind, args) bindFront;
		}
	}

	/**
	 */
	template bindBack(bind...)
	{
		template bindBack(args...)
		{
			alias templat!(args, bind) bindBack;
		}
	}
}

/// ditto
template Instantiate(string templat)
{
	alias Instantiate!(templateFun!templat) Instantiate;
}

unittest
{
}


private template Instantiator(args...)
{
	template Instantiator(alias templat)
	{
		alias Instantiate!templat.With!args Instantiator;
	}
}


/**
 */
template templateNot(alias pred)
{
	template templateNot(args...)
	{
		enum templateNot = !Instantiate!pred.With!args;
	}
}

unittest
{
}


/**
 */
template templateAnd(preds...)
{
	template templateAnd(args...)
	{
		alias allSatisfy!(Instantiator!args, preds) templateAnd;
	}
}

/// ditto
template templateOr(preds...)
{
	template templateOr(args...)
	{
		alias anySatisfy!(Instantiator!args, preds) templateOr;
	}
}

unittest
{
}


/**
 */
template templateCompose(templates...)
	if (templates.length >= 1)
{
	template templateCompose(args...)
	{
		static if (templates.length == 1)
		{
			alias Instantiate!(templates[0]).With!args templateCompose;
		}
		else
		{
			alias Instantiate!(templates[0])
						.With!(Instantiate!(.templateCompose!(templates[1 .. $]))
									 .With!args)
				  templateCompose;
		}
	}
}

unittest
{
}



//----------------------------------------------------------------------------//


/**
 */
template Select(bool condition, Then, Else)
{
	static if (cnodition)
	{
		alias Then Select;
	}
	else
	{
		alias Else Select;
	}
}

/// ditto
template Select(bool condition, Then, alias Else)
{
	static if (condition)
	{
		alias Then Select;
	}
	else
	{
		alias Else Select;
	}
}

/// ditto
template Select(bool condition, alias Then, Else)
{
	static if (condition)
	{
		alias Then Select;
	}
	else
	{
		alias Else Select;
	}
}

/// ditto
template Select(bool condition, alias Then, alias Else)
{
	static if (condition)
	{
		alias Then Select;
	}
	else
	{
		alias Else Select;
	}
}

unittest
{
}


/**
 */
A select(bool cond, A, B)(A a, lazy B b)
	if (cond)
{
	return a;
}

/// Ditto
B select(bool cond, A, B)(lazy A a, B b)
	if (!cond)
{
	return b;
}

unittest
{
}


//----------------------------------------------------------------------------//
// Filtering Predicates
//----------------------------------------------------------------------------//
/**
 */
template TypeOf(alias a)
{
	alias typeof(a) TypeOf;
}


/**
 */
template StringOf(alias A)
{
	enum StringOf = A.stringof;
}
/// ditto
template StringOf(T)
{
	enum StringOf = T.stringof;
}


/**
 */
template LengthOf(T...)
{
	enum size_t LengthOf = T.length;
}


/**
	alternation of built-in __traits(identifier, A)
 */
template Identifier(alias A)
{
	enum Identifier = __traits(identifier, A);
}
/// ditto
alias Identifier NameOf;
unittest
{
	int v;
	static assert(Identifier!v == __traits(identifier, v));
}


//----------------------------------------------------------------------------//
// Conditional Predicates
//----------------------------------------------------------------------------//
/**
 */
template isStruct(T)
{
	enum isStruct= is(T == struct);
}


/**
 */
template isUnion(T)
{
	enum isUnion= is(T == union);
}


/**
 */
template isClass(T)
{
	enum isClass= is(T == class);
}


/**
 */
template isInterface(T)
{
	enum isInterface = is(T == interface);
}


/**
 */
template isType(T)
{
	enum isType = true;
}
/// ditto
template isType(alias A)
{
	enum isType = false;
}


/**
 */
template isAlias(T)
{
	enum isAlias = false;
}
/// ditto
template isAlias(alias A)
{
	enum isAlias = true;
}

unittest
{
	alias Sequence!(int, long, 10, 2.0) S;

	alias staticFilter!(isType,  S) Rt;
	alias Sequence!(int, long) At;
	static assert(is(Rt == At));

	alias staticFilter!(isAlias, S) Ra;
	alias Sequence!(10, 2.0) Aa;
//	static assert(Ra == Aa);
	static assert(Ra[0] == Aa[0]);
	static assert(Ra[1] == Aa[1]);
}


//----------------------------------------------------------------------------//
// Sequences
//----------------------------------------------------------------------------//

version = Fixed_Issue4217;

version(Fixed_Issue4217)
{
	template VirtualFunctionsOfImpl(T, string name)
	{
		alias Sequence!(__traits(getVirtualFunctions, T, name)) Result;
	}
}
else
{
	// issue4217が修正されないと、シンボルのシーケンスの要素は正しく比較できない
	// 下のworkaroundは間違い

//	private template VirtualFunctionsOfImpl(T, string name)
//	{
//		alias Sequence!(__traits(getVirtualFunctions, T, name)) Overloads;
//		//pragma(msg, ">> ", typeof(Overloads));
//		
//		template MakeSeq(int n)
//		{
//			static if( n >= Overloads.length )
//			{
//				alias Sequence!() Result;
//			}
//			else
//			{
//				//pragma(msg, ". ", typeof(Overloads[n]));
//				alias Overloads[n] Symbol;
//				
//				alias Sequence!(
//					Symbol,//Overloads[n],
//					MakeSeq!(n+1).Result
//				) Result;
//			}
//		}
//		alias MakeSeq!(0).Result Result;
//	}
//	version(unittest)
//	{
//		interface I
//		{
//			int f() const;
//			int f() immutable;
//		}
//		alias VirtualFunctionsOfImpl!(I, "f").Result F;
//		//pragma(msg, TypeOf!(F[0]), ", ", typeof(F[0]));
//		static assert(is(TypeOf!(F[0]) == typeof(F[0])));
//		//pragma(msg, TypeOf!(F[1]), ", ", typeof(F[1]));
//		static assert(is(TypeOf!(F[1]) == typeof(F[1])));
//	}
}
/**
	does not reduce overloads
	Parameter:
		name :	specified member name.
				if it is empty string, all of virtual-functions on T returns.
 */
template VirtualFunctionsOf(T, string name="")
{
	static if( name == "" )
	{
		alias staticMap!(
			Instantiate!(
				Instantiate!VirtualFunctionsOfImpl.bindFront!T
			).Returns!"Result",
			Sequence!(__traits(allMembers, T))
		) VirtualFunctionsOf;
	}
	else
	{
		alias VirtualFunctionsOfImpl!(T, name).Result VirtualFunctionsOf;
	}
}


private template staticIndexOfIfImpl(alias pred, seq...)
{
	enum len = seq.length;
	enum len2 = staticFindIf!(pred, seq).length;
	static if( len2 == 0 )
	{
		enum int Result = -1;
	}
	else
	{
		enum int Result = len - len2;
	}
}
template staticIndexOfIf(alias pred, seq...)
{
	enum staticIndexOfIf = staticIndexOfIfImpl!(pred, seq).Result;
}



/**
	both of template-mixin or string-mixin
 */
template mixinAll(mixins...)
{
	static if (mixins.length == 1)
	{
		static if (is(typeof(mixins[0]) == string))
		{
			mixin(mixins[0]);
		}
		else
		{
			alias mixins[0] it;
			mixin it;
		}
	}
	else static if (mixins.length >= 2)
	{
		mixin mixinAll!(mixins[ 0 .. $/2]);
		mixin mixinAll!(mixins[$/2 .. $ ]);
	}
}
