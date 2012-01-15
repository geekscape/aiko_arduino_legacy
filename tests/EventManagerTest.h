#include <cxxtest/TestSuite.h>
#include <Arduino.h>
#include <AikoEvents.h>

using namespace Aiko;

static int handlerCallCount = 0;
static void testHandler() {
  handlerCallCount++;
}

class EventManagerTests : public CxxTest::TestSuite {
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

  void test_should_call_a_one_shot_handler_just_once() {
    Events.addOneShotHandler(testHandler, 1000);
    Events.loop(0);
    TS_ASSERT_EQUALS(handlerCallCount, 0);
    Events.loop(1000);
    TS_ASSERT_EQUALS(handlerCallCount, 1);
    Events.loop(2000);
    TS_ASSERT_EQUALS(handlerCallCount, 1);
  }

};
