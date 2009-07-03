#include "AikoSExpression.h"
#include <stdlib.h>

namespace Aiko {

  char* SExpression::scan(char* head, char* tail, SExpression* expression) {
    if (expression) expression->head_ = expression->tail_ = 0;
    char* s = skipWhitespace(head, tail);
    if (s < tail) {
      switch(*s) {
        case '(':
          s = scanArray(s, tail, expression);
          break;
        default:
          s = scanRawString(s, tail, expression);
          break;
      }
      s = skipWhitespace(s, tail);
    }
    return s;
  }

  unsigned char SExpression::isEqualTo(char* s) {
    return size() == strlen(s) && strncmp(s, head_, size()) == 0;
  }
  
  char* SExpression::scanRawString(char* head, char* tail, SExpression* expression) {
    char* s;
    for (s = head; s < tail && *s != ' ' && *s != ')'; s++);
    if (expression) {
      expression->head_ = head;
      expression->tail_ = s;
      expression->isArray_ = false;
    }
    return s;
  }
  
  char* SExpression::scanArray(char* head, char* tail, SExpression* expression) {
    char* s = SExpressionArray::parse(head, tail, 0);
    if (expression) {
      expression->head_ = head;
      expression->tail_ = s;
      expression->isArray_ = true;
    }
    return s;
  }
  
  char* SExpression::skipWhitespace(char* head, char* tail) {
    while (head < tail && *head == ' ') head++;
    return head;
  }

  SExpressionArray::SExpressionArray(SExpression* expressions, unsigned char maxLength) {
    maxLength_   = maxLength;
    expressions_ = expressions;
    isMalloced_  = false;
  }
    
  SExpressionArray::SExpressionArray(unsigned char maxLength) {
    maxLength_   = maxLength;
    expressions_ = static_cast<SExpression*>(calloc(maxLength_, sizeof(SExpression)));
    isMalloced_  = true;
  }
  
  SExpressionArray::~SExpressionArray() {
    if (isMalloced_) free(expressions_);
  }
  
  char* SExpressionArray::parse(char* head, char* tail, SExpressionArray* array) {
    char* s = skipWhitespace(head, tail);
    if (array) array->head_ = s;
    if (s < tail && *s == '(') {
      s++;
  
      if(array) array->length_ = 0;
      while (s < tail && *s != ')') {
        SExpression* expression = array ? &(array->expressions_[array->length_++]) : 0;
        s = SExpression::scan(s, tail, expression);
      }
  
      if (s < tail && *s == ')') {
        if (array) array->tail_ = s;
        s = skipWhitespace(++s, tail);
        return s;
      }
    }
    return 0;
  }

};
