Aiko: Arduino Framework
=======================

A small modular, event-driven framework for structuring Arduino
sketches, such that individual device drivers can be easily
componentized and combined into a single application.

Aiko allows you to write event-driven code:

    #include <AikoEvents.h>
    using namespace Aiko;

    int ledPin = 13;

    void setup() {
      pinMode(ledPin, OUTPUT);
      Events.addHandler(blink, 1000);  // Every 1000 ms
    }

    void loop() {
      Events.loop();
    }

    void blink() {
      digitalWrite(ledPin, !digitalRead(ledPin));
    }

Writing individual device drivers as event-driven functions makes it
simpler to create device specific modules that can be shared with others
and easier to then combine and integrate them with less code changes.


Installation
============

Change into your Arduino libraries folder and use git to clone the project.

On a Mac this looks like:

    cd /Applications/arduino-0015/hardware/libraries
    git clone git://github.com/geekscape/Aiko.git

On Linux, this will directory will be wherever you install your Arduino
software.

Alternatively you can download a tarball or ZIP archive from the Aiko
repository by clicking the "download" link at:

    http://github.com/geekscape/Aiko/tree/master


Modules
=======

- **Events** - Schedule regular callbacks so you can easily deal with
  a bunch of devices connected to your Arduino.
- **SExpression** - Parse simple SExpressions. Think of this as the
  Arduino equivalent of JSON.

See the corresponding files in the docs directory for more info on each module.


Community
=========

Report bugs on our [GitHub bug tracker](http://github.com/geekscape/Aiko/issues).

Written by Andy Gelme and Pete Yandell.

Copyright (C) 2009 by Geekscape Pty. Ltd.
Copyright (C) 2009 by Pete Yandell.
Released under the GPLv3 license (dual-licensed).
