test:
	python tests/cxxtest/cxxtestgen.py --error-printer -o tests/runner.cpp tests/*.h
	g++ -g -o tests/runner tests/runner.cpp tests/stubs/*.cpp tests/stubs/**/*.cpp *.cpp -I. -Itests/cxxtest -Itests/stubs
	./tests/runner
	
clean:
	rm -f *.o tests/*.o tests/runner.cpp tests/runner
	rm -rf applet
