loop
====
To cause event handlers specified using addHandler to be executed the
sketch needs to make a call to Events.loop() within the main program
loop.

In an application which is executed entirely by Aiko event handlers the
main program loop can be as simple as:

  void loop() {
    Events.loop();
  }
