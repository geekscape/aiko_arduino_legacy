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
  Serial.print((int) hour);
  Serial.print(":");
  Serial.print((int) minute);
  Serial.print(":");
  Serial.println((int) second);
}
