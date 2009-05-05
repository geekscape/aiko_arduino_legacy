#include "aiko/string.h"

namespace Aiko {
    
    unsigned int strlen(char* s) {
        unsigned int i;
        for (i = 0; s[i] != 0; i++);
        return i;
    }
    
    char strncmp(char* a, char* b, n) {
        unsigned int i;
        while (a[i] != 0 && b[i] != 0 && i < n) {
            char d = a[i] - b[i];
            
        }
        return 0;
    }
    
};
