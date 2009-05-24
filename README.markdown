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
      Events.addHandler(blink, 1000);  // Every 1,000 ms
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

Change into your Arduino libraries folder and use git to clone the project.

On a Mac this looks like:

    cd /Applications/arduino-0015/hardware/libraries
    git clone git://github.com/geekscape/Aiko.git

On Linux, this will directory will be wherever you install your Arduino
software.


Components
==========


Community
=========

Report bugs at http://github.com/geekscape/Aiko/issues


Written by Andy Gelme and Pete Yandell.

Copyright (C) 2009 by Geekscape Pty. Ltd.
Copyright (C) 2009 by Pete Yandell.
Released under the GPLv3 license (dual-licensed).
