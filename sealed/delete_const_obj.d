class C
{
}

void main()
{
	const c = new C();
	delete c;	//�ʂ��Ă��܂�
	assert(c is null);
}
