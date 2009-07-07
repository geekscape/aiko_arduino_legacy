#include <cxxtest/TestSuite.h>
#include <AikoCallback.h>

using namespace Aiko;

static int functionCallbackCount;
static void function() { functionCallbackCount++; }

class CallbackTests : public CxxTest::TestSuite {
public:
  void test_function_callback() {
    functionCallbackCount = 0;
    Callback callback = functionCallback(function);
    callback();
    TS_ASSERT_EQUALS(functionCallbackCount, 1);
  }

  class Receiver {
    public:
      Receiver() : methodCallbackCount_(0) { }
      void method() { methodCallbackCount_++; }
      int methodCallbackCount() { return methodCallbackCount_; }

    private:
      int methodCallbackCount_;
  };

  void test_method_callback() {
    Receiver receiver;
    Callback callback = methodCallback(receiver, &Receiver::method);
    callback();
    TS_ASSERT_EQUALS(receiver.methodCallbackCount(), 1);
  }

};
