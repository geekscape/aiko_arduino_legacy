#include <cxxtest/TestSuite.h>
#include <wiring.h>
#include <AikoEvents.h>

using namespace Aiko;

class EventHandlerListTests : public CxxTest::TestSuite {
public:
  void setUp() {
    list_.flush();
    list_.add(&handler1_);
    list_.add(&handler2_);
    list_.add(&handler3_);
  }

  void test_should_iterate_over_all_items_added_in_order() {
    list_.resetIterator();
    TS_ASSERT_EQUALS(list_.next(), &handler1_);
    TS_ASSERT_EQUALS(list_.next(), &handler2_);
    TS_ASSERT_EQUALS(list_.next(), &handler3_);
    TS_ASSERT_EQUALS(list_.next(), (EventHandler*)0);
    TS_ASSERT_EQUALS(list_.next(), (EventHandler*)0);
  }

  void test_should_reset_the_iterator() {
    list_.resetIterator();
    TS_ASSERT_EQUALS(list_.next(), &handler1_);
    TS_ASSERT_EQUALS(list_.next(), &handler2_);
    list_.resetIterator();
    TS_ASSERT_EQUALS(list_.next(), &handler1_);
  }

  void test_should_iterate_correctly_when_the_current_item_is_removed() {
    list_.resetIterator();
    TS_ASSERT_EQUALS(list_.next(), &handler1_);
    TS_ASSERT_EQUALS(list_.next(), &handler2_);
    list_.remove(&handler2_);
    TS_ASSERT_EQUALS(list_.next(), &handler3_);
    TS_ASSERT_EQUALS(list_.next(), (EventHandler*)0);
  }

  void test_should_iterate_correctly_when_the_next_item_is_removed() {
    list_.resetIterator();
    TS_ASSERT_EQUALS(list_.next(), &handler1_);
    list_.remove(&handler2_);
    TS_ASSERT_EQUALS(list_.next(), &handler3_);
    TS_ASSERT_EQUALS(list_.next(), (EventHandler*)0);
  }

  void test_should_iterate_correctly_when_an_item_is_added_after_the_current_item() {
    EventHandler handler4;
    list_.resetIterator();
    TS_ASSERT_EQUALS(list_.next(), &handler1_);
    TS_ASSERT_EQUALS(list_.next(), &handler2_);
    TS_ASSERT_EQUALS(list_.next(), &handler3_);
    list_.add(&handler4);
    TS_ASSERT_EQUALS(list_.next(), &handler4);
    TS_ASSERT_EQUALS(list_.next(), (EventHandler*)0);
  }

private:
  EventHandler handler1_, handler2_, handler3_;
  EventHandlerList list_;
};

