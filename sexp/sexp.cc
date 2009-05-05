#include "sexp.h"
#include <stdlib.h>

namespace Aiko {

    char* Atom::scan(char* s, char* lastByte) {
        firstByte_ = s;
        while (s < lastByte && *s != ' ' && *s != ')') s++;
        lastByte_ = s;
        return s;
    }
  
    char* Sexp::parse(char* firstByte, char* lastByte) {
        firstByte_ = firstByte;
        lastByte_  = lastByte;
        
        char* s = skipWhitespace(firstByte_);
        if (s < lastByte && *s == '(') {
            s++;
            s = skipWhitespace(s);
        
            atomCount_ = 0;
            while (s < lastByte_ && *s != ')') {
                s = atoms_[atomCount_++].scan(s, lastByte_);
                s = skipWhitespace(s);
            }
        
            if (s < lastByte && *s == ')') {
                s++;
                return s;
            }
        }
        return 0;
    }
    
    char* Sexp::skipWhitespace(char* s) {
        while (s < lastByte_ && *s == ' ') s++;
        return s;
    }
  
};







// Rename lastByte to indicate last byte + 1
// Differentiate between last byte of string and last byte of atom
// Move Atom somewhere useful (inside SExp)
