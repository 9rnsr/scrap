class C
{
}

void main()
{
	const c = new C();
	delete c;	//’Ê‚Á‚Ä‚µ‚Ü‚¤
	assert(c is null);
}
