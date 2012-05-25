#include <OneWire.h>
#include <AikoCommands.h>
#include <AikoEvents.h>

using namespace Aiko;
using namespace Command;

void setup() {
  Serial.begin(38400);

  Events.addHandler(clockHandler,  1000);
  Events.addHandler(outputHandler, 1000);
}

void loop() {
  Events.loop();
}

void outputHandler(void) {
  if (second > 20) resetClockCommand();

  outputNumber(hour);
  Serial.print(":");
  outputNumber(minute);
  Serial.print(":");
  outputNumber(second);
  Serial.println();
}

void outputNumber(
  byte number) {

  if (number < 10) Serial.print("0");
  Serial.print((int) number);
}
