#ifndef AikoSExpression_h
#define AikoSExpression_h

#include <string.h>

namespace Aiko {

  class SExpression {
  public:
    char* scan(char* head)                      { return SExpression::scan(head, head + strlen(head), this); }
    char* scan(char* head, unsigned int length) { return SExpression::scan(head, head+length, this); }
    char* scan(char* head, char* tail)          { return SExpression::scan(head, tail, this); }

    char* head() { return head_; }
    char* tail() { return tail_; }
    unsigned int size() { return tail_ - head_; }
    unsigned char isEqualTo(char* s);
    unsigned char isArray() { return isArray_; }

  protected:
    static char* scan          (char* head, char* tail, SExpression* expression);
    static char* scanRawString (char* head, char* tail, SExpression* expression);
    static char* scanArray     (char* head, char* tail, SExpression* expression);
    static char* skipWhitespace(char* head, char* tail);

    char *head_, *tail_;
    unsigned char isArray_;
  };

  class SExpressionArray : public SExpression {
  public:
    SExpressionArray(SExpression* expressions, unsigned char maxLength);
    SExpressionArray(unsigned char maxLength = 10);
    ~SExpressionArray();

    char* parse(char* head)                      { return parse(head, head + strlen(head), this); }
    char* parse(char* head, unsigned int length) { return parse(head, head + length, this); }
    char* parse(char* head, char* tail)          { return parse(head, tail, this); }
    char* parse(SExpression& expression)         { return parse(expression.head(), expression.tail(), this); }

    unsigned char length() { return length_; }
    SExpression& operator[](unsigned int i) { return expressions_[i]; }

    friend class SExpression;

  private:
    static char* parse(char* head, char* tail, SExpressionArray* array);

    unsigned char maxLength_;
    SExpression *expressions_;
    unsigned char isMalloced_;
    unsigned char length_;
  };

};

#endif
