#include <string>
#include <iostream>
#include "test1.h"
#include <vector>
#include <cassert>

const int MAXARGS = 4;


void lafonction(){
 std::cout <<"lafonction\n";
 int x = 1;
 int y = x +1;
  Inline xyz;
  xyz.foo(true);

  unsigned int w =4;
  w = xyz.bar(w);
}
void lautrefonction();
void otherGetName(std::string& rpcTestNames);


void getName(std::string& testNames) {
	size_t lineEnd = testNames.find_first_of("S", 0);
	if (lineEnd != std::string::npos){
		std::cout << ".";
	}
}


int main( int argc, char* argv[] ) {
  std::string rpcTestNames = "Arm2 Dewarp VGA Single Bilinear Pad-0v0 ";
// get the arguments and store in vector:
assert( argc <= MAXARGS );
assert( argc > 1 );
std::vector<std::string> args( MAXARGS );
for (int i = 0; i < argc; i++) {
  std::string s( argv[i] );
  args[i] = s;
}
/* iterates over
the arguments and tries to establish ?pair-wise
equality? or some such notion. The details are
not really relevant, but you can see that it checks
a pair of arguments first, printing a message if
they are equal. If they are not equal, it checks
for the string ?Hey!? instead and prints a differ-
*/
std::cout << "argc " << argc <<"\n";
for (int i = 1; i <= argc-1; i++) {
  std::cout << "args[i] = \""<<args[i]<<"\"\n";
  if (args[i] == args[i+1]) {
    std::cout << "Two consecutive args are identical!" << std::endl;
    getName(rpcTestNames);
    getName(rpcTestNames);
    getName(rpcTestNames);
    getName(rpcTestNames);
    lafonction();
  }
  else if ( args[i] == "XYZ" ) {
    std::cout << "One of the args is XYZ!" << std::endl;
    lautrefonction();
    otherGetName(rpcTestNames);
  }
  else {
    std::cout << "Args are different!" << std::endl;
    getName(rpcTestNames);
  }
}
return 0;
}



