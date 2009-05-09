#include <AikoEvents.h>
#include <MsTimer2.h>

using namespace Aiko;

int ledPin = 13;

void setup() {
  pinMode(ledPin, OUTPUT);
  Events.registerHandler(1000, blink);
  Events.start();
}

void blink() {
  static boolean on = HIGH;
  digitalWrite(ledPin, on);
  on = !on;
}

void loop() {
  Events.loop();
}
