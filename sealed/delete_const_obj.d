class C
{
}

void main()
{
	const c = new C();
	delete c;	//通ってしまう
	assert(c is null);
}
