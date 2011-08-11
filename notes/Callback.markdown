Aiko Callback Module
====================

    #include <AikoCallback.h>

This provides an easy way to pass around a reference to a function or method
to be called at a later time.

Function Callbacks
------------------

To create a function callback, do this:

    void myFunction() {
      // Do something.
    }

    Callback myCallback = functionCallback(myFunction);

Then, to invoke the callback and call the function:

    myCallBack();

Method Callbacks
----------------

To create a method callback, do this:

    call MyClass {
      public:
        void myMethod();
    };

    void MyClass::myMethod() {
      // Do something.
    }

    MyClass myObject;
    
    Callback myCallback = methodCallback(myObject, &MyClass::myMethod);

Invoke the callback the same way as for a function callback:

    myCallback();
