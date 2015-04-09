#include <iostream>
#include <basetools.h>


namespace BaseWrappers
{
	void TestBaseTools()
	{
		BaseTools::TestFunction1();
		BaseTools::TestFunction2();
		std::cout << "TestBaseTools (basewrappers.cpp): Success\n";
	}
}

