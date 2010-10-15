/**
	original of this module is by rsinfu (http://gist.github.com/598659)
*/
module meta;

private import std.conv : to;
private import std.string;
private import std.traits;


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
template StringOf(T...)
{
	enum StringOf = T[0].stringof;
}


/**
	std.typetuple.staticLength ?
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


/**
 */
template isInstantiatedWith(alias A, alias T)
{
	static if (__traits(compiles, Identifier!A))
	{
		enum isInstantiatedWith = 
			chompPrefix(
				Identifier!A,
				"__T" ~ to!string(Identifier!T.length) ~ Identifier!T)
			!= Identifier!A;
	}
	else
	{
		enum isInstantiatedWith = false;
	}
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
//			static if (n >= Overloads.length)
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
	static if (name == "")
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
	static if (len2 == 0)
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


//----------------------------------------------------------------------------//
// Mixins
//----------------------------------------------------------------------------//

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


private @trusted
{
	bool isoctdigit(dchar c)
	{
		return '0'<=c && c<='7';
	}
	bool ishexdigit(dchar c)
	{
		return ('0'<=c && c<='9') || ('A'<=c && c<='F') || ('a'<=c && c<='f');
	}

	struct ParseResult
	{
		string result;
		string remain;
		
		bool opCast(T)() if (is(T==bool))
		{
			return result.length > 0;
		}
		
		this(string res, string rem)
		{
			result = res;
			remain = rem;
		}
		this(string rem)
		{
			result = null;
			remain = rem;
		}
	}

	ParseResult parseStr(string code)
	{
		auto remain = chompPrefix(code, `"`);
		if (remain.length < code.length)
		{
			size_t i = code.length - remain.length;
			auto result = code[0 .. i];
			for (; i<code.length; ++i)
			{
				auto pVar = parseVar(code[i..$]);
				if (pVar)
				{
					result ~= "`~"
							~ pVar.result[2..$-1]
							~ "~`";
					i += pVar.result.length;
				}
				
				if (code[i] == '\\')
				{
					result ~= code[i];
					++i;
				}
				else if (code[i] == '\"')
				{
					result ~= code[i];
					return ParseResult(result, code[i+1..$]);
				}
				result ~= code[i];
			}
		}
		return ParseResult(code);
	}

	ParseResult parseAltStr(string code)
	{
		auto remain = chompPrefix(code, "`");
		if (remain.length < code.length)
		{
			foreach (i; 0..remain.length)
			{
				if (remain[i] == '`')
				{
					return ParseResult(code[0..1+i+1], remain[i+1..$]);
				}
			}
		}
		return ParseResult(code);
	}

	ParseResult parseRawStr(string code)
	{
		auto remain = chompPrefix(code, `r"`);
		if (remain.length < code.length)
		{
			foreach (i; 0..remain.length)
			{
				if (remain[i] == '\"')
				{
					return ParseResult(code[0..2+i+1], remain[i+1..$]);
				}
			}
		}
		return ParseResult(code);
	}

	ParseResult parseVar(string code)
	{
		auto remain = chompPrefix(code, `${`);
		if (remain.length < code.length)
		{
			foreach (i; 0..remain.length)
			{
				if (remain[i] == '}')
				{
					return ParseResult(code[0..2+i+1], remain[i+1..$]);
				}
			}
		}
		return ParseResult(code);
	}

	string expandCode(string code)
	{
		auto remain = code;
		auto result = "";
		while (remain.length)
		{
			auto pStr    = parseStr(remain);
			auto pAltStr = parseAltStr(remain);
			auto pRawStr = parseRawStr(remain);
			auto pVar    = parseVar(remain);
			
			if (pStr)
			{
				result ~= pStr.result;
				remain  = pStr.remain;
			}
			else if (pAltStr)
			{
				result ~= "`~\"`\"~`"
						~ pAltStr.result[1..$-1]
						~ "`~\"`\"~`";
				remain  = pAltStr.remain;
			}
			else if (pRawStr)
			{
				result ~= pRawStr.result;
				remain  = pRawStr.remain;
			}
			else if (pVar)
			{
				result ~= "`~"
						~ pVar.result[2..$-1]
						~ "~`";
				remain  = pVar.remain;
			}
			else
			{
				result ~= remain[0];
				remain  = remain[1..$];
			}
		}
		return result;
	}
}
/**
	Expand expression in code string
	----
	enum string op = "+";
	static assert(expand!q{ 1 ${op} 2 } == q{ 1 + 2 });
	----
	
	Using both mixin expression, it is easy making parameterized code-blocks.
	----
	template DeclFunc(string name)
	{
		mixin(expand!q{
			int ${name}(int a){ return a; }
		});
	}
	----
	DeclFunc template generates specified name function.
 */
template expand(string code)
{
	enum expand = "`" ~ expandCode(code) ~ "`";
}


version(unittest)
{
	template ExpandTest(string op, string from)
	{
		enum ExpandTest = mixin(expand!from);
	}
	static assert(ExpandTest!("+", q{a ${op} b})     == q{a + b});
	static assert(ExpandTest!("+", q{`raw string`})  == q{`raw string`});
	static assert(ExpandTest!("+", q{"a ${op} b"})   == q{"a + b"});
	static assert(ExpandTest!("+", q{r"${op}"})      == q{r"${op}"});
	static assert(ExpandTest!("+", q{`${op}`})       == q{`${op}`});
	static assert(ExpandTest!("+", q{"\a"})          == q{"\a"});
	static assert(ExpandTest!("+", q{"\xA1"})        == q{"\xA1"});
	static assert(ExpandTest!("+", q{"\0"})          == q{"\0"});
	static assert(ExpandTest!("+", q{"\01"})         == q{"\01"});
	static assert(ExpandTest!("+", q{"\012"})        == q{"\012"});
	static assert(ExpandTest!("+", q{"\u0FFF"})      == q{"\u0FFF"});
	static assert(ExpandTest!("+", q{"\U00000FFF"})  == q{"\U00000FFF"});

	static assert(ExpandTest!("+", q{"\""})          == q{"\""});

	static assert(ExpandTest!("+", q{${op} ${op}})   == q{+ +});
	static assert(ExpandTest!("+", q{"${op} ${op}"}) == q{"+ +"});
}


//----------------------------------------------------------------------------//
// Traits
//----------------------------------------------------------------------------//


/**
	Specialized template for ParameterStorageClass
 */
template StringOf(ParameterStorageClass pstc)
{
	static if (pstc & ParameterStorageClass.SCOPE) enum StringOf = "scope ";
	static if (pstc & ParameterStorageClass.OUT  ) enum StringOf = "out ";
	static if (pstc & ParameterStorageClass.REF  ) enum StringOf = "ref ";
	static if (pstc & ParameterStorageClass.LAZY ) enum StringOf = "lazy ";
}


/// 
enum ParameterStorageClassSet : ParameterStorageClass
{
	NONE = ParameterStorageClass.NONE,	//dummy
}

private template StringOf_PStC(alias pstcs, size_t i)
{
	static if (pstcs == 0)
		enum StringOf_PStC = "";
	else static if (pstcs & (1<<i))
		enum StringOf_PStC =
			StringOf!(cast(ParameterStorageClass)(pstcs & (1<<i)))
			~ StringOf_PStC!(cast(ParameterStorageClassSet)(pstcs & ~(1<<i)), i+1);
	else
		enum StringOf_PStC =
			StringOf_PStC!(cast(ParameterStorageClassSet)(pstcs), i+1);
}
/**
	Specialized template for ParameterStorageClassSet
 */
template StringOf(ParameterStorageClassSet pstcs)
{
	alias StringOf_PStC!(pstcs, 0) StringOf;
}


/**
	Specialized template for FunctionAttribute
 */
template StringOf(FunctionAttribute attr)
{
	static if (attr == FunctionAttribute.PURE    ) enum StringOf = "pure ";
	static if (attr == FunctionAttribute.NOTHROW ) enum StringOf = "nothrow ";
	static if (attr == FunctionAttribute.REF     ) enum StringOf = "ref ";
	static if (attr == FunctionAttribute.PROPERTY) enum StringOf = "@property ";
	static if (attr == FunctionAttribute.TRUSTED ) enum StringOf = "@trusted ";
	static if (attr == FunctionAttribute.SAFE    ) enum StringOf = "@safe ";
}


/// 
enum FunctionAttributeSet : FunctionAttribute
{
	NONE = FunctionAttribute.NONE,	//dummy
}

private template StringOf_FAs(alias attrs, size_t i)
{
	static if (attrs == 0)
		enum StringOf_FAs = "";
	else static if (attrs & (1<<i))
		enum StringOf_FAs =
			StringOf!(cast(FunctionAttribute)(attrs & (1<<i)))
			~ StringOf_FAs!(cast(FunctionAttributeSet)(attrs & ~(1<<i)), i+1);
	else
		enum StringOf_FAs =
			StringOf_FAs!(cast(FunctionAttributeSet)(attrs), i+1);
}
/**
	Specialized template for FunctionAttributeSet
*/
template StringOf(FunctionAttributeSet attrs)
{
	alias StringOf_FAs!(attrs, 0) StringOf;
}


/**
 */
template ParameterInfo(alias Param)
{
	alias Identity!(Param.at!0) Type;
	
	enum ParameterStorageClassSet storageClass =
		cast(ParameterStorageClassSet)(Param.at!1);
	enum isScope = (storageClass & ParameterStorageClass.SCOPE) != 0;
	enum isOut   = (storageClass & ParameterStorageClass.OUT  ) != 0;
	enum isRef   = (storageClass & ParameterStorageClass.REF  ) != 0;
	enum isLazy  = (storageClass & ParameterStorageClass.LAZY ) != 0;
}


/**
 */
template FunctionInfo(alias F)
{
	alias .ReturnType!F ReturnType;
	
	alias staticMap!(
		ParameterInfo,
		staticZip!(
			Wrap!(ParameterTypeTuple!F),
			Wrap!(ParameterStorageClassTuple!F))) Parameters;
	
	enum FunctionAttributeSet attributes =
		cast(FunctionAttributeSet)(functionAttributes!F);
	enum isPure     = (attributes & FunctionAttribute.PURE    ) != 0;
	enum isNothrow  = (attributes & FunctionAttribute.NOTHROW ) != 0;
	enum isRef      = (attributes & FunctionAttribute.REF     ) != 0;
	enum isProperty = (attributes & FunctionAttribute.PROPERTY) != 0;
	enum isTrusted  = (attributes & FunctionAttribute.TRUSTED ) != 0;
	enum isSafe     = (attributes & FunctionAttribute.SAFE    ) != 0;
}
unittest
{
	alias ParameterStorageClass PStC;
	alias FunctionAttribute FA;

	void test(int, scope int, out int, ref int, lazy int) nothrow @safe { }
	alias FunctionInfo!test T;
	
	static assert(is(T.ReturnType == void));
	
	alias Identity!(T.Parameters[0]) P0;
	alias Identity!(T.Parameters[1]) P1;
	alias Identity!(T.Parameters[2]) P2;
	alias Identity!(T.Parameters[3]) P3;
	alias Identity!(T.Parameters[4]) P4;
	static assert(is(P0.Type == int));
	static assert(is(P1.Type == int));
	static assert(is(P2.Type == int));
	static assert(is(P3.Type == int));
	static assert(is(P4.Type == int));
	
	static assert(P0.storageClass == PStC.NONE);
	static assert(P1.storageClass == PStC.SCOPE);
	static assert(P2.storageClass == PStC.OUT);
	static assert(P3.storageClass == PStC.REF);
	static assert(P4.storageClass == PStC.LAZY);
	static assert(StringOf!(T.Parameters[0].storageClass) == "");
	static assert(StringOf!(T.Parameters[1].storageClass) == "scope ");
	static assert(StringOf!(T.Parameters[2].storageClass) == "out ");
	static assert(StringOf!(T.Parameters[3].storageClass) == "ref ");
	static assert(StringOf!(T.Parameters[4].storageClass) == "lazy ");
	
	static assert(T.attributes == (FA.SAFE | FA.NOTHROW));
	static assert(StringOf!(T.attributes) == "nothrow @safe ");
}


//----------------------------------------------------------------------------//
// Declarations
//----------------------------------------------------------------------------//

/**
 */
template Declare(T, string name, init...)
{
//	import std.traits : isSomeFunction, FunctionTypeOf;
//	
//	static if (isSomeFunction!T)
//	{
//		mixin DeclareFunction!(FunctionTypeOf!T, name, init);
//	}
//	else
//	{
		static if (init.length == 0)
		{
			mixin("T " ~ name ~ ";");
		}
		static if (init.length == 1)
		{
			mixin("T " ~ name ~ " = init[0];");
		}
//	}
}
/// ditto
template Declare(alias wrap)
{
	mixin Declare!(wrap.Expand);
}
unittest
{
	mixin Declare!(int, "a");
	assert(a == int.init);
	a = 10;
	
	mixin Declare!(double, "b", 10.0);
	assert(b == 10.0);
	b = 20.0;
	
	mixin Declare!(Wrap!(string, "c", "test"));
	assert(c == "test");
}


/**
 */
template DeclareFunction(T, string name, string code) if (isSomeFunction!T)
{
private:
	import std.traits, std.typetuple;
	
	alias FunctionTypeOf!T F;
	
	enum paramName = "a";
	template DeclareImpl(F)
	{
		template PrmSTC2Str(uint stc)
		{
			static if (stc == ParameterStorageClass.NONE)
			{
				enum PrmSTC2Str = "";
			}
			else static if (stc & ParameterStorageClass.SCOPE)
			{
				enum PrmSTC2Str = "scope "
					~ PrmSTC2Str!(stc & ~ParameterStorageClass.SCOPE);
			}
			else static if (stc & ParameterStorageClass.OUT)
			{
				enum PrmSTC2Str = "out "
					~ PrmSTC2Str!(stc & ~ParameterStorageClass.OUT);
			}
			else static if (stc & ParameterStorageClass.REF)
			{
				enum PrmSTC2Str = "ref "
					~ PrmSTC2Str!(stc & ~ParameterStorageClass.REF);
			}
			else static if (stc & ParameterStorageClass.LAZY)
			{
				enum PrmSTC2Str = "lazy "
					~ PrmSTC2Str!(stc & ~ParameterStorageClass.LAZY);
			}
		}
		static string PrmSTCs(int mode) @trusted
		{
			alias staticMap!(PrmSTC2Str, ParameterStorageClassTuple!F) pstcs;
			
			string result;
			foreach (i, stc ; pstcs)
			{
				if (i > 0)
					result ~= ", ";
				if (mode == 0)      // Parameter defines
				{
					result ~= pstcs[i]
						~ mixin(expand!q{
							ParameterTypeTuple!F[${to!string(i)}]
						}) ~ paramName ~ to!string(i);
				}
				else if (mode == 1) // Parameter names
				{
					result ~= paramName ~ to!string(i);
				}
			}
			return result;
		}
		
		static string FunSTCs()
		{
			string result;
			static if (is(F == shared))
			{
				result ~= "shared ";
			}
			static if (is(F == const))
			{
				result ~= "const ";
			}
			static if (is(F == immutable))
			{
				result ~= "immutable ";
			}
			return result;
		}
	}
	alias DeclareImpl!F Impl;

public:
	mixin(
		mixin(expand!
		q{
			ReturnType!F ${name}(${Impl.PrmSTCs(0)}) ${Impl.FunSTCs()} {
				alias TypeTuple!(${Impl.PrmSTCs(1)}) args;
				mixin(code);
			}
		})
	);
}


unittest
{
	static class C
	{
		alias int function(scope int, ref double) F;
		
		int value = 10;
		mixin DeclareFunction!(F, "f", q{ a1      *= 2; return value*2; });
		mixin DeclareFunction!(F, "g", q{ args[1] *= 3; return value*3; });
	}
	
	auto c = new C();
	double v = 1.0;
	assert(c.f(1, v) == 20);  assert(v == 2.0);
	assert(c.g(1, v) == 30);  assert(v == 6.0);
}
unittest
{
	static class C
	{
		int f()             { return 10; }
		int g() const       { return 20; }
		int h() shared      { return 30; }
		int i() shared const{ return 40; }
		int j() immutable   { return 50; }
		
		// for overload set
		mixin DeclareFunction!(typeof(f), "a1", q{ return f(); });  alias a1 a;
		mixin DeclareFunction!(typeof(g), "a2", q{ return g(); });  alias a2 a;
		mixin DeclareFunction!(typeof(h), "a3", q{ return h(); });  alias a3 a;
		mixin DeclareFunction!(typeof(i), "a4", q{ return i(); });  alias a4 a;
		mixin DeclareFunction!(typeof(j), "a5", q{ return j(); });  alias a5 a;
	}
	auto           c = new C();
	const         cc = new C();
	shared        sc = new shared(C)();
	shared const scc = new shared(const(C))();
	immutable     ic = new immutable(C)();
	assert(  c.a() == 10);
	assert( cc.a() == 20);
	assert( sc.a() == 30);
	assert(scc.a() == 40);
	assert( ic.a() == 50);
}
