#include <cxxtest/TestSuite.h>
#include <AikoSExpression.h>

using namespace Aiko;

/*
  SExpressionArray
    should fail gracefully with no closing bracket
    should fail gracefully with extra closing brackets
    should fail gracefully when we overflow the atom buffer
*/

class SExpressionTests : public CxxTest::TestSuite {
public:
  /* SExpression tests */

  void test_expression_should_scan_a_token_terminated_by_end_of_string() {
    char *a = "testing";
    char *b = a + strlen(a);

    SExpression expression;
    char *s = expression.scan(a, b);
    TS_ASSERT_EQUALS(expression.head(), a);
    TS_ASSERT_EQUALS(expression.tail(), b);
    TS_ASSERT_EQUALS(s, b);
  }

  void test_expression_should_scan_atom_terminated_by_space() {
    char *a = "testing ";
    char *b = a + strlen(a);

    SExpression expression;
    char *s = expression.scan(a, b);
    TS_ASSERT_EQUALS(expression.head(), a);
    TS_ASSERT_EQUALS(expression.tail(), b-1);
    TS_ASSERT_EQUALS(s, b);
  }

  void test_should_scan_atom_terminated_by_bracket() {
    char *a = "testing)";
    char *b = a + strlen(a);

    SExpression expression;
    char *s = expression.scan(a, b);
    TS_ASSERT_EQUALS(expression.head(), a);
    TS_ASSERT_EQUALS(expression.tail(), b-1);
    TS_ASSERT_EQUALS(s, b-1);
  }

  void test_should_scan_whitespace() {
    char *a = "   ";
    char *b = a + strlen(a);

    SExpression expression;
    char *s = expression.scan(a, b);
    TS_ASSERT(expression.head() == (char*)0);
    TS_ASSERT(expression.tail() == (char*)0);
    TS_ASSERT_EQUALS(s, b);
  }

  /* SExpressionArray tests */

  void test_array_should_parse_an_empty_expression() {
    char *a = "()";
    SExpressionArray array;
    char* s = array.parse(a);
    TS_ASSERT_EQUALS(array.length(), 0);
    TS_ASSERT_EQUALS(s, a + strlen(a));
  }

  void test_array_should_parse_an_expression_with_a_single_atom() {
    char* a = "(test)";
    SExpressionArray array;
    char* s = array.parse(a);
    TS_ASSERT_EQUALS(array.length(), 1);
    TS_ASSERT_EQUALS(s, a + strlen(a));
  }

  void test_array_should_parse_an_expression_with_multiple_atoms() {
    char *a = "(the quick brown fox)";
    SExpressionArray array;
    char* s = array.parse(a);
    TS_ASSERT_EQUALS(array.length(), 4);
    TS_ASSERT(array[0].isEqualTo("the"));
    TS_ASSERT(array[1].isEqualTo("quick"));
    TS_ASSERT(array[2].isEqualTo("brown"));
    TS_ASSERT(array[3].isEqualTo("fox"));
  }

  void test_array_should_parse_nested_expressions() {
    char *a = "(the (quick brown) fox)";

    SExpressionArray array;
    array.parse(a);
    TS_ASSERT_EQUALS(array.length(), 3);
    TS_ASSERT(array[0].isEqualTo("the"));
    TS_ASSERT(array[1].isArray());
    TS_ASSERT(array[2].isEqualTo("fox"));

    SExpressionArray subArray;
    subArray.parse(array[1]);
    TS_ASSERT_EQUALS(subArray.length(), 2);
    TS_ASSERT(subArray[0].isEqualTo("quick"));
    TS_ASSERT(subArray[1].isEqualTo("brown"));
  }

  void test_array_should_ignore_space_after_opening_brackets() {
    char* a = "( test)";
    SExpressionArray array;
    char* s = array.parse(a);
    TS_ASSERT_EQUALS(array.length(), 1);
    TS_ASSERT(array[0].isEqualTo("test"));
    TS_ASSERT_EQUALS(s, a + strlen(a));
  }

  void test_array_should_ignore_space_before_closing_brackets() {
    char* a = "(test )";
    SExpressionArray array;
    char* s = array.parse(a);
    TS_ASSERT_EQUALS(array.length(), 1);
    TS_ASSERT(array[0].isEqualTo("test"));
    TS_ASSERT_EQUALS(s, a + strlen(a));
  }
};

