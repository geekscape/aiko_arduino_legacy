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
    setMillis(1);
    Events.loop();
    setMillis(1001);
    Events.loop();
    TS_ASSERT_EQUALS(handlerCallCount, 1);
  }

};
