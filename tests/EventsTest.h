#include <cxxtest/TestSuite.h>
#include <wiring.h>
#include <AikoEvents.h>

using namespace Aiko;

int handlerCallCount = 0;
void testHandler() {
  handlerCallCount++;
}

class EventsTests : public CxxTest::TestSuite {
public:
  void setUp() {
    handlerCallCount = 0;
    Events.reset();
  }

  void test_should_call_our_handler_at_regular_intervals() {
    Events.addHandler(testHandler, 1000);
    for (int i = 0; i < 5; i++) {
      Events.loop(i * 1000);
      TS_ASSERT_EQUALS(handlerCallCount, i + 1);
    }
  }

};
