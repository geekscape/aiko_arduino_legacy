#include <AikoEvents.h>

using namespace Aiko;

int ledPin = 13;

void setup() {
  pinMode(ledPin, OUTPUT);
  Events.addHandler(blink, 1000);
}

void blink() {
  static boolean on = HIGH;
  digitalWrite(ledPin, on);
  on = !on;
}

void loop() {
  Events.loop();
}
