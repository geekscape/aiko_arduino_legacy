/*
 * Blink
 *
 * An "Aiko-ised" version of the basic Arduino example.  Turns on an
 * LED on for one second, then off for one second, and so on...  We
 * use pin 13 because, depending on your Arduino board, it has either a
 * built-in LED or a built-in resistor so that you need only an LED.
 *
 * The difference between this version and the original "Blink" is that
 * using Aiko allows the blink function to be called at a specified
 * interval and return immediately rather than using delay and blocking
 * the execution of other code in the sketch.
 */

#include <OneWire.h>
#include <AikoEvents.h>

using namespace Aiko;

int ledPin = 13;

void setup(void) {
  pinMode(ledPin, OUTPUT);

  Events.addHandler(blink, 1000);  // Every 1000ms
}

void loop(void) {
  Events.loop();
}

void blink(void) {
  static boolean on = HIGH;

  digitalWrite(ledPin, on);

  on = ! on;
}
