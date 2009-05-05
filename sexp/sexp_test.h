#include <cxxtest/TestSuite.h>

#include "sexp.h"

using namespace Aiko;


/*
  Atom
    should parse an unquoted string terminated by a space
    should parse an unquoted string terminated by a close bracket
    
  Sexp
    should parse an empty expression
    should parse an expression with a single atom
    should parse an expression with multiple atoms
    should fail gracefully with no closing bracket
    should fail gracefully with extra closing brackets
    should fail gracefully when we overflow the atom buffer
*/



class SexpTest : public CxxTest::TestSuite 
{
public:
    
    /* Sexp tests */
    
    void test_should_parse_an_expression_with_multiple_atoms() {
        char *a = "(the quick brown fox)";
        char *b = a + strlen(a);
        
        Sexp sexp;
        char* s = sexp.parse(a, b);
        TS_ASSERT_EQUALS(sexp.length(), 4);
        TS_ASSERT_EQUALS(strncmp("the", sexp.atoms_[0].firstByte_, sexp.atoms_[0].length()), 0);
    }
    
    /* Atom tests */
    
    void test_should_scan_atom_terminated_by_end_of_string() {
        char *a = "testing";
        char *b = a + strlen(a);

        Atom atom;        
        char *s = atom.scan(a, b);
        TS_ASSERT_EQUALS(atom.firstByte_, a);
        TS_ASSERT_EQUALS(atom.lastByte_,  b);
        TS_ASSERT_EQUALS(s, b);
    }
    
    void test_should_scan_atom_terminated_by_space() {
        char *a = "testing ";
        char *b = a + strlen(a);
        
        Atom atom;
        char *s = atom.scan(a, b);
        TS_ASSERT_EQUALS(atom.firstByte_, a);
        TS_ASSERT_EQUALS(atom.lastByte_,  b-1);
        TS_ASSERT_EQUALS(s, b-1);
    }
    
    void test_should_scan_atom_terminated_by_bracket() {
        char *a = "testing)";
        char *b = a + strlen(a);
        
        Atom atom;
        char *s = atom.scan(a, b);
        TS_ASSERT_EQUALS(atom.firstByte_, a);
        TS_ASSERT_EQUALS(atom.lastByte_,  b-1);
        TS_ASSERT_EQUALS(s, b-1);
    }
};

