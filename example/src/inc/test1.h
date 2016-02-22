
class Inline{
  public:
  void foo(bool x){
    if(x){ std::cout << "x";}
    else{ std::cout << "z";}
  }
  template <typename X>
  X bar (X x) { return x +1;}
};

