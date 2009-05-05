#ifndef AIKO_SEXP
#define AIKO_SEXP

namespace Aiko {

  struct Atom {
    char *firstByte_, *lastByte_;
    
    char* scan(char* s, char* lastByte);
    inline unsigned int length() { return lastByte_ - firstByte_; }
    unsigned char isEqual(char* s);
  };
  
  class Sexp {
  public:
    char* parse(char* firstByte, char* lastByte);
    
    unsigned char length() { return atomCount_; }
  
    char* skipWhitespace(char* s);
    
    char *firstByte_, *lastByte_;
    unsigned char atomCount_;
    struct Atom atoms_[12];
  };

};

#endif
