/*
 * Blink2
 *
 * An extension of the basic "Blink" example to demonstrate the added
 * flexibility that Aiko's event-driven approach provides. Blinks two
 * LEDs independently at different frequencies: the LED on pin 13 will
 * turn on for one second, then off for one second, and so on while an
 * LED connected to pin 12 will run at a slightly faster interval of
 * 700ms per state. As the sketch runs the relative timing of the two
 * LEDs will vary as they change state at different rates. The two
 * blink functions could therefore be replaced by your own event
 * handlers and will be invoked at the correct frequency in the order
 * the handlers are defined within setup().
 *
 * This sketch also demonstrates the use of a technique to toggle the
 * state of an output by checking the current state using digitalRead()
 * and then inverting the value before writing it back out. This
 * technique avoids the need to store the last known state of an output
 * in a global variable by using the digital I/O line itself to track
 * the current state, but be warned that this will fail if the output
 * pin itself is being electrically forced into a different state from
 * what the Arduino is attempting to assert. This can occur, for
 * example, if a digital I/O line is tied to GND via a pull-down
 * resistor: reading it will always return a "LOW" value even if it has
 * been set to a "HIGH" state using digitalWrite() because
 * digitalRead() returns the actual state of the pin, not the asserted
 * state.
 */

#include <AikoEvents.h>
using namespace Aiko;

int firstLedPin  = 13;
int secondLedPin = 12;

void setup() {
  pinMode(firstLedPin, OUTPUT);
  pinMode(secondLedPin, OUTPUT);
  Events.addHandler(blinkFirstLed, 1000);  // Every 1000ms
  Events.addHandler(blinkSecondLed, 700);  // Every 700ms
}

void loop() {
  Events.loop();
}

void blinkFirstLed() {
  digitalWrite(firstLedPin, !digitalRead(firstLedPin));
}

void blinkSecondLed() {
  digitalWrite(secondLedPin, !digitalRead(secondLedPin));
}
