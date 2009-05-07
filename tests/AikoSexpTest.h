#include <cxxtest/TestSuite.h>
#include <AikoSexp.h>

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
    should deal with whitespace after open brackets, before close brackets, etc.
*/



class SexpTest : public CxxTest::TestSuite 
{
public:
    
    /* SexpArray tests */
    
    void test_sexp_array_should_parse_an_expression_with_multiple_atoms() {
        char *a = "(the quick brown fox)";
        char *b = a + strlen(a);
        
        SexpArray array;
        char* s = array.parse(a, b);
        TS_ASSERT_EQUALS(array.tokenCount(), 4);
        TS_ASSERT(array[0].isEqualTo("the"));
        TS_ASSERT(array[1].isEqualTo("quick"));
        TS_ASSERT(array[2].isEqualTo("brown"));
        TS_ASSERT(array[3].isEqualTo("fox"));
    }
    
    
    void test_sexp_array_should_parse_nested_expressions() {
        char *a = "(the (quick brown) fox)";
        
        SexpArray array;
        array.parse(a);
        TS_ASSERT_EQUALS(array.tokenCount(), 3);
        TS_ASSERT(array[0].isEqualTo("the"));
        TS_ASSERT(array[1].isArray());
        TS_ASSERT(array[2].isEqualTo("fox"));
        
        SexpArray subArray;
        subArray.parse(array[1]);
        TS_ASSERT_EQUALS(subArray.tokenCount(), 2);
        TS_ASSERT(subArray[0].isEqualTo("quick"));
        TS_ASSERT(subArray[1].isEqualTo("brown"));
    }
    
    
    /* SexpToken tests */
    
    void test_sexp_token_should_scan_a_token_terminated_by_end_of_string() {
        char *a = "testing";
        char *b = a + strlen(a);

        SexpToken token;        
        char *s = token.scan(a, b);
        TS_ASSERT_EQUALS(token.head(), a);
        TS_ASSERT_EQUALS(token.tail(), b);
        TS_ASSERT_EQUALS(s, b);
    }
  
    
    /*
    // void test_should_scan_atom_terminated_by_space() {
        char *a = "testing ";
        char *b = a + strlen(a);
        
        SexpAtom atom;
        char *s = atom.scan(a, b);
        TS_ASSERT_EQUALS(atom.head_, a);
        TS_ASSERT_EQUALS(atom.tail_,  b-1);
        TS_ASSERT_EQUALS(s, b-1);
    }
    
    // void test_should_scan_atom_terminated_by_bracket() {
        char *a = "testing)";
        char *b = a + strlen(a);
        
        SexpAtom atom;
        char *s = atom.scan(a, b);
        TS_ASSERT_EQUALS(atom.head_, a);
        TS_ASSERT_EQUALS(atom.tail_,  b-1);
        TS_ASSERT_EQUALS(s, b-1);
    }
    */
};

