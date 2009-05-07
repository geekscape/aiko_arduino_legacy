#ifndef AikoSexp_h
#define AikoSexp_h

#include <string.h>

namespace Aiko {

  class SexpToken {
  public:
    char* scan(char* head, char* tail) { return SexpToken::scan(head, tail, this); }
    
    char* head() { return head_; }
    char* tail() { return tail_; }
    unsigned int length() { return tail_ - head_; }
    unsigned char isEqualTo(char* s) { return length() == strlen(s) && strncmp(s, head_, length()) == 0; }
    unsigned char isArray() { return isArray_; }
    
    friend class SexpArray;
    
  private:
    static char* scan(char* head, char* tail, SexpToken* token);
    static char* scanRawString(char* head, char* tail, SexpToken* token);
    static char* scanArray    (char* head, char* tail, SexpToken* token);

    char *head_, *tail_;
    unsigned char isArray_;
  };
  
  class SexpArray : SexpToken {
  public:
    char* parse(char* head)                      { return SexpArray::parse(head, head + strlen(head), this); }
    char* parse(char* head, unsigned int length) { return SexpArray::parse(head, head + length, this); }
    char* parse(char* head, char* tail)          { return SexpArray::parse(head, tail, this); }
    char* parse(SexpToken& token)                { return SexpArray::parse(token.head_, token.tail_, this); }
    
    unsigned char tokenCount() { return tokenCount_; }
    SexpToken& operator[](unsigned int i) { return tokens_[i]; }
    
    friend class SexpToken;

  private:
    static char* parse(char* head, char* tail, SexpArray* array);
    static char* skipWhitespace(char* s, char* tail);

    unsigned char tokenCount_;
    SexpToken tokens_[12];
  };

};

#endif
