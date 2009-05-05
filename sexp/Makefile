
test:
	python cxxtest/cxxtestgen.py --error-printer -o runner.cpp sexp_test.h
	g++ -o runner runner.cpp sexp.cc -Icxxtest
	./runner

	