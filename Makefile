test:
	python tests/cxxtest/cxxtestgen.py --error-printer -o tests/runner.cpp tests/*.h
	g++ -o tests/runner tests/runner.cpp *.cpp -I. -Itests/cxxtest
	./tests/runner
	
clean:
	rm -f *.o tests/*.o tests/runner.cpp tests/runner
