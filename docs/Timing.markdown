Aiko Events Module
==================

    #include <AikoTiming.h>

The Timing module provides more precise timing than the standard Arduino
timing functions. The regular millis() function has jitter > 1ms, whereas
the Timing::millis() method has jitter of roughly a few microseconds.

### Effect on PWM

Methods
-------

Timing::setup()

Timing::millis()

