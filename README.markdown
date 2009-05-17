Aiko: Arduino Framework
=======================

A small modular, event-driven framework for structuring Arduino
sketches, such that individual device drivers can be easily
componentized and combined into a single application.

Aiko allows you to write event-driven code:

    #include <AikoEvents.h>
    using namespace Aiko;

    int ledPin = 13;
    boolean status = LOW;

    void setup() {
      pinMode(ledPin, OUTPUT);
      Events.registerHandler(1000, blink);  // Every 1,000 ms
    }

    void loop() {
      Events.loop();
    }

    void blink() {
      digitalWrite(ledPin, status);
      status = ! status;
    }

By writing individual device drivers as event-driven functions, means that
it is simpler to create device specific modules that can be shared with
others and easier to then integrate them (with less code changes).

Installation
============

FAQ
===

Credits
=======
Written by Andy Gelme and Pete Yandell.

Copyright (C) 2009 by Geekscape Pty. Ltd.
Copyright (C) 2009 by Pete Yandel.
Released under the GPLv3 license (dual-licensed).
