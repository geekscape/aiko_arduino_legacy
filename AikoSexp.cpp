#include "AikoSexp.h"
#include <stdlib.h>

namespace Aiko {

  char* SexpToken::scan(char* head, char* tail, SexpToken* token) {
    char* s;
    switch(*head) {
      case '(':
        s = scanArray(head, tail, token);
        break;
      default:
        s = scanRawString(head, tail, token);
        break;
    }
    return s;
  }
  
  char* SexpToken::scanRawString(char* head, char* tail, SexpToken* token) {
    char* s;
    for (s = head; s < tail && *s != ' ' && *s != ')'; s++);
    if (token) {
      token->head_ = head;
      token->tail_ = s;
      token->isArray_ = false;
    }
    return s;
  }
  
  char* SexpToken::scanArray(char* head, char* tail, SexpToken* token) {
    char* s = SexpArray::parse(head, tail, 0);
    if (token) {
      token->head_ = head;
      token->tail_ = s;
      token->isArray_ = true;
    }
    return s;
  }

  SexpArray::SexpArray(unsigned char tokenBufferLength) {
    tokenBufferLength_ = tokenBufferLength;
    tokens_ = static_cast<SexpToken*>(calloc(tokenBufferLength, sizeof(SexpToken)));
    isMalloced_ = true;
  }
  
  SexpArray::SexpArray(SexpToken* tokenBuffer, unsigned char tokenBufferLength) {
    tokenBufferLength_ = tokenBufferLength;
    tokens_ = tokenBuffer;
    isMalloced_ = false;
  }
    
  SexpArray::~SexpArray() {
    if (isMalloced_) free(tokens_);
  }
  
  char* SexpArray::parse(char* head, char* tail, SexpArray* array) {
    if (array) {
      array->head_ = head;
      array->tail_ = tail;
    }
    
    char* s = skipWhitespace(head, tail);
    if (s < tail && *s == '(') {
      s++;
      s = skipWhitespace(s, tail);
  
      if(array) array->tokenCount_ = 0;
      while (s < tail && *s != ')') {
        SexpToken* token = 0;
        if (array) token = &(array->tokens_[array->tokenCount_++]);
        s = SexpToken::scan(s, tail, token);
        s = skipWhitespace(s, tail);
      }
  
      if (s < tail && *s == ')') {
        s++;
        return s;
      }
    }
    return 0;
  }
  
  char* SexpArray::skipWhitespace(char* s, char* tail) {
    while (s < tail && *s == ' ') s++;
    return s;
  }
  
};
