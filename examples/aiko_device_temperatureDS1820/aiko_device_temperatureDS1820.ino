#include <OneWire.h>
#include <AikoDevices.h>
#include <AikoEvents.h>

using namespace Aiko;
using namespace Device;

void setup() {
  Serial.begin(38400);
  Events.addHandler(temperatureDS1820Handler, 1000);
  Events.addHandler(outputHandler,            1000);
}

void loop() {
  Events.loop();
}

void outputHandler(void) {
  if (temperatureDS1820Ready) {
    Serial.print(temperatureDS1820Whole);
    Serial.print(".");
    if (temperatureDS1820Fraction < 10) Serial.print("0");
    Serial.print(temperatureDS1820Fraction);
    Serial.println(" C");
  }
}
