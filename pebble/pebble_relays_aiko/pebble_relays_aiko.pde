#include <Aiko.h>

using namespace Aiko;

#define PIN_RELAY_1 6
#define PIN_RELAY_2 7

byte relay1State = HIGH;
byte relay2State = LOW;

void setup() {
  pinMode(PIN_RELAY_1, OUTPUT);
  pinMode(PIN_RELAY_2, OUTPUT);

  Events.addHandler(relay1Handler, 500);
  Events.addHandler(relay2Handler, 600);
}

void loop() {
  Events.loop();
}

void relay1Handler() {
  digitalWrite(PIN_RELAY_1, relay1State);
  relay1State = ! relay1State;
}

void relay2Handler() {
  digitalWrite(PIN_RELAY_2, relay2State);
  relay2State = ! relay2State;
}
