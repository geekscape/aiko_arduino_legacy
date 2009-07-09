TEST_SOURCES = AikoEvents.cpp AikoSExpression.cpp AikoTiming.cpp
STUB_SOURCES = tests/stubs/avr/interrupt.cpp tests/stubs/wiring.cpp

test:
	python tests/cxxtest/cxxtestgen.py --error-printer -o tests/runner.cpp tests/*.h
	g++ -g -o tests/runner tests/runner.cpp $(STUB_SOURCES) $(TEST_SOURCES) -I. -Itests/cxxtest -Itests/stubs
	./tests/runner
	
clean:
	rm -f *.o tests/*.o tests/runner.cpp tests/runner
	rm -rf applet
