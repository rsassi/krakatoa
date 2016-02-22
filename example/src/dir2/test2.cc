#include <string>
#include <iostream>
#include "test1.h"


void lautrefonction(){
 std::cout << "etlautre\n";
 int x = 1;
 int y = x +1;
  Inline xyz;
  xyz.foo(false);
//  signed long long w =9;
//  w = xyz.bar(w);
}

void otherGetName(std::string& testNames) {
	size_t lineEnd = testNames.find_first_of("W", 0);
	if (lineEnd != std::string::npos){
		std::cout << "o";
	}
}

