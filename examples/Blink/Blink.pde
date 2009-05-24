#include <AikoEvents.h>
using namespace Aiko;

int ledPin = 13;

void setup() {
  pinMode(ledPin, OUTPUT);
  Events.addHandler(blink, 1000);  // Every 1000ms
}

void loop() {
  Events.loop();
}

void blink() {
  digitalWrite(ledPin, !digitalRead(ledPin));
}
