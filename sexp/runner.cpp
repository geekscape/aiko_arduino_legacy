/* Generated file, do not edit */

#ifndef CXXTEST_RUNNING
#define CXXTEST_RUNNING
#endif

#define _CXXTEST_HAVE_STD
#include <cxxtest/TestListener.h>
#include <cxxtest/TestTracker.h>
#include <cxxtest/TestRunner.h>
#include <cxxtest/RealDescriptions.h>
#include <cxxtest/ErrorPrinter.h>

int main() {
 return CxxTest::ErrorPrinter().run();
}
#include "sexp_test.h"

static SexpTest suite_SexpTest;

static CxxTest::List Tests_SexpTest = { 0, 0 };
CxxTest::StaticSuiteDescription suiteDescription_SexpTest( "sexp_test.h", 24, "SexpTest", suite_SexpTest, Tests_SexpTest );

static class TestDescription_SexpTest_test_should_parse_an_expression_with_multiple_atoms : public CxxTest::RealTestDescription {
public:
 TestDescription_SexpTest_test_should_parse_an_expression_with_multiple_atoms() : CxxTest::RealTestDescription( Tests_SexpTest, suiteDescription_SexpTest, 30, "test_should_parse_an_expression_with_multiple_atoms" ) {}
 void runTest() { suite_SexpTest.test_should_parse_an_expression_with_multiple_atoms(); }
} testDescription_SexpTest_test_should_parse_an_expression_with_multiple_atoms;

static class TestDescription_SexpTest_test_should_scan_atom_terminated_by_end_of_string : public CxxTest::RealTestDescription {
public:
 TestDescription_SexpTest_test_should_scan_atom_terminated_by_end_of_string() : CxxTest::RealTestDescription( Tests_SexpTest, suiteDescription_SexpTest, 42, "test_should_scan_atom_terminated_by_end_of_string" ) {}
 void runTest() { suite_SexpTest.test_should_scan_atom_terminated_by_end_of_string(); }
} testDescription_SexpTest_test_should_scan_atom_terminated_by_end_of_string;

static class TestDescription_SexpTest_test_should_scan_atom_terminated_by_space : public CxxTest::RealTestDescription {
public:
 TestDescription_SexpTest_test_should_scan_atom_terminated_by_space() : CxxTest::RealTestDescription( Tests_SexpTest, suiteDescription_SexpTest, 53, "test_should_scan_atom_terminated_by_space" ) {}
 void runTest() { suite_SexpTest.test_should_scan_atom_terminated_by_space(); }
} testDescription_SexpTest_test_should_scan_atom_terminated_by_space;

static class TestDescription_SexpTest_test_should_scan_atom_terminated_by_bracket : public CxxTest::RealTestDescription {
public:
 TestDescription_SexpTest_test_should_scan_atom_terminated_by_bracket() : CxxTest::RealTestDescription( Tests_SexpTest, suiteDescription_SexpTest, 64, "test_should_scan_atom_terminated_by_bracket" ) {}
 void runTest() { suite_SexpTest.test_should_scan_atom_terminated_by_bracket(); }
} testDescription_SexpTest_test_should_scan_atom_terminated_by_bracket;

#include <cxxtest/Root.cpp>
